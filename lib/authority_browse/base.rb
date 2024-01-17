module AuthorityBrowse
  class Base
    class << self
      # :nocov:
      [
        :reset_db,
        :remote_skos_file,
        :field_name,
        :local_skos_file,
        :from_biblio_table,
        :database_klass,
        :mutator_klass,
        :kind
      ].each do |method|
        define_method(method) { raise NotImplementedError }
      end
      # :nocov:

      def term_fetcher
        TermFetcher.new(field_name: field_name, table: from_biblio_table, database_klass: database_klass)
      end

      # Fetches terms from Biblio, updates counts in :names, and adds loc ids to
      # the :_from_biblio table
      def update(my_term_fetcher = term_fetcher)
        S.logger.info "Start Term fetcher"
        my_term_fetcher.run
        S.logger.info "Start: zeroing out counts"
        S.logger.measure_info("Zeroed out counts") do
          mutator_klass.zero_out_counts
        end
        S.logger.info "Start: update #{kind}s with counts"
        S.logger.measure_info("updated #{kind}s with counts") do
          mutator_klass.update_main_with_counts
        end
        S.logger.info "Start: add ids to #{kind}s_from_biblio"
        S.logger.measure_info("Updated ids in #{from_biblio_table}") do
          mutator_klass.add_ids_to_from_biblio
        end
      end

      # Private method
      # Writes docs to the solr_docs_file
      #
      # @yieldparam out [Zlib::GzipWriter] writes line to the solr_docs_file
      # @yieldparam milemarker [Milemarker] instance of Milemarker for writing
      # docs to a file
      def write_docs
        milemarker = Milemarker.new(name: "Write solr docs to file", batch_size: 100_000, logger: Services.logger)
        milemarker.log "Start!"
        Zinzout.zout(solr_docs_file) do |out|
          yield(out, milemarker)
        end
        milemarker.log_final_line
      end

      # Path to the file containing the solr docs
      # @return [String]
      def solr_docs_file
        S.solr_docs_file
      end

      # Fetches the names skos file from the library of congress. Puts it in the
      # tmp directory. This is a pain to test so that's why it's been extracted.
      # To try it you can run this method and put in a different url and make
      # sure it gets approriately downloaded.
      #
      # @param url [String] [location skos file for names]
      def fetch_skos_file(remote_file: remote_skos_file, local_file: local_skos_file)
        `wget -O #{local_file} #{remote_skos_file}`
      end
    end
  end
end
