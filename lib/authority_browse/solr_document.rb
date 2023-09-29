module AuthorityBrowse
  class SolrDocument
    TODAY = DateTime.now.strftime("%Y-%m-%d") + "T00:00:00Z"
    EMPTY = [[], nil, "", {}, [nil], [false]]
    def id
      Normalize.match_text(term) + "\u001fname"
    end

    def loc_id
    end

    def term
      @term_entry[:term]
    end

    def browse_field
      "name"
    end

    def see_also
      []
    end

    def count
      @term_entry[:count]
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
      }.reject { |_k, v| EMPTY.include?(v) }
        .to_json
    end
  end

  class AuthorityGraphSolrDocument < SolrDocument
    # Take a authority_graph Name entry. Turn it into a solr document.
    # It requires the AuthorityBrowse::terms_db to have data in it
    # @param authority_graph_entry [Name] Name instance
    def initialize(authority_graph_entry)
      @authority_graph_entry = authority_graph_entry
      @term_entry_dataset = terms_db.filter(term: @authority_graph_entry.label)
      set_in_authority_graph if in_term_db?

      @term_entry = @term_entry_dataset.first
    end

    def in_term_db?
      !@term_entry_dataset.empty?
    end

    def set_in_authority_graph
      @term_entry_dataset.update(in_authority_graph: true)
    end

    def loc_id
      @authority_graph_entry[:id]
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
  end

  class UnmatchedSolrDocument < SolrDocument
    # Take an unmatched term from the terms db. Turn it into a solr document.
    # @param term_entry [Hash] Hash entry from terms_db
    def initialize(term_entry)
      @term_entry = term_entry
    end

    def term
      @term_entry[:term]
    end
  end
end
