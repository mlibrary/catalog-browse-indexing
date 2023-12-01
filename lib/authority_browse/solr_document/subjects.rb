module AuthorityBrowse
  class SolrDocument
    class Subjects
      def self.kind
        "subject"
      end

      def self.xrefs
        [:broader, :narrower]
      end

      class AuthorityGraphSolrDocument < Subjects
        def self.new(data)
          AuthorityBrowse::SolrDocument::AuthorityGraph.new(data: data, kind: kind, xrefs: xrefs)
        end
      end

      class UnmatchedSolrDocument < Subjects
        def self.new(data)
          AuthorityBrowse::SolrDocument::Unmatched.new(data: data, kind: kind, xrefs: xrefs)
        end
      end
    end
  end
end
