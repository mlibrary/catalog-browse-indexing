require "faraday"
require "httpx/adapters/faraday"

module AuthorityBrowse
  class TermFetcher
    attr_reader :mile_marker
    def initialize(field_name: "author_authoritative_browse", page_size: 10_000, logger: Logger.new($stdout))
      @milemarker = Milemarker.new(name: "loading names_from_biblio", batch_size: page_size, logger: logger)
      @logger = logger
      @field_name = field_name
      @page_size = page_size
      @query = "*:*"
      @table = AuthorityBrowse.db[:names_from_biblio]
    end

    def conn
      @conn ||= Faraday.new do |builder|
        builder.use Faraday::Response::RaiseError
        builder.request :url_encoded
        builder.request :json
        builder.request :authorization, :basic, "solr", "SolrRocks"
        builder.response :json
        builder.adapter :httpx
        builder.headers["Content-Type"] = "application/json"
      end
    end

    def payload(offset)
      {
        query: @query,
        limit: 0,
        facet: {
          @field_name => {
            type: "terms",
            field: @field_name,
            limit: @page_size,
            numBuckets: true,
            allBuckets: true,
            offset: offset,
            sort: "index asc"
          }
        }
      }
    end

    def get_batch(offset)
      url = ENV["BIBLIO_URL"].chomp("/") + "/select"
      resp = conn.post(url, payload(offset))
      resp.body&.dig("facets", @field_name, "buckets")
    end

    def load_batch(batch)
      @table.db.transaction do
        batch.each do |pair|
          match_text = AuthorityBrowse::Normalize.match_text(pair["val"])
          @table.insert(term: pair["val"], count: pair["count"], match_text: match_text)
          @milemarker.increment_and_log_batch_line
        end
      end
    end

    def run
      offset = 0
      @milemarker.log "Start"
      loop do
        batch = get_batch(offset)
        load_batch(batch)
        offset += @page_size
        break if batch.size < @page_size
      rescue => e
        @logger.error(e.message)
      end
      @milemarker.log_final_line
    rescue => e
      @logger.error(e.message)
    end
  end
end
