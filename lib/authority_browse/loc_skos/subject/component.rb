# frozen_string_literal: true

require_relative "../generic_component"
require "json"

module AuthorityBrowse
  module LocSKOSRDF
    module Subject
      class Component < GenericComponent

        def self.target_prefix
          "http://id.loc.gov"
        end

        JSON_CREATE_ID = JSON.create_id.freeze
        ComponentName = self.name.freeze

        def initialize(*args, **kwargs)
          super
          @broader = []
          @narrower = []
        end

        # Some components don't have language-tagged prefLabels, they just have the strings.
        # So I guess we have to check for that.
        def pref_label
          @pl ||= begin
                    pl = @raw_entry["skos:prefLabel"]
                    case pl
                    when String
                      pl.unicode_normalize(:nfkc)
                    else
                      collect_single_value("skos:prefLabel")
                    end
                  end

        rescue
          require 'pry'; binding.pry
        end

        # Deleted records will only have a literal form
        def literal_form
          @lf ||= collect_single_value("skosxl:literalForm").unicode_normalize(:nfkc)
        end

        def label
          (pref_label or literal_form).unicode_normalize(:nfkc)
        end

        def alt_labels
          @alts ||= collect_values("skos:altLabel").map { |x| x.unicode_normalize(:nfkc) }
        end

        def see_also_ids
          @sa ||= collect_ids("rdfs:seeAlso")
        end

        def broader_ids
          collect_ids("skos:broader")
        end

        def narrower_ids
          collect_ids("skos:narrower")
        end

        def to_json(*args)
          {
            id: id,
            type: type,
            raw_entry: raw_entry,
            JSON_CREATE_ID => ComponentName
          }.to_json(*args)
        end

        def self.json_create(rec)
          new(rec["raw_entry"])
        end

      end
    end
  end
end