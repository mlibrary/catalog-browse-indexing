require "sequel"
require "json"
require "byebug"
require "pathname"
require "milemarker"
require "zinzout"
$LOAD_PATH.unshift(Pathname.new(__dir__) + "lib")
require "authority_browse"

query = <<~SQL.strip
  SELECT names.id, 
         names.label, 
         names2.label AS see_also_label 
  FROM names 
  LEFT OUTER JOIN names_see_also AS nsa 
  ON names.id = nsa.name_id 
  LEFT JOIN names AS names2 
  ON nsa.see_also_id = names2.id 
  WHERE names2.label IS NOT null 
  LIMIT 1000;
SQL

# query2 = "select names.id, names.label, names2.label as see_also_label from names left outer join names_see_also as nsa on names.id = nsa.name_id left join names as names2 on nsa.see_also_id = names2.id where names.id = 'http://id.loc.gov/authorities/names/n79021164';"

docs_file = "solr_docs.jsonl.gz"

db = AuthorityBrowse.db
logger = Logger.new($stdout)
milemarker = Milemarker.new(name: "Write solr docs to file", batch_size: 100, logger: logger)
milemarker.log "Start!"
Zinzout.zout(docs_file) do |out|
  db.fetch(query).chunk_while { |bef, aft| aft[:id] == bef[:id] }.each do |ary|
    out.puts AuthorityBrowse::SolrDocument::Names::AuthorityGraphSolrDocument.new(ary).to_solr_doc
    milemarker.increment_and_log_batch_line
  end

  db[:names_from_biblio].filter(name_id: nil).limit(100).each do |name|
    out.puts AuthorityBrowse::SolrDocument::Names::UnmatchedSolrDocument.new(name).to_solr_doc
    milemarker.increment_and_log_batch_line
  end
end
milemarker.log_final_line

batch_size = 100_000
solr_uploader = AuthorityBrowse::SolrUploader.new(collection: "authority_browse")

mm = Milemarker.new(batch_size: 100_000, name: "Docs sent to solr", logger: logger)

mm.log "Sending #{docs_file} in batches of #{batch_size}"

Zinzout.zin(docs_file) do |infile|
  infile.each_slice(batch_size) do |batch|
    solr_uploader.upload(batch)
    mm.increment(batch_size)
    mm.on_batch { mm.log_batch_line }
  end
end

mm.log "Committing"
solr_uploader.commit
mm.log "Finished"
mm.log_final_line
