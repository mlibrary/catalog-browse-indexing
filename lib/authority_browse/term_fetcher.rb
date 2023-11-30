require "concurrent"
require "faraday"
require "httpx/adapters/faraday"

module AuthorityBrowse
  class TermFetcher
    attr_reader :mile_marker
    def initialize(field_name:, table:, database_klass:, page_size: 10_000, logger: Services.logger, threads: 4)
      @milemarker = Milemarker.new(name: "loading #{table}", batch_size: page_size, logger: logger)
      @threads = threads
      @logger = logger
      @field_name = field_name
      @page_size = page_size
      @query = "*:*"
      @table_name = table
      @db_klass = database_klass
      @table = AuthorityBrowse.db[table]
    end

    def conn
      @conn ||= Faraday.new do |builder|
        builder.use Faraday::Response::RaiseError
        builder.request :url_encoded
        builder.request :json
        # builder.request :authorization, :basic, S.solr_user, S.solr_password
        builder.response :json
        builder.adapter :httpx
        builder.headers["Content-Type"] = "application/json"
      end
    end

    def payload(offset, page_size = @page_size)
      {
        query: @query,
        limit: 0,
        facet: {
          @field_name => {
            type: "terms",
            field: @field_name,
            limit: page_size,
            numBuckets: true,
            allBuckets: true,
            offset: offset,
            sort: "index asc"
          }
        }
      }
    end

    def url
      @url ||= S.biblio_solr.chomp("/") + "/select"
    end

    def get_batch(offset)
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

    def pool
      @pool ||= Concurrent::ThreadPoolExecutor.new(
        min_threads: @threads,
        max_threads: @threads,
        max_queue: 200,
        fallback_policy: :caller_runs
      )
    end

    def run(pool_instance = pool)
      @db_klass.recreate_table!(@table_name)
      resp = conn.post(url, payload(0, 0))
      count = resp.body&.dig("facets", @field_name, "numBuckets")
      @milemarker.log "Start"
      @milemarker.threadsafify!
      (0..count).step(@page_size) do |o|
        pool_instance.post(o) do |offset|
          batch = get_batch(offset)
          load_batch(batch)
        end
      end
      pool_instance.shutdown
      pool_instance.wait_for_termination
      @milemarker.log_final_line
    end
  end
end
