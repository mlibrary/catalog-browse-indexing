# frozen_string_literal: true

require "zip"

module SolrCloud
  class Connection
    # methods having to do with configsets, to be included by the connection object.
    # These are split out only to make it easier to deal with them.
    module ConfigsetAdmin

      # Given the path to a solr configuration "conf" directory (i.e., the one with
      # solrconfig.xml in it), zip it up and send it to solr as a new configset.
      # @param name [String] Name to give the new configset
      # @param confdir [String, Pathname] Path to the solr configuration "conf" directory
      # @param force [Boolean] Whether or not to overwrite an existing configset if there is one
      # @raise [WontOverwriteError] if the configset already exists and "force" is false
      # @return [Configset] the configset created
      def create_configset(name:, confdir:, force: false)
        config_set_name = name
        unless legal_solr_name?(config_set_name)
          raise IllegalNameError.new("'#{config_set_name}' is not a valid solr configset name. Use only ASCII letters/numbers, dash, and underscore")
        end

        if has_configset?(config_set_name) && !force
          raise WontOverwriteError.new("Won't replace configset #{config_set_name} unless 'force: true' passed ")
        end
        zfile = "#{Dir.tmpdir}/solr_add_configset_#{name}_#{Time.now.hash}.zip"
        z = ZipFileGenerator.new(confdir, zfile)
        z.write
        @connection.put("api/cluster/configs/#{config_set_name}") do |req|
          req.body = File.binread(zfile)
        end
        # TODO: Error check in here somewhere
        FileUtils.rm(zfile, force: true)
        get_configset(name)
      end

      # Get a list of the already-defined configSets
      # @return [Array<Configset>] possibly empty list of configSets
      def configsets
        configset_names.map { |cs| Configset.new(name: cs, connection: self) }
      end

      # @return [Array<String>] the names of the config sets
      def configset_names
        connection.get("api/cluster/configs").body["configSets"]
      end

      # Check to see if a configset is defined
      # @param name [String] Name of the configSet
      # @return [Boolean] Whether a configset with that name exists
      def has_configset?(name)
        configset_names.include? name.to_s
      end

      # Get an existing configset
      def get_configset(name)
        Configset.new(name: name, connection: self)
      end

      # Remove the configuration set with the given name. No-op if the
      # configset doesn't actually exist. Test with {#has_configset?} and
      # {Configset#in_use?} manually if need be.
      #
      # In general, prefer using {Configset#delete!} instead of running everything
      # through the connection object.
      # @param [String] name The name of the configuration set
      # @raise [InUseError] if the configset can't be deleted because it's in use by a live collection
      # @return [Connection] self
      def delete_configset(name)
        if has_configset? name
          connection.delete("api/cluster/configs/#{name}")
        end
        self
      rescue Faraday::BadRequestError => e
        msg = e.response[:body]["error"]["msg"]
        if msg.match?(/not delete ConfigSet/)
          raise ConfigSetInUseError.new msg
        else
          raise e
        end
      end

      # Pulled from the examples for rubyzip. No idea why it's not just a part
      # of the normal interface, but I guess I'm not one to judge.
      #
      # Code taken wholesale from https://github.com/rubyzip/rubyzip/blob/master/samples/example_recursive.rb
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
end
