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
          "http://id.loc.gov/authorities/names/no2003079632",
        ])
      end
    end
    context "#see_also_ids?" do
      it "is true" do
        expect(subject.see_also_ids?).to eq(true)
      end
    end
  end
  context "writing a name and its see_also to the database" do
    context "#save_to_db" do
      it "has cross references as expected" do
        mark_twain = JSON.parse(fixture("loc_authorities/mark_twain_skos.json"))
        louis = JSON.parse(fixture("loc_authorities/louis_de_conte_skos.json"))
        described_class.new(mark_twain).save_to_db
        described_class.new(louis).save_to_db

        louis_entry = Name.find(id: "http://id.loc.gov/authorities/names/no2003079632")
        mark_entry = Name.find(id: "http://id.loc.gov/authorities/names/n79021164")
        expect(mark_entry.see_also).to include(louis_entry)
        expect(louis_entry.see_also).to include(mark_entry)
      end
    end
  end
end
