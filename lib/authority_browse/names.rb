module AuthorityBrowse
  module Names
    class << self
      # Loads the names and names_see_also table with data from loc
      # @param loc_file_getter [Proc] when called needs to put a file with skos
      # data into skos_file
      def reset_db(loc_file_getter = lambda { fetch_skos_file })
        # get names file
        loc_file_getter.call

        db = AuthorityBrowse.db
        names_table = AuthorityBrowse.db[:names]
        see_also_table = AuthorityBrowse.db[:names_see_also]

        DB::Names.recreate_table!(:names)
        DB::Names.recreate_table!(:names_see_also)

        milemarker = Milemarker.new(batch_size: 100_000, name: "adding to entries array", logger: Services.logger)
        milemarker.log "Starting adding to entries array"
        Zinzout.zin(skos_file).each_slice(100_000) do |slice|
          # Zinzout.zin("./data/smaller.jsonld.gz").each_slice(100_000) do |slice|
          entries = slice.map do |line|
            AuthorityBrowse::LocAuthorities::Entry.new(JSON.parse(line))
          end
          db.transaction do
            entries.each do |entry|
              names_table.insert(id: entry.id, label: entry.label, match_text: entry.match_text, deprecated: entry.deprecated?)
            end
          end

          db.transaction do
            entries.each do |entry|
              if entry.see_also_ids?
                entry.see_also_ids.each do |see_also_id|
                  see_also_table.insert(name_id: entry.id, see_also_id: see_also_id)
                end
              end
            end
          end
          milemarker.increment(100_000)
          milemarker.on_batch { milemarker.log_batch_line }
        end

        milemarker.log_final_line

        DBMutator::Names.remove_deprecated_when_undeprecated_match_text_exists
      end

      # Fetches terms from Biblio, updates counts in :names, and adds loc ids to
      # :names_from_biblio
      def update
        TermFetcher.run
        DBMutator::Names.zero_out_counts
        DBMutator::Names.update_names_with_counts
        DBMutator::Names.add_ids_to_names_from_biblio
      end

      # Loads solr with documents of names that match data from library of
      # congress.
      # @param solr_uploader [AuthorityBrowse::SolrUploader]
      def load_solr_with_matched(solr_uploader = AuthorityBrowse::SolrUploader.new(collection: "authority_browse"))
        write_and_send_docs(solr_uploader) do |out, milemarker|
          AuthorityBrowse.db.fetch(get_matched_query).chunk_while { |bef, aft| aft[:id] == bef[:id] }.each do |ary|
            out.puts AuthorityBrowse::SolrDocument::Names::AuthorityGraphSolrDocument.new(ary).to_solr_doc
            milemarker.increment_and_log_batch_line
          end
        end
      end

      # Loads solr with documents of names that don't match entries in library
      # of congress
      # @param solr_uploader [AuthorityBrowse::SolrUploader]
      def load_solr_with_unmatched(solr_uploader = AuthorityBrowse::SolrUploader.new(collection: "authority_browse"))
        write_and_send_docs(solr_uploader) do |out, milemarker|
          AuthorityBrowse.db[:names_from_biblio].filter(name_id: nil).where { count > 0 }.each do |name|
            out.puts AuthorityBrowse::SolrDocument::Names::UnmatchedSolrDocument.new(name).to_solr_doc
            milemarker.increment_and_log_batch_line
          end
        end
      end

      # Sequel query that gets names and see alsos with their counts
      #
      # Private method
      # @param solr_uploader [AuthorityBrowse::SolrUploader]
      # @yieldparam out [Zlib::GzipWriter] writes line to the solr_docs_file
      # @yieldparam milemarker [Milemarker] instance of Milemarker for writing
      # docs to a file
      def write_and_send_docs(solr_uploader)
        milemarker = Milemarker.new(name: "Write solr docs to file", batch_size: 100, logger: Services.logger)
        milemarker.log "Start!"
        Zinzout.zout(solr_docs_file) do |out|
          yield(out, milemarker)
        end
        milemarker.log_final_line
        send_to_solr(solr_uploader)
      end

      # Sequel query that gets names and see alsos with their counts
      #
      # Private method
      # return [String]
      def get_matched_query
        <<~SQL.strip
          SELECT names.id, 
                 names.label, 
                 names.match_text,
                 names.count,
                 names2.label AS see_also_label,
                 names2.count AS see_also_count 
          FROM names 
          LEFT OUTER JOIN names_see_also AS nsa 
          ON names.id = nsa.name_id 
          LEFT JOIN names AS names2 
          ON nsa.see_also_id = names2.id 
          WHERE names.count > 0
        SQL
      end

      # Reads solr_docs_file and sends the docs to the solr collection specified
      # in the SolrUploader
      #
      # Private method
      # @param solr_uploader [AuthorityBrowse::SolrUploader]
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
        "scratch/solr_docs.jsonl.gz"
      end

      # Path to the file library of congress skos data
      # @return [String]
      def skos_file
        "scratch/names.skosrdf.jsonld.gz"
      end

      # Fetches the names skos file from the library of congress. Puts it in
      # the scratch directory. This is a pain to test so that's why it's been
      # extracted. To try it you can run this method and put in a different url
      # and make sure it gets approriately downloaded.
      #
      # Private method
      # @param url [String] [location skos file for names]
      def fetch_skos_file(url = "https://id.loc.gov/download/authorities/names.skosrdf.jsonld.gz")
        conn = Faraday.new do |builder|
          builder.use Faraday::Response::RaiseError
          builder.adapter :httpx
        end
        File.open(skos_file, "w") do |f|
          conn.get(url) do |req|
            req.options.on_data = proc do |chunk, _overall_received_bytes, _env|
              f << chunk
            end
          end
        end
      end
    end
  end
end
