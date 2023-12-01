module AuthorityBrowse
  class SolrDocument
    class Unmatched < Base
      def term
        @data[:term]
      end

      def match_text
        @data[:match_text]
      end

      def xrefs
        @kind.xrefs.map { |x| [x.name, []] }.to_h
      end
    end
  end
end
