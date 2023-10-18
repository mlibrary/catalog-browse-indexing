module AuthorityBrowse
  class SolrUploader
    def initialize(collection:)
      @conn = AuthorityBrowse::Solr::Admin.new.collection_for(collection)
      @endpoint = "update"
    end

    # Uploads docs to solr
    # @param docs [Array] Array of json strings  of docs
    def upload(docs)
      body = "[" + docs.join(",") + "]"
      @conn.post(@endpoint, body)
    end

    def commit
      @conn.get(@endpoint, commit: "true")
    end
  end
end
