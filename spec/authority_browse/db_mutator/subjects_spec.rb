RSpec.describe AuthorityBrowse::DBMutator::Subjects do
  before(:each) do
    @subjects = AuthorityBrowse.db[:subjects]
    @sfb = AuthorityBrowse.db[:subjects_from_biblio]
  end
  context ".update_subjects_with_counts" do
    it "updates the subjects table with counts from the subjects_from_biblio table" do
      @subjects.insert(id: "id1", match_text: "match")
      @sfb.insert(term: "match", match_text: "match", count: 1)
      @sfb.insert(term: "match2", match_text: "match", count: 5)

      @subjects.insert(id: "id2", match_text: "whatever")

      described_class.update_subjects_with_counts

      expect(@subjects.filter(id: "id1").first[:count]).to eq(6)
      expect(@subjects.filter(id: "id2").first[:count]).to eq(0)
    end
  end
  context ".remove_deprecated_when_undeprecated_match_text_exists" do
    it "only removes deprecated subjects where the match_text is the same as an undeprecated term" do
      @subjects.insert(id: "id1", match_text: "match")
      @subjects.insert(id: "id2", match_text: "whatever")
      @subjects.insert(id: "id3", match_text: "whatever")

      # this is the deprecated name with the match text that's in an
      # undeprecated name
      @subjects.insert(id: "id4", match_text: "whatever", deprecated: true)
      @subjects.insert(id: "id5", match_text: "unique", deprecated: true)

      described_class.remove_deprecated_when_undeprecated_match_text_exists

      expect(@subjects.filter(id: "id4").empty?).to eq(true)

      expect(@subjects.filter(id: "id1").empty?).to eq(false)
      expect(@subjects.filter(id: "id2").empty?).to eq(false)
      expect(@subjects.filter(id: "id3").empty?).to eq(false)
      expect(@subjects.filter(id: "id5").empty?).to eq(false)
    end
  end
  context ".add_ids_to_subjects_from_biblio" do
    it "adds name_id to sfb where sfb match_text matches in subjects" do
      @subjects.insert(id: "id1", match_text: "match")
      @sfb.insert(term: "match", match_text: "match", count: 0)
      @sfb.insert(term: "x", match_text: "whatever", count: 0)

      described_class.add_ids_to_subjects_from_biblio

      expect(@sfb.filter(term: "match").first[:subject_id]).to eq("id1")
      expect(@sfb.filter(term: "x").first[:subject_id]).to eq(nil)
    end
  end
end
