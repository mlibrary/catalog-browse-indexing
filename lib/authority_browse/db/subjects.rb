module AuthorityBrowse
  class DB
    class Subjects < AuthorityBrowse::DB
      # Tables for subjects for AuthorityBrowse
      #
      # @return [Hash]
      def self.database_definitions
        {
          subjects: proc do
            String :id
            String :label, text: true
            String :match_text, text: true
            Boolean :deprecated, default: false
            Integer :count, default: 0
          end,
          subjects_xrefs: proc do
            String :subject_id
            String :xref_id
            String :xref_kind
          end,
          subjects_from_biblio: proc do
            String :term, text: true
            String :match_text, text: true, index: true
            Integer :count, default: 0
            String :subject_id, default: nil
          end
        }
      end

      # Sets indexes on the :subjects and :subjects_xrefs tables
      #
      # @return [Nil]
      def self.set_subjects_indexes!
        AuthorityBrowse.db.alter_table(:subjects) do
          add_index :id
          add_index :match_text
          add_index :deprecated
          add_index :count
        end

        AuthorityBrowse.db.alter_table(:subjects_xrefs) do
          add_index :subject_id
          add_index :xref_id
        end
      end
    end
  end
end
