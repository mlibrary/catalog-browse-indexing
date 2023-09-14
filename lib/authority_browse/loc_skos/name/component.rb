# frozen_string_literal: true

require_relative "../generic_component"
require "json"

module AuthorityBrowse
  module LocSKOSRDF
    module Name
      class Component < GenericComponent
        ComponentName = name.freeze
        REJECT_KEYS = ["skos:changeNote", "skos:exactMatch"]

        def self.target_prefix
          "http://id.loc.gov"
        end

        # Some components don't have language-tagged prefLabels, they just have the strings.
        # So I guess we have to check for that.
        def pref_label
          @pl ||= collect_scalar("skos:prefLabel")&.unicode_normalize(:nfkc)
        end

        # Deleted records will only have a literal form
        def literal_form
          @lf ||= collect_scalar("skosxl:literalForm")&.unicode_normalize(:nfkc)
        end

        def label
          (pref_label or literal_form)
        end

        def alt_labels
          @alts ||= collect_scalars("skos:altLabel").map { |x| x.unicode_normalize(:nfkc) }
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

        def to_json(*)
          {
            :id => id,
            :type => type,
            :raw_entry => raw_entry.except(*REJECT_KEYS),
            AuthorityBrowse::JSON_CREATE_ID => ComponentName
          }.to_json(*)
        end

        def self.json_create(rec)
          new(rec["raw_entry"])
        end
      end
    end
  end
end
