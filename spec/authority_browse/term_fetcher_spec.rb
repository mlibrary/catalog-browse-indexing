RSpec.describe AuthorityBrowse::TermFetcher do
  before(:each) do
    @params = {
      field_name: "author_authoritative_browse",
      page_size: 3,
      logger: instance_double(Logger, info: nil)
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
      expect(nfb.filter(term: "First Term").first[:count]).to eq(1)
      expect(nfb.count).to eq(3)
    end
  end
  context "#get_batch(offset)" do
    it "returns array of terms and counts" do
      body = fixture("term_fetcher_page.json")
      stub_request(:post, ENV.fetch("BIBLIO_URL") + "/select")
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
      second_page["facets"]["author_authoritative_browse"]["buckets"] = [
        {
          "val" => "z",
          "count" => 3
        }
      ]

      stub_request(:post, ENV.fetch("BIBLIO_URL") + "/select")
        .with(body: subject.payload(0))
        .to_return(body: body, headers: {content_type: "application/json"})

      stub_request(:post, ENV.fetch("BIBLIO_URL") + "/select")
        .with(body: subject.payload(3))
        .to_return(body: second_page.to_json, headers: {content_type: "application/json"})
      nfb = AuthorityBrowse.db[:names_from_biblio]

      subject.run
      expect(nfb.filter(term: "First Term").first[:count]).to eq(1)
      expect(nfb.count).to eq(4)
    end
  end
end
