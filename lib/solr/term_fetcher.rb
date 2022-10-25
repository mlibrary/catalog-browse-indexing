# frozen_string_literal: true

require "authority_browse/connection"

# Extract term/count pairs from the given solr core
# Output is tab-delimited lines of the form value\tcount

module Solr
  # Simple interface to get term/number-of-document pairs from the
  # /terms solr request handler
  class TermFetcher
    include Enumerable

    attr_accessor :url, :field, :query, :batch_size


    # @param [String] url URL to the _core_
    # @param [String] query Query over whose results to grab terms
    # @param [Integer] batch_size Number of terms to fetch at once
    # @param [String] start_at Only fetch after this term
    def initialize(url:, field:, query: '*:*', batch_size: 1_000, start_at: '')
      @url = url.chomp('/') + '/terms'
      @field = field
      @query = query
      @batch_size = batch_size
      @last_value = start_at
    end

    # @yieldreturn [Array<String,Integer>] Term/document-count pair
    def each
      return enum_for(:each) unless block_given?

      last_value = @last_value
      loop do
        pairs = get_batch(last_value)
        last_value = pairs.last.first
        pairs.each do |val_count|
          yield val_count
        end
        break if pairs.size < batch_size
      end
    end

    # @param [String, Integer, etc., nil] last_value Last seen term value
    # @return [Array<Array<Object, Integer>>] Batch of term/count pairs
    def get_batch(last_value)
      resp = connection.get(@url, params: params(last_value))
      resp.json["terms"][field]
            rescue => e
      require 'pry'; binding.pry

      
    end

    # Helper method to build up set of params to send to solr /term handler
    # @param [String, Integer, etc., nil] last_value Last seen term value
    # @return [Hash] Suitable set of solr parameters to start/continue term gathering
    def params(last_value)
      {q: query,
       "terms.limit" => batch_size,
       "terms.fl" => field,
       "terms.lower" => last_value,
       "terms.sort" => "index",
       "json.nl" => "arrarr",
       "terms.lower.incl" => "false",
       "terms" => "true"}
    end

    # @return [AuthorityBrowse::Connection] A new connection
    def connection
      @connection ||= AuthorityBrowse::Connection.new
    end

  end
end

