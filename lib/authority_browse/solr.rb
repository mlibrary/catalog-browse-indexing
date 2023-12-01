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
      unless S.solrcloud.configset?(configset_name)
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
      S.solrcloud.create_alias(name: reindex_alias, collection_name: collection_name)
    end

    # This sets the production alias to today's collection.
    #
    # @return[Nil]
    def self.set_production_alias
      S.solrcloud.create_alias(name: production_alias, collection_name: collection_name)
    end

    # This verifies that today's collection has enough documents in it. For now
    # the collection must have more than 7_000_000 documents in it.
    #
    # @return[Nil]
    def self.verify_reindex
      body = S.solrcloud.get("solr/#{collection_name}/select", {q: "*:*"}).body
      raise NotEnoughDocsError unless body["response"]["numFound"] > 7000000
    end

    # This deletes all authority_browse collections with dates that are older
    # than the newest three authority_browse collections.
    #
    # @return[Nil]
    def self.prune_old_collections
      S.logger.info "Pruning the following collections: #{list_old_collections}"
      list_old_collections.map { |c| S.solrcloud.connection(c) }.each do |coll|
        coll.delete!
      end
    end

    # Lists the authority_browse collections that are older than the newest
    # three authority_browse collections
    #
    # @param list [Array] Array of all SolrCloud collections
    # @param keep [Integer] how many versions to keep, even if they're old
    # @return [Array] Array of old authority browse Solrcloud collection
    # strings
    def self.list_old_collections(list = S.solrcloud.collections, keep: 3)
      list.select do |item|
        item.match?("authority_browse")
      end.sort do |a, b|
        Date.parse(a.split("_").last) <=> Date.parse(b.split("_").last)
      end[0..(0 - keep - 1)]
    end
  end
end
