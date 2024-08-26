# frozen_string_literal: true

module SolrCloud
  class Connection
    # methods having to do with aliases, to be included by the connection object.
    # These are split out only to make it easier to deal with them.
    module AliasAdmin

      # A simple data-class to pair an alias with its collection
      AliasCollectionPair = Struct.new(:alias, :collection)

      # Create an alias for the given collection name.
      #
      # In general, prefer {Collection#alias_as} instead of
      # running everything through the connection object.
      # @param name [String] Name of the new alias
      # @param collection_name [String] name of the collection
      # @param force [Boolean] whether to overwrite an existing alias
      # @raise [NoSuchCollectionError] if the collections isn't found
      # @return [Alias] the newly-created alias
      def create_alias(name:, collection_name:, force: false)
        unless legal_solr_name?(name)
          raise IllegalNameError.new("'#{name}' is not a valid solr alias name. Use only ASCII letters/numbers, dash, and underscore")
        end
        raise NoSuchCollectionError.new("Can't find collection #{collection_name}") unless has_collection?(collection_name)
        if has_alias?(name) && !force
          raise WontOverwriteError.new("Alias '#{name}' already points to collection '#{self.get_alias(name).collection.name}'; won't overwrite without force: true")
        end
        connection.get("solr/admin/collections", action: "CREATEALIAS", name: name, collections: collection_name)
        get_alias(name)
      end

      # Is there an alias with this name?
      # @return [Boolean]
      def has_alias?(name)
        alias_names.include? name
      end

      # List of alias objects
      # @return [Array<SolrCloud::Alias>] List of aliases
      def aliases
        alias_map.values.map(&:alias)
      end

      # List of alias names
      # @return [Array<String>] the alias names
      def alias_names
        alias_map.keys
      end

      # Get an alias object for the given name, erroring out if not found
      # @param name [String] the name of the existing alias
      # @return [Alias, nil] The alias if found, otherwise nil
      def get_alias(name)
        return nil unless has_alias?(name)
        alias_map[name].alias
      end

      # Get an alias object for the given name, erroring out if not found
      # @param name [String] the name of the existing alias
      # @raise [SolrCloud::NoSuchAliasError] if it doesn't exist
      # @return [SolrCloud::Alias]
      def get_alias!(name)
        raise NoSuchAliasError unless has_alias?(name)
        get_alias(name)
      end

      # Get the aliases and create a map of the form AliasName -> AliasObject
      # @return [Hash<String,Alias>] A hash mapping alias names to alias objects
      def alias_map
        raw_alias_map.keys.each_with_object({}) do |alias_name, h|
          a = Alias.new(name: alias_name, connection: self)
          c = Collection.new(name: raw_alias_map[alias_name], connection: self)
          h[alias_name] = AliasCollectionPair.new(a, c)
        end
      end

      # The "raw" alias map, which just maps alias names to collection names
      # @return [Hash<String, String>]
      def raw_alias_map
        connection.get("solr/admin/collections", action: "LISTALIASES").body["aliases"]
      end
    end
  end
end


