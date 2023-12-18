module AuthorityBrowse
  class SolrDocument
    class Unmatched < Base
      # @return [String]
      def term
        @data[:term]
      end

      # @return [String]
      def match_text
        @data[:match_text]
      end

      # Hash of xref types. Each type has an empty array because all
      # unmatched terms will have no xrefs.
      #
      # @return [Hash]
      def xrefs
        @xrefs.map { |x| [x.name.to_sym, []] }.to_h
      end
    end
  end
end
