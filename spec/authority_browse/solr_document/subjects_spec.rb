RSpec.describe AuthorityBrowse::SolrDocument::Subjects::AuthorityGraphSolrDocument do
  let(:counterpoint_id) { "http://id.loc.gov/authorities/subjects/sh85033444" }

  before(:each) do
    # set up AuthorityGraph db
    @subject = [
      {
        id: "http://id.loc.gov/authorities/subjects/sh85033444",
        match_text: "counterpoint",
        label: "Counterpoint",
        count: 1000,
        xref_label: "Music theory",
        xref_count: 50,
        xref_kind: "broader"
      },
      {
        id: "http://id.loc.gov/authorities/subjects/sh85033444",
        match_text: "counterpoint",
        label: "Counterpoint",
        count: 1000,
        xref_label: "Cantus firmus",
        xref_count: 7,
        xref_kind: "narrower"
      },
      {
        id: "http://id.loc.gov/authorities/subjects/sh85033444",
        match_text: "counterpoint",
        label: "Counterpoint",
        count: 1000,
        xref_label: "Canon (Musical form)",
        xref_count: 30,
        xref_kind: "narrower"
      }
    ]
  end
  subject do
    described_class.new(@subject)
  end
  context "#any?" do
    it "is true if the main item has a count and the xrefs all have counts" do
      expect(subject.any?).to eq(true)
    end

    it "is true if the main item does not have a count but at least one see also does" do
      3.times { |x| @subject[x][:count] = 0 }
      expect(subject.any?).to eq(true)
    end
    it "is true if the main item has a count but none of the xrefs have a count" do
      3.times do |x|
        @subject[x][:xref_count] = 0
      end
      expect(subject.any?).to eq(true)
    end
    it "is false if all see also counts and the main count are zero" do
      3.times do |x|
        @subject[x][:count] = 0
        @subject[x][:xref_count] = 0
      end
      expect(subject.any?).to eq(false)
    end
    it "is false if main count is zero and all see also counts are nil" do
      3.times do |x|
        @subject[x][:count] = 0
        @subject[x][:xref_count] = nil
      end
      expect(subject.any?).to eq(false)
    end
  end
  context "#id" do
    it "returns a normalized version fo the name with a unicode space and string name" do
      expect(subject.id).to eq("counterpoint\u001fsubject")
    end
  end
  context "#loc_id" do
    it "returns the loc_id when the id is a loc id" do
      expect(subject.loc_id).to eq(counterpoint_id)
    end
    it "returns nil when it's not the loc id" do
      @subject[0][:id] = "9912351598"
      expect(subject.loc_id).to be_nil
    end
  end
  context "#term" do
    it "has the expected term" do
      expect(subject.term).to eq("Counterpoint")
    end
  end
  context "#count" do
    it "has the expected count" do
      expect(subject.count).to eq(1000)
    end
  end
  context "#match_text" do
    it "has the match test from the db" do
      expect(subject.match_text).to eq("counterpoint")
    end
  end
  context "#xrefs" do
    it "has the broader and narrower terms and their count separated by ||" do
      expect(subject.xrefs).to eq({
        broader: ["Music theory||50"],
        narrower: ["Canon (Musical form)||30", "Cantus firmus||7"],
        see_instead: []
      })
    end
    it "handles see_instead values" do
      @subject[0][:xref_kind] = "see_instead"
      expect(subject.xrefs).to eq({
        broader: [],
        narrower: ["Canon (Musical form)||30", "Cantus firmus||7"],
        see_instead: ["Music theory||50"]
      })
    end
    it "is shows broaders when there are nil broaders" do
      @subject = [
        {
          id: counterpoint_id,
          match_text: "counterpoint",
          label: "Counterpoint",
          count: 1000,
          xref_label: "Music theory",
          xref_count: nil,
          xref_kind: "boader"
        }
      ]
      expect(subject.xrefs).to eq({
        broader: [],
        narrower: [],
        see_instead: []
      })
    end
    it "is shows when broaders have a 0 count" do
      @subject = [
        {
          id: counterpoint_id,
          match_text: "counterpoint",
          label: "Counterpoint",
          count: 1000,
          xref_label: "something",
          xref_count: 0
        }
      ]
      expect(subject.xrefs).to eq({
        broader: [],
        narrower: [],
        see_instead: []
      })
    end
  end
  context "#to_solr_doc" do
    it "returns the document with all of the fields" do
      expect(subject.to_solr_doc("2023-09-02T00:00:00Z")).to eq({
        id: "counterpoint\u001fsubject",
        loc_id: counterpoint_id,
        browse_field: "subject",
        term: "Counterpoint",
        count: 1000,
        date_of_index: "2023-09-02T00:00:00Z",
        broader: [
          "Music theory||50"
        ],
        narrower: [
          "Canon (Musical form)||30",
          "Cantus firmus||7"
        ]
      }.to_json)
    end
  end
end
RSpec.describe AuthorityBrowse::SolrDocument::Subjects::UnmatchedSolrDocument do
  before(:each) do
    @term_entry = {term: "Counterpoint", match_text: "counterpoint", count: 7}
  end
  subject do
    described_class.new(@term_entry)
  end
  context "#id" do
    it "returns a normalized version fo the name with a unicode space and string name" do
      expect(subject.id).to eq("counterpoint\u001fsubject")
    end
  end
  context "#xrefs" do
    it "returns hash of xrefs with empty arrays" do
      expect(subject.xrefs).to eq({
        broader: [],
        narrower: [],
        see_instead: []
      })
    end
  end
  context "#count" do
    it "returns the count" do
      expect(subject.count).to eq(7)
    end
  end
  context "#match_text" do
    it "returns the matched text" do
      expect(subject.match_text).to eq("counterpoint")
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
        id: "counterpoint\u001fsubject",
        browse_field: "subject",
        term: "Counterpoint",
        count: 7,
        date_of_index: "2023-09-02T00:00:00Z"
      }.to_json)
    end
  end
end
