require "sequel"
require "json"
require "byebug"
require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__) + "lib")
require "authority_browse"
DB = Sequel.sqlite

DB.create_table :names do
  String :id, primary_key: true
  String :label  
end

DB.create_table :names_see_also do
  primary_key :id
  String :name_id
  String :see_also_id
end

class Name < Sequel::Model
  many_to_many :see_also, left_key: :name_id, right_key: :see_also_id,
    join_table: :names_see_also, class: self
end

Name.unrestrict_primary_key
#name = Name.create(id: "some_id", label: "Some Id") 
#other_name = Name.create(id: "other_id", label: "Some Other Id") 
#yet_another_name = Name.create(id: "yet_another_id", label: "Yet Another Id" )
#


File.readlines("twain_skos.json").each do |line|
  parsed = JSON.parse(line)
 # need to parse the graph. get the label from the one that matches the id. It's
  # a skos concept. The rest, where the id is a link to another one, that's a see_also
  entry = AuthorityBrowse::LocSKOSRDF::Name::Entry.new_from_skosline(line)
  Name.create(id: entry.id, label: entry.label) 
  entry.components.each do |id, component|
    next if id == entry.id
    DB[:names_see_also].insert(name_id: entry.id, see_also_id: id )
  end
  # 
end

byebug
puts "hello"
