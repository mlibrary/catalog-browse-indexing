RSpec.describe Browse::CLI::Names do
  before(:each) do
    [:update, :reset_db, :load_solr_with_matched, :load_solr_with_unmatched].each do |method|
      # verify that these methods exist before mocking them
      AuthorityBrowse::Names.method(method)
      allow(AuthorityBrowse::Names).to receive(method)
    end
  end
  subject do
    described_class.new
  end
  it "calls #update" do
    subject.invoke(:update)
    expect(AuthorityBrowse::Names).to have_received(:update)
  end
  it "calls #reset_db" do
    subject.invoke(:reset_db)
    expect(AuthorityBrowse::Names).to have_received(:reset_db)
  end
  it "calls #load_solr_with_matched" do
    subject.invoke(:load_solr_with_matched)
    expect(AuthorityBrowse::Names).to have_received(:load_solr_with_matched)
  end
  it "calls #load_solr_with_unmatched" do
    subject.invoke(:load_solr_with_unmatched)
    expect(AuthorityBrowse::Names).to have_received(:load_solr_with_unmatched)
  end
end
