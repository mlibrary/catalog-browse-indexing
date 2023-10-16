# frozen_string_literal: true

require "delegate"
require "faraday"
require "httpx/adapters/faraday"

module AuthorityBrowse
  class SolrUploader
    def initialize(collection:)
      @conn = Faraday.new(request: {params_encoder: Faraday::FlatParamsEncoder}) do |builder|
        builder.use Faraday::Response::RaiseError
        builder.request :json
        builder.request :authorization, :basic, "solr", "SolrRocks"
        builder.response :json
        builder.adapter :httpx
        builder.headers["Content-Type"] = "application/json"
      end
      @endpoint = "#{ENV.fetch("SEARCH_SOLR_URL")}/#{collection}/update"
    end

    # Uploads docs to solr
    # @param docs [Array] Array of json strings  of docs
    def upload(docs)
      body = "[" + docs.join(",") + "]"
      @conn.post(@endpoint, body)
    end

    def commit
      @conn.get(@endpoint, commit: "true")
    end
  end

  class Connection < SimpleDelegator
    attr_reader :conn
    # A basic solr connection with url encoding and json handling
    def initialize
      @conn = HTTPX.with(timeout: {connect_timeout: 60})
      __setobj__(@conn)
      yield self if block_given?
    end
  end

  # class SolrUploader < Connection
  # attr_accessor :url, :threads, :batch_size

  # def initialize(url: nil, threads: 3, batch_size: 100)
  # super()
  # @url = url.chomp("/") + "/update"
  # @batch = []
  # @batch_size = batch_size
  # @threads = threads
  # end

  # def add(future)
  # @batch << future
  # if @batch.size == batch_size
  # to_send = @batch.dup
  # @batch = []
  # send_to_solr(to_send)
  # end
  # end

  # def send_to_solr(docs)
  # conn.post(@url, json: docs.map(&:value!))
  # end

  # def send_dregs_and_close
  # send_to_solr(@batch)
  # conn.get(@url, params: {commit: true})
  # @batch = []
  # end
  # end
end
