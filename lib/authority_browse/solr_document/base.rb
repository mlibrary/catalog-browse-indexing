module AuthorityBrowse
  class SolrDocument
    class Base
      TODAY = DateTime.now.strftime("%Y-%m-%d") + "T00:00:00Z"
      EMPTY = [[], nil, "", {}, [nil], [false]]

      # @param data [Array] Array of hashes of name and one see_also
      # @parameter kind [Class] either AuthorityBrowse::Name or AuthorityBrowse::Subject
      def initialize(data:, kind:, xrefs: "#placeholder")
        @data = data
        @kind = kind
        @xrefs = xrefs
      end

      # Unique id for element. The kind is for distinguishing between subjects
      # and names.
      #
      # @return [String]
      def id
        match_text + "\u001f#{@kind}"
      end

      # Library of Congress ID
      #
      # @return [Nil]
      def loc_id
      end

      # @return [String]
      def browse_field
        @kind.to_s
      end

      def xrefs
        raise NotImplementedError
      end

      # @return [Integer]
      def count
        @data[:count]
      end

      # Today formatted to be midnight UTC
      #
      # @param today [String] string of today's date.
      # @return [String] JSON formatted string of solr document
      def to_solr_doc(today = TODAY)
        {
          id: id,
          loc_id: loc_id,
          browse_field: browse_field,
          term: term,
          count: count,
          date_of_index: today
        }.merge(xrefs).reject { |_k, v| EMPTY.include?(v) }
          .to_json
      end
    end
  end
end
