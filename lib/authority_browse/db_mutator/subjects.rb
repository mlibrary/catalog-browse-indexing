module AuthorityBrowse
  class DBMutator
    class Subjects < Base
      class << self
        def update_subjects_with_counts
          update_main_with_counts
        end

        def add_ids_to_subjects_from_biblio
          add_ids_to_from_biblio
        end

        def main_id
          :subject_id
        end

        def main_table
          :subjects
        end

        def from_biblio_table
          :subjects_from_biblio
        end
      end
    end
  end
end
