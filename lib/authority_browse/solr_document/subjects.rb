module AuthorityBrowse
  class SolrDocument
    class Subjects
      # #@return [String] What kind of SolrDocument it is
      def self.kind
        "subject"
      end

      # @return [Array<Symbol>] List of kinds of xrefs for subjects
      def self.xrefs
        [:broader, :narrower]
      end

      class AuthorityGraphSolrDocument < Subjects
        # @param data [Array<Hash>] Array of rows from the joined :subjects and
        # :subjects_see_also tables
        # @return [AuthorityBrowse::SolrDocument::AuthorityGraph]
        def self.new(data)
          AuthorityBrowse::SolrDocument::AuthorityGraph.new(data: data, kind: kind, xrefs: xrefs)
        end
      end

      class UnmatchedSolrDocument < Subjects
        # @param data [Hash] Row from the :subjects_see_also_table
        # @return [AuthorityBrowse::SolrDocument::Unmatched]
        def self.new(data)
          AuthorityBrowse::SolrDocument::Unmatched.new(data: data, kind: kind, xrefs: xrefs)
        end
      end
    end
  end
end
