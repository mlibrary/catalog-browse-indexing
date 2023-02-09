# frozen_string_literal: true

require_relative "../generic_entry"
require_relative "component"
require "json"

module AuthorityBrowse::LocSKOSRDF
  module Subject

    class Entry < GenericEntry
      # Freeze these 'cause they'll be used over and over again
      ConceptEntryName = name.freeze
      NAMESPACE = "http://id.loc.gov/authorities/subjects"
      attr_accessor :category, :narrower, :broader, :components, :see_also, :incoming_see_also

      def initialize(skos_hash)
        super(skos_hash, component_klass: AuthorityBrowse::LocSKOSRDF::Subject::Component)
        set_main!
        pare_down_components!
        @category = "subject"
        @narrower = build_references(narrower_ids)
        @broader = build_references(broader_ids)
        @see_also = build_references(see_also_ids)
        @incoming_see_also = {}
      rescue NoMethodError => e
        # TODO log
        warn "#{e} in subject entry creation"
      end

      def deprecated?
        @deprecated
      end

      def in_namespace?(id)
        id.start_with?(NAMESPACE)
      rescue => e
        # TODO log
        warn "#{e} in subject entry in_namespace"
      end

      def xref_ids
        @xref_ids ||= broader_ids.union(narrower_ids).union(see_also_ids)
      end

      def pare_down_components!
        @components.reject! { |_id, c| c.type == "cs:ChangeSet" }
        @components.select! { |id, c| in_namespace?(id) or xref_ids.include?(id) }
      end

      def authorized?
        mcoll = main.raw_entry["http://www.loc.gov/mads/rdf/v1#isMemberOfMADSCollection"]
        mcoll.nil? or mcoll.include?("http://id.loc.gov/authorities/subjects/collection_LCSHAuthorizedHeadings")
      end

      # Try to build id/label pairs for a set of ids (for narrower/broader).
      def build_references(ids)
        rv = {}
        ids.each do |id|
          if @components[id]
            if @components[id].pref_label.nil?
              print '.'
            else
              rv[id] = AuthorityBrowse::GenericXRef.new(id: id, label: @components[id].pref_label)
            end
          end
        end
        rv
      end

      # The "score" is basically just a count of how many
      # things are referenced.
      def score
        label.size + narrower_ids.size + broader_ids.size
      end

      def needs_xref_lookups?
        broader.keys.size != broader_ids.size or
          narrower.keys.size != narrower_ids.size or
          see_also.keys.size != see_also_ids.size
      end

      def broader_ids
        collect_relevant_ids("skos:broader")
      end

      def narrower_ids
        collect_relevant_ids("skos:narrower")
      end

      def see_also_ids
        collect_relevant_ids("rdfs:seeAlso")
      end

      # A "relevant" id is one in our NAMESPACE or one that we already have a component for
      def collect_relevant_ids(tag)
        main.collect_ids(tag).select { |id| in_namespace?(id) or @components[id] }
      rescue => e
        puts self
        raise e
      end

      def add_narrower(id, narrow_label)
        @narrower[id] = AuthorityBrowse::GenericXRef.new(id: id, label: narrow_label) unless narrow_label == label
      end

      def add_broader(id, broader_label)
        @broader[id] = AuthorityBrowse::GenericXRef.new(id: id, label: broader_label) unless broader_label == label
      end

      # Only add in a redirect if the text is different than the deleted record's label. If
      # it is, the new record will have been found anyway.
      def add_see_also(id, sa_label)
        @see_also[id] = AuthorityBrowse::GenericXRef.new(id: id, label: sa_label) unless sa_label == label
      end

      # We need to resolve any missing xrefs through the use of an object (like Subjects)
      # that responds to o[id] with an entry
      def resolve_xrefs!(lookup_table)
        return unless needs_xref_lookups?
        (broader_ids - broader.keys).each do |xid|
          e = lookup_table[xid]
          if e
            add_broader(xid, e.label)
          else
            warn "Entry #{id} can't find broader xref #{xid}"
          end
        end
        (narrower_ids - narrower.keys).each do |xid|
          e = lookup_table[xid]
          if e
            add_narrower(xid, e.label)
          else
            warn "Entry #{id} can't find narrower xref #{xid}"
          end
        end
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

      def add_xref_counts!(lookup_table)
        broader_ids.each do |xid|
          e = lookup_table[xid]
          if e
            broader[xid].count = e.count
          end
        end

        narrower_ids.each do |xid|
          e = lookup_table[xid]
          if e
            narrower[xid].count = e.count
          end
        end

        see_also_ids.each do |xid|
          e = lookup_table[xid]
          if e
            next unless see_also[xid]
            see_also[xid].count = e.count
          end
        end
        self
      end

      def zero_out_counts!
        count = 0
        broader.values.each { |xref| xref.count = 0 }
        narrower.values.each { |xref| xref.count = 0 }
        see_also.values.each { |xref| xref.count = 0 }
      end

      def to_solr_doc
        {
          id: label,
          loc_id: id =~ /http/ ? id : nil,
          term: label,
          count: count,
          alternate_forms: alt_labels,
          narrower: narrower.values.select { |xref| xref.count > 0 }.map { |s| s.label + "||" + s.count.to_s }.sort,
          broader: broader.values.select { |xref| xref.count > 0 }.map { |s| s.label + "||" + s.count.to_s }.sort,
          see_also: see_also.values.select { |xref| xref.count > 0 }.map { |s| s.label + "||" + s.count.to_s }.sort,
          incoming_see_also: incoming_see_also.values,
          browse_field: category,
          json: {id: id, subject: label, narrower: narrower, broader: broader, see_also: see_also, incoming_see_also: incoming_see_also}.to_json
        }.reject { |_k, v| v.nil? or v == "" or (v.respond_to?(:empty?) and v.empty?) }
      end

      def to_json(*args)
        {
          id: id,
          label: label,
          match_text: match_text,
          category: category,
          alternate_forms: alt_labels,
          narrower: @narrower,
          broader: @broader,
          components: @components,
          see_also: @see_also,
          incoming_see_also: @incoming_see_also,
          need_xref: needs_xref_lookups?,
          AuthorityBrowse::JSON_CREATE_ID => ConceptEntryName
        }.reject { |_k, v| v.nil? or v == [] or v == "" }.to_json(*args)
      rescue => e
        require 'pry'; binding.pry
      end

      def self.json_create(rec)
        e = allocate
        e.id = rec["id"]
        e.category = rec["category"]
        e.narrower = rec["narrower"] || {}
        e.broader = rec["broader"] || {}
        e.see_also = rec["see_also"] || {}
        e.incoming_see_also = rec["incoming_see_also"] || {}
        e.components = rec["components"]
        e.set_main!
        e
      end
    end

    class UnmatchedEntry < Entry

      attr_accessor :label, :count, :category

      def initialize(label, count)
        @label = cleanup(label)
        @id = @label
        @count = count
        @category = "subject"
        @broader = {}
        @narrower = {}
        @see_also = {}
      end

      MISSING_END_PARENS = /\([^)]+\Z/

      def cleanup(str)
        s = str.gsub(/\s*--\s*/, "--").gsub(/\s+/, " ").strip
        if MISSING_END_PARENS.match? s
          s + ')'
        else
          s
        end
      end

      def add_xref_counts!(lookup_table)
        self
      end

      def match_text
        AuthorityBrowse::Normalize.match_text(label)
      end

      def score
        label.size
      end

      def to_json(*args)
        {
          id: id,
          label: label,
          match_text: match_text,
          category: category
        }
      end

      def to_solr_doc
        {
          id: @label,
          term: @label,
          count: @count,
          browse_field: "subject",
          json: {id: @label, subject: @label}.to_json
        }
      end
    end
  end
end
