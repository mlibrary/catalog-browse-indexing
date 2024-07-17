require "library_stdnums"
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

      def loc_id
        loc_id_str = StdNum::LCCN.normalize(@record["010"]["a"])
        "http://id.loc.gov/authorities/subjects/#{loc_id_str}"
      end

      def label
        @record["150"].subfields.map { |x| x.value }.join("--")
      end

      def match_text
        AuthorityBrowse::Normalize.match_text(label)
      end
    end
  end
end
