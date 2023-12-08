module AuthorityBrowse
  module Solr
    class NotEnoughDocsError < StandardError; end

    # The AuthorityBrowse collection name for today. It has the git tag or
    # short commit hash for the git repository and it has today's date.
    #
    # @return [String] collection name for today
    def self.collection_name
      "authority_browse_#{S.git_tag}_#{S.today}"
    end

    # The AuthorityBrowse configset name. It is `authority_browse_` followed by
    # the git tag or the short commit hash for the git repository
    #
    # @return[String]
    def self.configset_name
      "authority_browse_#{S.git_tag}"
    end

    # The Authority Browse SolrCloud reindex alias
    #
    # @return[String]
    def self.reindex_alias
      "authority_browse_reindex"
    end

    # The Authority Browse SolrCloud solr production alias
    #
    # @return[String]
    def self.production_alias
      "authority_browse"
    end

    # The directory in that has the authority browse Solr configuration files
    #
    # @return[String]
    def self.solr_conf_dir
      "/app/solr/authority_browse/conf"
    end

    # Creates the configset in SolrCloud if there isn't already a configset
    #
    # @return[Nil]
    def self.create_configset_if_needed
      if S.solrcloud.has_configset?(configset_name)
        S.solrcloud.get_configset(configset_name)
      else
        S.solrcloud.create_configset(
          name: configset_name,
          confdir: solr_conf_dir
        )
      end
    end

    # Creates the SolrCloud collection for today. This will error out if there
    # is already a collection of the same name.
    #
    # @return[Nil]
    def self.create_daily_collection
      S.solrcloud.create_collection(
        name: collection_name,
        configset: configset_name
      )
    end

    def self.latest_daily_collection
      _sorted_collections.last
    end

    # This creates the daily collection and then sets the reindex alias to that
    # collection
    #
    # @return[Nil]
    def self.set_up_daily_collection
      create_daily_collection
      set_daily_reindex_alias
    end

    # This sets the reindex alias to today's collection.
    #
    # @return[Nil]
    def self.set_daily_reindex_alias
      latest_daily_collection.alias_as(reindex_alias)
    end

    # This sets the production alias to today's collection.
    #
    # @return[Nil]
    def self.set_production_alias
      latest_daily_collection.alias_as(production_alias)
    end

    # This verifies that today's collection has enough documents in it. For now
    # the collection must have more than 7_000_000 documents in it.
    # @raise [NotEnoughDocsError] if there aren't enough docs in the collection
    # @return[Nil]
    def self.verify_reindex(min_records: S.min_authority_browse_record_count)
      raise NotEnoughDocsError unless latest_daily_collection.count > min_records
    end

    # This deletes all authority_browse collections with dates that are older
    # than the newest three authority_browse collections.
    #
    # @return[Nil]
    def self.prune_old_collections(collections_generator: lambda { |keep| AuthorityBrowse::Solr.list_old_collections(keep: keep) }, keep: 3)
      collections = collections_generator.call(keep)
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
    def self.list_old_collections(list: S.solrcloud.only_collections, keep: 3)
      _sorted_collections(list: list)[0..(0 - keep - 1)]
    end

    def self._sorted_collections(list: S.solrcloud.only_collections)
      list.select do |item|
        item.name.match?("authority_browse")
      end.sort do |a, b|
        a.name.split("_").last <=> b.name.split("_").last
      end
    end
  end
end
