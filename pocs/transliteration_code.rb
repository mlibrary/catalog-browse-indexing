require 'icu'

n = ICU::Transliterator.new("NFD; [:Nonspacing Mark:] Remove; NFC")

puts n.transliterate(ARGV.join(" "))

