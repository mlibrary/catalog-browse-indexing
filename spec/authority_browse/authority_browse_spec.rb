RSpec.describe AuthorityBrowse::Name do
  subject do
    described_class
  end

  it "has a .name ':name'" do
    expect(subject.name).to eq(:name)
  end

  it "has .xrefs" do
    expect(subject.xrefs).to eq([
      OpenStruct.new(name: :see_also, count_key: :see_also_count, label_key: :see_also_label)
    ])
  end
end
RSpec.describe AuthorityBrowse::Subject do
  subject do
    described_class
  end

  it "has a .name ':subject'" do
    expect(subject.name).to eq(:subject)
  end

  it "has .xrefs" do
    expect(subject.xrefs).to eq([
      OpenStruct.new(name: :broader, count_key: :broader_count, label_key: :broader_label),
      OpenStruct.new(name: :narrower, count_key: :narrower_count, label_key: :narrower_label)
    ])
  end
end
