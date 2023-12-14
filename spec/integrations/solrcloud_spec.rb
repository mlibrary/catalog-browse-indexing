RSpec.describe Browse::CLI::Solr, solrcloud: true do
  before(:all) do
    WebMock.allow_net_connect!
  end
  after(:all) do
    WebMock.disable_net_connect!
  end
  before(:each) do
    @collection = Solr::Collection.new(kind: "authority_browse")
    @today_collection_name = @collection.daily_name
  end
  after(:each) do
    coll = S.solrcloud.get_collection(@today_collection_name)
    cset = S.solrcloud.get_configset(@collection.configset_name)
    if !coll.nil?
      coll.aliases.each { |x| x.delete! }
      coll.delete!
    end
    cset&.delete!
  end
  subject do
    described_class.new
  end
  context "browse solr set_up_daily_authority_browse_collection" do
    it "creates the daily collection and sets the reindex alias" do
      configset_name = @collection.configset_name
      expect(S.solrcloud.has_configset?(configset_name)).to eq(false)
      expect(S.solrcloud.get_collection(@today_collection_name)).to be_nil
      subject.invoke(:set_up_daily_authority_browse_collection)
      expect(S.solrcloud.has_configset?(configset_name)).to eq(true)
      collection = S.solrcloud.get_collection(@today_collection_name)
      expect(collection).not_to be_nil
      expect(collection.has_alias?(@collection.reindex_alias)).to eq(true)
    end
  end

  context "browse solr verify_and_deploy_authority_browse_collection" do
    it "verifies that the collection has enough records and then sets the production alias to it" do
      subject.invoke(:set_up_daily_authority_browse_collection)
      one_doc = [{
        id: "twain mark 1835 1910\u001fname",
        browse_field: "name",
        term: "Twain, Mark, 1835-1910",
        count: 7,
        date_of_index: "2023-09-02T00:00:00Z"
      }.to_json]

      collection = S.solrcloud.get_collection(@today_collection_name)
      uploader = Solr::Uploader.new(collection: @today_collection_name)
      uploader.upload(one_doc)
      uploader.commit

      subject.invoke(:verify_and_deploy_authority_browse_collection)

      expect(collection.has_alias?(@collection.production_alias)).to eq(true)
    end
  end
  context "browse solr prune_authority_browse_collections" do
    # not testing the cli invocation because we want to inject collections to prune
    it "prunes the old collections" do
      subject.invoke(:set_up_daily_authority_browse_collection)
      col = S.solrcloud.get_collection(@today_collection_name)
      expect(col).not_to be_nil
      col.aliases.each { |x| x.delete! }
      # actual subject
      subject.invoke(:prune_authority_browse_collections, [], keep: 0)

      expect(S.solrcloud.only_collection_names).not_to include(@today_collection_name)
    end
  end
end
