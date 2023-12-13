module Solr
  class Uploader
    def initialize(collection:)
      @collection = S.solrcloud.get_collection collection
      @endpoint = "solr/#{collection}/update"
    end

    # Uploads docs to solr
    # @param docs [Array] Array of json strings  of docs
    def upload(docs)
      body = "[" + docs.join(",") + "]"
      @collection.post(@endpoint, body)
    end

    def commit
      @collection.commit
    end
  end
end
