# frozen_string_literal: true

require "authority_browse/generic_xref"

# Need some sort of placeholder for stuff from teh dump that doesn't match any LoC
class AuthorityBrowse::LocSKOSRDF::UnmatchedEntry < AuthorityBrowse::GenericXRef
  def initialize(label:, count: 0, id: "ignored")
    super(label: label, count: count, id: id)
  end

  def to_solr
    {
      id: label,
      term: label,
      count: count,
      browse_field: "name",
      json: to_json
    }.to_json
  end
end
