module AuthorityBrowse
  class Base
    class << self
      def reset_db
        raise NotImplementedError
      end

      def remote_skos_file
        raise NotImplementedError
      end

      def field_name
        raise NotImplementedError
      end

      # Sequel query that gets names and see alsos with their counts
      #
      # Private method
      # @param solr_uploader [AuthorityBrowse::Solr::Uploader]
      # @yieldparam out [Zlib::GzipWriter] writes line to the solr_docs_file
      # @yieldparam milemarker [Milemarker] instance of Milemarker for writing
      # docs to a file
      def write_and_send_docs(solr_uploader)
        milemarker = Milemarker.new(name: "Write solr docs to file", batch_size: 100_000, logger: Services.logger)
        milemarker.log "Start!"
        Zinzout.zout(solr_docs_file) do |out|
          yield(out, milemarker)
        end
        milemarker.log_final_line
        send_to_solr(solr_uploader)
      end

      # Reads solr_docs_file and sends the docs to the solr collection specified
      # in the Solr::Uploader
      #
      # Private method
      # @param solr_uploader [AuthorityBrowse::Solr::Uploader]
      def send_to_solr(solr_uploader)
        batch_size = 100_000

        milemarker = Milemarker.new(batch_size: 100_000, name: "Docs sent to solr", logger: Services.logger)
        milemarker.log "Sending #{solr_docs_file} in batches of #{batch_size}"

        Zinzout.zin(solr_docs_file) do |infile|
          infile.each_slice(batch_size) do |batch|
            solr_uploader.upload(batch)
            milemarker.increment(batch_size)
            milemarker.on_batch { milemarker.log_batch_line }
          end
        end

        milemarker.log "Committing"
        solr_uploader.commit
        milemarker.log "Finished"
        milemarker.log_final_line
      end

      # Path to the file containing the solr docs
      # @return [String]
      def solr_docs_file
        "tmp/solr_docs.jsonl.gz"
      end
    end
  end
end
