# frozen_string_literal: true

require_relative "entry"
require "zinzout"
require "delegate"

module AuthorityBrowse::LocSKOSRDF::Name
  # A set of names
  class Names < SimpleDelegator
    include Enumerable

    # @return [Hash<Entry>] Hash of entry_id => entry pairs
    attr_reader :lookup_table

    def initialize(skosrdf_input: nil)
      @lookup_table = {}
      __setobj__(@lookup_table)
      @skos = Zinzout.zin(skosrdf_input)
    end

    def self.convert(input:, output:)
      Zinzout.zout(output) do |o|
        Zinzout.zin(input).each do |line|
          e = Entry.new_from_skosline(line)
          next if e.id == "http://id.loc.gov/authorities/names/n"
          o.puts JSON.fast_generate(e)
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
      @lookup_table[entry.id] = entry
      self
    end

    alias_method :add, :<<

    def dump(output)
      Zinzout.zout(output) do |out|
        each { |e| out.puts e.to_json }
      end
      nil
    end

    # @yieldreturn [Event] Each event, in turn, from the previously-dumped file
    def self.each_from_dump(dumpfile)
      return enum_for(:each_from_dump) unless block_given?
      Zinzout.zin(dumpfile).each { |eline| yield Entry.new_from_dumpline(eline) }
    end

    def self.load(input)
      subs = new
      Zinzout.zin(input) do |infile|
        infile.each do |eline|
          subs << Entry.new_from_dumpline(eline)
        end
      end
      subs
    end

    def self.add_dump_to_db(dumpfile:, sequel_table:)
      ds = sequel_table.prepare(:insert, :insert_full_hash, id: :$id, label: :$label, normalized: :$normalized, xrefs: :$xrefs, json: :$json)
      sequel_table.db.transaction do
        Zinzout.zin(dumpfile).each_with_index do |eline, i|
          e = Entry.new_from_dumpline(eline)
          ds.call e.db_object
          puts "#{i}  #{DateTime.now}" if i % 100_000 == 0
        end
      end
    end
  end
end
