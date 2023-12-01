module AuthorityBrowse
  class SolrDocument
    class Names
      class AuthorityGraphSolrDocument
        def self.new(data)
          AuthorityBrowse::SolrDocument::AuthorityGraph.new(data: data, kind: AuthorityBrowse::Name)
        end
      end

      class UnmatchedSolrDocument
        def self.new(data)
          AuthorityBrowse::SolrDocument::Unmatched.new(data: data, kind: AuthorityBrowse::Name)
        end
      end
    end
  end
end
