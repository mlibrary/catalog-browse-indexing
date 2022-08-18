# frozen_string_literal: true

require_relative "entry"
require "zinzout"
require "delegate"

module AuthorityBrowse
  module LocSKOSRDF
    module Subject
      # A set of subjects
      class Subjects < SimpleDelegator
        include Enumerable

        # @return [Hash<Entry>] Hash of entry_id => entry pairs
        attr_reader :lookup_table

        def initialize(skosrdf_input: nil)
          @lookup_table = {}
          __setobj__(@lookup_table)
          if skosrdf_input
            Zinzout.zin(skosrdf_input).each do |line|
              self << Entry.new(JSON.parse(line))
            end
          end
        end

        # @param [String] id Id of the entry you want
        # @return [Entry, nil] The found entry, or nil if not found
        def [](id)
          lookup_table[id]
        end

        # @param [Entry] entry the entry to add
        # @return [Subjects] self
        def <<(entry)
          lookup_table[entry.id] = entry
          self
        end

        # @yieldreturn [Entry] An Entry
        def each
          return enum_for(:each) unless block_given?
          lookup_table.each_pair do |_id, e|
            yield e
          end
        end

        alias_method :add, :<<

        # Go through and resolve anything that needs resolving, tracking
        # things that have no resolution
        def resolve_xrefs!
          each { |e| e.resolve_xrefs!(self) }
          self
        end

        def dump(output)
          Zinzout.zout(output) do |out|
            each {|e| out.puts e.to_json}
          end
          nil
        end

        def self.load(input)
          subs = self.new
          Zinzout.zin(input) do |infile|
            infile.each do |eline|
              subs << JSON.parse(eline, create_additions: true)
            end
          end
          subs
        end

      end
    end
  end
end


