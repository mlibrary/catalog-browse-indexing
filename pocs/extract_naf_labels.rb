## frozen_string_literal: true

require "json"

filename = ARGV.shift
filename ||= "../lcnaf.skos.ndjson"

module NAF
  FS = "\u001c" # Field separator

  class Entry
    def self.new(str)
      orig = str
      graph = JSON.parse(str)["@graph"]
      main = graph.find { |x| x.dig("skos:inScheme", "@id") == "http://id.loc.gov/authorities/names" }

      if main.nil?
        RedirctEntry.new(orig, graph)
      else
        NormalEntry.new(orig, graph)
      end
    end
  end

  class NormalEntry
    attr_accessor :graph, :orig, :main

    def type
      :entry
    end

    def initialize(orig, graph)
      @orig = orig
      @graph = graph
      @main = @graph.find { |x| x.dig("skos:inScheme", "@id") == "http://id.loc.gov/authorities/names" }
    end

    def deprecated?
      @deprecated ||= main.nil? and @graph.find { |x| x["cs:changeReason"] == "deprecated" }
    end

    # Remove punctuation that might interfere with matches against MARC data
    def clean_up(str)
      str.gsub(/[,.;]\Z/, "")
    end

    def id
      id_from_uri(main["@id"])
    rescue => e
      require "pry"
      binding.pry
    end

    def pref_label
      main["skos:prefLabel"]
    end

    def other_labels
      [altLabels, skosx_labels].flatten.uniq.compact
    end

    def skosx_labels
      items = main["skosxl:altLabel"]
      items = [items] if items.is_a? Hash
      if items
        ids = Array(items).map { |x| x["@id"] }
        ids.map { |id| skosx_label_by_id(id) }
      else
        []
      end
    rescue => e
      require "pry"
      binding.pry
    end

    def skosx_label_by_id(id)
      @graph.find { |x| x["@id"] == id }["skosxl:literalForm"]
    end

    def altLabels
      Array(main["skos:altLabel"])
    end

    def id_from_uri(str)
      str.split("/").last
    end

    # id = naf.id
    # pclean = naf.clean_up(naf.prefLabel)
    # puts [id, naf.prefLabel, pclean, 'p'].join("\t")
    # naf.other_labels.each do |l|
    #   lclean = naf.clean_up(l)
    #   puts [id, l, lclean, 'a'].join("\t")

    def to_json
      {type: type, id: id, label: pref_label, alternate_labels: other_labels}.to_json
    end

    def to_tsv
      [pref_label, id, type, other_labels.join(FS)].join("\t")
    end
  end

  class RedirctEntry < NormalEntry
    def type
      if change_structure
        :see_instead
      else
        :deprecation
      end
    end

    def initialize(orig, graph)
      @orig = orig
      @graph = graph
    end

    def change_structure
      @cs ||= @graph.find { |x| x["rdfs:seeAlso"] }
    end

    def see_also_uris
      rdfssa = change_structure["rdfs:seeAlso"]
      sa = case rdfssa
      when Hash
        [rdfssa]
      when Array
        rdfssa
      else raise "rdfssa is a #{rdfssa.class}, whcih it shouldn't be."
      end
      sa.map { |x| x["@id"] }.compact
    rescue
      require "pry"
      binding.pry
    end

    def pref_label
      change_structure["skosxl:literalForm"]
    end

    def uri
      change_structure["@id"]
    end

    def id
      id_from_uri(uri)
    end

    def targets
      see_also_uris.map do |uri|
        label = @graph.find { |x| x["@id"] == uri and x["@type"] == "skos:Concept" and x["skos:prefLabel"] }["skos:prefLabel"]
        next unless label
        [id_from_uri(uri), uri, label]
      end
    end

    def to_json
      {type: type, id: id, label: pref_label, targets: targets}.to_json
    end

    NO_OTHER_LABELS = ""
    def to_tsv
      [pref_label, id, type, NO_OTHER_LABELS, targets.map { |x| x.join("|") }.join(FS)].join("\t")
    end
  end
end

puts %w[label id type alternate_labels targets].join("\t")
File.open(filename, "r:utf-8").each_with_index do |line, i|
  naf = NAF::Entry.new(line)
  next if naf.type == :deprecation
  puts naf.to_tsv
end

__END__





  id = naf.id
  pclean = naf.clean_up(naf.prefLabel)
  puts [id, naf.prefLabel, pclean, 'p'].join("\t")
  naf.other_labels.each do |l|
    lclean = naf.clean_up(l)
    puts [id, l, lclean, 'a'].join("\t")
  end

