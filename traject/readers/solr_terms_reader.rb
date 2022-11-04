# frozen_string_literal: true

# Just yield lines of the file one at a time without the
# trailing newline

require "zinzout"
require "faraday"
require "httpx/adapters/faraday"

# Read newline-delimited JSON file, where each line is a marc-in-json string.
# UTF-8 encoding is required.

class Traject::SolrTermsReader
  include Enumerable

  attr_accessor :field

  # @param [File] input_stream Ignored
  # @param [Hash] settings Normal traject settings
  def initialize(input_stream, settings)
    @settings = settings
    @url = @settings["terms_reader.url"]
    @field = @settings["terms_reader.field"]
    unless @url && @field
      raise "Terms reader needs two settings: 'terms_reader.url' (to the core) and 'terms_reader.field'"
    end

    @batch = @settings["terms_reader.batch_size"] || 2_000
  end

  # @return [Faraday::Connection] A new connection
  def connection
    @connection ||= Faraday.new(request: {params_encoder: Faraday::FlatParamsEncoder}) do |builder|
      builder.use Faraday::Response::RaiseError
      builder.request :url_encoded
      # builder.request :retry
      builder.response :json
      builder.adapter :httpx
    end
  end

  def page_params(last_term)
    {
      "terms.fl" => @field,
      "terms.sort" => "index",
      "terms.limit" => @batch,
      "json.nl" => "arrarr",
      "terms.lower.incl" => false,
      "terms.lower" => last_term
    }
  end

  def fetch_batch(end_of_last_batch)
    resp = connection.get(@url + "/terms", page_params(end_of_last_batch))
    solr_response = resp.body
    solr_response["terms"][@field]
  end

  def logger
    @logger ||= (@settings[:logger] || Yell.new($stderr, level: "gt.fatal")) # null logger)
  end

  def each
    unless block_given?
      return enum_for(:each)
    end

    end_of_last_batch = ""

    loop do
      field_count_pairs = fetch_batch(end_of_last_batch)
      field_count_pairs.each { |x| yield x }
      end_of_last_batch = field_count_pairs.last.first
      break if field_count_pairs.size < @batch
    end
  end
end
