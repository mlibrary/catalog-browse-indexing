# frozen_string_literal: true

require "pry"
require "byebug"
require "webmock/rspec"
require "simplecov"
require "sequel"
SimpleCov.start

Sequel.extension :migration
#DB = Sequel.mysql2(host: "database", user: ENV.fetch("MARIADB_USER"), password: ENV.fetch("MARIADB_PASSWORD"), database: ENV.fetch("MARIADB_DATABASE"))
DB = Sequel.sqlite
Sequel::Model.db = DB
Sequel::Migrator.run(DB, "db")

require "authority_browse"
ENV["APP_ENV"] = "test"



RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect

  end
  config.around(:each) do |example|
    DB.transaction(rollback: :always){example.run}
  end
end
def fixture(path)
  File.read("./spec/fixtures/#{path}")
end
