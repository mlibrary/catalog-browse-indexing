module AuthorityBrowse
  class DBMutator
    class Names
      def self.zero_out_counts
        AuthorityBrowse.db.transaction do
          AuthorityBrowse.db[:names].update(count: 0)
        end
      end

      def self.update_names_with_counts
        statement = <<~SQL.strip
          UPDATE names AS n
          SET count = (
            SELECT COALESCE( sum(count), 0)  
            FROM names_from_biblio AS nfb
            WHERE n.match_text = nfb.match_text);
        SQL

        AuthorityBrowse.db.run(statement)
      end

      def self.remove_deprecated_when_undeprecated_match_text_exists
        statement = <<~SQL.strip
          DELETE FROM names   
          WHERE names.match_text IN (   
            SELECT n2.match_text 
            FROM names as n2    
            WHERE n2.deprecated = false
          )  
          AND names.deprecated = true;
        SQL
        AuthorityBrowse.db.run(statement)
      end

      def self.add_ids_to_names_from_biblio
        statement = <<~SQL.strip
          UPDATE names_from_biblio AS nfb 
          SET name_id=(
            SELECT id 
            FROM names AS n 
            WHERE n.match_text = nfb.match_text 
            LIMIT 1);
        SQL
        AuthorityBrowse.db.run(statement)
      end
    end
  end
end
