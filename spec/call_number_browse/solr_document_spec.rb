RSpec.describe CallNumberBrowse::SolrDocument do
  before(:each) do
    @bib_id = "9912345"
    @call_number = "call_number"
  end
  let(:id) { "#{@call_number}\u001F#{@bib_id}" }
  subject do
    described_class.new(bib_id: @bib_id, call_number: @call_number)
  end
  it "has an #bib_id" do
    expect(subject.bib_id).to eq(@bib_id)
  end
  it "has an #call_number" do
    expect(subject.call_number).to eq(@call_number)
  end
  it "has an #id" do
    expect(subject.id).to eq(id)
  end
  it "it can create a solr document with #.to_solr_doc" do
    expect(subject.to_solr_doc).to eq({
      uid: id,
      id: id,
      bib_id: @bib_id,
      callnumber: @call_number
    }.to_json)
  end
  context ".for" do
    it "creates a SolrDocument object for biblio_doc output" do
      biblio_doc = {"id" => @bib_id, "callnumber_browse" => [@call_number]}
      solr_doc = described_class.for(biblio_doc)
      expect(solr_doc.bib_id).to eq(@bib_id)
      expect(solr_doc.call_number).to eq(@call_number)
    end
  end
end
