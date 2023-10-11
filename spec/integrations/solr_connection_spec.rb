require "authority_browse/solr/connection"

RSpec.describe AuthorityBrowse::Solr::Admin do

  before(:all) do
    WebMock.allow_net_connect!
    @c = AuthorityBrowse::Solr::Admin.new
  end

  after(:all) do
    WebMock.disable_net_connect!
  end

  describe "config sets" do

    it "can get list of configsets" do
      expect(@c.configurations).to be_a(Array)
    end

    it "can create/delete a configset" do
      cname = "test_#{Random.rand(999)}"
      @c.create_configset(name: cname, confdir: "spec/fixtures/simple_configuration/conf")
      expect(@c.configurations).to include(cname)
      @c.delete_configset(cname)
      expect(@c.configurations).not_to include(cname)
    end
  end

  describe "collection create/delete" do
    before(:each) do
      @configname = "collection_tests"
      @c = AuthorityBrowse::Solr::Admin.new
      @c.create_configset(name: @configname, confdir: "spec/fixtures/simple_configuration/conf", force: true)
    end

    after(:each) do
      @c.delete_configset(@configname)
    end

    it "can create/delete a collection" do
      @c.create_collection(name: "t1", configset: @configname)
      expect(@c.collection?("t1"))
      @c.delete_collection("t1")
      expect(@c.collection?("t1")).to be_falsey
    end

    it "throws an error if you try to create a collection with a bad configset" do
      expect {
        @c.create_collection(name: "t2", configset: "INVALID")
      }.to raise_error(AuthorityBrowse::Solr::NoSuchConfigSetError)
    end

    it "throws an error if you try to get admin for a non-existant collection" do
      expect { @c.collection_admin("ddddd") }.to raise_error(AuthorityBrowse::Solr::NoSuchCollectionError)
    end

    it "won't allow you to drop a configset in use" do
      @c.create_configset(name: "conf1", confdir: "spec/fixtures/simple_configuration/conf", force: true)
      @c.create_collection(name: "coll1", configset: "conf1")
      expect { @c.delete_configset "conf1"}.to raise_error(AuthorityBrowse::Solr::InUseError)
      @c.delete_collection("coll1")
    end

  end

  describe "individual collections" do
    before(:all) do
      @cname = "test_collection"
      @configname = "test_configuration"
      @admin = AuthorityBrowse::Solr::Admin.new
      @admin.delete_collection(@cname)
      @admin.delete_configset(@configname)
      @admin.create_configset(name: @configname, confdir: "spec/fixtures/simple_configuration/conf", force: true)
    end

    after(:all) do
      @admin.delete_configset(@configname)
    end

    before(:each) do
      @admin.create_collection(name: @cname, configset: @configname)
      @coll = @admin.collection_admin(@cname)
    end

    after(:each) do
      @admin.delete_collection(@cname)
    end

    it "can ping a collection" do
      expect(@coll.ping?)
    end


  end

end
