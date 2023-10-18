module AuthorityBrowse
  class SolrDocument
    class Names
      TODAY = DateTime.now.strftime("%Y-%m-%d") + "T00:00:00Z"
      EMPTY = [[], nil, "", {}, [nil], [false]]
      def id
        match_text + "\u001fname"
      end

      def loc_id
      end

      def browse_field
        "name"
      end

      def see_also
        []
      end

      def count
        @data[:count]
      end

      # @param today [String] string of today's date.
      # @return [String] JSON formatted string of solr document
      def to_solr_doc(today = TODAY)
        {
          id: id,
          loc_id: loc_id,
          browse_field: browse_field,
          term: term,
          see_also: see_also,
          count: count,
          date_of_index: today
        }.reject { |_k, v| EMPTY.include?(v) }
          .to_json
      end

      class AuthorityGraphSolrDocument < Names
        # @param data [Array] Array of hashes of name and one see_also
        def initialize(data)
          @data = data
          @first = @data.first
        end

        def match_text
          @first[:match_text]
        end

        def term
          @first[:label]
        end

        def loc_id
          @first[:id]
        end

        def count
          @first[:count]
        end

        # Today formatted to be midnight UTC
        def see_also
          @data.filter_map do |xref|
            sa_count = xref[:see_also_count]
            "#{xref[:see_also_label]}||#{xref[:see_also_count]}" unless sa_count.nil? || sa_count == 0
          end
        end
      end

      class UnmatchedSolrDocument < Names
        # Take an unmatched term from the terms db. Turn it into a solr document.
        # @param term_entry [Hash] Hash entry from terms_db
        def initialize(term_entry)
          @data = term_entry
        end

        def term
          @data[:term]
        end

        def match_text
          @data[:match_text]
        end
      end
    end
  end
end
