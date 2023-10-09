RSpec.describe AuthorityBrowse::DB::Names do
  subject do
    described_class
  end
  context ".already_set_up?" do
    it "is true when it's already set up" do
      expect(subject.already_set_up?).to eq(true)
    end
    it "is false when it isn't already setup" do
      tables = subject.database_definitions.keys
      tables.each { |t| AuthorityBrowse.db.drop_table?(t) }
      expect(subject.already_set_up?).to eq(false)
    end
  end
  context ".recreate_table!" do
    it "drops and recreates a given table" do
      AuthorityBrowse.db[:names].insert(id: "some id")
      AuthorityBrowse.db[:names_see_also].insert(name_id: "some id", see_also_id: "some id")
      AuthorityBrowse.db[:names_from_biblio].insert(term: "some term")
      expect(AuthorityBrowse.db[:names].count).to eq(1)
      expect(AuthorityBrowse.db[:names_see_also].count).to eq(1)
      expect(AuthorityBrowse.db[:names_from_biblio].count).to eq(1)
      subject.recreate_table!(:names)
      expect(AuthorityBrowse.db[:names].count).to eq(0)
      expect(AuthorityBrowse.db[:names_see_also].count).to eq(1)
      expect(AuthorityBrowse.db[:names_from_biblio].count).to eq(1)
    end
  end
  context ".recreate_all_tables!" do
    it "drops all tables" do
      AuthorityBrowse.db[:names].insert(id: "some id")
      AuthorityBrowse.db[:names_see_also].insert(name_id: "some id", see_also_id: "some id")
      AuthorityBrowse.db[:names_from_biblio].insert(term: "some term")
      expect(AuthorityBrowse.db[:names].count).to eq(1)
      expect(AuthorityBrowse.db[:names_see_also].count).to eq(1)
      expect(AuthorityBrowse.db[:names_from_biblio].count).to eq(1)
      subject.recreate_all_tables!
      expect(AuthorityBrowse.db[:names].count).to eq(0)
      expect(AuthorityBrowse.db[:names_see_also].count).to eq(0)
      expect(AuthorityBrowse.db[:names_from_biblio].count).to eq(0)
    end
  end
end
