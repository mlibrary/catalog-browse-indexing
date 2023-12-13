module Solr
  class Uploader
    def initialize(collection:)
      @collection = S.solrcloud.get_collection collection
      @endpoint = "solr/#{collection}/update"
    end

    # [TODO:description]
    # @param solr_docs_file [String] path to json.gzip file with solr documents
    def send_file_to_solr(solr_docs_file)
      batch_size = 100_000

      milemarker = Milemarker.new(batch_size: 100_000, name: "Docs sent to solr", logger: Services.logger)
      milemarker.log "Sending #{solr_docs_file} in batches of #{batch_size}"

      Zinzout.zin(solr_docs_file) do |infile|
        infile.each_slice(batch_size) do |batch|
          upload(batch)
          milemarker.increment(batch_size)
          milemarker.on_batch { milemarker.log_batch_line }
        end
      end

      milemarker.log "Committing"
      commit
      milemarker.log "Finished"
      milemarker.log_final_line
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
