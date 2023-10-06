# frozen_string_literal: true

require "pry"
require "byebug"
require "webmock/rspec"
require "simplecov"
require "sequel"
SimpleCov.start
ENV["APP_ENV"] = "test"
require "authority_browse"

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
    Sequel.transaction([AuthorityBrowse.db], rollback: :always) { example.run }
  end
end
def fixture(path)
  File.read("./spec/fixtures/#{path}")
end
