module AuthorityBrowse
  class SolrDocument
    class Names
      # #@return [String] What kind of SolrDocument it is
      def self.kind
        "name"
      end

      # @return [Array<Symbol>] List of kinds of xrefs for names
      def self.xrefs
        [:see_also]
      end

      class AuthorityGraphSolrDocument < Names
        # @param data [Array<Hash>] Array of rows from the joined :names and
        # :names_see_also tables
        # @return [AuthorityBrowse::SolrDocument::AuthorityGraph]
        def self.new(data)
          AuthorityBrowse::SolrDocument::AuthorityGraph.new(data: data, kind: kind, xrefs: xrefs)
        end
      end

      class UnmatchedSolrDocument < Names
        # @param data [Hash] Row from the :names_see_also_table
        # @return [AuthorityBrowse::SolrDocument::Unmatched]
        def self.new(data)
          AuthorityBrowse::SolrDocument::Unmatched.new(data: data, kind: kind, xrefs: xrefs)
        end
      end
    end
  end
end
