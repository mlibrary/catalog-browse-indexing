RSpec.describe Name do
  before(:each) do
    Name.create(id: "some_id", label: "Some Label")
  end
  it "has an id" do
    expect(Name.last.id).to eq("some_id")
  end
  it "has a label" do
    expect(Name.last.label).to eq("Some Label")
  end
  it "has appropriate see alsos" do
    AuthorityBrowse.authorities_graph_db[:names_see_also].insert(name_id: "main_id", see_also_id: "see_also_id")
    Name.create(id: "main_id", label: "Main")
    Name.create(id: "see_also_id", label: "See Also")
    main = Name.find(id: "main_id")
    see_also = Name.find(id: "see_also_id")
    expect(main.see_also.first).to eq(see_also)
    expect(see_also.see_also.empty?).to eq(true)
  end
end
