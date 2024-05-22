RSpec.describe AuthorityBrowse::RemediatedSubjects do
  subject do
    described_class.new(File.join(S.project_root, "spec", "fixtures", "remediated_subjects.xml"))
  end

  it "is enumerable" do
    expect(subject.is_a?(Enumerable)).to eq(true)
  end

  it "contains Entry objects" do
    expect(subject.first.class).to eq(AuthorityBrowse::RemediatedSubjects::Entry)
  end
end

RSpec.describe AuthorityBrowse::RemediatedSubjects::Entry do
  subject do
    described_class.new(fixture("remediated_subject.xml"))
  end
  it "returns the mms_id for the #id" do
    expect(subject.id).to eq("98187481368506381")
  end

  it "returns the url for the #loc_id (minus the extension) from 010$a" do
    expect(subject.loc_id).to eq("http://id.loc.gov/authorities/subjects/sh2008104250")
  end

  it "returns the #label from 150$a" do
    expect(subject.label).to eq("Undocumented immigrants--Government policy--United States")
  end

  it "returns the #match_text of the label" do
    expect(subject.match_text).to eq("undocumented immigrants--government policy--united states")
  end
end
