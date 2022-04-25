## frozen_string_literal: true

require 'json'

filename = ARGV.shift
filename ||= "../lcnaf.skos.ndjson"

class NAFEntry
  attr_accessor :graph
  attr_reader :orig
  def initialize(str)
    @orig = str
    @graph = JSON.parse(str)['@graph']
  end

  def deprecated?
    @deprecated ||= main.nil? and @graph.find{|x| x["cs:changeReason"] == "deprecated"}
  end

  # Remove punctuation that might interfere with matches against MARC data
  def clean_up(str)
    str.gsub(/[,.;]/, '').downcase
  end


  def id
    if deprecated?
    else
      main['@id'].split('/').last
    end
  rescue => e
    require 'pry'; binding.pry
  end

  # TODO
  def main
    return @main if @main
    normal = @graph.find { |x| x.dig('skos:inScheme', '@id') == "http://id.loc.gov/authorities/names" }
    @main = normal
  end

  def prefLabel
    main["skos:prefLabel"]
  end

  def other_labels
    [altLabels, skosx_labels].flatten.uniq.compact
  end

  def skosx_labels
    items = main["skosxl:altLabel"]
    items = [items] if items.kind_of? Hash
    if items
      ids = Array(items).map{|x| x["@id"]}
      ids.map{|id| skosx_label_by_id(id)}
    else
      []
    end
  rescue => e
    require 'pry'; binding.pry
  end

  def skosx_label_by_id(id)
    @graph.find { |x| x['@id'] == id }["skosxl:literalForm"]
  end

  def altLabels
    Array(main["skos:altLabel"])
  end
end


File.open(filename, 'r:utf-8').each do |line|
  naf = NAFEntry.new(line)
  if naf.main.nil?
    STDERR.puts naf.orig
    next
  end
  id = naf.id
  pclean = naf.clean_up(naf.prefLabel)
  puts [id, naf.prefLabel, pclean, 'p'].join("\t")
  naf.other_labels.each do |l|
    lclean = naf.clean_up(l)
    puts [id, l, lclean, 'a'].join("\t")
  end
end


