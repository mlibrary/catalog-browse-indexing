module CallNumberBrowse
  class TermFetcher
    def initialize(page_size: 10_000)
      @page_size = page_size
    end

    def pool
      @pool ||= Concurrent::ThreadPoolExecutor.new(
        min_threads: @threads,
        max_threads: @threads,
        max_queue: 200,
        fallback_policy: :caller_runs
      )
    end

    def run_with_paging(pool_instance = pool)
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

    def call_number_field
      self.class.call_number_field
    end

    def solr_docs_file
      self.class.solr_docs_file
    end

    def payload(offset, page_size = @page_size)
      {
        q: "*:*",
        rows: page_size,
        start: offset,
        fl: "id,#{call_number_field}",
        fq: "callnumber_browse:[* TO *]"
      }
    end

    def get_batch(offset)
      resp = conn.get(url, payload(offset))
      resp.body&.dig("response", "docs")
    end

    def url
      @url ||= S.biblio_solr.chomp("/") + "/select"
    end

    class << self
      def call_number_field
        "callnumber_browse"
      end

      def solr_docs_file
        S.solr_docs_file
      end

      def run
        milemarker = Milemarker.new(name: "write solr docs to file", logger: S.logger, batch_size: 5000)
        cs = Solr::CursorStream.new(url: S.biblio_solr, fields: ["id", call_number_field], filters: "#{call_number_field}:[* TO *]")
        milemarker.log "Start writing call number docs!"
        Zinzout.zout(solr_docs_file) do |out|
          while (bibdocs = cs.take(5000))
            bibdocs.each do |doc|
              # cs.each_with_index do |doc, i|
              # break if i > 50
              milemarker.increment_and_log_batch_line
              out.puts CallNumberBrowse::SolrDocument.for(doc).to_solr_doc
            end
          end
          milemarker.log_final_line
        end
      end
    end
  end
end
