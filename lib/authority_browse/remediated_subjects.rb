module AuthorityBrowse
  class RemediatedSubjects
    include Enumerable

    # List of RemediatedSubjects::Entriees
    # @param file_path [String] Path to config file with remediated subjects
    # info
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
      AUTHORIZED_TERM_FIELDS = ["100", "110", "111", "130", "150", "151", "155"].freeze
      VARIANT_TERM_FIELDS = ["400", "410", "411", "430", "450", "451", "455"].freeze

      def self.variant_term_fields
        VARIANT_TERM_FIELDS
      end

      # An Authority Record Entry
      # @param xml [String] Authority Record MARCXML String
      def initialize(xml)
        @record = MARC::XMLReader.new(StringIO.new(xml)).first
      end

      def id
        @record["001"].value
      end

      def preferred_term
        @preferred_term ||= Term::Preferred.new(@record.fields(AUTHORIZED_TERM_FIELDS).first)
      end

      # Returns the cross references found in the 450 and 550 fields
      # @return [Array<Term>] An Array of xref terms
      def xrefs
        @record.fields([VARIANT_TERM_FIELDS + ["550"]].flatten).map do |field|
          [Term::SeeInstead, Term::Broader, Term::Narrower].find do |kind|
            kind.match?(field)
          end&.new(field)
        end.compact
      end

      # Adds the preferred term and xrefs to the subjects and subjects_xrefs
      # db tables
      # @return [Nil]
      def add_to_db
        preferred_term.add_to_db(id)
        xrefs.each do |xref|
          xref.add_to_db(id)
        end
      end
    end

    class Term
      # @param field [MARC::DataField] A subject term field
      def initialize(field)
        @field = field
      end

      # What kind of field it is. It's used for setting the xref_kind in the subjects_xrefs table.
      def kind
        raise NotImplementedError
      end

      # This is the first step in adding the xref to term to the database. It's
      # overwritten for a PreferredTerm. The check for id and match_text is to
      # make sure the id isn't already in the db. If the id given is the match
      # text that means the term isn't in the db.
      #
      # @param preferred_term_id [[TODO:type]] [TODO:description]
      def add_to_db(preferred_term_id)
        if id == match_text
          AuthorityBrowse.db[:subjects].insert(id: id, label: label, match_text: match_text, deprecated: false)
        end
      end

      # @return [String]
      def label
        @field.subfields
          .filter_map do |x|
            x.value if ["a", "v", "x", "y", "z"].include?(x.code)
          end
          .join("--")
      end

      # @return [String]
      def match_text
        AuthorityBrowse::Normalize.match_text(label)
      end

      # @return [String]
      def id
        AuthorityBrowse.db[:subjects]&.first(match_text: match_text)&.dig(:id) || match_text
      end

      class Preferred < Term
        # Adds the preferred term to the db
        #
        # @return nil
        def add_to_db(id)
          AuthorityBrowse.db[:subjects].insert(id: id, label: label, match_text: match_text, deprecated: false)
        end
      end

      class SeeInstead < Term
        def self.match?(field)
          Entry::VARIANT_TERM_FIELDS.include?(field.tag)
        end

        def kind
          "see_instead"
        end

        # @param preferred_term_id [String]
        # @return [Nil]
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

        # @param preferred_term_id [String]
        # @return [Nil]
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

        # @param preferred_term_id [String]
        # @return [Nil]
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
