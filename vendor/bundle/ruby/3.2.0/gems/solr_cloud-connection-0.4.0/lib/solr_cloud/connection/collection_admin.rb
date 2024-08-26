# frozen_string_literal: true

module SolrCloud
  class Connection
    # methods having to do with collections, to be included by the connection object.
    # These are split out only to make it easier to deal with them.
    #
    # For almost everything in here, we treat aliases like collections -- calls to #collections,
    # #has_collection?, #collection, etc. will respond to, and return, and alias if there is one.
    # The idea is that you shouldn't need to know if something is an alias or a collection
    # until it's relevant
    module CollectionAdmin
      # Create and return a new collection.
      # @param name [String] Name for the new collection
      # @param configset [String, Configset] (name of) the configset to use for this collection
      # @param shards [Integer]
      # @param replication_factor [Integer]
      # @raise [IllegalNameError]
      # @raise [NoSuchConfigSetError] if the named configset doesn't exist
      # @raise [WontOverwriteError] if the collection already exists
      # @return [Collection] the collection created
      def create_collection(name:, configset:, shards: 1, replication_factor: 1)

        unless legal_solr_name?(name)
          raise IllegalNameError.new("'#{name}' is not a valid solr name. Use only ASCII letters/numbers, dash, and underscore")
        end

        configset_name = case configset
                           when Configset
                             configset.name
                           else
                             configset.to_s
                         end
        raise WontOverwriteError.new("Collection #{name} already exists") if has_collection?(name)
        raise NoSuchConfigSetError.new("Configset '#{configset_name}' doesn't exist") unless has_configset?(configset_name)

        args = {
          :action => "CREATE",
          :name => name,
          :numShards => shards,
          :replicationFactor => replication_factor,
          "collection.configName" => configset_name
        }
        connection.get("solr/admin/collections", args)
        get_collection(name)
      end

      # Get a list of _only_ collections, as opposed to the mix of collections and aliases we
      # usually do.
      def only_collections
        connection.get("api/collections").body["collections"].map { |c| Collection.new(name: c, connection: self) }
      end

      # The names of only connections (and not aliases). Useful as a utility.
      # @return [Array<String>] the names of the connections
      def only_collection_names
        only_collections.map(&:name)
      end

      # Get a list of collections (and aliases)
      # @return [Array<Collection, Alias>] possibly empty list of collection and alias objects
      def collections
        only_collections.union(aliases)
      end

      # A list of the names of existing collections and aliases
      # @return [Array<String>] the collection/alias names, or empty array if there are none
      def collection_names
        collections.map(&:name)
      end

      # @param name [String] name of the collection to check on
      # @return [Boolean] Whether a collection with the passed name exists
      def has_collection?(name)
        collection_names.include? name
      end

      # Get a collection object specifically for the named collection
      # @param collection_name [String] name of the (already existing) collection
      # @return [Collection, Alias, nil] The collection or alias if found, nil if not
      def get_collection(collection_name)
        return nil unless has_collection?(collection_name)
        if only_collection_names.include?(collection_name)
          Collection.new(name: collection_name, connection: self)
        else
          get_alias(collection_name)
        end
      end

      # Get a connection/alias object, throwing an error if it's not found
      # @param collection_name [String] name of the (already existing) collection
      # @return [Collection, Alias] The collection or alias
      # @raise [NoSuchCollectionError] if the collection/alias doesn't exist
      def get_collection!(collection_name)
        raise NoSuchCollectionError.new("Collection '#{collection_name}' not found") unless has_collection?(collection_name)
        get_collection(collection_name)
      end
    end
  end
end
