# frozen_string_literal: true

require "icu"
require "json"

n = ICU::Transliterator.new("NFD; [:Nonspacing Mark:] Remove; NFC")

naf_file = "data/naf.jsonld"

File.open("data/label_pairs.tsv", "w:utf-8") do |out|
  File.open(naf_file, "r:utf-8").each do |line|
    r = JSON.parse(line)
    id = r["id"]
    labels = [r["label"], r["alternate_labels"]]
    labels.flatten!
    labels.compact!
    labels.map! do |l|
      nl = n.transliterate(l).downcase
      nl.gsub!(/[\p{P}\p{S}]/, "")
      nl.gsub!(/\s+/, " ")
      nl.strip!
      nl
    end
    labels.uniq!
    labels.each { |nl| out.puts "#{nl}\t#{id}" }
  end
end
