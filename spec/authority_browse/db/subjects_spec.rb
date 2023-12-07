RSpec.describe AuthorityBrowse::DB::Subjects do
  before(:each) do
    described_class.recreate_all_tables!
  end
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
      AuthorityBrowse.db[:subjects].insert(id: "some id")
      AuthorityBrowse.db[:subjects_xrefs].insert(subject_id: "some id", xref_id: "some id", xref_kind: "broader")
      AuthorityBrowse.db[:subjects_from_biblio].insert(term: "some termsss")
      expect(AuthorityBrowse.db[:subjects].count).to eq(1)
      expect(AuthorityBrowse.db[:subjects_xrefs].count).to eq(1)
      expect(AuthorityBrowse.db[:subjects_from_biblio].count).to eq(1)
      subject.recreate_table!(:subjects)
      expect(AuthorityBrowse.db[:subjects].count).to eq(0)
      expect(AuthorityBrowse.db[:subjects_xrefs].count).to eq(1)
      expect(AuthorityBrowse.db[:subjects_from_biblio].count).to eq(1)
    end
  end
  context ".recreate_all_tables!" do
    it "drops all tables" do
      AuthorityBrowse.db[:subjects].insert(id: "some id")
      AuthorityBrowse.db[:subjects_xrefs].insert(subject_id: "some id", xref_id: "some id")
      AuthorityBrowse.db[:subjects_from_biblio].insert(term: "some term")
      expect(AuthorityBrowse.db[:subjects].count).to eq(1)
      expect(AuthorityBrowse.db[:subjects_xrefs].count).to eq(1)
      expect(AuthorityBrowse.db[:subjects_from_biblio].count).to eq(1)
      subject.recreate_all_tables!
      expect(AuthorityBrowse.db[:subjects].count).to eq(0)
      expect(AuthorityBrowse.db[:subjects_xrefs].count).to eq(0)
      expect(AuthorityBrowse.db[:subjects_from_biblio].count).to eq(0)
    end
  end
  context ".set_subjects_indexes!" do
    it "sets the indexes on subjects and subjects_xrefs" do
      expect(AuthorityBrowse.db.indexes(:subjects)).to eq({})
      expect(AuthorityBrowse.db.indexes(:subjects_xrefs)).to eq({})
      subject.set_subjects_indexes!
      expect(AuthorityBrowse.db.indexes(:subjects)).not_to eq({})
      expect(AuthorityBrowse.db.indexes(:subjects_xrefs)).not_to eq({})
    end
  end
end
