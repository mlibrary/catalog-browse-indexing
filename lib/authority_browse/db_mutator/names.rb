module AuthorityBrowse
  class DBMutator
    class Names < Base
      class << self
        # Alias of update_main_with_counts
        #
        # @return [Nil]
        def update_names_with_counts
          update_main_with_counts
        end

        # Alias of add_ids_to_from_biblio
        #
        # @return [Nil]
        def add_ids_to_names_from_biblio
          add_ids_to_from_biblio
        end

        # @return [:Symbol]
        def main_id
          :name_id
        end

        # @return [:Symbol]
        def main_table
          :names
        end

        # @return [:Symbol]
        def from_biblio_table
          :names_from_biblio
        end
      end
    end
  end
end
