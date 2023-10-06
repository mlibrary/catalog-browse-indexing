require "services"
RSpec.describe "Services" do
  it "has a test database file" do
    ENV["TEST_DATABASE_FILE"] = "somefile.db"
    expect(Services.test_database_file).to eq("somefile.db")
  end
  xit "can change the database based on how the services object is set" do
    ENV["TEST_DATABASE_FILE"] = "somefile.db"
    # ENV["APP_ENV"] = "test"
    Services.register(:app_env) { "test" }
    expect(Services.database.class).to eq(Sequel::SQLite::Database)
    Services.register(:app_env) { "production" }
    expect(Services.database.class).to eq(Sequel::Mysql2::Database)
  end
end
