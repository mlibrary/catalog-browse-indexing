require_relative "../../bin/subjects/skos_to_dumpfile"
RSpec.describe SkosToDumpWrapper do
  before(:each) do
    @skos_file = "spec/fixtures/civil_war.json.gz"
    @dumpfile = "tmp/dumpfile.jsonl.gz"
  end
  it "runs something" do
    expect(File.exist?(@dumpfile)).to eq(false)
    described_class.run(@skos_file, @dumpfile)
    expect(File.exist?(@dumpfile)).to eq(true)
  end
  after(:each) do
    `rm tmp/*`
  end
end
