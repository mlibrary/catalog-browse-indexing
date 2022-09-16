# frozen_string_literal: true

require_relative "../generic_entry"
require_relative "component"
require "json"
require_relative "../../generic_xref"

module AuthorityBrowse::LocSKOSRDF
  module Name
    class Entry < GenericEntry

      attr_accessor :components, :count

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

      # @return [Entry]
      def self.new_from_dumpline(eline)
        JSON.parse(eline, create_additions: true)
      end

      # @return [Entry]
      def self.new_from_skosline(skosline)
        self.new(JSON.parse(skosline))
      end

      def in_namespace?(id)
        id.start_with?(@namespace)
      rescue => e
        # TODO log
      end

      def xref_ids
        see_also_ids
      end

      def xref_ids?
        !see_also_ids.empty?
      end

      def non_empty_see_also
        @see_also.select { |_id, x| x.count > 0 }
      end

      def non_empty_incoming_see_also
        @incoming_see_also.select { |_id, x| x.count > 0 }
      end

      def remove_countless_xrefs!
        @see_also = non_empty_see_also
        @incoming_see_also = non_empty_incoming_see_also
      end

      def pare_down_components!
        @components.reject! { |_id, c| c.type == "cs:ChangeSet" }
        @components.select! { |id, c| in_namespace?(id) or xref_ids.include?(id) }
      end

      # Try to build id/label pairs for a set of ids
      def build_references(ids)
        rv = {}
        ids.each do |id|
          if @components[id]
            text = components[id].pref_label
            rv[id] = AuthorityBrowse::GenericXRef.new(id: id, label: text) unless text == label
          end
        end
        rv
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
        @see_also[id] = AuthorityBrowse::GenericXRef.new(id: id, label: text) unless text == label
      end

      # Only add in reverses with different labels, too
      def add_incoming_see_also(id, text)
        @incoming_see_also[id] = AuthorityBrowse::GenericXRef.new(id: id, label: text) unless text == label
      end


      EMPTY = [[], nil, "", {}]

      # Be able to round-trip as JSON
      def to_json(*args)
        {
          id: id,
          loc_id: base_id,
          label: label,
          sort_key: sort_key,
          category: category,
          alternate_forms: alt_labels,
          components: @components,
          see_also: @see_also,
          incoming_see_also: @incoming_see_also,
          need_xref: needs_xref_lookups?,
          deprecated: deprecated?,
          count: count,
          AuthorityBrowse::JSON_CREATE_ID => ConceptEntryName
        }.reject { |_k, v| EMPTY.include?(v) }.to_json(*args)
      end

      def self.json_create(rec)
        e = allocate
        e.id = rec["id"]
        e.category = rec["category"]
        e.see_also = rec["see_also"] || {}
        e.incoming_see_also = rec["incoming_see_also"] || {}
        e.components = rec["components"]
        e.set_main!
        e
      end

      # The structure we save to the database, using the round-tripable json
      def db_object
        {
          id: id,
          label: label,
          sort_key: sort_key,
          xrefs: xref_ids?,
          deprecated: deprecated?,
          json: self.to_json
        }
      end

      # JSON suitable to insert into a solr document as a field value, containing
      # everything we need to drive the interface
      def to_solr_json(*args)
        {
          id: id,
          loc_id: base_id,
          label: label,
          sort_key: sort_key,
          category: category,
          alternate_forms: alt_labels,
          see_also: non_empty_see_also,
          incoming_see_also: non_empty_incoming_see_also,
          count: count
        }.reject { |_k, v| EMPTY.include?(v) }.to_json(*args)
      end

      # Hash that provides the structure we need to send to solr
      def to_solr_doc
        {
          id: AuthorityBrowse.alphajoin(sort_key, base_id),
          loc_id: id,
          browse_field: "name",
          term: label,
          sort_key: sort_key,
          alternate_forms: alt_labels,
          see_also: !see_also.empty?,
          incoming_see_also: !incoming_see_also.empty?,
          count: count,
          json: to_solr_json
        }.reject { |_k, v| EMPTY.include?(v) }
      end
    end
  end
end

