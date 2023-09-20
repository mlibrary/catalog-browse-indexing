Sequel.migration do
  change do
    create_table(:names) do
      String :id, primary_key: true
      String :label  
    end
  end
end
