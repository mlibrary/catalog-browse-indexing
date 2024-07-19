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

    # Faraday connection for connecting to Biblio Solr
    #
    # @return [Faraday::Connection]
    def conn
      @conn ||= Faraday.new do |builder|
        builder.use Faraday::Response::RaiseError
        builder.request :url_encoded
        builder.request :json
        builder.response :json
        builder.adapter :httpx
        builder.headers["Content-Type"] = "application/json"
        if S.biblio_solr_cloud_on?
          builder.request :authorization, :basic, S.solr_user, S.solr_password
        end
      end
    end

    # Body to send to Solr when looking for page of facets and counts.
    # numBuckets shows the number of facet entries there are total.
    #
    # @param offset [Integer] Where to start looking for records
    # @param page_size [Integer] How many facets should solr return
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

    # Biblio Url
    #
    # @return [String]
    def url
      @url ||= S.biblio_solr.chomp("/") + "/select"
    end

    # Given a starting point, return a list of facets and their counts
    #
    # @param offset [Integer] Where should the page of results start?
    # @return [Array<Hash>] Array of facets and counts
    def get_batch(offset)
      resp = conn.post(url, payload(offset))
      resp.body&.dig("facets", @field_name, "buckets")
    end

    # Given an Array with facet and count info, load that batch of information
    # into the :_from_biblio table
    #
    # @param batch [Array<Hash>] Each hash has a key `val` with a term, and a `count`
    def load_batch(batch)
      @table.db.transaction do
        batch.each do |pair|
          match_text = AuthorityBrowse::Normalize.match_text(pair["val"])
          @table.insert(term: pair["val"], count: pair["count"], match_text: match_text)
          @milemarker.increment_and_log_batch_line
        end
      end
    end

    # @retrun Concurrent::ThreadPoolExecutor
    def pool
      @pool ||= Concurrent::ThreadPoolExecutor.new(
        min_threads: @threads,
        max_threads: @threads,
        # max_queue: 0 means unlimited items in the queue. This is so we don't lose any
        # work when shutting down.
        max_queue: 0,
        # fallback_policy is probably unnessary here but it won't hurt to set is explictly
        fallback_policy: :caller_runs
      )
    end

    # Fetch all of the facets and load them into the :_from_biblio table
    #
    # @param pool_instance [Concurrent::ThreadPoolExecutor] Threadpool
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
