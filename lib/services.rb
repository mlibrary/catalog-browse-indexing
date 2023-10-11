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

# Sick and tired of writting "Services" all the time
S = Services


# Add ENV variables from docker-compose
%w[DATABASE_ADAPTER MARIADB_ROOT_PASSWORD MARIADB_USER MARIADB_PASSWORD
  DATABASE_HOST].each do |e|
  Services.register(e.downcase.to_sym) { ENV[e] }
end

Services.register(:app_env) { ENV["APP_ENV"] }
Services.register(:db_database) { ENV["MARIADB_DATABASE"] }

# Various databases
Services.register(:test_database_memory) { Sequel.sqlite }

Services.register(:test_database_file) { ENV["TEST_DATABASE_FILE"] }
Services.register(:test_database_persistent) do
  unless Services[:test_database_file]
    stderr.puts "Need to define path for test_database in ENV[TEST_DATABASE_FILE]"
    exit 1
  end
  Sequel.sqlite(Services[:test_database_file])
end

Services.register(:mariadb_database) do
  Sequel.connect(
    adapter: Services[:database_adapter],
    host: Services[:database_host],
    database: Services[:db_database],
    user: Services[:mariadb_user],
    password: Services[:mariadb_password],
    encoding: "utf8mb4"
  )
end

Services.register(:database) do
  if Services[:app_env] == "test"
    Services[:test_database_memory]
  else
    Services[:mariadb_database]
  end
end


# Solr stuff

S.register(:solr_user) { ENV["SOLR_USER"] || "solr" }
S.register(:solr_password) { ENV["SOLR_PASSWORD"] || "SolrRocks"}
S.register(:solr_host) { ENV["SOLR_HOST"] || "http://solr:8983" }
S.register(:solr_configuration) { ENV["SOLR_CONFIGURATION"] || "authority_browse" }
S.register(:solr_collection) { ENV["SOLR_COLLECTION"] || "authority_browse" }
S.register(:biblio_solr) { ENV["BIBLIO_SOLR"] }