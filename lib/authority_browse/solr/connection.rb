# frozen_string_literal: true

require "faraday"
require "httpx/adapters/faraday"
require "services"
require "delegate"
require "uri"
require "zip"

module AuthorityBrowse
  module Solr
    class NoSuchCollectionError < ArgumentError; end

    class NoSuchConfigSetError < ArgumentError; end

    class WontOverwriteError < ArgumentError; end

    class InUseError < ArgumentError; end

    class Connection < SimpleDelegator
      attr_accessor :host
      attr_reader :conn

      def initialize(host = S.solr_host)
        @conn = Faraday.new(request: {params_encoder: Faraday::FlatParamsEncoder}, url: URI(host)) do |builder|
          builder.use Faraday::Response::RaiseError
          builder.request :url_encoded
          builder.request :json
          builder.request :authorization, :basic, S.solr_user, S.solr_password
          builder.response :json
          builder.adapter :httpx
          builder.headers["Content-Type"] = "application/json"
        end
        @host = host
        __setobj__(@conn)
      end
    end

    class Admin < Connection
      def configsets
        get("api/cluster/configs").body["configSets"]
      end

      alias_method :configSets, :configsets
      alias_method :configurations, :configsets

      def configset?(setname)
        configsets.include? setname.to_s
      end

      def create_configset(name:, confdir:, force: false)
        if configset?(name) && force == false
          raise WontOverwriteError.new("Won't replace configset #{name} unless 'force: true' passed ")
        end
        zfile = "tmp/solr_add_configset_#{name}_#{Time.now.hash}.zip"
        FileUtils.rm(zfile, force: true)
        z = ZipFileGenerator.new(confdir, zfile)
        z.write
        put("api/cluster/configs/#{name}") do |req|
          req.body = File.binread(zfile)
        end
        # TODO: Error check in here somewhere?
        FileUtils.rm(zfile, force: true)
      end

      # Remove the configuration set with the given name. No-op if the
      # configset doesn't actually exist.
      # @param [String,Symbol] name The name of the configuration set
      # @return [Connection] self
      def delete_configset(name)
        if configset? name
          delete("api/cluster/configs/#{name}")
        end
        self
      rescue Faraday::BadRequestError => e
        msg = e.response[:body]["error"]["msg"]
        if /not delete ConfigSet/.match?(msg)
          raise InUseError.new msg
        else
          raise e
        end
      end

      def collections
        get("solr/admin/collections", action: "LIST").body["collections"]
      end

      def collection?(name)
        collections.include? name
      end

      def create_collection(name:, configset:, shards: 1, replication_factor: 1)
        # TODO what if the collection exists?
        raise NoSuchConfigSetError.new("Configset #{configset} doesn't exist") unless configset?(configset)
        args = {
          :action => "CREATE",
          :name => name,
          :numShards => shards,
          :replicationFactor => replication_factor,
          "collection.configName" => configset
        }
        get("solr/admin/collections", args)
        self
      end

      def delete_collection(name)
        if collection? name
          get("solr/admin/collections", {action: "DELETE", name: name})
        end
        self
      end

      def collection_for(collection_name)
        unless collection?(collection_name)
          raise NoSuchCollectionError.new("Collection #{collection_name} doesn't exist")
        end

        Collection.new("#{host}/solr/#{collection_name}")
      end
    end

    class Collection < Connection
      def ping?
        get("admin/ping").body["status"]
      rescue Faraday::ResourceNotFound
        false
      end
    end

    # Pulled from the examples for rubyzip. No idea why it's not just a part
    # of the normal interface.
    class ZipFileGenerator
      # Initialize with the directory to zip and the location of the output archive.
      def initialize(input_dir, output_file)
        @input_dir = input_dir
        @output_file = output_file
      end

      # Zip the input directory.
      def write
        entries = Dir.entries(@input_dir) - %w[. ..]
        ::Zip::File.open(@output_file, create: true) do |zipfile|
          write_entries entries, "", zipfile
        end
      end

      private

      # A helper method to make the recursion work.
      def write_entries(entries, path, zipfile)
        entries.each do |e|
          zipfile_path = (path == "") ? e : File.join(path, e)
          disk_file_path = File.join(@input_dir, zipfile_path)

          if File.directory? disk_file_path
            recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
          else
            put_into_archive(disk_file_path, zipfile, zipfile_path)
          end
        end
      end

      def recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
        zipfile.mkdir zipfile_path
        subdir = Dir.entries(disk_file_path) - %w[. ..]
        write_entries subdir, zipfile_path, zipfile
      end

      def put_into_archive(disk_file_path, zipfile, zipfile_path)
        zipfile.add(zipfile_path, disk_file_path)
      end
    end
  end
end
