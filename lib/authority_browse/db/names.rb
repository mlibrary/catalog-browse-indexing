module AuthorityBrowse
  class DB
    class Names < AuthorityBrowse::DB
      def self.database_definitions
        {
          names: proc do
            String :id, primary_key: true
            String :label, text: true
            String :match_text, text: true, index: true
            Boolean :deprecated, default: false, index: true
            Integer :count, default: 0, index: true
          end,
          names_see_also: proc do
            primary_key :id
            String :name_id, index: true
            String :see_also_id, index: true
          end,
          names_from_biblio: proc do
            primary_key :id
            String :term, text: true
            String :match_text, text: true, index: true
            Integer :count, default: 0
            String :name_id, default: nil
          end
        }
      end
    end
  end
end
