RSpec.describe AuthorityBrowse::LocAuthorities::Entry do
  context "entry without cross references" do
    before(:each) do
      @data = JSON.parse(fixture("loc_authorities/shania_skos.json"))
    end
    subject do
      described_class.new(@data)
    end
    context "#id" do
      it "has an id with the loc web address before it" do
        expect(subject.id).to eq("http://id.loc.gov/authorities/names/no95055361")
      end
    end
    context "#deprecated?" do
      it "is false when there isn't a deprecated change reason" do
        expect(subject.deprecated?).to eq(false)
      end
    end
    context "#label" do
      it "has the preferred label" do
        expect(subject.label).to eq("Twain, Shania")
      end
    end
    context "#see_also_ids" do
      it "returns an empty array because there aren't any ids" do
        expect(subject.see_also_ids).to eq([])
      end
    end
    context "#see_also_ids?" do
      it "is false" do
        expect(subject.see_also_ids?).to eq(false)
      end
    end
    context "#match_text" do
      it "expects the normalized version of the label" do
        expect(subject.match_text).to eq("twain shania")
      end
    end
  end
  context "entry with one cross reference" do
    before(:each) do
      @data = JSON.parse(fixture("loc_authorities/louis_de_conte_skos.json"))
    end
    subject do
      described_class.new(@data)
    end
    context "#see_also_ids" do
      it "has the seeAlsos from the rdfs:seeAlso" do
        expect(subject.see_also_ids).to eq([
          "http://id.loc.gov/authorities/names/n79021164"
        ])
      end
    end
  end
  context "entry with multiple cross references" do
    before(:each) do
      @data = JSON.parse(fixture("loc_authorities/mark_twain_skos.json"))
    end
    subject do
      described_class.new(@data)
    end
    context "#see_also_ids" do
      it "has the seeAlsos from the rdfs:seeAlso" do
        expect(subject.see_also_ids).to eq([
          "http://id.loc.gov/authorities/names/n93099439",
          "http://id.loc.gov/authorities/names/n93099461",
          "http://id.loc.gov/authorities/names/no2003079632"
        ])
      end
    end
    context "#see_also_ids?" do
      it "is true" do
        expect(subject.see_also_ids?).to eq(true)
      end
    end
  end
  context "entry with deprecated label" do
    before(:each) do
      @data = JSON.parse(fixture("loc_authorities/deprecated_skos.json"))
    end
    subject do
      described_class.new(@data)
    end
    context "#label" do
      it "returns the literalForm" do
        expect(subject.label).to eq("Anpo, Masakazu")
      end
    end
    context "#deprecated?" do
      it "returns true when it's deprecated" do
        expect(subject.deprecated?).to eq(true)
      end
    end
  end
end
