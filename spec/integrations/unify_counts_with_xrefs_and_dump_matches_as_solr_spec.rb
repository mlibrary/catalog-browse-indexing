require_relative "../../bin/names/unify_counts_with_xrefs_and_dump_matches_as_solr.rb"
RSpec.describe UnifyWrapper do
  before(:each) do
    `mkdir -p tmp`
    @db_file = "tmp/database.db"
    @matched_file = "tmp/matched.json.gz"
    @logger = instance_double(Logger, info: nil)
    @db = AuthorityBrowse.db(@db_file)
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
  it "runs and outputs one match" do
    @db[:names].insert(**JSON.parse(fixture("name_no_xref.json")))
    expect(!File.exist?(@matched_file))
    described_class.new(@db_file, @matched_file, @logger).run
    expect(File.exist?(@matched_file))
    expect(`zgrep Twain #{@matched_file}`).not_to eq("")
  end
  it "runs and handles xref" do
    # this fixture has counts for the cross references that don't match what's
    # in the json field for the main item.
    names = JSON.parse(fixture("name_with_xref.json"))
    names.each do |name|
      @db[:names].insert(**name)
    end
    mark_twain = JSON.parse(@db[:names].where(label: "Twain, Mark, 1835-1910").first[:json])
    
    # 44 is the count of the cross reference not what's in the json
    expect(mark_twain["see_also"].first[1]["count"]).not_to eq(44)
    expect(mark_twain["incoming_see_also"].first[1]["count"]).not_to eq(44)
    expect(!File.exist?(@matched_file))
    described_class.new(@db_file, @matched_file, @logger).run
    expect(File.exist?(@matched_file))
    expect(`zgrep Twain #{@matched_file}`).not_to eq("")
    mark_twain = JSON.parse(@db[:names].where(label: "Twain, Mark, 1835-1910").first[:json])
    expect(mark_twain["see_also"].first[1]["count"]).to eq(44)
    expect(mark_twain["incoming_see_also"].first[1]["count"]).to eq(44)
  end
  after(:each) do
    `rm tmp/*`
    @db.disconnect
  end
end
