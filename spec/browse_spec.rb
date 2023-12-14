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
