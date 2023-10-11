module AuthorityBrowse
  module Names
    class << self
      # Loads the names and names_see_also table with data from loc
      # TODO actually fetch the file from loc.
      def reset_db(loc_file_getter = lambda { fetch_skos_file })
        # get names file
        loc_file_getter.call

        db = AuthorityBrowse.db
        names_table = AuthorityBrowse.db[:names]
        see_also_table = AuthorityBrowse.db[:names_see_also]

        DB::Names.recreate_table!(:names)
        DB::Names.recreate_table!(:names_see_also)

        logger = Logger.new($stdout)

        milemarker = Milemarker.new(batch_size: 100_000, name: "adding to entries array", logger: logger)
        milemarker.log "Starting adding to entries array"
        Zinzout.zin("./scratch/names.skosrdf.jsonld.gz").each_slice(100_000) do |slice|
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

      def update
        TermFetcher.run
        DBMutator::Names.zero_out_counts
        DBMutator::Names.update_names_with_counts
        DBMutator::Names.add_ids_to_names_from_biblio
      end

      def load_solr_with_matched
        query = <<~SQL.strip
          SELECT names.id, 
                 names.label, 
                 names2.label AS see_also_label 
          FROM names 
          LEFT OUTER JOIN names_see_also AS nsa 
          ON names.id = nsa.name_id 
          LEFT JOIN names AS names2 
          ON nsa.see_also_id = names2.id 
          WHERE names2.label IS NOT null 
          LIMIT 1000;
        SQL
        docs_file = "solr_docs.jsonl.gz"

        db = AuthorityBrowse.db
        logger = Logger.new($stdout)
        milemarker = Milemarker.new(name: "Write solr docs to file", batch_size: 100, logger: logger)
        milemarker.log "Start!"
        Zinzout.zout(docs_file) do |out|
          db.fetch(query).chunk_while { |bef, aft| aft[:id] == bef[:id] }.each do |ary|
            out.puts AuthorityBrowse::SolrDocument::Names::AuthorityGraphSolrDocument.new(ary).to_solr_doc
            milemarker.increment_and_log_batch_line
          end
        end
        milemarker.log_final_line

        batch_size = 100_000
        solr_uploader = AuthorityBrowse::SolrUploader.new(collection: "authority_browse")

        mm = Milemarker.new(batch_size: 100_000, name: "Docs sent to solr", logger: logger)

        mm.log "Sending #{docs_file} in batches of #{batch_size}"

        Zinzout.zin(docs_file) do |infile|
          infile.each_slice(batch_size) do |batch|
            solr_uploader.upload(batch)
            mm.increment(batch_size)
            mm.on_batch { mm.log_batch_line }
          end
        end

        mm.log "Committing"
        solr_uploader.commit
        mm.log "Finished"
        mm.log_final_line
      end

      def load_solr_with_unmatched
        docs_file = "solr_docs.jsonl.gz"

        db = AuthorityBrowse.db
        logger = Logger.new($stdout)
        milemarker = Milemarker.new(name: "Write solr docs to file", batch_size: 100, logger: logger)
        milemarker.log "Start!"
        Zinzout.zout(docs_file) do |out|
          db[:names_from_biblio].filter(name_id: nil).limit(100).each do |name|
            out.puts AuthorityBrowse::SolrDocument::Names::UnmatchedSolrDocument.new(name).to_solr_doc
            milemarker.increment_and_log_batch_line
          end
        end
        milemarker.log_final_line

        batch_size = 100_000
        solr_uploader = AuthorityBrowse::SolrUploader.new(collection: "authority_browse")

        mm = Milemarker.new(batch_size: 100_000, name: "Docs sent to solr", logger: logger)
        mm.log "Sending #{docs_file} in batches of #{batch_size}"

        Zinzout.zin(docs_file) do |infile|
          infile.each_slice(batch_size) do |batch|
            solr_uploader.upload(batch)
            mm.increment(batch_size)
            mm.on_batch { mm.log_batch_line }
          end
        end

        mm.log "Committing"
        solr_uploader.commit
        mm.log "Finished"
        mm.log_final_line
      end

      def fetch_skos_file(url = "https://id.loc.gov/download/authorities/names.skosrdf.jsonld.gz")
        conn = Faraday.new do |builder|
          builder.use Faraday::Response::RaiseError
          builder.adapter :httpx
        end
        File.open("/app/scratch/names.skosrdf.jsonld.gz", "w") do |f|
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
