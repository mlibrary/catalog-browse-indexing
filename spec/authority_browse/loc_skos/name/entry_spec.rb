RSpec.describe AuthorityBrowse::LocSKOSRDF::Name::Entry do
  context "name with no cross references" do
    before(:each) do
      @entry = JSON.parse(fixture("loc_skos/shania_skos.json"))
    end
    subject do
      described_class.new(@entry)
    end
    it "has a category of name" do
      expect(subject.category).to eq("name")
    end
    it "has components hash with ids of loc id that point to Objects that are a Name::Compoment" do
      #it also: 
      #  - gets rid of @type: cs:ChangeSet
      expect(subject.components.keys.count).to eq(1)
      expect(subject.components["http://id.loc.gov/authorities/names/no95055361"].class).to eq(AuthorityBrowse::LocSKOSRDF::Name::Component)
    end
    it "has an empty see_also" do
      expect(subject.see_also).to eq({})
    end
    it "has an empty incoming_see_also" do
      expect(subject.incoming_see_also).to eq({})
    end
    it "has an empty count" do
      expect(subject.count).to eq(0)
    end
    it "has empty xref_ids" do
      expect(subject.xref_ids).to eq([])
    end
    it "xref_ids? will be false" do
      expect(subject.xref_ids?).to eq(false)
    end
    it "has empty #non_empty_see_also" do
      expect(subject.non_empty_see_also).to eq({})
    end
    it "has empty #non_empty_incoming_see_also" do
      expect(subject.non_empty_incoming_see_also).to eq({})
    end
    it "makes expected #to_json" do
      expect(JSON.parse(subject.to_json)).to eq( 
        {
          "id"=>"http://id.loc.gov/authorities/names/no95055361", 
          "loc_id"=>"no95055361", 
          "label"=>"Twain, Shania", 
          "match_text"=>"twain shania", 
          "category"=>"name", 
          "alternate_forms"=> ["Edwards, Eilleen", "Twain, Eilleen"], 
          "components"=>{
            "http://id.loc.gov/authorities/names/no95055361"=>{
              "id"=>"http://id.loc.gov/authorities/names/no95055361", 
              "type"=>"skos:Concept", 
              "raw_entry"=>{
                "@id"=>"http://id.loc.gov/authorities/names/no95055361", 
                "@type"=>"skos:Concept", 
                "skos:altLabel"=>["Edwards, Eilleen", "Twain, Eilleen"], 
                "skos:inScheme"=>{"@id"=>"http://id.loc.gov/authorities/names"}, 
                "skos:prefLabel"=>"Twain, Shania", 
                "skosxl:altLabel"=>[
                  {"@id"=>"_:nd9a9b7df80ff403a8902b9a95ba12000b3"}, 
                  {"@id"=>"_:nd9a9b7df80ff403a8902b9a95ba12000b4"}
                ]}, 
                "json_class"=>"AuthorityBrowse::LocSKOSRDF::Name::Component"}
          }, 
          "need_xref"=>false, 
          "deprecated"=>false, 
          "count"=>0, 
          "json_class"=>"AuthorityBrowse::LocSKOSRDF::Name::Entry"
        }
     )
    end
    it "has a #db_object" do
      expect(subject.db_object).to eq({
        id: "http://id.loc.gov/authorities/names/no95055361", 
        label: "Twain, Shania",
        match_text: "twain shania",
        xrefs: false,
        deprecated: false,
        json: {
          "id"=>"http://id.loc.gov/authorities/names/no95055361", 
          "loc_id"=>"no95055361", 
          "label"=>"Twain, Shania", 
          "match_text"=>"twain shania", 
          "category"=>"name", 
          "alternate_forms"=> ["Edwards, Eilleen", "Twain, Eilleen"], 
          "components"=>{
            "http://id.loc.gov/authorities/names/no95055361"=>{
              "id"=>"http://id.loc.gov/authorities/names/no95055361", 
              "type"=>"skos:Concept", 
              "raw_entry"=>{
                "@id"=>"http://id.loc.gov/authorities/names/no95055361", 
                "@type"=>"skos:Concept", 
                "skos:altLabel"=>["Edwards, Eilleen", "Twain, Eilleen"], 
                "skos:inScheme"=>{"@id"=>"http://id.loc.gov/authorities/names"}, 
                "skos:prefLabel"=>"Twain, Shania", 
                "skosxl:altLabel"=>[
                  {"@id"=>"_:nd9a9b7df80ff403a8902b9a95ba12000b3"}, 
                  {"@id"=>"_:nd9a9b7df80ff403a8902b9a95ba12000b4"}
                ]}, 
              "json_class"=>"AuthorityBrowse::LocSKOSRDF::Name::Component"}
          }, 
          "need_xref"=>false, 
          "deprecated"=>false, 
          "count"=>0, 
          "json_class"=>"AuthorityBrowse::LocSKOSRDF::Name::Entry"
        }.to_json
      })
    end
    it "has a #to_solr_doc" do
      expect(subject.to_solr_doc).to eq({
        id: "Twain, Shania",
        loc_id: "http://id.loc.gov/authorities/names/no95055361", 
        browse_field: "name",
        term: "Twain, Shania",
        alternate_forms: ["Edwards, Eilleen", "Twain, Eilleen"],
        #see_also: nil,
        #incoming_see_also: nil
        count: 0,
        json: 
          {
          "id"=>"http://id.loc.gov/authorities/names/no95055361", 
          "loc_id"=>"no95055361", 
          "label"=>"Twain, Shania", 
          "category"=>"name", 
          "alternate_forms"=> ["Edwards, Eilleen", "Twain, Eilleen"], 
          "count"=>0, 
        }.to_json
}

      )
    end
    it "can be made from skosline with .new_from_skosline" do
      instance_from_new_from_skosline = described_class.new_from_skosline(@entry.to_json)

      expect(instance_from_new_from_skosline.to_json).to eq(subject.to_json)
    end
  
  end
end
