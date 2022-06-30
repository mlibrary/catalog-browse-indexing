require "traject"
require "traject/solr_json_writer"

settings do
  provide "solr.url", ENV["SOLR_URL"]
  provide "solr_writer.commit_on_close", "false"
  provide "solr_writer.thread_pool", 2
  provide "solr_writer.batch_size", ENV["AUTHORITY_BATCH"] || 2500
  provide "writer_class_name", "Traject::SolrJsonWriter"
  provide "processing_thread_pool", 12
  provide "log.batch_size", 100_000
end
