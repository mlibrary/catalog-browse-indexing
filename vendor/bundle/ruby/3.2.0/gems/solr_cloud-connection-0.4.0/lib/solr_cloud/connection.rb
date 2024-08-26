# frozen_string_literal: true

require "faraday"
require "httpx/adapters/faraday"
require "logger"

require_relative "connection/version"
require_relative "connection/configset_admin"
require_relative "connection/collection_admin"
require_relative "connection/alias_admin"
require_relative "collection"
require_relative "alias"
require_relative "configset"
require_relative "errors"

require "forwardable"

module SolrCloud
  # The connection object is the basis of all the other stuff. Everything will be created, directly
  # or indirectly, through the connection.
  #
  # For convenience, it forwards #get, #post, #put, and #delete HTTP verbs to the underlying
  # raw faraday http client.
  class Connection
    extend Forwardable

    include ConfigsetAdmin
    include CollectionAdmin
    include AliasAdmin

    # @return [String] String representation of the URL to solr
    attr_reader :url

    # @return [#info] The logger
    attr_reader :logger

    # @return [Faraday::Connection] the underlying Faraday connection
    attr_reader :connection

    # let the underlying connection handle HTTP verbs

    # @!method get
    # Forwarded on to the underlying Faraday connection
    # @see Faraday::Connection.get
    def_delegator :@connection, :get

    # @!method post
    # Forwarded on to the underlying Faraday connection
    # @see Faraday::Connection.post
    def_delegator :@connection, :post

    # @!method delete
    # Forwarded on to the underlying Faraday connection
    # @see Faraday::Connection.delete
    def_delegator :@connection, :delete

    # @!method put
    # Forwarded on to the underlying Faraday connection
    # @see Faraday::Connection.put
    def_delegator :@connection, :put

    # Create a new connection to talk to solr
    # @param url [String] URL to the "root" of the solr installation. For a default solr setup, this will
    # just be the root url (_not_ including the `/solr`)
    # @param user [String] username for basic auth, if you're using it
    # @param password [String] password for basic auth, if you're using it
    # @param logger [#info, :off, nil] An existing logger to pass in. The symbol ":off" means
    #   don't do logging. If left undefined, will create a standard ruby logger to $stdout
    # @param adapter [Symbol] The underlying http library to use within Faraday
    def initialize(url:, user: nil, password: nil, logger: nil, adapter: :httpx)
      @url = url
      @user = user
      @password = password
      @logger = case logger
                  when :off, :none
                    Logger.new(File::NULL, level: Logger::FATAL)
                  when nil
                    Logger.new($stderr, level: Logger::WARN)
                  else
                    logger
                end
      @connection = create_raw_connection(url: url, adapter: adapter, user: user, password: password, logger: @logger)
      bail_if_incompatible!
      @logger.info("Connected to supported solr at #{url}")
    end

    # Pass in your own faraday connection
    # @param faraday_connection [Faraday::Connection] A pre-build faraday connection object
    def self.new_from_faraday(faraday_connection)
      c = allocate
      c.instance_variable_set(:@connection, faraday_connection)
      c.instance_variable_set(:@url, faraday_connection.build_url.to_s)
      c
    end

    # Create a Faraday connection object to base the API client off of
    # @see #initialize
    def create_raw_connection(url:, adapter: :httpx, user: nil, password: nil, logger: nil)
      Faraday.new(request: { params_encoder: Faraday::FlatParamsEncoder }, url: URI(url)) do |faraday|
        faraday.use Faraday::Response::RaiseError
        faraday.request :url_encoded
        if user
          faraday.request :authorization, :basic, user, password
        end
        faraday.request :json
        faraday.response :json
        if logger
          faraday.response :logger, logger
        end
        faraday.adapter adapter
        faraday.headers["Content-Type"] = "application/json"
      end
    end

    # Allow accessing the raw_connection via "connection". Yes, connection.connection
    # can be confusing, but it makes the *_admin stuff easier to read.
    alias_method :connection, :connection

    # Check to see if we can actually talk to the solr in question
    # raise [UnsupportedSolr] if the solr version isn't at least 8
    # raise [ConnectionFailed] if we can't connect for some reason
    def bail_if_incompatible!
      raise UnsupportedSolr.new("SolrCloud::Connection needs at least solr 8") if major_version < 8
      raise UnsupportedSolr.new("SolrCloud::Connection only works in solr cloud mode") unless cloud?
    rescue Faraday::ConnectionFailed
      raise ConnectionFailed.new("Can't connect to #{url}")
    end

    # Get basic system info from the server
    # @raise [Unauthorized] if the server gives a 401
    # @return [Hash] The response from the info call
    def system
      resp = get("/solr/admin/info/system")
      resp.body
    rescue Faraday::UnauthorizedError
      raise Unauthorized.new("Server reports failed authorization")
    end

    # @return [String] the mode ("solrcloud" or "std") solr is running in
    def mode
      system["mode"]
    end

    # @return [Boolean] whether or not solr is running in cloud mode
    def cloud?
      mode == "solrcloud"
    end

    # @return [String] the major.minor.patch string of the solr version
    def version_string
      system["lucene"]["solr-spec-version"]
    end

    # Helper method to get version parts as ints
    # @return [Integer] Integerized version of the 0,1,2 portion of the version string
    def _version_part_int(index)
      version_string.split(".")[index].to_i
    end

    # @return [Integer] solr major version
    def major_version
      _version_part_int(0)
    end

    # @return [Integer] solr minor version
    def minor_version
      _version_part_int(1)
    end

    # @return [Integer] solr patch version
    def patch_version
      _version_part_int(2)
    end

    # Check to see if the given string follows solr's rules for thing
    # Solr only allows ASCII letters and numbers, underscore, and dash,
    # and it can't start with an underscore.
    # @param str [String] string to check
    # @return [Boolean]
    def legal_solr_name?(str)
      !(/[^a-zA-Z_\-.0-9]/.match?(str) or str.start_with?("-"))
    end

    def inspect
      "<#{self.class} #{@url}>"
    end

    alias_method :to_s, :inspect

    def pretty_print(q)
      q.text inspect
    end
  end
end



