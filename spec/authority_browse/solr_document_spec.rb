RSpec.describe AuthorityBrowse::AuthorityGraphSolrDocument do
  let(:mark_twain_id) { "http://id.loc.gov/authorities/names/n79021164" }
  let(:mark_twain_term) { "Twain, Mark, 1835-1910" }

  before(:each) do
    # set up AuthorityGraph db
    mark_twain = JSON.parse(fixture("loc_authorities/mark_twain_skos.json"))
    louis = JSON.parse(fixture("loc_authorities/louis_de_conte_skos.json"))
    AuthorityBrowse::LocAuthorities::Entry.new(mark_twain).save_to_db
    AuthorityBrowse::LocAuthorities::Entry.new(louis).save_to_db

    # set up terms DB
    @terms_db = AuthorityBrowse.terms_db[:names]
    @terms_db.insert(term: mark_twain_term, count: 7)
    @terms_db.insert(term: "Conte, Louis de, 1835-1910", count: 2)
  end
  subject do
    described_class.new(Name.find(id: mark_twain_id))
  end
  context "#in_term_db? and #set_in_authority_graph" do
    it "is true when the term is in the terms_db" do
      expect(subject.in_term_db?).to eq(true)
      term_mark_twain = @terms_db.find(term: mark_twain_term).first
      expect(term_mark_twain[:in_authority_graph]).to eq(true)
    end
    it "is false when term is not in the term db" do
      @terms_db.filter(term: mark_twain_term).delete
      expect(subject.in_term_db?).to eq(false)
    end
  end
  context "#id" do
    it "returns a normalized version fo the name with a unicode space and string name" do
      expect(subject.id).to eq("twain mark 1835 1910\u001fname")
    end
  end
  context "#loc_id" do
    it "returns the loc_id" do
      expect(subject.loc_id).to eq(mark_twain_id)
    end
  end
  context "#term" do
    it "has the expected term" do
      expect(subject.term).to eq(mark_twain_term)
    end
  end
  context "#count" do
    it "has the expected count" do
      expect(subject.count).to eq(7)
    end
  end
  context "#see_also" do
    it "has the see_also terms and their count separated by ||" do
      expect(subject.see_also).to eq([
        "Conte, Louis de, 1835-1910||2"
      ])
    end
    it "skips over xrefs that aren't in the terms_db" do
      @terms_db.filter(term: "Conte, Louis de, 1835-1910").delete
      expect(subject.see_also).to eq([])
    end
  end
  context "#to_solr_doc" do
    it "returns the document with all of the fields" do
      expect(subject.to_solr_doc("2023-09-02T00:00:00Z")).to eq({
        id: "twain mark 1835 1910\u001fname",
        loc_id: mark_twain_id,
        browse_field: "name",
        term: mark_twain_term,
        see_also: ["Conte, Louis de, 1835-1910||2"],
        count: 7,
        date_of_index: "2023-09-02T00:00:00Z"
      }.to_json)
    end
  end
end
RSpec.describe AuthorityBrowse::UnmatchedSolrDocument do
  before(:each) do
    @term_entry = {term: "Twain, Mark, 1835-1910", count: 7, in_authority_graph: false}
  end
  subject do
    described_class.new(@term_entry)
  end
  context "#id" do
    it "returns a normalized version fo the name with a unicode space and string name" do
      expect(subject.id).to eq("twain mark 1835 1910\u001fname")
    end
  end
  context "#see_also" do
    it "returns an empty array" do
      expect(subject.see_also).to eq([])
    end
  end
  context "#count" do
    it "returns the count" do
      expect(subject.count).to eq(7)
    end
  end
  context "#loc_id" do
    it "is nil" do
      expect(subject.loc_id).to be_nil
    end
  end
  context "#to_solr_doc" do
    it "returns the document with all of the fields" do
      expect(subject.to_solr_doc("2023-09-02T00:00:00Z")).to eq({
        id: "twain mark 1835 1910\u001fname",
        browse_field: "name",
        term: "Twain, Mark, 1835-1910",
        count: 7,
        date_of_index: "2023-09-02T00:00:00Z"
      }.to_json)
    end
  end
end
