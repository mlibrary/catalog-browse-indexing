# frozen_string_literal: true

require_relative "entry"
require "zinzout"
require "delegate"

module AuthorityBrowse
  module LocSKOSRDF
    module Subject
      # A set of subjects. It's enumerable, and exposes ways to get
      # a subject by id (`subjects[id]`) or by matching label
      # (`subjects.match(term)`)
      class Subjects
        include Enumerable

        # @return [Hash<Entry>] Hash of entry_id => entry pairs
        attr_reader :lookup_table, :normalized_label_table

        def initialize(skosrdf_input: nil)
          @lookup_table = {}
          @normalized_label_table = {}
          # __setobj__(@lookup_table)
          if skosrdf_input
            Zinzout.zin(skosrdf_input).each do |line|
              e = Entry.new(JSON.parse(line))
              next if /-781\Z/.match?(e.id)
              if e.authorized?
                add e
              else
                print "u"
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

        # @param [String] term Term to try and match on
        # @return [Subject,nil] Subject that matches (via normalized label) that text.
        def match(term)
          normalized_label_table[AuthorityBrowse::Normalize.match_text(term)]
        end

        # Which entry is "better"? Deprecated entries
        # are the worst; otherwise, choose by entry.score
        # @param [Entry] e1
        # @param [Entry] e2
        # @return [Entry] the "better" entry
        def better_entry(e1, e2)
          if e2.deprecated? or e2.score <= e1.score
            e1
          else
            e2
          end
        end

        # @param [Entry] entry the entry to add
        # @return [Boolean]
        def duplicate_label?(entry)
          normalized_label_table.has_key?(entry.match_text)
        end


        # Add an entry to the id-based hash.
        # If the match text of the new entry is already indexed in normalized_label_table,
        # figure out which entry is the best and note the duplication (by putting it in the
        # duplicates hash).
        # @param [Entry] new_entry the entry to add
        # @return [Subjects] self
        def add(new_entry)
          lookup_table[new_entry.id] = new_entry
          if duplicate_label?(new_entry)
            older = normalized_label_table[new_entry.match_text]
            return if better_entry(new_entry, older).id == older.id
          end
          normalized_label_table[new_entry.match_text] = new_entry
          new_entry.count ||= 0
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

        # Copy counts from "main" entries to broader/narrower
        def add_xref_counts!
          each { |e| e.add_xref_counts!(self) }
          self
        end

        # Zero out all the counts
        def zero_out_counts!
          each {|e| e.zero_out_counts!}
        end

        # Print out each entry as a json object, one line at a time
        # (so, producing a .jsonl stream)
        def dump(output)
          resolve_xrefs!
          Zinzout.zout(output) do |out|
            each { |e| out.puts e.to_json }
          end
          nil
        end

        # Create a new Subjects object by loading in the result of
        # a previous #dump
        def self.load(filename_or_file)
          subjects = new
          Zinzout.zin(filename_or_file) do |infile|
            infile.each do |eline|
              subjects.add JSON.parse(eline, create_additions: true)
            end
          end
          subjects
        end

        MISSING_PAREN = /\([^\)]+\Z/


        def load_terms(termfile)
          zero_out_counts!
          Zinzout.zin(termfile).each do |line|
            tc = line.chomp.split("\t")
            term = tc.first.strip
            count = tc.last.to_i
            s = match term
            if s
              s.count += count
            else
              if MISSING_PAREN.match(term)
                term = term + ')'
              end
              nonmatch = AuthorityBrowse::LocSKOSRDF::Subject::UnmatchedEntry.new(term, count)
              add(nonmatch)
            end
          end
        end

      end
    end
  end
end
