module Solr
  class Collection
    attr_reader :kind
    def initialize(kind:)
      @kind = kind
    end

    def daily_name
      "#{kind}_#{S.git_tag}_#{S.today}"
    end

    def configset_name
      "#{kind}_#{S.git_tag}"
    end

    def reindex_alias
      "#{kind}_reindex"
    end

    def production_alias
      kind
    end

    def solr_conf_directory
      "/app/solr/#{kind}/conf"
    end

    def min_record_count
      S.public_send("min_#{kind}_record_count")
    end
  end
end
