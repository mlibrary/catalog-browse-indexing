RSpec.describe Solr::Manager do
  subject do
    Solr::Manager::AuthorityBrowse.new
  end
  context "#list_old_collections" do
    before(:each) do
      @list = [
        "something_11d2069_2023-11-16",
        "something_11d2069_2023-11-15",
        "something_11d2069_2023-11-14",
        "something_11d2069_2023-11-13",
        "authority_browse_1.0.1_2023-11-13",
        "authority_browse_11d2069_2023-11-16",
        "authority_browse_11d2069_2023-11-13",
        "authority_browse_11d2069_2023-11-15",
        "authority_browse_11d2069_2023-11-14"
      ].map { |x| instance_double(SolrCloud::Collection, name: x) }
    end
    it "returns authority_browse collections older than the newest three" do
      expect(subject.list_old_collections(list: @list).map { |x| x.name }).to eq([
        "authority_browse_1.0.1_2023-11-13",
        "authority_browse_11d2069_2023-11-13"
      ])
    end

    it "returns old collections with a custom keep_at_least" do
      expect(subject.list_old_collections(list: @list, keep: 4).map { |x| x.name }).to eq(["authority_browse_1.0.1_2023-11-13"])
    end
  end
end
