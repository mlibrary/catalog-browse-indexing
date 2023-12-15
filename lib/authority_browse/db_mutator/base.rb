module AuthorityBrowse
  class DBMutator
    class Base
      class << self
        # Sets count to 0 in the main table.
        #
        # @return [Nil]
        def zero_out_counts
          AuthorityBrowse.db.transaction do
            AuthorityBrowse.db[main_table].update(count: 0)
          end
        end

        # Updates the main table with counts from the from_biblio table.
        # The match between the tables happens on the `match_text` fields
        # in both tables.
        #
        # @return [Nil]
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

        # Removes deprecated terms in the main table when there is an
        # undeprecated term with the same match text.
        #
        # @return [Nil]
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

        # Updates the from_biblio table with ids of matching entries in the
        # main_table. This enables determining the list of unmatched entries in
        # the from_biblio table
        #
        # @return [Nil]
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
