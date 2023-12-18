module CallNumberBrowse
  class SolrDocument
    attr_reader :bib_id, :call_number
    SEP = "\u001F"
    # Given a biblio_doc, return a SolrDocument object
    #
    # @param biblio_doc [Hash] Hash of Solr Document form Biblio Solr core
    # @return CallNumberBrowse::SolrDocument
    def self.for(biblio_doc)
      new(bib_id: biblio_doc["id"], call_number: biblio_doc["callnumber_browse"]&.first)
    end

    # @param bib_id [String] String of the Bib ID (either an mms_id or a
    # hathitrust id)
    # @param call_number [String] String of the call number
    def initialize(bib_id:, call_number:)
      @bib_id = bib_id.to_s
      @call_number = call_number.to_s
    end

    # Unique identifier for Solr
    #
    # @return [String]
    def id
      call_number + SEP + bib_id
    end

    # JSON string of solr doc
    #
    # @return [String]
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
