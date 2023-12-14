module CallNumberBrowse
  class SolrDocument
    attr_reader :bib_id, :call_number
    SEP = "\u001F"
    def self.for(biblio_doc)
      new(bib_id: biblio_doc["id"], call_number: biblio_doc["callnumber_browse"]&.first)
    end

    def initialize(bib_id:, call_number:)
      @bib_id = bib_id.to_s
      @call_number = call_number.to_s
    end

    def id
      call_number + SEP + bib_id
    end

    def to_solr_doc
      {
        uid: id,
        id: id,
        bib_id: bib_id,
        callnumber: call_number
      }.to_json
    end
  end
end
