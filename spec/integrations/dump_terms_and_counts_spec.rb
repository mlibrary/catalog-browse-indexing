require_relative "../../bin/dump_terms_and_counts"
RSpec.describe TermFetcherWrapper do
  before(:each) do
    `mkdir -p tmp`
    @url = ENV.fetch("BIBLIO_URL")
    @field = "author_authoritative_browse"
    @output_file = "tmp/output.gz"
    @limit = -1
  end

  context ".run" do
    it "runs" do
      skip "Need to work on solr stuff"

      params =
        {
          :q => "*:*",
          "terms.limit" => 1_000,
          "terms.fl" => "author_authoritative_browse",
          "terms.lower" => "",
          "terms.sort" => "index",
          "json.nl" => "arrarr",
          "terms.lower.incl" => "false",
          "terms" => "true"
        }
      body = fixture("terms.json")
      stub_request(:get, ENV.fetch("BIBLIO_URL") + "/terms").with(query: params)
        .to_return(body: body, headers: {content_type: "application/json"})
      expect(!File.exist?(@output_file))
      described_class.run(@url, @field, @output_file, @limit)
      expect(File.exist?(@output_file))
    end
  end
  after(:each) do
    `rm tmp/output.gz`
  end
end
