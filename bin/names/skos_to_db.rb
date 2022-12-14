# frozen_string_literal: true

require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent.parent + "lib").to_s

require "authority_browse"
require "logger"

LOGGER = Logger.new(STDERR)

skosfile = ARGV.shift
dbfile = ARGV.shift

db = AuthorityBrowse.db(dbfile)

if db.tables.include? :names
  LOGGER.info "Dropping old names table"
  db.drop_table(:names)
end

LOGGER.info "Creating table"
db.create_table(:names) do
  String :id, primary_key: true
  String :label
  String :match_text
  Boolean :xrefs
  Boolean :deprecated
  Integer :count, default: 0
  String :json, text: true
end

sequel_table = db[:names]
ds = sequel_table.prepare(:insert, :insert_full_hash, id: :$id, label: :$label,
                          match_text: :$match_text, deprecated: :$deprecated,
                          xrefs: :$xrefs, json: :$json)

milemarker = Milemarker.new(batch_size: 100_000, name: "Add skos data to database", logger: LOGGER )
milemarker.log "Starting skos parsing"
sequel_table.db.transaction do
  AuthorityBrowse::LocSKOSRDF::Name::Skosfile.new(skosfile).each_with_index do |e, i|
    ds.call e.db_object
    milemarker.increment_and_log_batch_line
  end
  milemarker.log_final_line
end

milemarker.log "Adding indexes"
db.alter_table(:names) do
  add_index :deprecated
  add_index :label
  add_index :match_text
  add_index :xrefs
  add_index [:match_text, :deprecated]
  add_index :count
end

# Buzz through all the items in the table that declare they have xrefs
# and add the labels for forward/backward see-alsos
# @param [Sequel::Dataset] sequel_table The table we're using
sequel_table = db[:names]

updater = sequel_table.where(id: :$id).prepare(:update, :json_update, json: :$json)

sequel_table.db.transaction do
  milemarker = Milemarker.new(batch_size: 10_000, name: "xref resolution", logger: LOGGER)
  milemarker.logger.info "Starting xref stuff"
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
    milemarker.increment_and_log_batch_line
  end
  milemarker.log_final_line
end




