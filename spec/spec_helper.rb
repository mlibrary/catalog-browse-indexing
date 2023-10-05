# frozen_string_literal: true

require "pry"
require "byebug"
require "webmock/rspec"
require "simplecov"
require "sequel"
SimpleCov.start
ENV["APP_ENV"] = "test"
require "authority_browse"
require "authority_browse/db"

# Sequel.extension :migration
# Names = Sequel.mysql2(host: "database", user: ENV.fetch("MARIADB_USER"), password: ENV.fetch("MARIADB_PASSWORD"), database: ENV.fetch("MARIADB_DATABASE"))
# Names = Sequel.sqlite
# Sequel::Model.db = Names
# Sequel::Migrator.run(Names, "db")

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Set up the in-memory database and clean it out
  Services.register(:database) { Services[:test_database_memory] }
  AuthorityBrowse::DB::Names.recreate_all_tables!
  config.around(:each) do |example|
    Sequel.transaction([Services[:database]], rollback: :always) { example.run }
  end
end
def fixture(path)
  File.read("./spec/fixtures/#{path}")
end
