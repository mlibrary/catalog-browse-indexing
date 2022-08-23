# frozen_string_literal: true

require_relative "../generic_entry"
require_relative "component"
require "json"

module AuthorityBrowse::LocSKOSRDF
  module Name
    class Entry < GenericEntry

      attr_accessor :components

      # Freeze these 'cause they'll be used over and over again
      ConceptEntryName = self.name.freeze

      attr_accessor :category, :components, :see_also, :incoming_see_also

      def initialize(skos_hash)
        @namespace = "http://id.loc.gov/authorities/names"
        super(skos_hash, component_klass: AuthorityBrowse::LocSKOSRDF::Name::Component)
        set_main!
        pare_down_components!
        @category = "name"
        @see_also = build_references(see_also_ids)
        @incoming_see_also = {}
      rescue NoMethodError => e
        # TODO log
      end

      def in_namespace?(id)
        id.start_with?(@namespace)
      rescue => e
        # TODO log
      end

      def xref_ids
        see_also_ids
      end

      def pare_down_components!
        @components.reject! { |_id, c| c.type == "cs:ChangeSet" }
        @components.select! { |id, c| in_namespace?(id) or xref_ids.include?(id) }
      end

      # Try to build id/label pairs for a set of ids (for narrower/broader).
      def build_references(ids)
        rv = {}
        ids.each do |id|
          if @components[id]
            rv[id] = @components[id].pref_label
          end
        end
        rv
      end

      def label
        main.label
      end

      def needs_xref_lookups?
        see_also.keys.size != see_also_ids.size
      end

      def see_also_ids
        collect_relevant_ids("rdfs:seeAlso")
      end

      # A "relevant" id is one in our @namespace or one that we already have a component for
      def collect_relevant_ids(tag)
        main.collect_ids(tag).select { |id| in_namespace?(id) or @components[id] }
      end

      # Only add in a redirect if the text is different than the deleted record's label. If
      # it is the same label, the new record would have been found anyway.
      def add_see_also(id, text)
        @see_also[id] = text unless text == label
      end

      # We need to resolve any missing xrefs through the use of an object (like Subjects)
      # that responds to o[id] with an entry
      def resolve_xrefs!(lookup_table)
        return unless needs_xref_lookups?
        (see_also_ids - see_also.keys).each do |xid|
          e = lookup_table[xid]
          if e
            add_see_also(xid, e.label) unless see_also.has_key?(xid)
            e.incoming_see_also[id] = label
          else
            warn "Entry #{id} can't find seeAlso xref #{xid}"
          end
        end
      end

      def to_solr_doc
        {
          id: AuthorityBrowse.alphajoin(label, id),
          term: label,
          alternate_forms: alt_labels,
          see_also: see_also.values,
          incoming_see_also: incoming_see_also.values,
          browse_field: "name",
          json: {id: id, name: label, see_also: see_also, incoming_see_also: incoming_see_also}.to_json
        }.reject { |_k, v| v.nil? or v == [] or v == "" }
      end

      def to_json(*args)
        {
          id: id,
          label: label,
          category: category,
          alternate_forms: alt_labels,
          components: @components,
          see_also: @see_also,
          incoming_see_also: @incoming_see_also,
          need_xref: needs_xref_lookups?,
          AuthorityBrowse::JSON_CREATE_ID => ConceptEntryName
        }.reject { |_k, v| v.nil? or v == [] or v == "" }.to_json(*args)
      end

      def self.json_create(rec)
        e = allocate
        e.id = rec["id"]
        e.category = rec["category"]
        e.see_also = rec["see_also"]
        e.incoming_see_also = rec["incoming_see_also"]
        e.components = rec["components"]
        e.set_main!
        e
      end
    end
  end
end
