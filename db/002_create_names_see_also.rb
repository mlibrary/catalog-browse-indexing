Sequel.migration do
  change do
    create_table(:names_see_also) do
      primary_key :id
      String :name_id
      String :see_also_id
    end
  end
end
