RSpec.describe AuthorityBrowse::Normalize do
  context "#match_text" do
    it "will remove the leading 'the'" do
      expect(described_class.match_text("the cat in the hat")).to eq("cat in the hat")
    end
    context "unicode normalization with icu" do
      it "handles case folding" do
        # \u0393 = Γ
        # \u03b3 = γ
        expect(described_class.match_text("CAT \u0393")).to eq("cat \u03b3")
      end

      it "collapses compound characters to one character and changes to ascii" do
        # unicode makes: ḱṷṓn
        expect(described_class.match_text("\u006B\u0301\u0075\u032D\u006F\u0304\u0301\u006E")).to eq("kuon")
      end
    end
    it "removes spaces around a double dash" do
      expect(described_class.match_text("cat -- in")).to eq("cat--in")
    end
    it "changes : and - to spaces" do
      expect(described_class.match_text("cat:in-:-the -hat:")).to eq("cat in the hat")
    end
    
    # https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Character+Properties
    it "changes Unicode Punctuation Character set to empty string" do
      expect(described_class.match_text("cat¶§;in")).to eq("catin")
    end
    it "gets rid of too many spaces" do
      expect(described_class.match_text("    cat       \t\t\t in  \t\n")).to eq("cat in")
    end
  end
end
