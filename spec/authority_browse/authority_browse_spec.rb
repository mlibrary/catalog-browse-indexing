RSpec.describe AuthorityBrowse do
  context "#load_terms_db" do
    it "loads terms and counts into the names table of the terms_db" do
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
      described_class.load_terms_db
      expect(AuthorityBrowse.terms_db[:names].count).to eq(10)
      first = AuthorityBrowse.terms_db[:names].first
      expect(first[:term]).to eq("Twain, Mark 1835-1910")
      expect(first[:count]).to eq(3)
      expect(first[:in_authority_graph]).to eq(false)
    end

  end
end
