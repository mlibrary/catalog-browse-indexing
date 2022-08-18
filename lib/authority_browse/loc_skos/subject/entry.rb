# frozen_string_literal: true

require_relative "../generic_entry"
require_relative "component"
require "json"

module AuthorityBrowse::LocSKOSRDF
  module Subject
    class Entry

      attr_accessor :components

      def self.new(skos_hash)
        if GenericEntry.has_see_also?(skos_hash)
          SeeAlsoEntry.new(skos_hash)
        else
          ConceptEntry.new(skos_hash)
        end
      end
    end

    class ConceptEntry < GenericEntry

      # Freeze these 'cause they'll be used over and over again
      JSON_CREATE_ID = JSON.create_id.freeze
      ConceptEntryName = self.name.freeze

      attr_accessor :category, :narrower, :broader, :components

      def initialize(skos_hash)
        @namespace = "http://id.loc.gov/authorities/subjects"
        super(skos_hash, component_klass: AuthorityBrowse::LocSKOSRDF::Subject::Component)
        set_main!
        pare_down_components!
        @category = "subject"
        @narrower = build_references(narrower_ids)
        @broader = build_references(broader_ids)
      rescue NoMethodError => e
        require 'pry'; binding.pry
      end

      def in_namespace?(id)
        id.start_with?(@namespace)
      rescue => e
        require 'pry'; binding.pry
      end

      def xref_ids
        broader_ids.union(narrower_ids)
      end

      def pare_down_components!
        @components.reject! { |_id, c| c.type == "cs:ChangeSet" }
        @components.select! { |id, c| in_namespace?(id) or xref_ids.include?(id) }
      end

      # Try to build id/label pairs for a set of ids (for narrower/broader). Lucky for us, the LoC only
      # _sometiems_ includes the necessary information in another component, so we'll side-effect setting
      # a flag that says we'll need to fill things in during another pass.
      def build_references(ids)
        rv = {}
        ids.each do |id|
          if @components[id]
            rv[id] = @components[id].pref_label
          end
        end
        rv
      end

      def see_also?
        false
      end

      alias_method :label, :pref_label

      def needs_xref_lookups?
        broader.keys.size != broader_ids.size or narrower.keys.size != narrower_ids.size
      end

      def broader_ids
        collect_relevant_ids("skos:broader")
      end

      def narrower_ids
        collect_relevant_ids("skos:narrower")
      end

      # A "relevant" id is one in our @namespace or one that we already have a component for
      def collect_relevant_ids(tag)
        main.collect_ids(tag).select { |id| in_namespace?(id) or @components[id] }
      end

      def add_narrower(id, label)
        @narrower[id] = label
      end

      def add_broader(id, label)
        @broader[id] = label
      end

      # We need to resolve any missing xrefs through the use of an object (like Subjects)
      # that responds to o[id] with an entry

      def resolve_xrefs!(lookup_table)
        return unless needs_xref_lookups?
        (broader_ids - components.keys).each do |xid|
          e = lookup_table[xid]
          if e
            add_broader(xid, e.label)
          else
            warn "Entry #{id} can't find broader xref #{xid}"
          end
        end
        (narrower_ids - components.keys).each do |xid|
          e = lookup_table[xid]
          if e
            add_narrower(xid, e.label)
          else
            warn "Entry #{id} can't find narrower xref #{xid}"
          end
        end
      end

      def to_json(*args)
        {
          id: id,
          label: label,
          category: category,
          narrower: @narrower,
          broader: @broader,
          components: @components,
          need_xref: needs_xref_lookups?,
          JSON_CREATE_ID => ConceptEntryName
        }.to_json(*args)
      end

      def self.json_create(rec)
        e = allocate
        e.id = rec["id"]
        e.category = rec["category"]
        e.narrower = rec["narrower"]
        e.broader = rec["broader"]
        e.components = rec["components"]
        e.set_main!
        e
      end

    end

    class SeeAlsoEntry < ConceptEntry
      SEEALSOENTRYNAME = self.name

      attr_accessor :see_also

      def initialize(*args, **kwargs)
        super
        @see_also = build_references(see_also_ids)
        @category = "see_also"
      end

      def see_also?
        true
      end

      def needs_xref_lookups?
        see_also_ids.size != see_also.size
      end

      def label
        main.label
      end

      def see_also_ids
        collect_relevant_ids("rdfs:seeAlso")
      end

      # Only add in a redirect if the text is different than the deleted record's label. If
      # it is, the new record will have been found anyway.
      def add_see_also(id, text)
        @see_also[id] = text unless text == label
      end

      def resolve_xrefs!(lookup_table)
        (see_also_ids - components.keys).each do |xid|
          e = lookup_table[xid]
          if e
            add_see_also(xid, e.label)
          else
            warn "Entry #{id} can't find seeAlso xref #{xid}"
          end
        end
      end

      def to_json(*args)
        {
          id: id,
          category: category,
          label: label,
          see_also: see_also,
          components: components,
          JSON_CREATE_ID => SEEALSOENTRYNAME
        }.to_json(*args)
      end

      def self.json_create(rec)
        e = allocate
        e.components = rec["components"]
        e.see_also = rec["see_also"]
        e.set_main!
        e
      end

    end
  end
end
