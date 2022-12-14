
require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib").to_s

require "zinzout"
require "faraday"
require "httpx/adapters/faraday"
require "authority_browse/connection"
require "milemarker"

url = ARGV.shift
filename = ARGV.shift
batch_size = (ARGV.shift || 1000).to_i

unless url =~ /update/
  url = url.chomp("/") + "/update"
end


c = Faraday.new(request: {params_encoder: Faraday::FlatParamsEncoder}) do |builder|
  builder.use Faraday::Response::RaiseError
  builder.request :url_encoded
  builder.response :json
  builder.adapter :httpx
  builder.headers['Content-Type'] = 'application/json'
end

mm = Milemarker.new(batch_size: 100_000, name: "Docs sent to solr")
mm.create_logger!(STDERR)

mm.log "Sending #{filename} to #{url} in batches of #{batch_size}"
begin
Zinzout.zin(filename) do |infile|
  while batch = infile.take(batch_size)
    break if batch.empty?
    body = "[" << batch.join(",") << "]"
    resp = c.post(url, body, "Content-Type" => "application/json")
    mm.increment(batch_size)
    mm.on_batch { mm.log_batch_line }
  end
end
rescue => err

end
mm.log "Committing"
c.get(url, commit: "true")
mm.log "Finished"
mm.log_final_line

exit 0



