# frozen_string_literal: true

require_relative "entry"
require "zinzout"
require "delegate"

module AuthorityBrowse
  module LocSKOSRDF
    module Subject
      # A set of subjects
      class Subjects
        include Enumerable

        # @return [Hash<Entry>] Hash of entry_id => entry pairs
        attr_reader :lookup_table, :term_table

        def initialize(skosrdf_input: nil)
          @lookup_table = {}
          @term_table = {}
          # __setobj__(@lookup_table)
          if skosrdf_input
            Zinzout.zin(skosrdf_input).each do |line|
              e = Entry.new(JSON.parse(line))
              next if /-781\Z/.match?(e.id)
              if e.authorized?
                add e
              else
                print "."
              end
            end
          end
        end

        # Convert a raw skos file into our local dump format
        def self.convert(infile:, outfile:)
          subs = new(skosrdf_input: infile)
          subs.resolve_xrefs!
          subs.dump(outfile)
        end

        # @param [String] id Id of the entry you want
        # @return [Entry, nil] The found entry, or nil if not found
        def [](id)
          lookup_table[id]
        end

        # @param [Entry] entry the entry to add
        # @return [Subjects] self
        def add(entry)
          lookup_table[entry.id] = entry
          if term_table.has_key?(entry.label)
            older = term_table[entry.label]
            newer = entry
            return self if newer.deprecated?
            older_score = older.narrower_ids.size + older.broader_ids.size
            newer_score = newer.narrower_ids.size + newer.broader_ids.size
            return if older_score > newer_score
          end
          term_table[entry.label] = entry
          self
        end

        # @yieldreturn [Entry] An Entry
        def each
          return enum_for(:each) unless block_given?
          lookup_table.each_pair do |_id, e|
            yield e
          end
        end

        # Go through and resolve anything that needs resolving, tracking
        # things that have no resolution
        def resolve_xrefs!
          each { |e| e.resolve_xrefs!(self) }
          self
        end

        # Print out each entry as a json object, one line at a time
        # (so, producing a .jsonl stream)
        def dump(output)
          Zinzout.zout(output) do |out|
            each { |e| out.puts e.to_json }
          end
          nil
        end

        # Create a new Subjects object by loading in the result of
        # a previous #dump
        def self.load(filename_or_file)
          subs = new
          Zinzout.zin(filename_or_file) do |infile|
            infile.each do |eline|
              add JSON.parse(eline, create_additions: true)
            end
          end
          subs
        end
      end
    end
  end
end
