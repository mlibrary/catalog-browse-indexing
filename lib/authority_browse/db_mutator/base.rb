module AuthorityBrowse
  class DBMutator
    class Base
      class << self
        def zero_out_counts
          AuthorityBrowse.db.transaction do
            AuthorityBrowse.db[main_table].update(count: 0)
          end
        end

        def update_main_with_counts
          statement = <<~SQL.strip
            UPDATE #{main_table} AS m
            SET count = (
              SELECT COALESCE( sum(count), 0)  
              FROM #{from_biblio_table} AS fb
              WHERE m.match_text = fb.match_text);
          SQL

          AuthorityBrowse.db.run(statement)
        end

        def remove_deprecated_when_undeprecated_match_text_exists
          statement = <<~SQL.strip
            DELETE FROM #{main_table}   
            WHERE #{main_table}.match_text IN (   
              SELECT m2.match_text 
              FROM #{main_table} as m2    
              WHERE m2.deprecated = false
            )  
            AND #{main_table}.deprecated = true;
          SQL
          AuthorityBrowse.db.run(statement)
        end

        def add_ids_to_from_biblio
          statement = <<~SQL.strip
            UPDATE #{from_biblio_table} AS fb 
            SET #{main_id}=(
              SELECT id 
              FROM #{main_table} AS m 
              WHERE m.match_text = fb.match_text 
              LIMIT 1);
          SQL
          AuthorityBrowse.db.run(statement)
        end
      end
    end
  end
end
