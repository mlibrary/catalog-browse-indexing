module AuthorityBrowse
  class SolrDocument
    class Subjects
      class AuthorityGraphSolrDocument
        def self.new(data)
          AuthorityBrowse::SolrDocument::AuthorityGraph.new(data: data, kind: AuthorityBrowse::Subject)
        end
      end

      class UnmatchedSolrDocument
        def self.new(data)
          AuthorityBrowse::SolrDocument::Unmatched.new(data: data, kind: AuthorityBrowse::Subject)
        end
      end
    end
  end
end
