RSpec.describe AuthorityBrowse::TermFetcher do
  before(:each) do
    @params = {
      field_name: "author_browse_terms",
      table: :names_from_biblio,
      database_klass: AuthorityBrowse::DB::Names,
      page_size: 3,
      logger: instance_double(Logger, info: nil),
      threads: 1
    }
  end
  subject do
    described_class.new(**@params)
  end
  context "#payload" do
    it "has the expected payload" do
      expect(subject.payload(10)).to eq({
        query: "*:*",
        limit: 0,
        facet: {
          @params[:field_name] => {
            type: "terms",
            field: @params[:field_name],
            limit: @params[:page_size],
            numBuckets: true,
            allBuckets: true,
            offset: 10,
            sort: "index asc"
          }
        }
      })
    end
  end
  context "#load_batch(batch)" do
    it "loads a batch of terms into names_from_biblio" do
      batch = [
        {
          "val" => "First Term",
          "count" => 1
        },
        {
          "val" => "Second Term",
          "count" => 5
        },
        {
          "val" => "Third Term",
          "count" => 10
        }
      ]
      nfb = AuthorityBrowse.db[:names_from_biblio]
      subject.load_batch(batch)
      expect(nfb.filter(term: "First Term")&.first&.[](:count)).to eq(1)
      expect(nfb.count).to eq(3)
    end
  end
  context "#get_batch(offset)" do
    it "returns array of terms and counts" do
      body = fixture("term_fetcher_page.json")
      stub_request(:post, S.biblio_solr + "/select")
        .with(body: subject.payload(0))
        .to_return(body: body, headers: {content_type: "application/json"})
      expect(subject.get_batch(0)).to eq(
        [
          {
            "val" => "First Term",
            "count" => 1
          },
          {
            "val" => "Second Term",
            "count" => 5
          },
          {
            "val" => "Third Term",
            "count" => 10
          }

        ]
      )
    end
  end
  context "#run" do
    it "loads all terms into names from biblio" do
      body = fixture("term_fetcher_page.json")
      second_page = JSON.parse(body)
      second_page["facets"]["author_browse_terms"]["buckets"] = [
        {
          "val" => "z",
          "count" => 3
        }
      ]

      pool_stub = instance_double(Concurrent::ThreadPoolExecutor, shutdown: nil, wait_for_termination: nil)
      [0, 3].each do |offset|
        allow(pool_stub).to receive(:post).with(offset).and_yield(offset)
      end

      stub_request(:post, S.biblio_solr + "/select")
        .with(body: subject.payload(0, 0))
        .to_return(body: body, headers: {content_type: "application/json"})

      stub_request(:post, S.biblio_solr + "/select")
        .with(body: subject.payload(0))
        .to_return(body: body, headers: {content_type: "application/json"})

      stub_request(:post, S.biblio_solr + "/select")
        .with(body: subject.payload(3))
        .to_return(body: second_page.to_json, headers: {content_type: "application/json"})
      nfb = AuthorityBrowse.db[:names_from_biblio]

      subject.run(pool_stub)

      expect(nfb.filter(term: "First Term").first[:count]).to eq(1)
      expect(nfb.count).to eq(4)
    end
  end
end
