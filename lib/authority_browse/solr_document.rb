module AuthorityBrowse
  class AuthorityGraphSolrDocument
    TODAY = DateTime.now.strftime("%Y-%m-%d") + "T00:00:00Z"

    # Take a authority_graph Name entry. Turn it into a solr document.
    # It requires the AuthorityBrowse::terms_db to have data in it
    # @param authority_graph_entry [Name] Name instance
    def initialize(authority_graph_entry)
      @authority_graph_entry = authority_graph_entry
      @term_entry_dataset = terms_db.filter(term: term)
      set_in_authority_graph if in_term_db?

      @term_entry = @term_entry_dataset.first
    end

    def in_term_db?
      !@term_entry_dataset.empty?
    end

    def set_in_authority_graph
      @term_entry_dataset.update(in_authority_graph: true)
    end

    def id
      Normalize.match_text(term) + "\u001fname"
    end

    def loc_id
      @authority_graph_entry[:id]
    end

    def term
      @authority_graph_entry[:label]
    end

    def count
      @term_entry.count
    end

    def browse_field
      "name"
    end

    # Today formatted to be midnight UTC
    def see_also
      @authority_graph_entry.see_also.filter_map do |xref|
        xref_dataset = terms_db.filter(term: xref.label)
        "#{xref.label}||#{xref_dataset.first[:count]}" unless xref_dataset.empty?
      end
    end

    def terms_db
      AuthorityBrowse.terms_db[:names]
    end

    # @param today [String] string of today's date.
    # @return [String] JSON formatted string of solr document
    def to_solr_doc(today = TODAY)
      {
        id: id,
        loc_id: loc_id,
        browse_field: browse_field,
        term: term,
        see_also: see_also,
        count: count,
        date_of_index: today
      }.to_json
    end
  end
end
