# frozen_string_literal: true

# db stuff
#
# alts = db[:names].join(db[:names_see_also], see_also_id: :id).
#   select(Sequel[:label].as(:see_also_label), :name_id, :see_also_id)
#
# n1.graph(alts, name_id: :id)
#
# n1.graph(alts, name_id: :id).select(:id, :label, :see_also_label)

require "canister"
require "sequel"



Services = Canister.new

# Add ENV variables from docker-compose

%w[DB_ADAPTER DB_ROOT_PASSWORD DB_USER DB_PASSWORD
     DB_DATABASE DB_HOST].each do |e|
  Services.register(e.downcase.to_sym) { ENV[e] }
end

Services.register(:app_env) { ENV["APP_ENV"] }


# Various databases
Services.register(:test_database_memory ) { Sequel.sqlite }

Services.register(:test_database_file) { ENV["TEST_DATABASE_FILE"]}
Services.register(:test_database_persistent) do
  unless Services[:test_database_file]
    stderr.puts "Need to define path for test_database in ENV[TEST_DATABASE_FILE]"
    exit 1
  end
  Sequel.sqlite(Services[:test_database_file])
end

Services.register(:database_schema) { "mysql://" }
Services.register(:mariadb_database) do
  Sequel.connect(adapter: Services[:db_adapter], host: Services[:db_host],
    database: Services[:db_database],
    user: Services[:db_user], password: Services[:db_password])
end

Services.register(:database) do
  if Services[:app_env] == "test"
    Services[:test_database]
  else
    Services[:mariadb_database]
  end
end



