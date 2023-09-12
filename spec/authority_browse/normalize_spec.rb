RSpec.describe AuthorityBrowse::Normalize do
  context "#match_text" do
    it "will remove the leading 'the'" do
      expect(described_class.match_text("the cat in the hat")).to eq("cat in the hat")
    end
    xit "exercises the jruby unicode normalization" do
    end
    it "removes spaces around a double dash" do
      expect(described_class.match_text("cat -- in")).to eq("cat--in")
    end
    it "changes : and - to spaces" do
      expect(described_class.match_text("cat:in-:-the -hat:")).to eq("cat in the hat")
    end
    # https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Character+Properties
    #
    it "changes Unicode Punctuation Character set to empty string" do
      expect(described_class.match_text("cat¶§;in")).to eq("catin")
    end
    it "gets rid of too many spaces" do
      expect(described_class.match_text("    cat       \t\t\t in  \t\n")).to eq("cat in")
    end
  end
end
