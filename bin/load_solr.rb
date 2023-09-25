require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib").to_s

require "authority_browse"
require "milemarker"
require "logger"

AuthorityBrowse.generate_and_send_solr_documents
# AuthorityBrowse.load_terms_db
