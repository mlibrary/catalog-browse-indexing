RSpec.describe AuthorityBrowse::AuthorityGraphSolrDocument do
  let(:mark_twain_id) { "http://id.loc.gov/authorities/names/n79021164" }
  let(:mark_twain_term) { "Twain, Mark, 1835-1910" }

  before(:each) do
    # set up AuthorityGraph db
    @name = [
      {
        id: "http://id.loc.gov/authorities/names/n79021164",
        match_text: "twain mark 1835 1910",
        label: "Twain, Mark, 1835-1910",
        count: 1000,
        see_also_label: "Clemens, Samuel Langhorne, 1835-1910",
        see_also_count: 50
      },
      {
        id: "http://id.loc.gov/authorities/names/n79021164",
        match_text: "twain mark 1835 1910",
        label: "Twain, Mark, 1835-1910",
        count: 1000,
        see_also_label: "Snodgrass, Quintus Curtius, 1835-1910",
        see_also_count: 30

      },
      {
        id: "http://id.loc.gov/authorities/names/n79021164",
        match_text: "twain mark 1835 1910",
        label: "Twain, Mark, 1835-1910",
        count: 1000,
        see_also_label: "Conte, Louis de, 1835-1910",
        see_also_count: 22
      }
    ]
  end
  subject do
    described_class.new(@name)
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
      expect(subject.count).to eq(1000)
    end
  end
  context "#see_also" do
    it "has the see_also terms and their count separated by ||" do
      expect(subject.see_also).to eq([
        "Clemens, Samuel Langhorne, 1835-1910||50",
        "Snodgrass, Quintus Curtius, 1835-1910||30",
        "Conte, Louis de, 1835-1910||22"
      ])
    end
  end
  context "#to_solr_doc" do
    it "returns the document with all of the fields" do
      expect(subject.to_solr_doc("2023-09-02T00:00:00Z")).to eq({
        id: "twain mark 1835 1910\u001fname",
        loc_id: mark_twain_id,
        browse_field: "name",
        term: mark_twain_term,
        see_also: [
          "Clemens, Samuel Langhorne, 1835-1910||50",
          "Snodgrass, Quintus Curtius, 1835-1910||30",
          "Conte, Louis de, 1835-1910||22"
        ],
        count: 1000,
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
