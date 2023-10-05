# takes in gzip with aab
# db
# unmatched zipfile

require_relative "../../bin/names/add_counts_to_db_and_dump_unmatched_as_solr"

RSpec.describe DumpCountsWrapper do
  before(:each) do
    `mkdir -p tmp`
    @solr_extract = "spec/fixtures/author_authoritative_browse.tsv.gz"
    @db_file = "tmp/database.db"
    @unmatched_file = "tmp/unmatched.json.gz"
    @logger = instance_double(Logger, info: nil)
    @db = AuthorityBrowse.db_old(@db_file)
    @db.create_table(:names) do
      String :id, primary_key: true
      String :label
      String :match_text
      Boolean :xrefs
      Boolean :deprecated
      Integer :count, default: 0
      String :json, text: true
    end
  end
  it "runs and matches nothing" do
    expect(!File.exist?(@unmatched_file))
    described_class.new(@solr_extract, @db_file, @unmatched_file, @logger).run(1)
    expect(File.exist?(@unmatched_file))
    expect(`zgrep Twain #{@unmatched_file}`).not_to eq("")
  end
  it "runs and matches something" do
    @db[:names].insert(label: "Twain, Shania", match_text: "twain shania", xrefs: false, id: "http://id.loc.gov/authorities/names/no95055361", json: "{}", deprecated: false)
    expect(@db[:names].first[:count]).to eq(0)
    described_class.new(@solr_extract, @db_file, @unmatched_file, @logger).run(1)
    # because Twain, Shania has 6 in the @solr_extract fixture
    expect(@db[:names].first[:count]).to eq(6)
  end
  after(:each) do
    `rm tmp/*`
    @db.disconnect
  end
end
