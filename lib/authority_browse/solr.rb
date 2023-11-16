module AuthorityBrowse
  module Solr
    class NotEnoughDocsError < StandardError; end

    def self.collection_name
      "authority_browse_#{S.git_tag}_#{S.today}"
    end

    def self.configset_name
      "authority_browse_#{S.git_tag}"
    end

    def self.reindex_alias
      "authority_browse_reindex"
    end

    def self.production_alias
      "authority_browse"
    end

    def self.solr_conf_dir
      "/app/solr/authority_browse/conf"
    end

    def self.create_configset_if_needed
      byebug
      unless S.solrcloud.configset?(configset_name)
        S.solrcloud.create_configset(
          name: configset_name,
          confdir: solr_conf_dir
        )
      end
    end

    def self.create_daily_collection
      S.solrcloud.create_collection(
        name: collection_name,
        configset: configset_name
      )
    end

    def self.setup_daily_collection
      create_daily_collection
      set_daily_reindex_alias
    end

    def self.set_daily_reindex_alias
      S.solrcloud.get(
        "solr/admin/collections",
        {
          action: "CREATEALIAS",
          name: reindex_alias,
          collections: [collection_name]
        }
      )
    end

    def self.set_production_alias
      S.solrcloud.get(
        "solr/admin/collections",
        {
          action: "CREATEALIAS",
          name: production_alias,
          collections: [collection_name]
        }
      )
    end

    def self.verify_reindex
      body = S.solrcloud.get("solr/#{collection_name}/select", {q: "*:*"}).body
      raise NotEnoughDocsError unless body["response"]["numFound"] > 7000000
    end
  end
end