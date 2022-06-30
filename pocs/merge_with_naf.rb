# frozen_string_literal: true

require "simple_solr_client"
require "httpx"

# Given a reader that produces [name, count] pairs, figure out of there is such a thing in the
# LCNAF solr, and (whether found or not) produce a solr document suitable for author browse.

# Read the pairs from a file. Presumably there could be a streaming version based on teh
# term_extractor.rb script
class AuthorCountFileReader
  include Comparable

  def initialize(filename = "data/authorStr_browse_terms.tsv")
    @filename = filename
  end

  def each
    File.open(@filename).each do |line|
      name, count = line.chomp.split("\t")
      yield [name, count]
    end
  end

  def each_pair
    each do |nc|
      yield(*nc)
    end
  end
end

core = SimpleSolrClient::Client.new("http://search-prep.umdl.umici")
acr = AuthorCountFileReader.new
acr.each_pair do |name, count|
end
