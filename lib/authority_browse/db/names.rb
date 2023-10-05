# frozen_string_literal: true

require "authority_browse/db"

module AuthorityBrowse::DB
  module Names
    extend AuthorityBrowse::DB

    # @overload
    def self.database_definitions
      {
        names: Proc.new do
          String :id, primary_key: true
          String :label, text: true
          String :match_text, text: true, index: true
          Boolean :deprecated, default: false, index: true
          Integer :count, default: 0, index: true
          String :xrefs # no longer needed
          String :json  # no longer needed
        end,
        names_see_also: Proc.new do
          primary_key :id
          String :name_id, index: true
          String :see_also_id, index: true
        end,
        names_from_biblio: Proc.new do
          String :term, primary_key: true
          String :match_text, index: true
          Integer :count, default: 0
          String :name_id, default: nil
        end
      }
    end
  end
end
