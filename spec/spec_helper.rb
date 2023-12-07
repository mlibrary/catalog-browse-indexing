# frozen_string_literal: true

require "pry"
require "byebug"
require "webmock/rspec"
require "httpx/adapters/webmock"
require "simplecov"
require "sequel"
SimpleCov.start
ENV["APP_ENV"] = "test"
require "browse"
require "authority_browse"

if ENV["GHA_TEST"] == "true"
  S.register(:database_host) { "127.0.0.1" }
end

# S.register(:git_tag) { "my.test.tag" }
S.register(:git_tag) { "version" }
S.register(:today) { "2099-12-01-00-00-00" }
S.register(:min_authority_browse_record_count) { 0 }

Services.register(:database) do
  root = Sequel.connect(
    adapter: Services[:database_adapter],
    host: Services[:database_host],
    user: "root",
    password: Services[:mariadb_root_password]
  )
  create_db_statement = <<~SQL
    CREATE DATABASE IF NOT EXISTS test_database;
  SQL
  root.run(create_db_statement)
  Sequel.connect(
    adapter: Services[:database_adapter],
    host: Services[:database_host],
    user: "root",
    password: Services[:mariadb_root_password],
    database: "test_database",
    encoding: "utf8mb4"
  )
end

AuthorityBrowse::DB::Names.recreate_all_tables!

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:each) do |example|
    AuthorityBrowse.db.transaction(rollback: :always) do
      example.run
    end
  end
end
def fixture(path)
  File.read("./spec/fixtures/#{path}")
end
