require "faraday/follow_redirects"
module AuthorityBrowse
  class Names < Base
    class << self
      # What kind of Object is it?
      #
      # @return [String]
      def kind
        "name"
      end

      # Loads the names and names_see_also table with data from LOC
      #
      # @param loc_file_getter [Proc] when called needs to put a file with skos
      # data into skos_file
      # @return [Nil]
      def reset_db(loc_file_getter = lambda { fetch_skos_file })
        # get names file
        loc_file_getter.call

        db = AuthorityBrowse.db
        names_table = AuthorityBrowse.db[:names]
        see_also_table = AuthorityBrowse.db[:names_see_also]

        DB::Names.recreate_table!(:names)
        DB::Names.recreate_table!(:names_see_also)

        milemarker = Milemarker.new(batch_size: 100_000, name: "add names to db", logger: Services.logger)
        milemarker.log "Start adding names to db"
        Zinzout.zin(local_skos_file).each_slice(100_000) do |slice|
          entries = slice.map do |line|
            AuthorityBrowse::LocAuthorities::Name.new(JSON.parse(line))
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

        S.logger.info "Start: set the indexes"
        S.logger.measure_info("set the indexes") do
          AuthorityBrowse::DB::Names.set_names_indexes!
        end
        S.logger.info "Start: remove deprecated when undeprecated match text exists"
        S.logger.measure_info("removed deprecated terms with undprecated match text") do
          DBMutator::Names.remove_deprecated_when_undeprecated_match_text_exists
        end
      end

      # Loads solr with documents of names that match data from Library of
      # Congress.
      #
      # @param solr_uploader [Solr::Uploader]
      # @return [Nil]
      def load_solr_with_matched(solr_uploader = Solr::Uploader.new(collection: "authority_browse_reindex"))
        write_docs do |out, milemarker|
          AuthorityBrowse.db.fetch(get_matched_query).stream.chunk_while { |bef, aft| aft[:id] == bef[:id] }.each do |ary|
            document = AuthorityBrowse::SolrDocument::Names::AuthorityGraphSolrDocument.new(ary)
            out.puts document.to_solr_doc if document.any?
            milemarker.increment_and_log_batch_line
          end
        end
        solr_uploader.send_file_to_solr(solr_docs_file)
      end

      # Loads solr with documents of names that don't match entries in Library
      # of Congress
      #
      # @param solr_uploader [Solr::Uploader]
      # @return [Nil]
      def load_solr_with_unmatched(solr_uploader = Solr::Uploader.new(collection: "authority_browse_reindex"))
        write_docs do |out, milemarker|
          AuthorityBrowse.db[:names_from_biblio].stream.filter(name_id: nil).where { count > 0 }.each do |name|
            out.puts AuthorityBrowse::SolrDocument::Names::UnmatchedSolrDocument.new(name).to_solr_doc
            milemarker.increment_and_log_batch_line
          end
        end
        solr_uploader.send_file_to_solr(solr_docs_file)
      end

      # Sequel query that gets names and see alsos with their counts
      #
      # Private method
      # @return [String]
      def get_matched_query
        <<~SQL.strip
          SELECT names.id, 
                 names.label, 
                 names.match_text,
                 names.count,
                 names2.label AS xref_label,
                 names2.count AS xref_count 
          FROM names 
          LEFT OUTER JOIN names_see_also AS nsa 
          ON names.id = nsa.name_id 
          LEFT OUTER JOIN names AS names2 
          ON nsa.see_also_id = names2.id 
        SQL
      end

      # Field name/Facet in Biblio that we should get counts for
      #
      # @return [String]
      def field_name
        "author_browse_terms"
      end

      # URL for LOC skos file
      #
      # @return [String]
      def remote_skos_file
        "https://id.loc.gov/download/authorities/names.skosrdf.jsonld.gz"
      end

      # Path to the file library of congress skos data
      #
      # @return [String]
      def local_skos_file
        File.join(S.project_root, "tmp/names.skosrdf.jsonld.gz")
      end

      # @return [Symbol]
      def from_biblio_table
        :names_from_biblio
      end

      def database_klass
        AuthorityBrowse::DB::Names
      end

      def mutator_klass
        AuthorityBrowse::DBMutator::Names
      end
    end
  end
end
