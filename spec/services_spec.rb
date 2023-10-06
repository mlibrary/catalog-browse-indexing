require "services"
RSpec.describe "Services" do
  it "has app_env of test when APP_ENV is test" do
    expect(Services.app_env).to eq("test")
  end
  it "fails test_database_persistent when no database file is defined" do
    Services.register(:test_database_file) { nil }
    expect { Services.test_database_persistent }.to raise_error(StandardError)
  end
  it "returns returns sqlite if the file is set" do
    Services.register(:test_database_file) { "some_file.db" }
    expect(Services.test_database_persistent.class).to eq(Sequel::SQLite::Database)
  end
  it "has a test database file" do
    ENV["TEST_DATABASE_FILE"] = "somefile.db"
    expect(Services.test_database_file).to eq("some_file.db")
  end
end
