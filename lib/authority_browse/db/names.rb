module AuthorityBrowse
  class DB
    class Names < AuthorityBrowse::DB
      # Tables for names for AuthorityBrowse
      #
      # @return [Hash]
      def self.database_definitions
        {
          names: proc do
            String :id
            String :label, text: true
            String :match_text, text: true
            Boolean :deprecated, default: false
            Integer :count, default: 0
          end,
          names_see_also: proc do
            String :name_id
            String :see_also_id
          end,
          names_from_biblio: proc do
            String :term, text: true
            String :match_text, text: true, index: true
            Integer :count, default: 0
            String :name_id, default: nil
          end
        }
      end

      # Sets indexes on the :names and :names_see_also tables
      #
      # @return [Nil]
      def self.set_names_indexes!
        AuthorityBrowse.db.alter_table(:names) do
          add_index :id
          add_index :match_text
          add_index :deprecated
          add_index :count
        end

        AuthorityBrowse.db.alter_table(:names_see_also) do
          add_index :name_id
          add_index :see_also_id
        end
      end
    end
  end
end
