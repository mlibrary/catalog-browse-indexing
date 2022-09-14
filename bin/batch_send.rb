
require "pathname"
$LOAD_PATH.unshift (Pathname.new(__dir__).parent + "lib").to_s

require "zinzout"
require "faraday"
require "httpx/adapters/faraday"
require "authority_browse/connection"

url = ARGV.shift
filename = ARGV.shift
batch_size = (ARGV.shift || 1000).to_i

c = Faraday.new(request: {params_encoder: Faraday::FlatParamsEncoder}) do |builder|
  builder.use Faraday::Response::RaiseError
  builder.request :url_encoded
  builder.response :json
  builder.adapter :httpx
  builder.headers['Content-Type'] = 'application/json'
end

puts "#{url}||#{filename}||#{batch_size}"
Zinzout.zin(filename) do |infile|
  while batch = infile.take(batch_size)
    break if batch.empty?
    body = "[" << batch.join(",") << "]"
    resp = c.post(url, body, "Content-Type" => "application/json")
    print '.'
  end
end


