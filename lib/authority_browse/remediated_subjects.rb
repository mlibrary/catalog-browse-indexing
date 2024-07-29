module AuthorityBrowse
  class RemediatedSubjects
    include Enumerable

    def initialize(file_path = S.remediated_subjects_file)
      xml_lines = File.readlines(file_path)
      @entries = xml_lines.map do |line|
        Entry.new(line)
      end
    end

    def each(&block)
      @entries.each(&block)
    end

    class Entry
      def initialize(xml)
        @record = MARC::XMLReader.new(StringIO.new(xml)).first
      end

      def id
        @record["001"].value
      end

      def preferred_term
        @preferred_term ||= Term::Preferred.new(@record["150"])
      end

      def xrefs
        @record.fields(["450", "550"]).map do |field|
          [Term::SeeInstead, Term::Broader, Term::Narrower].find do |kind|
            kind.match?(field)
          end&.new(field)
        end.compact
      end

      def add_to_db
        preferred_term.add_to_db(id)
        xrefs.each do |xref|
          xref.add_to_db(id)
        end
      end
    end

    class Term
      def initialize(field)
        @field = field
      end

      def kind
        raise NotImplementedError
      end

      def add_to_db(preferred_term_id)
        if id == match_text
          AuthorityBrowse.db[:subjects].insert(id: id, label: label, match_text: match_text, deprecated: false)
        end
      end

      def label
        @field.subfields
          .filter_map do |x|
            x.value if ["a", "v", "x", "y", "z"].include?(x.code)
          end
          .join("--")
      end

      def match_text
        AuthorityBrowse::Normalize.match_text(label)
      end

      def id
        AuthorityBrowse.db[:subjects]&.first(match_text: match_text)&.dig(:id) || match_text
      end

      class Preferred < Term
        def add_to_db(id)
          AuthorityBrowse.db[:subjects].insert(id: id, label: label, match_text: match_text, deprecated: false)
        end
      end

      class SeeInstead < Term
        def self.match?(field)
          field.tag == "450"
        end

        def kind
          "see_instead"
        end

        def add_to_db(preferred_term_id)
          super
          xrefs = AuthorityBrowse.db[:subjects_xrefs]
          xrefs.insert(subject_id: id, xref_id: preferred_term_id, xref_kind: kind)
        end
      end

      class Broader < Term
        def self.match?(field)
          field.tag == "550" && field["w"] == "g"
        end

        def kind
          "broader"
        end

        def add_to_db(preferred_term_id)
          super
          xrefs = AuthorityBrowse.db[:subjects_xrefs]
          xrefs.insert(subject_id: preferred_term_id, xref_id: id, xref_kind: kind)
          xrefs.insert(subject_id: id, xref_id: preferred_term_id, xref_kind: "narrower")
        end
      end

      class Narrower < Term
        def self.match?(field)
          field.tag == "550" && field["w"] == "h"
        end

        def kind
          "narrower"
        end

        def add_to_db(preferred_term_id)
          super
          xrefs = AuthorityBrowse.db[:subjects_xrefs]
          xrefs.insert(subject_id: preferred_term_id, xref_id: id, xref_kind: kind)
          xrefs.insert(subject_id: id, xref_id: preferred_term_id, xref_kind: "broader")
        end
      end
    end
  end
end
