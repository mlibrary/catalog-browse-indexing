module AuthorityBrowse
  module Subjects
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
