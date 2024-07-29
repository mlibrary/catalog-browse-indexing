RSpec.describe AuthorityBrowse::Names do
  [:kind, :field_name, :remote_skos_file, :local_skos_file].each do |method|
    it "has a .#{method} that returns a string" do
      expect(described_class.public_send(method).class).to eq(String)
    end
  end
  it "has a .from_biblio_table" do
    expect(described_class.from_biblio_table).to eq(:names_from_biblio)
  end
  it "has a .database_klass" do
    expect(described_class.database_klass).to eq(AuthorityBrowse::DB::Names)
  end
  it "has a .mutator_klass" do
    expect(described_class.mutator_klass).to eq(AuthorityBrowse::DBMutator::Names)
  end

  context ".update" do
    it "calls the expected methods" do
      term_fetcher = instance_double(AuthorityBrowse::TermFetcher, run: nil)
      names_methods = [:zero_out_counts, :update_main_with_counts, :add_ids_to_from_biblio]
      names_methods.each do |method|
        allow(AuthorityBrowse::DBMutator::Names).to receive(method)
      end
      described_class.update(term_fetcher)
      expect(term_fetcher).to have_received(:run)
      names_methods.each do |method|
        expect(AuthorityBrowse::DBMutator::Names).to have_received(method)
      end
    end
  end

  context ".reset_db" do
    it "fetches and loads a skos file into names and names see also" do
      # This stup has three lines. All of the lines have xrefs. The third is a
      # deprecated xref that has an identical match text to one of the others.
      # That deprecated one gets pruned from :names but doesn't get pruned from
      # :names_see_also
      file_fetcher_stub = lambda { `cp spec/fixtures/twain_skos2.json.gz tmp/names.skosrdf.jsonld.gz` }
      described_class.reset_db(file_fetcher_stub)
      expect(AuthorityBrowse.db[:names].count).to eq(2)
      expect(AuthorityBrowse.db[:names_see_also].count).to eq(5)
    end
  end
  context ".load_solr_with_matched" do
    it "loads the terms in the names db with counts into solr" do
      solr_uploader_double = instance_double(Solr::Uploader, send_file_to_solr: nil)
      names = AuthorityBrowse.db[:names]
      nsa = AuthorityBrowse.db[:names_see_also]

      names.insert(id: "id1", label: "First", match_text: "first", count: 1)
      names.insert(id: "id2", label: "Second", match_text: "second", count: 2)
      names.insert(id: "id3", label: "Third", match_text: "third", count: 3)
      names.insert(id: "id4", label: "Fourth", match_text: "fourth", count: 0)
      nsa.insert(name_id: "id1", see_also_id: "id2")
      nsa.insert(name_id: "id1", see_also_id: "id3")
      described_class.load_solr_with_matched(solr_uploader_double)
      expect(solr_uploader_double).to have_received(:send_file_to_solr)
      file_contents = []
      Zinzout.zin(AuthorityBrowse::Subjects.solr_docs_file) do |infile|
        infile.each { |x| file_contents.push(x) }
      end
      expect(file_contents).to eq([
        {
          id: "first\u001fname",
          browse_field: "name",
          term: "First",
          count: 1,
          date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z",
          see_also: ["Second||2", "Third||3"]
        }.to_json + "\n",
        {
          id: "second\u001fname",
          browse_field: "name",
          term: "Second",
          count: 2,
          date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
        }.to_json + "\n",
        {
          id: "third\u001fname",
          browse_field: "name",
          term: "Third",
          count: 3,
          date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
        }.to_json + "\n"
      ])
    end
  end
  context ".load_solr_with_unmatched" do
    it "sends solr the expected docs" do
      solr_uploader_double = instance_double(Solr::Uploader, send_file_to_solr: nil)
      nfb = AuthorityBrowse.db[:names_from_biblio]
      nfb.insert(term: "term1", count: 1, match_text: "match_text")
      nfb.insert(term: "term2", count: 2, match_text: "match_text")
      nfb.insert(term: "term3", count: 0, match_text: "term3")
      nfb.insert(term: "term4", count: 4, match_text: "term4")
      nfb.insert(term: "term5", count: 5, match_text: "term5", name_id: "id1")
      described_class.load_solr_with_unmatched(solr_uploader_double)
      # TODO term1 and term2 shouldn't occur because then there'd be identical
      # solr ids.
      expect(solr_uploader_double).to have_received(:send_file_to_solr)
      file_contents = []
      Zinzout.zin(AuthorityBrowse::Subjects.solr_docs_file) do |infile|
        infile.each { |x| file_contents.push(x) }
      end
      expect(file_contents).to eq([
        {
          id: "match_text\u001fname",
          browse_field: "name",
          term: "term1",
          count: 1,
          date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
        }.to_json + "\n",
        {
          id: "match_text\u001fname",
          browse_field: "name",
          term: "term2",
          count: 2,
          date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
        }.to_json + "\n",
        {
          id: "term4\u001fname",
          browse_field: "name",
          term: "term4",
          count: 4,
          date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
        }.to_json + "\n"
      ])
    end
  end
  after(:each) do
    %x(if [ ! -z `ls /app/tmp/` ]; then rm tmp/*; fi)
  end
end
