RSpec.describe Browse::CLI::Solr do
  subject do
    described_class.new
  end
  it "calls #set_up_daily_authority_browse_collection" do
    setup_methods = [:create_configset_if_needed, :set_up_daily_collection, :configset_name]
    setup_methods.each do |method|
      allow(AuthorityBrowse::Solr).to receive(method)
    end
    subject.invoke(:set_up_daily_authority_browse_collection)
    setup_methods.each do |method|
      expect(AuthorityBrowse::Solr).to have_received(method)
    end
  end
  it "calls #verify_and_deploy_authority_browse_collection" do
    setup_methods = [:verify_reindex, :set_production_alias]
    setup_methods.each do |method|
      allow(AuthorityBrowse::Solr).to receive(method)
    end
    subject.invoke(:verify_and_deploy_authority_browse_collection)
    setup_methods.each do |method|
      expect(AuthorityBrowse::Solr).to have_received(method)
    end
  end
  it "calls #list_authority_browse_collections_to_prune" do
    allow(AuthorityBrowse::Solr).to receive(:list_old_collections)
    subject.invoke(:list_authority_browse_collections_to_prune)
    expect(AuthorityBrowse::Solr).to have_received(:list_old_collections)
  end
  it "calls #prune_authority_browse_collections" do
    allow(AuthorityBrowse::Solr).to receive(:prune_old_collections)
    subject.invoke(:prune_authority_browse_collections)
    expect(AuthorityBrowse::Solr).to have_received(:prune_old_collections)
  end
end
RSpec.describe Browse::CLI::Names do
  names_methods = [:update, :reset_db, :load_solr_with_matched, :load_solr_with_unmatched]
  before(:each) do
    names_methods.each do |method|
      # verify that these methods exist before mocking them
      AuthorityBrowse::Names.method(method)
      allow(AuthorityBrowse::Names).to receive(method)
    end
  end
  subject do
    described_class.new
  end
  names_methods.each do |method|
    it "calls ##{method}" do
      subject.invoke(method)
      expect(AuthorityBrowse::Names).to have_received(method)
    end
  end
end
RSpec.describe Browse::CLI::Subjects do
  subjects_methods = [:update, :reset_db, :load_solr_with_matched, :load_solr_with_unmatched]
  before(:each) do
    subjects_methods.each do |method|
      # verify that these methods exist before mocking them
      AuthorityBrowse::Subjects.method(method)
      allow(AuthorityBrowse::Subjects).to receive(method)
    end
  end
  subject do
    described_class.new
  end
  subjects_methods.each do |method|
    it "calls ##{method}" do
      subject.invoke(method)
      expect(AuthorityBrowse::Subjects).to have_received(method)
    end
  end
end
