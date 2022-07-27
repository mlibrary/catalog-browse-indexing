# frozen_string_literal: true

require "authority_browse/author"

PARAMS1 = {author: "Bill", naf_id: nil, count: 10, alternate_forms: %w[Bill1 Bill2]}
PARAMS2 = {author: "Danit", naf_id: "n111", count: 20, see_instead: "Bill"}
AAE = AuthorityBrowse::Author::Entry

RSpec.describe AuthorityBrowse::Author::Entry do
  describe AuthorityBrowse::Author::Record do
    let(:rec) { AuthorityBrowse::Author::Record.new(**PARAMS1) }

    it "creates from simple info" do
      expect(rec.author).to eq("Bill")
      expect(rec.record_type).to eq("record")
      expect(rec.see_instead).to eq(nil)
    end

    it "switches to a redirect" do
      redir = rec.to_redirect(see_instead: "one two three")
      expect(redir.record_type).to eq("redirect")
    end

    it "noops on to_record" do
      expect(rec.to_record).to equal(rec)
    end
  end

  describe AuthorityBrowse::Author::Redirect do
    let(:redir) { AuthorityBrowse::Author::Redirect.new(**PARAMS2) }
    it "creates from simple info" do
      expect(redir.author).to eq("Danit")
      expect(redir.record_type).to eq("redirect")
      expect(redir.see_instead).to eq("Bill")
    end

    it "switches to a record" do
      rec = redir.to_record
      expect(rec.record_type).to eq("record")
    end

    it "noops on to_redirect" do
      expect(redir.to_redirect).to equal(redir)
    end
  end

  describe "Entry" do
    let(:rec) { AAE.new(**PARAMS1) }
    let(:redir) { AAE.new(**PARAMS2) }

    it "creates an appropriate type of entry" do
      expect(rec.record_type).to eq("record")
      expect(redir.record_type).to eq("redirect")
    end

    it "switches between the two when assigning to see_instead" do
      e = AAE.new(**PARAMS2)
      expect(e.is_redirect?).to be_truthy
      e.see_instead = nil
      expect(e.is_redirect?).to be_falsey
      e.see_instead = "One two three"
      expect(e.is_redirect?).to be_truthy
    end

    it "builds an id with hash" do
      expect(rec.id).to match(/#{rec.author}#{AuthorityBrowse::Author::Record::PARTS_JOINER}[a-z0-9]+/)
    end
  end
end
