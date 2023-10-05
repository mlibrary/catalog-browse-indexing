require_relative "../../bin/names/skos_to_db"
RSpec.describe SkosToDbWrapper do
  before(:each) do
    @skos_file = "spec/fixtures/twain_skos.json.gz"
    @db_file = "tmp/database.db"
    @logger = instance_double(Logger, info: nil)
    Services.register(:test_database_file) { @db_file }
    Services.register(:database) { Services[:test_database_persistent] }
    @db = Services[:database]
    AuthorityBrowse::DB::Names.recreate_table!(:names)
  end
  
  it "runs something" do
    described_class.run(@skos_file, @db_file)
  end
  after(:each) do
    @db.disconnect
    `rm tmp/#{@db_file}`
  end
end
