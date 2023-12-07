RSpec.describe AuthorityBrowse::SolrDocument::Names::AuthorityGraphSolrDocument do
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
        xref_label: "Clemens, Samuel Langhorne, 1835-1910",
        xref_count: 50
      },
      {
        id: "http://id.loc.gov/authorities/names/n79021164",
        match_text: "twain mark 1835 1910",
        label: "Twain, Mark, 1835-1910",
        count: 1000,
        xref_label: "Snodgrass, Quintus Curtius, 1835-1910",
        xref_count: 30

      },
      {
        id: "http://id.loc.gov/authorities/names/n79021164",
        match_text: "twain mark 1835 1910",
        label: "Twain, Mark, 1835-1910",
        count: 1000,
        xref_label: "Conte, Louis de, 1835-1910",
        xref_count: 22
      }
    ]
  end
  subject do
    described_class.new(@name)
  end
  context "#any?" do
    it "is true if the main item has a count and the see also all have counts" do
      expect(subject.any?).to eq(true)
    end

    it "is true if the main item does not have a count but at least one see also does" do
      3.times { |x| @name[x][:count] = 0 }
      expect(subject.any?).to eq(true)
    end
    it "is true if the main item has a count but none of the see also have a count" do
      3.times { |x| @name[x][:xref_count] = 0 }
      expect(subject.any?).to eq(true)
    end
    it "is false if all see also counts and the main count are zero" do
      3.times do |x|
        @name[x][:count] = 0
        @name[x][:xref_count] = 0
      end
      expect(subject.any?).to eq(false)
    end
    it "is false if main count is zero and all see also counts are nil" do
      3.times do |x|
        @name[x][:count] = 0
        @name[x][:xref_count] = nil
      end
      expect(subject.any?).to eq(false)
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
      expect(subject.count).to eq(1000)
    end
  end
  context "#match_text" do
    it "has the match test from the db" do
      expect(subject.match_text).to eq("twain mark 1835 1910")
    end
  end
  context "#xrefs" do
    it "has a hash of xrefs with kind and terms and their count separated by ||" do
      expect(subject.xrefs).to eq({see_also: [
        "Clemens, Samuel Langhorne, 1835-1910||50",
        "Snodgrass, Quintus Curtius, 1835-1910||30",
        "Conte, Louis de, 1835-1910||22"
      ]})
    end
    it "is empty when there are nil see_alsos" do
      @name = [
        {
          id: "http://id.loc.gov/authorities/names/n79021164",
          match_text: "twain mark 1835 1910",
          label: "Twain, Mark, 1835-1910",
          count: 1000,
          xref_label: nil,
          xref_count: nil
        }
      ]
      expect(subject.xrefs).to eq({see_also: []})
    end
    it "is empty when see_alsos have a 0 count" do
      @name = [
        {
          id: "http://id.loc.gov/authorities/names/n79021164",
          match_text: "twain mark 1835 1910",
          label: "Twain, Mark, 1835-1910",
          count: 1000,
          xref_label: "something",
          xref_count: 0
        }
      ]
      expect(subject.xrefs).to eq(see_also: [])
    end
  end
  context "#to_solr_doc" do
    it "returns the document with all of the fields" do
      expect(subject.to_solr_doc("2023-09-02T00:00:00Z")).to eq({
        id: "twain mark 1835 1910\u001fname",
        loc_id: mark_twain_id,
        browse_field: "name",
        term: mark_twain_term,
        count: 1000,
        date_of_index: "2023-09-02T00:00:00Z",
        see_also: [
          "Clemens, Samuel Langhorne, 1835-1910||50",
          "Snodgrass, Quintus Curtius, 1835-1910||30",
          "Conte, Louis de, 1835-1910||22"
        ]
      }.to_json)
    end
  end
end
RSpec.describe AuthorityBrowse::SolrDocument::Names::UnmatchedSolrDocument do
  before(:each) do
    @term_entry = {term: "Twain, Mark, 1835-1910", match_text: "twain mark 1835 1910", count: 7}
  end
  subject do
    described_class.new(@term_entry)
  end
  context "#id" do
    it "returns a normalized version fo the name with a unicode space and string name" do
      expect(subject.id).to eq("twain mark 1835 1910\u001fname")
    end
  end
  context "#xrefs" do
    it "returns an empty array" do
      expect(subject.xrefs).to eq(see_also: [])
    end
  end
  context "#count" do
    it "returns the count" do
      expect(subject.count).to eq(7)
    end
  end
  context "#match_text" do
    it "returns the matched text" do
      expect(subject.match_text).to eq("twain mark 1835 1910")
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
