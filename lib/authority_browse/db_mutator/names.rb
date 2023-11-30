module AuthorityBrowse
  class DBMutator
    class Names < Base
      class << self
        def update_names_with_counts
          update_main_with_counts
        end

        def add_ids_to_names_from_biblio
          add_ids_to_from_biblio
        end

        def main_id
          :name_id
        end

        def main_table
          :names
        end

        def from_biblio_table
          :names_from_biblio
        end
      end
    end
  end
end
