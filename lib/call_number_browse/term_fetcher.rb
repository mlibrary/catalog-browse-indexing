module CallNumberBrowse
  class TermFetcher
    def initialize(page_size: 10_000)
      @page_size = page_size
    end

    # @retrun Concurrent::ThreadPoolExecutor
    def pool
      @pool ||= Concurrent::ThreadPoolExecutor.new(
        min_threads: @threads,
        max_threads: @threads,
        max_queue: 200,
        fallback_policy: :caller_runs
      )
    end

    # Fetch all of the call numbers and their ids, turn them into solr docs,
    # and write them to a file
    #
    # @param pool_instance [Concurrent::ThreadPoolExecutor] Threadpool
    def run(pool_instance = pool)
      milemarker = Milemarker.new(name: "write solr docs to file", logger: S.logger, batch_size: @page_size)
      milemarker.log "Start writing call number docs!"
      milemarker.threadsafify!
      lock = Concurrent::ReadWriteLock.new
      resp = conn.get(url, payload(0, 0))
      count = resp.body&.dig("response", "numFound")
      Zinzout.zout(solr_docs_file) do |out|
        (0..count).step(@page_size) do |o|
          pool_instance.post(o) do |offset|
            batch = get_batch(offset)
            lock.with_write_lock do
              batch.each do |doc|
                out.puts CallNumberBrowse::SolrDocument.for(doc).to_solr_doc
                milemarker.increment_and_log_batch_line
              end
            end
          end
        end
      end
      milemarker.log_final_line
      pool_instance.shutdown
      pool_instance.wait_for_termination
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
      end
    end

    # Field to look for call number entries
    def call_number_field
      "callnumber_browse"
    end

    # Filepath for writing solr docs before uploading to Solr
    def solr_docs_file
      S.solr_docs_file
    end

    # URL params to send to solr when looking for a page of results. This only returns the id and `call_number_field`
    # @param offset [Integer] Where to start looking for records
    # @param page_size [Integer] How many rows should solr return
    def payload(offset, page_size = @page_size)
      {
        q: "*:*",
        rows: page_size,
        start: offset,
        fl: "id,#{call_number_field}",
        fq: "callnumber_browse:[* TO *]"
      }
    end

    # Given a starting point, return a list of callnumbers and their ids
    #
    # @param offset [Integer] Where should the page of results start?
    # @return [Array<Hash>] Array of facets and counts
    def get_batch(offset)
      resp = conn.get(url, payload(offset))
      resp.body&.dig("response", "docs")
    end

    # Biblio Url
    #
    # @return [String]
    def url
      @url ||= S.biblio_solr.chomp("/") + "/select"
    end
  end
end
