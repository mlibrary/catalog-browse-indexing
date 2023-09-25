require "byebug"
require "pathname"
$LOAD_PATH.unshift(Pathname.new(__dir__).parent + "lib")
require "authority_browse/db"
AuthorityBrowse.setup_authorities_graph_db

require "authority_browse"
require "json"

mark_twain = JSON.parse(File.read("spec/fixtures/loc_authorities/mark_twain_skos.json"))
louis_de_conte_skos = JSON.parse(File.read("spec/fixtures/loc_authorities/louis_de_conte_skos.json"))
AuthorityBrowse::LocAuthorities::Entry.new(mark_twain).save_to_db
AuthorityBrowse::LocAuthorities::Entry.new(louis_de_conte_skos).save_to_db

# some stuff for testing
AuthorityBrowse.setup_terms_db

terms_db = AuthorityBrowse.terms_db[:names]
terms_db.insert(term: "Twain, Mark, 1835-1910", count: 7)
terms_db.insert(term: "Conte, Louis de, 1835-1910", count: 2)

docs = Name.all.map do |name|
  AuthorityBrowse::AuthorityGraphSolrDocument.new(name).to_solr_doc
end

# solr_uploader = AuthorityBrowse::SolrUploader.new(url: "http://solr:SolrRocks@solr:8983/solr/authority_browse/update")
# docs = File.readlines("/app/bin/docs.json")

# puts docs
solr_uploader = AuthorityBrowse::SolrUploader.new(collection: "authority_browse")
solr_uploader.upload docs
