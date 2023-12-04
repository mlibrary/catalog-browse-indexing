RSpec.describe AuthorityBrowse::Subjects do
  [:kind, :field_name, :remote_skos_file, :local_skos_file].each do |method|
    it "has a .#{method} that returns a string" do
      expect(described_class.public_send(method).class).to eq(String)
    end
  end
  it "has a .from_biblio_table" do
    expect(described_class.from_biblio_table).to eq(:subjects_from_biblio)
  end
  it "has a .database_klass" do
    expect(described_class.database_klass).to eq(AuthorityBrowse::DB::Subjects)
  end
  it "has a .mutator_klass" do
    expect(described_class.mutator_klass).to eq(AuthorityBrowse::DBMutator::Subjects)
  end

  context ".reset_db" do
    it "fetches and loads a skos file into :subjects and :subjects_xrefs" do
      # This stup has three lines. All of the lines have xrefs. The third is a
      # deprecated xref that has an identical match text to one of the others.
      # That deprecated one gets pruned from :names but doesn't get pruned from
      # :names_see_also
      file_fetcher_stub = lambda { `cp spec/fixtures/counterpoint.jsonl.gz tmp/subjects.skosrdf.jsonld.gz` }
      described_class.reset_db(file_fetcher_stub)
      expect(AuthorityBrowse.db[:subjects].count).to eq(7)
      expect(AuthorityBrowse.db[:subjects_xrefs].count).to eq(11)
    end
  end
  context ".load_solr_with_matched" do
    it "loads the terms in the names db with counts into solr" do
      solr_uploader_double = instance_double(AuthorityBrowse::Solr::Uploader, upload: nil, commit: nil)
      subjects = AuthorityBrowse.db[:subjects]
      subxref = AuthorityBrowse.db[:subjects_xrefs]

      subjects.insert(id: "id1", label: "First", match_text: "first", count: 1)
      subjects.insert(id: "id2", label: "Second", match_text: "second", count: 2)
      subjects.insert(id: "id3", label: "Third", match_text: "third", count: 3)
      subjects.insert(id: "id4", label: "Fourth", match_text: "fourth", count: 0)
      subxref.insert(subject_id: "id1", xref_id: "id2", xref_kind: "broader")
      subxref.insert(subject_id: "id1", xref_id: "id3", xref_kind: "narrower")
      described_class.load_solr_with_matched(solr_uploader_double)
      expect(solr_uploader_double).to have_received(:upload).with(
        [
          {
            id: "first\u001fsubject",
            loc_id: "id1",
            browse_field: "subject",
            term: "First",
            count: 1,
            date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z",
            broader: ["Second||2"],
            narrower: ["Third||3"]
          }.to_json + "\n",
          {
            id: "second\u001fsubject",
            loc_id: "id2",
            browse_field: "subject",
            term: "Second",
            count: 2,
            date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
          }.to_json + "\n",
          {
            id: "third\u001fsubject",
            loc_id: "id3",
            browse_field: "subject",
            term: "Third",
            count: 3,
            date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
          }.to_json + "\n"
        ]
      )
    end
  end
  context ".load_solr_with_unmatched" do
    it "sends solr the expected docs" do
      solr_uploader_double = instance_double(AuthorityBrowse::Solr::Uploader, upload: nil, commit: nil)
      sfb = AuthorityBrowse.db[:subjects_from_biblio]
      sfb.insert(term: "term1", count: 1, match_text: "match_text")
      sfb.insert(term: "term2", count: 2, match_text: "match_text")
      sfb.insert(term: "term3", count: 0, match_text: "term3")
      sfb.insert(term: "term4", count: 4, match_text: "term4")
      sfb.insert(term: "term5", count: 5, match_text: "term5", subject_id: "id1")
      described_class.load_solr_with_unmatched(solr_uploader_double)
      expect(solr_uploader_double).to have_received(:upload).with(
        [
          {
            id: "match_text\u001fsubject",
            browse_field: "subject",
            term: "term1",
            count: 1,
            date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
          }.to_json + "\n",
          {
            id: "match_text\u001fsubject",
            browse_field: "subject",
            term: "term2",
            count: 2,
            date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
          }.to_json + "\n",
          {
            id: "term4\u001fsubject",
            browse_field: "subject",
            term: "term4",
            count: 4,
            date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
          }.to_json + "\n"
        ]
      )
    end
  end
  after(:each) do
    %x(if [ ! -z `ls /app/tmp/` ]; then rm tmp/*; fi)
  end
end
