# frozen_string_literal: true

require "authority_browse/connection"

# Extract term/count pairs from the given solr core
# Output is tab-delimited lines of the form value\tcount

module Solr
  class TermFetcher
    include Enumerable

    attr_accessor :url, :field, :query, :batch_size

    def initialize(url:, field:, query: '*:*', batch_size: 1_000, start_at: '')
      @url = url.chomp('/') + '/terms'
      @field = field
      @query = query
      @batch_size = batch_size
      @last_value = start_at
    end

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

    def get_batch(last_value)
      resp = connection.get(@url, params: params(last_value))
      resp.json["terms"][field]
    end

    def params(last_value)
      {q: query,
       "terms.limit" => batch_size,
       "terms.fl" => field,
       "terms.lower" => last_value,
       "terms.sort" => "index",
       "json.nl" => "arrarr",
       "terms.lower.incl" => false}
    end

    # @return [AuthorityBrowse::Connection] A new connection
    def connection
      @connection ||= AuthorityBrowse::Connection.new
    end

  end
end

