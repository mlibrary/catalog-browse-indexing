# takes in gzip with aab
# db
# unmatched zipfile

require_relative "../../bin/names/add_counts_to_db_and_dump_unmatched_as_solr"
require "authority_browse/db/names"
RSpec.describe DumpCountsWrapper do
  before(:each) do
    `mkdir -p tmp`
    @solr_extract = "spec/fixtures/author_authoritative_browse.tsv.gz"
    @db_file = "tmp/database.db"
    @unmatched_file = "tmp/unmatched.json.gz"
    @logger = instance_double(Logger, info: nil)
    # @db = AuthorityBrowse.db(@db_file)
    Services.register(:test_database_file) { @db_file }
    Services.register(:database) { Services[:test_database_persistent] }
    @db = AuthorityBrowse::DB.switch_to_persistent_sqlite(@db_file)
    AuthorityBrowse::DB::Names.recreate_table!(:names)
  end

  after(:each) do
    @db.disconnect
    `rm #{@db_file}`
    Services.register(:database) { Services[:test_database_memory] }
  end

  it "runs and matches nothing" do
    expect(!File.exist?(@unmatched_file))
    described_class.new(@solr_extract, @db_file, @unmatched_file, @logger).run(1)
    expect(File.exist?(@unmatched_file))
    expect(`zgrep Twain #{@unmatched_file}`).not_to eq("")
  end
  it "runs and matches something" do
    @db[:names].insert(label: "Twain, Shania", match_text: "twain shania", id: "http://id.loc.gov/authorities/names/no95055361", deprecated: false)
    expect(@db[:names].first[:count]).to eq(0)
    described_class.new(@solr_extract, @db_file, @unmatched_file, @logger).run(1)
    # because Twain, Shania has 6 in the @solr_extract fixture
    expect(@db[:names].first[:count]).to eq(6)
  end
end
