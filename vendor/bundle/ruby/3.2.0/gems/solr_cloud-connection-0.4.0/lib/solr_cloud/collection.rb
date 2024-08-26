# frozen_string_literal: true

require "solr_cloud/connection"
require "forwardable"

module SolrCloud
  # A Collection provides basic services on the collection -- checking its health,
  # creating or reporting aliases, and deleting itself.
  class Collection

    extend Forwardable

    # Forward the HTTP verbs to the  underlying connection

    # @!method get
    # Forwarded on to the underlying SolrCloud connection
    # @see SolrCloud::Connection#get
    def_delegator :@connection, :get

    # @!method post
    # Forwarded on to the underlying SolrCloud connection
    # @see SolrCloud::Connection#post
    def_delegator :@connection, :post

    # @!method delete
    # Forwarded on to the underlying SolrCloud connection
    # @see SolrCloud::Connection#delete
    def_delegator :@connection, :delete

    # @!method put
    # Forwarded on to the underlying SolrCloud connection
    # @see SolrCloud::Connection#put
    def_delegator :@connection, :put

    # @return [SolrCloud::Connection] the underlying SolrCloud connection
    attr_reader :name

    # @return The name of the get_collection
    attr_reader :connection

    # In general, users shouldn't use Collection.new; instead, use
    # connection.create_collection(name: "coll_name", configset: "existing_configset_name")
    #
    # @param [String] name The name of the (already existing) collection
    # @param [SolrCloud::Connection] connection Connection to the solr "root" (http://blah:8888/)
    def initialize(name:, connection:)
      # raise NoSuchCollectionError.new("No collection #{name}") unless connection.has_collection?(name)
      @connection = connection.dup
      @name = name
      @sp = "/solr/#{name}"
    end

    # Delete this collection. Will no-op if the collection somehow doesn't still exist (because it was
    # deleted via a different method, such as through the API)
    # @return [Connection] The connection object used to create this collection object
    def delete!
      return connection unless exist?
      raise CollectionAliasedError.new("Cannot delete collection #{name}; it has alias(s) #{alias_names.join(", ")}") if aliased?
      connection.get("solr/admin/collections", { action: "DELETE", name: name })
      connection
    end

    # Does this collection still exist?
    # @return [Boolean]
    def exist?
      connection.only_collection_names.include?(name)
    end

    # Check to see if the collection is alive
    # @return [Boolean]
    def alive?
      connection.get("solr/#{name}/admin/ping").body["status"]
    rescue Faraday::ResourceNotFound
      false
    end

    # Is this an alias?
    # Putting this in here breaks all sorts of isolation principles,
    # but being able to call #get_alias? on anything collection-like is
    # convenient
    def alias?
      false
    end

    # Access to the root info from the api. Mostly for internal use, but not labeled as such
    # 'cause users will almost certainly find a use for it.
    def info
      connection.get("api/collections/#{name}").body["cluster"]["collections"][name]
    end

    # Reported as healthy?
    # @return [Boolean]
    def healthy?
      info["health"] == "GREEN"
    end

    # A (possibly empty) list of aliases targeting this collection
    # @return [Array<SolrCloud::Alias>] list of aliases that point to this collection
    def aliases
      connection.alias_map.select { |_alias_name, ac| ac.collection.name == name }.values.map(&:alias)
    end

    # The names of the aliases that point to this collection
    # @return [Array<String>] the alias names
    def alias_names
      aliases.map(&:name)
    end

    # Does this collection have at least one alias?
    # @return [Boolean] whether or not it has an alias
    def aliased?
      !aliases.empty?
    end

    # Do we have an alias of the given name?
    # Get a specific alias by name
    # @param alias_name [String] name of the alias
    # @return [Boolean]
    def has_alias?(alias_name)
      alias_names.include?(alias_name)
    end

    # Get an alias that points to this collection by name, or nil if not found
    # @param alias_name [String] name of the alias
    # @return [Alias, nil] The alias object, or nil if not found
    def get_alias(alias_name)
      return nil unless has_alias?(alias_name)
      connection.get_alias(alias_name)
    end

    # Create an alias for this collection. Always forces an overwrite unless you tell it not to
    # @param alias_name [String] name of the alias to create
    # @param force [Boolean] whether or not to overwrite an existing alias
    # @return [SolrCloud::Alias]
    def alias_as(alias_name, force: true)
      connection.create_alias(name: alias_name, collection_name: name, force: true)
    end

    # Send a commit (soft if unspecified)
    # @return self
    def commit(hard: false)
      if hard
        connection.get("solr/#{name}/update", commit: true)
      else
        connection.get("solr/#{name}/update", softCommit: true)
      end
      self
    end

    # What configset was this created with?
    # @return [SolrCloud::ConfigSet]
    def configset
      Configset.new(name: info["configName"], connection: connection)
    end

    # Add a document or array of documents
    # @todo Gotta check for errors and such!
    # @param docs [Hash, Array<Hash>] One or more documents to add
    # @return self

    def add(docs)
      docarray = if docs === Array
                   docs
                 else
                   [docs]
                 end
      post("solr/#{name}/update/") do |r|
        r.body = docarray
      end
      self
    end

    # Get a count of how many documents are in the index
    # @return [Fixnum] the number of documents
    def count
      get("solr/#{name}/select", q: "*:*").body["response"]["numFound"]
    end

    def inspect
      anames = alias_names
      astring = if anames.empty?
                  ""
                else
                  " (aliased by #{anames.map { |x| "'#{x}'" }.join(", ")})"
                end
      "<#{self.class} '#{name}'#{astring}>"
    end

    alias_method :to_s, :inspect

    def pretty_print(q)
      q.text inspect
    end
  end
end
