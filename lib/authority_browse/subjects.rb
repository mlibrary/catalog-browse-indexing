module AuthorityBrowse
  class Subjects < Base
    class << self
      def reset_db(loc_file_getter = lambda { AuthorityBrowse.fetch_skos_file(remote_file: remote_skos_file, local_file: local_skos_file) })
        loc_file_getter.call

        db = AuthorityBrowse.db
        subjects_table = AuthorityBrowse.db[:subjects]
        xrefs_table = AuthorityBrowse.db[:subjects_xrefs]

        DB::Subjects.recreate_table!(:subjects)
        DB::Subjects.recreate_table!(:subjects_xrefs)

        milemarker = Milemarker.new(batch_size: 100_000, name: "add subjects to db", logger: Services.logger)
        milemarker.log "Start adding subjects to db"
        Zinzout.zin(local_skos_file).each_slice(100_000) do |slice|
          entries = slice.map do |line|
            AuthorityBrowse::LocAuthorities::Subject.new(JSON.parse(line))
          end
          db.transaction do
            entries.each do |entry|
              subjects_table.insert(id: entry.id, label: entry.label, match_text: entry.match_text, deprecated: entry.deprecated?)
            end
          end

          db.transaction do
            entries.each do |entry|
              if entry.xref_ids?
                entry.broader_ids.each do |xref_id|
                  xrefs_table.insert(subject_id: entry.id, xref_id: xref_id, xref_kind: "broader")
                end
                entry.narrower_ids.each do |xref_id|
                  xrefs_table.insert(subject_id: entry.id, xref_id: xref_id, xref_kind: "narrower")
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
          AuthorityBrowse::DB::Subjects.set_subjects_indexes!
        end
        # S.logger.info "Start: remove deprecated when undeprecated match text exists"
        # S.logger.measure_info("removed deprecated terms with undprecated match text") do
        # DBMutator::Names.remove_deprecated_when_undeprecated_match_text_exists
        # end
      end

      def update
        S.logger.info "Start Term fetcher"
        TermFetcher.new(field_name: field_name, table: :subjects_from_biblio, database_klass: AuthorityBrowse::DB::Subjects).run
        S.logger.info "Start: zeroing out counts"
        S.logger.measure_info("Zeroed out counts") do
          DBMutator::Subjects.zero_out_counts
        end
        S.logger.info "Start: update names with counts"
        S.logger.measure_info("updated names with counts") do
          DBMutator::Subjects.update_subjects_with_counts
        end
        S.logger.info "Start: add ids to names_from_biblio"
        S.logger.measure_info("Updated ids in names_from_biblio") do
          DBMutator::Subjects.add_ids_to_subjects_from_biblio
        end
      end

      # Loads solr with documents of names that match data from library of
      # congress.
      # @param solr_uploader [AuthorityBrowse::Solr::Uploader]
      def load_solr_with_matched(solr_uploader = AuthorityBrowse::Solr::Uploader.new(collection: "authority_browse_reindex"))
        write_and_send_docs(solr_uploader) do |out, milemarker|
          AuthorityBrowse.db.fetch(get_matched_query).stream.chunk_while { |bef, aft| aft[:id] == bef[:id] }.each do |ary|
            document = AuthorityBrowse::SolrDocument::Subjects::AuthorityGraphSolrDocument.new(ary)
            out.puts document.to_solr_doc if document.any?
            milemarker.increment_and_log_batch_line
          end
        end
      end

      # Loads solr with documents of names that don't match entries in library
      # of congress
      # @param solr_uploader [AuthorityBrowse::Solr::Uploader]
      def load_solr_with_unmatched(solr_uploader = AuthorityBrowse::Solr::Uploader.new(collection: "authority_browse_reindex"))
        write_and_send_docs(solr_uploader) do |out, milemarker|
          AuthorityBrowse.db[:subjects_from_biblio].stream.filter(subject_id: nil).where { count > 0 }.each do |subject|
            out.puts AuthorityBrowse::SolrDocument::Subjects::UnmatchedSolrDocument.new(subject).to_solr_doc
            milemarker.increment_and_log_batch_line
          end
        end
      end

      # Sequel query that gets names and see alsos with their counts
      #
      # Private method
      # return [String]
      def get_matched_query
        <<~SQL.strip
          SELECT subjects.id, 
                 subjects.label, 
                 subjects.match_text,
                 subjects.count,
                 subjects2.label AS xref_label,
                 subjects2.count AS xref_count,
                 subxref.xref_kind AS xref_kind
          FROM subjects 
          LEFT OUTER JOIN subjects_xrefs AS subxref 
          ON subjects.id = subxref.subject_id 
          LEFT OUTER JOIN subjects AS subjects2 
          ON subxref.xref_id = subjects2.id 
        SQL
      end

      def field_name
        "subject_browse_terms"
      end

      def remote_skos_file
        "https://id.loc.gov/download/authorities/subjects.skosrdf.jsonld.gz"
      end

      # Path to the file library of congress skos data
      # @return [String]
      def local_skos_file
        "tmp/subjects.skosrdf.jsonld.gz"
      end
    end
  end
end
