module AuthorityBrowse
  class SolrDocument
    class Names
      def self.kind
        "name"
      end

      def self.xrefs
        [:see_also]
      end

      class AuthorityGraphSolrDocument < Names
        def self.new(data)
          AuthorityBrowse::SolrDocument::AuthorityGraph.new(data: data, kind: kind, xrefs: xrefs)
        end
      end

      class UnmatchedSolrDocument < Names
        def self.new(data)
          AuthorityBrowse::SolrDocument::Unmatched.new(data: data, kind: kind, xrefs: xrefs)
        end
      end
    end
  end
end
