module AuthorityBrowse
  class DBMutator
    class Subjects < Base
      class << self
        # Alias of update_main_with_counts
        #
        # @return [Nil]
        def update_subjects_with_counts
          update_main_with_counts
        end

        # Alias of add_ids_to_from_biblio
        #
        # @return [Nil]
        def add_ids_to_subjects_from_biblio
          add_ids_to_from_biblio
        end

        # @return [:Symbol]
        def main_id
          :subject_id
        end

        # @return [:Symbol]
        def main_table
          :subjects
        end

        # @return [:Symbol]
        def from_biblio_table
          :subjects_from_biblio
        end
      end
    end
  end
end
