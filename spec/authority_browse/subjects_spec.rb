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
  context ".generate_remediated_authorities_file" do
    let(:set_id) { "1234" }
    let(:authority_record) { fixture("remediated_authority_record.json") }
    let(:authority_record_id) { "98187481368106381" }
    let(:authority_set) { fixture("authority_set.json") }
    let(:stub_set_request) {
      stub_alma_get_request(
        url: "conf/sets/#{set_id}/members",
        query: {limit: 100, offset: 0},
        output: authority_set
      )
    }
    let(:stub_authority_request) {
      stub_alma_get_request(
        url: "bibs/authorities/#{authority_record_id}",
        query: {view: "full"},
        output: authority_record
      )
    }
    it "fetches authority records from the alma api for a given set and generates a file with a list of marcxml authorities" do
      auth_stub = stub_authority_request
      set_stub = stub_set_request
      file_path = "#{S.project_root}/tmp/auth_file.xml"
      described_class.generate_remediated_authorities_file(file_path: file_path, set_id: set_id)
      expect(auth_stub).to have_been_requested
      expect(set_stub).to have_been_requested
      output_str = File.read(file_path).strip
      expect(output_str).to eq(JSON.parse(authority_record)&.dig("anies")&.first)
    end
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
      # solr_uploader_double = instance_double(::Solr::Uploader, upload: nil, commit: nil)
      solr_uploader_double = instance_double(Solr::Uploader, send_file_to_solr: nil)
      subjects = AuthorityBrowse.db[:subjects]
      subxref = AuthorityBrowse.db[:subjects_xrefs]

      subjects.insert(id: "id1", label: "First", match_text: "first", count: 1)
      subjects.insert(id: "id2", label: "Second", match_text: "second", count: 2)
      subjects.insert(id: "id3", label: "Third", match_text: "third", count: 3)
      subjects.insert(id: "id4", label: "Fourth", match_text: "fourth", count: 0)
      subxref.insert(subject_id: "id1", xref_id: "id2", xref_kind: "broader")
      subxref.insert(subject_id: "id1", xref_id: "id3", xref_kind: "narrower")
      described_class.load_solr_with_matched(solr_uploader_double)
      expect(solr_uploader_double).to have_received(:send_file_to_solr)
      file_contents = []
      Zinzout.zin(AuthorityBrowse::Names.solr_docs_file) do |infile|
        infile.each { |x| file_contents.push(x) }
      end
      expect(file_contents).to eq([
        {
          id: "first\u001fsubject",
          browse_field: "subject",
          term: "First",
          count: 1,
          date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z",
          broader: ["Second||2"],
          narrower: ["Third||3"]
        }.to_json + "\n",
        {
          id: "second\u001fsubject",
          browse_field: "subject",
          term: "Second",
          count: 2,
          date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
        }.to_json + "\n",
        {
          id: "third\u001fsubject",
          browse_field: "subject",
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
      sfb = AuthorityBrowse.db[:subjects_from_biblio]
      sfb.insert(term: "term1", count: 1, match_text: "match_text")
      sfb.insert(term: "term2", count: 2, match_text: "match_text")
      sfb.insert(term: "term3", count: 0, match_text: "term3")
      sfb.insert(term: "term4", count: 4, match_text: "term4")
      sfb.insert(term: "term5", count: 5, match_text: "term5", subject_id: "id1")
      described_class.load_solr_with_unmatched(solr_uploader_double)
      expect(solr_uploader_double).to have_received(:send_file_to_solr)
      file_contents = []
      Zinzout.zin(AuthorityBrowse::Subjects.solr_docs_file) do |infile|
        infile.each { |x| file_contents.push(x) }
      end
      expect(file_contents).to eq([
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
      ])
    end
  end
  context "incorporate_remediated_subjects" do
    it "handles adding remediated subjects" do
      subjects = AuthorityBrowse.db[:subjects]
      subxref = AuthorityBrowse.db[:subjects_xrefs]
      mms_id = "98187481368506381"
      loc_id = "http://id.loc.gov/authorities/subjects/sh2008104250"

      subjects.insert(id: loc_id, label: "Illegal Aliens", match_text: "illegal aliens", count: 0)
      subjects.insert(id: "id2", label: "Second", match_text: "second", count: 2)
      subxref.insert(subject_id: loc_id, xref_id: "id2", xref_kind: "broader")
      subxref.insert(subject_id: "id2", xref_id: loc_id, xref_kind: "narrower")

      AuthorityBrowse::Subjects.incorporate_remediated_subjects(File.join(S.project_root, "spec", "fixtures", "remediated_subject.xml"))
      remediated = subjects.where(id: mms_id).first
      expect(remediated[:label]).to eq("Undocumented immigrants--Government policy--United States")
      expect(remediated[:match_text]).to eq("undocumented immigrants--government policy--united states")

      broader = subxref.where(subject_id: mms_id).first
      expect(broader[:xref_id]).to eq("id2")
      expect(broader[:xref_kind]).to eq("broader")

      narrower = subxref.where(xref_id: mms_id).first
      expect(narrower[:subject_id]).to eq("id2")
      expect(narrower[:xref_kind]).to eq("narrower")

      new = subxref.where(subject_id: loc_id).first
      expect(new[:xref_id]).to eq(mms_id)
      expect(new[:xref_kind]).to eq("see_instead")
    end
  end
  after(:each) do
    Dir["#{S.project_root}/tmp/*"].each do |file|
      File.delete(file)
    end
  end
end
