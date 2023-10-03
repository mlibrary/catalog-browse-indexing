require "sequel"
require "json"
require "byebug"
require "pathname"
$LOAD_PATH.unshift(Pathname.new(__dir__) + "lib")
require "authority_browse"

# query = "select names.id, names.label, names2.label as see_also_label from names left outer join names_see_also as nsa on names.id = nsa.name_id left join names as names2 on nsa.see_also_id = names2.id where names2.label is not null limit 1000;"

query2 = "select names.id, names.label, names2.label as see_also_label from names left outer join names_see_also as nsa on names.id = nsa.name_id left join names as names2 on nsa.see_also_id = names2.id where names.id = 'http://id.loc.gov/authorities/names/n79021164';"

db = AuthorityBrowse.authorities_graph_db

db.fetch(query2).chunk_while { |bef, aft| aft[:id] == bef[:id] }.each do |ary|
  puts ary
end
