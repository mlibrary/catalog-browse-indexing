RSpec.describe AuthorityBrowse::Solr do
  context "#get_collections_to_delete" do
    it "returns authority_browse collections older than the newest three" do
      list = [
        "something_11d2069_2023-11-16",
        "something_11d2069_2023-11-15",
        "something_11d2069_2023-11-14",
        "something_11d2069_2023-11-13",
        "authority_browse_1.0.1_2023-11-13",
        "authority_browse_11d2069_2023-11-16",
        "authority_browse_11d2069_2023-11-13",
        "authority_browse_11d2069_2023-11-15",
        "authority_browse_11d2069_2023-11-14"
      ]
      expect(described_class.get_collections_to_delete(list)).to eq([
        "authority_browse_1.0.1_2023-11-13",
        "authority_browse_11d2069_2023-11-13"
      ])
    end
  end
end
