require_relative "../../bin/names/skos_to_db"
RSpec.describe SkosToDbWrapper do
  before(:each) do
    @skos_file = "spec/fixtures/twain_skos.json.gz"
    @db_file = "tmp/database.db"
    @logger = instance_double(Logger, info: nil)
    @db = AuthorityBrowse.db(@db_file)
  end
  it "runs something" do
    described_class.run(@skos_file, @db_file)
  end
  after(:each) do
    `rm tmp/*`
    @db.disconnect
  end
end
