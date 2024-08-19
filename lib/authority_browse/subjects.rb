module AuthorityBrowse
  class Subjects < Base
    class << self
      # What kind of Object is it?
      #
      # @return [String]
      def kind
        "subject"
      end

      # Fetches and writes the MARCXML Authority record data for remediated
      # subjects to a file.
      #
      # @param file_path [String] Path to remediated subjects config file
      # @param set_id [String] Alma Set ID for remediated subjects authority records
      # @return [Nil]
      def generate_remediated_authorities_file(file_path: S.remediated_subjects_file, set_id: S.subject_heading_remediation_set_id)
        conn = Faraday.new do |conn|
          conn.options.timeout = 10 * 60
        end
        client = AlmaRestClient::Client.new(conn)
        resp = client.get_all(url: "conf/sets/#{set_id}/members", record_key: "members")
        raise StandardError, "Couldn't retrieve authority set data for #{set_id}; #{resp.body}" if resp.status != 200
        ids = resp.body["member"].map { |x| x["id"] }
        File.open(file_path, "w") do |file|
          ids.each do |id|
            resp = client.get("bibs/authorities/#{id}", query: {view: "full"})
            raise StandardError, "Couldn't retrieve authority data for #{id}" if resp.status != 200
            file.puts(resp.body["anies"].first)
          end
        end
      end

      # Loads the subjects and subjecst_xrefs table with data from LOC
      #
      # @param loc_file_getter [Proc] when called needs to put a file with skos
      # data into skos_file
      # @return [Nil]
      def reset_db(loc_file_getter = lambda { fetch_skos_file })
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
      end

      # Adds the remediated subject information to the `subjects` and
      # `subjects_xrefs` table of the database
      #
      # @param file_path [String] Path to remediated subjects config file
      # @return [Nil]
      def incorporate_remediated_subjects(file_path = S.remediated_subjects_file)
        subjects = AuthorityBrowse::RemediatedSubjects.new(file_path)
        AuthorityBrowse.db.transaction do
          subjects.each do |entry|
            entry.add_to_db
          end
        end
      end

      # Loads solr with documents of subjects that match data from Library of
      # Congress.
      # @param solr_uploader Solr::Uploader]
      def load_solr_with_matched(solr_uploader = Solr::Uploader.new(collection: "authority_browse_reindex"))
        write_docs do |out, milemarker|
          AuthorityBrowse.db.fetch(get_matched_query).stream.chunk_while { |bef, aft| aft[:id] == bef[:id] }.each do |ary|
            document = AuthorityBrowse::SolrDocument::Subjects::AuthorityGraphSolrDocument.new(ary)
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
      def load_solr_with_unmatched(solr_uploader = Solr::Uploader.new(collection: "authority_browse_reindex"))
        write_docs do |out, milemarker|
          AuthorityBrowse.db[:subjects_from_biblio].stream.filter(subject_id: nil).where { count > 0 }.each do |subject|
            out.puts AuthorityBrowse::SolrDocument::Subjects::UnmatchedSolrDocument.new(subject).to_solr_doc
            milemarker.increment_and_log_batch_line
          end
        end
        solr_uploader.send_file_to_solr(solr_docs_file)
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

      # Path to the file Library of Congress skos data
      #
      # @return [String]
      def local_skos_file
        File.join(S.project_root, "tmp/subjects.skosrdf.jsonld.gz")
      end

      # @return [Symbol]
      def from_biblio_table
        :subjects_from_biblio
      end

      def database_klass
        AuthorityBrowse::DB::Subjects
      end

      def mutator_klass
        AuthorityBrowse::DBMutator::Subjects
      end
    end
  end
end
