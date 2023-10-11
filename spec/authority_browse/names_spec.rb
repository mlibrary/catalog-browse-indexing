RSpec.describe AuthorityBrowse::Names do
  context ".reset_db" do
    before(:each) do
    end
    it "does stuff" do
      # This stup has three lines. All of the lines have xrefs. The third is a
      # deprecated xref that has an identical match text to one of the others.
      # That deprecated one gets pruned from :names but doesn't get pruned from
      # :names_see_also
      file_fetcher_stub = lambda { `cp spec/fixtures/twain_skos2.json.gz scratch/names.skosrdf.jsonld.gz` }
      described_class.reset_db(file_fetcher_stub)
      expect(AuthorityBrowse.db[:names].count).to eq(2)
      expect(AuthorityBrowse.db[:names_see_also].count).to eq(5)
    end
    after(:each) do
      `rm scratch/*`
    end
  end
end
