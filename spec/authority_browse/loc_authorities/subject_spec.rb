RSpec.describe AuthorityBrowse::LocAuthorities::Subject do
  context "entry without cross references" do
    before(:each) do
      @data = JSON.parse(fixture("loc_authorities/golf_skos.json"))
    end
    subject do
      described_class.new(@data)
    end
    context "#xref_ids?" do
      it "is false" do
        expect(subject.xref_ids?).to eq(false)
      end
    end
  end
  context "entry with multiple cross references" do
    before(:each) do
      @data = JSON.parse(fixture("loc_authorities/counterpoint_skos.json"))
    end
    subject do
      described_class.new(@data)
    end
    context "#id" do
      it "has an id with the loc web address before it" do
        expect(subject.id).to eq("http://id.loc.gov/authorities/subjects/sh85033444")
      end
    end
    context "#deprecated?" do
      it "is false when there isn't a deprecated change reason" do
        expect(subject.deprecated?).to eq(false)
      end
    end
    context "#label" do
      it "has the preferred label" do
        expect(subject.label).to eq("Counterpoint")
      end
    end
    context "#broader_ids" do
      it "has the broaders from the skos:broader" do
        expect(subject.broader_ids).to eq([
          "http://id.loc.gov/authorities/subjects/sh85088826"
        ])
      end
    end
    context "#narrower_ids" do
      it "has the narrower from the skos:narrower" do
        expect(subject.narrower_ids).to eq([
          "http://id.loc.gov/authorities/subjects/sh85037121",
          "http://id.loc.gov/authorities/subjects/sh85052251",
          "http://id.loc.gov/authorities/subjects/sh92004988",
          "http://id.loc.gov/authorities/subjects/sh97002450"
        ])
      end
    end
    context "#xref_ids?" do
      it "is true" do
        expect(subject.xref_ids?).to eq(true)
      end
    end
    context "#match_text" do
      it "expects the normalized version of the label" do
        expect(subject.match_text).to eq("counterpoint")
      end
    end
  end
  context "entry with deprecated label" do
    before(:each) do
      @data = JSON.parse(fixture("loc_authorities/joan_pope_skos.json"))
    end
    subject do
      described_class.new(@data)
    end
    context "#label" do
      it "returns the literalForm" do
        expect(subject.label).to eq("Joan (Legendary Pope)")
      end
    end
    context "#deprecated?" do
      it "returns true when it's deprecated" do
        expect(subject.deprecated?).to eq(true)
      end
    end
  end
end
