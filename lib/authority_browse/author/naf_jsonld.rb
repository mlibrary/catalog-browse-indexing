# frozen_string_literal: true

require "delegate"
require "json"

module AuthorityBrowse
  module Author
    # Deal with the Name Authority File from the Library of Congress.
    # This deals with the data in the SKOS schema delivered as
    # newline-delimited json (.jsonld)
    module NAFSkosJsonld
      FS = "\u001c" # Field separator for .tsv output

      # The two types of NAF entries we're concerned with are
      # "normal" entries that are the current endpoint for the
      # authority, and "redirect" entries which are pointers to
      # a "normal" entry.
      #
      # Generally, we'll be ignoring the "deprecation" entries which
      # are bookkeeping and not useful for our purposes.
      class Entry < SimpleDelegator
        # To figure out what type of entry we're dealing with, we have to do some
        # screwing around.
        # @param [String] str_from_skos_jsonld A line from the .skos.jsonld file
        def initialize(str_from_skos_jsonld)
          orig = str_from_skos_jsonld
          graph = JSON.parse(str_from_skos_jsonld)["@graph"]
          main_section = find_main_section(graph)

          __setobj__(
            if NormalEntry.matches?(graph, main_section)
              NormalEntry.new(graph, main_section)
            elsif RedirectEntry.matches?(graph, main_section)
              RedirectEntry.new(graph, main_section)
            elsif DeprecationEntry.matches?(graph, main_section)
              DeprecationEntry.new(graph, main_section)
            else
              raise "Got something that doesn't look like an entry we're handling: #{orig}"
            end
          )
        end

        def to_json
          to_h.to_json
        end

        def find_main_section(graph)
          graph.find { |x| x.dig("skos:inScheme", "@id") == "http://id.loc.gov/authorities/names" }
        end

        def normal?
          type == :normal
        end

        def redirect?
          type == :redirect
        end

        def deprecated?
          type == :deprecated
        end
      end

      # A "normal" entry is one that has a preferred label, e.g., one that is the
      # "preferred" entry and not a redirect or a deprecation
      class NormalEntry
        attr_accessor :graph, :main_section

        # Does the given graph seem to conform to a "normal" entry?
        # Really only check if there's a main entry
        # @return [Boolean] does this look like a normal entry
        def self.matches?(graph, main_section)
          main_section and !graph.find { |x| x["rdfs:seeAlso"] }
        end

        def initialize(graph, main_section)
          @graph = graph
          @main_section = main_section
        end

        # The type of a normal entry is :normal
        # @return :normal
        def type
          :normal
        end

        # Extract the NAF id from the main entry
        def id
          @id ||= main_section["@id"]
        rescue => e
          require "pry"
          binding.pry
        end

        # @return [String] the preferred label (i.e., "best form of the name")
        def preferred_form
          main_section["skos:prefLabel"]
        rescue => e
          require 'pry'; binding.pry
        end

        # @return [Array<String>] Other forms of the name
        def other_labels
          [altLabels, skosx_labels].flatten.uniq.compact
        end

        alias_method :other_forms, :other_labels

        # @return [Array<String>] Alternate forms of the name
        # from the skosxl:altLabel namespace
        def skosx_labels
          items = main_section["skosxl:altLabel"]
          items = [items] if items.is_a? Hash
          if items
            ids = Array(items).map { |x| x["@id"] }
            ids.map { |id| skosx_label_by_id(id) }
          else
            []
          end
        rescue => e
          raise "Problem deriving skosx labels: #{e}"
        end

        # We need to dip into another part of the graph to find the
        # label connected to the given skos id
        # @param [String] skos_id The skos ID taken from a skos:altLabel entry
        # @return [String] The name form associated with that id
        def skosx_label_by_id(skos_id)
          @graph.find { |x| x["@id"] == skos_id }["skosxl:literalForm"]
        end

        # @return [Array<String>] Alternate forms of the name in the skos:altLabel space
        def altLabels
          Array(main_section["skos:altLabel"])
        end

        def to_h
          {type: type, id: id, author: preferred_form, alternate_forms: other_labels}
        end

        # @return [Hash] Full hash representing the solr document

        # @return [String] .tsv representation
        def to_tsv
          [preferred_form, id, type, other_labels.join(FS)].join("\t")
        end

        # Remove punctuation that might interfere with matches against MARC data
        def clean_up(str)
          str.gsub(/[,.;]\Z/, "")
        end
      end

      # A redirect entry has a preferred label, but also a set of
      # URI/label pairs to which the user should be redirected.
      # Generally there's only one, but not always.
      class RedirectEntry < NormalEntry
        # A redirect has a see also structure
        def self.matches?(graph, main_section)
          new(graph, main_section).see_also_section
        end

        def preferred_form
          x = (main_section and main_section["skos:prefLabel"]) || see_also_section["skosxl:literalForm"]
          raise "No preferred form for #{id}" unless x
          x
        rescue => e
          require 'pry'; binding.pry
        end

        # @return :redirect
        def type
          :redirect
        end

        def id
          see_also_section["@id"]
        end

        alias_method :uri, :id

        # @return [Hash<String,String>] Hash of the form URI => preferred_form for all the redirect targets
        def targets
          see_also_uris.each_with_object({}) do |uri, h|
            label = @graph.find { |x| x["@id"] == uri and x["@type"] == "skos:Concept" and x["skos:prefLabel"] }["skos:prefLabel"]
            next unless label
            h[uri] = label
          end
        end

        def target_strings
          targets.values
        end

        # All the info about a redirect comes from the seeAlso section
        # @return [Hash] the seeAlso part of the graph
        def see_also_section
          @cs ||= @graph.find { |x| x["rdfs:seeAlso"] }
        end

        # Get the URIs (NAF ids) for each of the seeAlso items, needed to
        # look up the associated labels in other parts of the graph
        # @return [Array<String>] URIs of the seeAlso targets
        def see_also_uris
          rdfssa = see_also_section["rdfs:seeAlso"]
          sa = case rdfssa
          when Hash
            [rdfssa]
          when Array
            rdfssa
          else
            raise "rdfssa is a #{rdfssa.class}, which it shouldn't be."
          end
          sa.map { |x| x["@id"] }.compact
        rescue => e
          require "pry"
          binding.pry
        end

        # @return JSON representation
        def to_h
          {type: type, id: id, author: preferred_form, see_instead: target_strings}
        end

        NO_OTHER_LABELS = ""

        # @return .tsv representation
        def to_tsv
          [preferred_form, id, type, NO_OTHER_LABELS, targets.values.join("|")].join("\t")
        end
      end

      class DeprecationEntry
        attr_reader :graph, :main_section

        def type
          :deprecated
        end

        def initialize(graph, main_section)
          @graph = graph
          @main_section = main_section
        end

        def self.matches?(graph, main_section)
          main_section.nil? and !RedirectEntry.matches?(graph, main_section)
        end
      end
    end
  end
end
