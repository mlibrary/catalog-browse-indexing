require_relative "../../bin/subjects/solr_docs_from_terms_and_dump_files.rb"
RSpec.describe SubjectToSolrDocsWrapper do
  before(:each) do
    @dumpfile = "spec/fixtures/civil_war_dumpfile.jsonl.gz"
    @termsfile = "spec/fixtures/civil_war_terms.tsv.gz"
    @outfile = "tmp/outfile.json"
  end
  it "runs something" do
    expect(File.exist?(@outfile)).to eq(false)
    described_class.run(@dumpfile, @termsfile, @outfile)
    expect(File.exist?(@outfile)).to eq(true)
  end
  after(:each) do
    `rm tmp/*`
  end
end
