# frozen_string_literal: true

require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib").to_s

require "authority_browse"

skosfile = ARGV.shift
dbfile = ARGV.shift

db = AuthorityBrowse.db(dbfile)


if db.tables.include? :names
  puts "Dropping old names table"
  db.drop_table(:names)
end

puts "Creating table"
db.create_table(:names) do
  String :id
  String :label
  String :normalized
  String :more_normalized
  Boolean :xrefs
  Integer :count, default: 0
  String :json, text: true
end

sequel_table = db[:names]
ds = sequel_table.prepare(:insert, :insert_full_hash, id: :$id, label: :$label,
                          normalized: :$normalized, more_normalized: :$more_normalized,
                          xrefs: :$xrefs, json: :$json)
sequel_table.db.transaction do
  AuthorityBrowse::LocSKOSRDF::Name::Skosfile.new(skosfile).each_with_index do |e, i|
    ds.call e.db_object
    puts "%8d %s" % [i, DateTime.now] if i % 100_000 == 0
  end
end

puts "Adding indexes"
db.alter_table(:names) do
  add_index :id
  add_index :label
  add_index :normalized
  add_index :more_normalized
  add_index :xrefs
end

puts "Starting xref resolution"
AuthorityBrowse::LocSKOSRDF::Name::Names.resolve_xrefs_in_db(sequel_table: sequel_table)



