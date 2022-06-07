require 'json'
require 'simple_solr_client'
require 'concurrent'
require 'logger'
require 'date'

@c = SimpleSolrClient::Client.new('http://search-prep.umdl.umich.edu:8025/solr').core('lcnaf')

@logger = Logger.new(File.new('author_file.jsonld', 'w:utf-8'))
@logger.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n"}

@pool = Concurrent::ThreadPoolExecutor.new(
   min_threads: 20,
   max_threads: 20,
   max_queue: 200,
   fallback_policy: :caller_runs
)

AUTHOR = "author".freeze
COUNT = "count".freeze
ID = "id".freeze

puts DateTime.now

def find_and_print(author, count)
  r = @c.fv_search('author', author)
  if r.num_found > 0
    d = r.docs.first.solr_doc_hash
    d[COUNT] = count
    @logger.info d.to_json
  else
    @logger.info({AUTHOR =>  author, ID =>  author, COUNT => count}.to_json)
  end
end  

terms = File.open('data/authorStr_browse_terms.tsv')
terms.each_with_index do |line, i|
  author, count = line.chomp.split(/\t/)
  author.gsub! /\A\s+/, ''
  count = count.to_i
  @pool.post(author, count) do |a, c|
    find_and_print(a, c)
  end    
end



@pool.shutdown
@pool.wait_for_termination


