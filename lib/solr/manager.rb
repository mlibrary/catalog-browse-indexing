require "forwardable"
module Solr
  class Manager
    class NotEnoughDocsError < StandardError; end

    extend Forwardable

    def_delegators :@collection, :kind, :daily_name, :configset_name, :reindex_alias, :production_alias, :solr_conf_directory, :min_record_count

    def initialize(collection)
      @collection = collection
    end

    # Creates the configset in SolrCloud if there isn't already a configset
    #
    # @return[Nil]
    def create_configset_if_needed
      if S.solrcloud.has_configset?(configset_name)
        S.solrcloud.get_configset(configset_name)
      else
        S.solrcloud.create_configset(
          name: configset_name,
          confdir: solr_conf_directory
        )
      end
    end

    def latest_daily_collection
      _sorted_collections.last
    end

    # Creates the SolrCloud collection for today. This will error out if there
    # is already a collection of the same name.
    #
    # @return[Nil]
    def create_daily_collection
      S.solrcloud.create_collection(
        name: daily_name,
        configset: configset_name
      )
    end

    # This creates the daily collection and then sets the reindex alias to that
    # collection
    #
    # @return[Nil]
    def set_up_daily_collection
      create_daily_collection
      set_daily_reindex_alias
    end

    # This sets the reindex alias to today's collection.
    #
    # @return[Nil]
    def set_daily_reindex_alias
      latest_daily_collection.alias_as(reindex_alias)
    end

    # This sets the production alias to today's collection.
    #
    # @return[Nil]
    def set_production_alias
      latest_daily_collection.alias_as(production_alias)
    end

    # This verifies that today's collection has enough documents in it. For now
    # the collection must have more than 7_000_000 documents in it.
    # @raise [NotEnoughDocsError] if there aren't enough docs in the collection
    # @return[Nil]
    def verify_reindex
      raise NotEnoughDocsError unless latest_daily_collection.count > min_record_count
    end

    # This deletes all authority_browse collections with dates that are older
    # than the newest three authority_browse collections.
    #
    # @return[Nil]
    def prune_old_collections(keep: 3)
      collections = list_old_collections(keep: keep)
      S.logger.info "Pruning the following collections: #{collections}"
      collections.each do |coll|
        coll.delete!
      end
    end

    # Lists the authority_browse collections that are older than the newest
    # three authority_browse collections
    #
    # @param list [Array<SolrCloud::Collection>] Array of all SolrCloud collections
    # @param keep [Integer] how many versions to keep, even if they're old
    # @return [Array<SolrCloud::Collection>] Array of old authority browse Solrcloud collections
    def list_old_collections(list: S.solrcloud.only_collections, keep: 3)
      _sorted_collections(list: list)[0..(0 - keep - 1)]
    end

    def _sorted_collections(list: S.solrcloud.only_collections)
      list.select do |item|
        item.name.match?("authority_browse")
      end.sort do |a, b|
        a.name.split("_").last <=> b.name.split("_").last
      end
    end

    class AuthorityBrowse
      def self.new
        Solr::Manager.new(Solr::Collection.new(kind: "authority_browse"))
      end
    end
  end
end
