class Name < Sequel::Model
  many_to_many :see_also, left_key: :name_id, right_key: :see_also_id, join_table: :names_see_also, class: self
end

Name.unrestrict_primary_key
