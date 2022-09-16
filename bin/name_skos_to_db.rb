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
  String :sort_key
  Boolean :xrefs
  Boolean :deprecated
  Integer :count, default: 0
  String :json, text: true
end

sequel_table = db[:names]
ds = sequel_table.prepare(:insert, :insert_full_hash, id: :$id, label: :$label,
                          sort_key: :$sort_key, deprecated: :$deprecated,
                          xrefs: :$xrefs, json: :$json)
sequel_table.db.transaction do
  AuthorityBrowse::LocSKOSRDF::Name::Skosfile.new(skosfile).each_with_index do |e, i|
    ds.call e.db_object
    puts "%8d %s" % [i, DateTime.now] if i % 100_000 == 0
  end
end

puts "Adding indexes"
db.alter_table(:names) do
  add_index :id, unique: true
  add_index :deprecated
  add_index :label
  add_index :sort_key
  add_index :xrefs
  add_index [:sort_key, :deprecated]
  add_index :count
end

puts "Starting xref resolution"

# Buzz through all the items in the table that declare they have xrefs
# and add the labels for forward/backward see-alsos
# @param [Sequel::Dataset] sequel_table The table we're using
sequel_table = db[:names]

updater = sequel_table.where(id: :$id).prepare(:update, :json_update, json: :$json)

sequel_table.db.transaction do

  sequel_table.where(xrefs: true).each do |rec|
    e = AuthorityBrowse::LocSKOSRDF::Name::Entry.new_from_dumpline(rec[:json])
    id = e.id
    label = e.label
    sequel_table.select(:id, :label, :json).where(id: e.xref_ids).each do |target_db_record|
      begin
        target = AuthorityBrowse::LocSKOSRDF::Name::Entry.new_from_dumpline(target_db_record[:json])
        e.add_see_also(target.id, target.label)
        target.add_incoming_see_also(id, label)
        updater.call(id: target.id, json: target.to_json)
      rescue => err
        require "pry"; binding.pry
      end
    end
    updater.call(id: e.id, json: e.to_json)
  end
end




