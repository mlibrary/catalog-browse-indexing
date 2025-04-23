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
  before(:each) do
    @subject_record = fixture("remediated_subject.xml")
  end
  let(:place_subject) { fixture("remediated_place_subject.xml") }
  subject do
    described_class.new(@subject_record)
  end
  it "returns the mms_id for the #id" do
    expect(subject.id).to eq("98187481368406381")
  end
  context "#preferred_term" do
    context "150 record" do
      it "returns the #label from 150$avxyz" do
        expect(subject.preferred_term.label).to eq("Children of undocumented immigrants--Education--Law and legislation")
      end
      it "returns the #match_text of the label" do
        expect(subject.preferred_term.match_text).to eq("children of undocumented immigrants--education--law and legislation")
      end
    end
    it "has xrefs" do
      xrefs = subject.xrefs
      expect(xrefs.count).to eq 3
      expect(xrefs[0].kind).to eq("see_instead")
      expect(xrefs[1].kind).to eq("see_instead")
      expect(xrefs[2].kind).to eq("broader")
    end
    context "151 record" do
      it "returns the #label from 151$avxy" do
        @subject_record = place_subject
        expect(subject.preferred_term.label).to eq("Mexico, Gulf of")
      end
    end
  end
end

RSpec.describe AuthorityBrowse::RemediatedSubjects::Term do
  let(:record) do
    MARC::XMLReader.new(StringIO.new(fixture("remediated_subject.xml"))).first
  end
  let(:preferred_term) do
    described_class::Preferred.new(record["150"])
  end
  let(:term) do
    record.fields("450")[1]
  end
  let(:xrefs_table) do
    AuthorityBrowse.db[:subjects_xrefs]
  end
  let(:subjects_table) do
    AuthorityBrowse.db[:subjects]
  end

  before(:each) do
    @term = term
  end
  subject do
    described_class.new(@term)
  end
  it "has a label" do
    expect(subject.label).to eq("Children of illegal aliens--Education--Law and legislation")
  end
  it "has a match_text" do
    expect(subject.match_text).to eq("children of illegal aliens--education--law and legislation")
  end
  context "id" do
    it "returns the id from the database if it exists" do
      subjects = AuthorityBrowse.db[:subjects]
      subjects.insert(id: "official_id", match_text: "children of illegal aliens--education--law and legislation")
      expect(subject.id).to eq("official_id")
    end
    it "returns the match text if it doesn't exist" do
      expect(subject.id).to eq("children of illegal aliens--education--law and legislation")
    end
  end
  context "kind" do
    it "raises NotImplemented error for base class" do
      expect { subject.kind }.to raise_error(NotImplementedError)
    end
  end
  context "Preferred" do
    it "adds remediated subject to db" do
      expect(AuthorityBrowse.db[:subjects].where(id: "preferred_term_id").any?).to eq(false)
      preferred_term.add_to_db("preferred_term_id")
      expect(AuthorityBrowse.db[:subjects].where(id: "preferred_term_id").any?).to eq(true)
    end
  end
  context "SeeInstead" do
    it "has kind :see_instead" do
      expect(described_class::SeeInstead.new(@term).kind).to eq("see_instead")
    end
    it "updates the xrefs db" do
      expect(xrefs_table.where(xref_kind: "see_instead").any?).to eq(false)
      see_instead_inst = described_class::SeeInstead.new(@term)
      see_instead_inst.add_to_db("preferred_term_id")
      see_instead = xrefs_table.where(xref_kind: "see_instead").first
      expect(see_instead[:xref_id]).to eq("preferred_term_id")
      expect(see_instead[:subject_id]).to eq("children of illegal aliens--education--law and legislation")
      expect(subjects_table.where(id: see_instead_inst.match_text).any?).to eq(true)
    end
    context "match?(field)" do
      context "450" do
        it "is true for a 450" do
          expect(described_class::SeeInstead.match?(@term)).to eq(true)
        end
        it "is false for not 450" do
          @term.tag = "550"
          expect(described_class::SeeInstead.match?(@term)).to eq(false)
        end
      end
      context "451" do
        it "is true for a 451" do
          term.tag = "451"
          expect(described_class::SeeInstead.match?(@term)).to eq(true)
        end
      end
    end
  end
  context "Broader" do
    let(:broader_term) do
      @term.tag = "550"
      @term.append(MARC::Subfield.new("w", "g"))
      @term
    end
    let(:broader_inst) do
      described_class::Broader.new(broader_term)
    end
    it "has kind :broader" do
      expect(broader_inst.kind).to eq("broader")
    end
    it "adds xrefs to db" do
      broader_inst.add_to_db("preferred_field_id")
      expect(xrefs_table.where(subject_id: "preferred_field_id").first[:xref_kind]).to eq("broader")
      expect(xrefs_table.where(xref_id: "preferred_field_id").first[:xref_kind]).to eq("narrower")
      expect(subjects_table.where(id: broader_inst.match_text).any?).to eq(true)
    end
    context "match?(field)" do
      it "is true for a 550 with $wg" do
        expect(described_class::Broader.match?(broader_term)).to eq(true)
      end
      it "is false for not 550" do
        expect(described_class::Broader.match?(@term)).to eq(false)
      end
      it "is false for 550 without $wg" do
        @term.tag = "550"
        expect(described_class::Broader.match?(@term)).to eq(false)
      end
    end
  end
  context "Narrower" do
    let(:narrower_term) do
      @term.tag = "550"
      @term.append(MARC::Subfield.new("w", "h"))
      @term
    end
    let(:narrower_inst) do
      described_class::Narrower.new(narrower_term)
    end
    it "has kind :broader" do
      expect(narrower_inst.kind).to eq("narrower")
    end
    it "adds xrefs to db" do
      narrower_inst.add_to_db("preferred_field_id")
      expect(xrefs_table.where(subject_id: "preferred_field_id").first[:xref_kind]).to eq("narrower")
      expect(xrefs_table.where(xref_id: "preferred_field_id").first[:xref_kind]).to eq("broader")
      expect(subjects_table.where(id: narrower_inst.match_text).any?).to eq(true)
    end
    context "match?(field)" do
      it "is true for a 550 with $wh" do
        expect(described_class::Narrower.match?(narrower_term)).to eq(true)
      end
      it "is false for not 550" do
        expect(described_class::Narrower.match?(@term)).to eq(false)
      end
      it "is false for 550 without $wh" do
        @term.tag = "550"
        expect(described_class::Narrower.match?(@term)).to eq(false)
      end
    end
  end
end
