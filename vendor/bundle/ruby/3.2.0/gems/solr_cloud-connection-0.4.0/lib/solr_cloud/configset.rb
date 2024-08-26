# frozen_string_literal: true

require "solr_cloud/connection"

module SolrCloud
  # A configset can't do much by itself, other than try to delete itself and
  # throw an error if that's an illegal operation (because a collection is
  # using it)
  class Configset

    # @return [String] the name of this configset
    attr_reader :name

    # @return [Connection] the connection object used to build this configset object
    attr_reader :connection

    def initialize(name:, connection:)
      @name = name
      @connection = connection
    end

    # Delete this configset.
    # @see Connection#delete_configset
    # @return The underlying connection
    def delete!
      connection.delete_configset(name)
      connection
    end

    # Which collections use this configset?
    # @return [Array<Collection>] The collections defined to use this configset
    def used_by
      connection.only_collections.select { |coll| coll.configset.name == name }
    end

    # Are there any collections currently using this configset?
    # @return [Boolean]
    def in_use?
      !used_by.empty?
    end

    def inspect
      "<#{self.class.name} '#{name}' at #{connection.url}>"
    end

    alias_method :to_s, :inspect

    def pretty_print(q)
      q.text inspect
    end
  end
end
