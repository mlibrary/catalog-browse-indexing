RSpec.describe AuthorityBrowse::DBMutator::Names do
  before(:each) do
    @names = AuthorityBrowse.db[:names]
    @nfb = AuthorityBrowse.db[:names_from_biblio]
  end
  context ".update_names_with_counts" do
    it "updates the names table with counts from the names_from_biblio table" do
      @names.insert(id: "id1", match_text: "match")
      @nfb.insert(term: "match", match_text: "match", count: 1)
      @nfb.insert(term: "match2", match_text: "match", count: 5)

      @names.insert(id: "id2", match_text: "whatever")
      @nfb.insert(term: "x", match_text: "whatever", count: 6)
      @nfb.insert(term: "y", match_text: "whatever", count: 5)
      @nfb.insert(term: "z", match_text: "whatever", count: 9)

      described_class.update_names_with_counts

      expect(@names.filter(id: "id1").first[:count]).to eq(6)
      expect(@names.filter(id: "id2").first[:count]).to eq(20)
    end
  end
  context ".remove_deprecated_when_undeprecated_match_text_exists" do
    it "only removes deprecated names where the match_text is the same as an undeprecated term" do
      @names.insert(id: "id1", match_text: "match")
      @names.insert(id: "id2", match_text: "whatever")
      @names.insert(id: "id3", match_text: "whatever")

      # this is the deprecated name with the match text that's in an
      # undeprecated name
      @names.insert(id: "id4", match_text: "whatever", deprecated: true)
      @names.insert(id: "id5", match_text: "unique", deprecated: true)

      described_class.remove_deprecated_when_undeprecated_match_text_exists

      expect(@names.filter(id: "id4").empty?).to eq(true)

      expect(@names.filter(id: "id1").empty?).to eq(false)
      expect(@names.filter(id: "id2").empty?).to eq(false)
      expect(@names.filter(id: "id3").empty?).to eq(false)
      expect(@names.filter(id: "id5").empty?).to eq(false)
    end
  end
end
