require "httpx/adapters/webmock"
require "solr/term_fetcher"
RSpec.describe Solr::TermFetcher do
  before(:each) do
    @params = {
      field: "author_authoritative_browse"
    }
  end
  subject do
    described_class.new(**@params) 
  end
  
  context "#params" do
    it "has expected params with default values" do
      expect(subject.params("my_last_value")).to eq(
        {
          :q => "*:*",
          "terms.limit" => 1_000,
          "terms.fl" => "author_authoritative_browse",
          "terms.lower" => "my_last_value",
          "terms.sort" => "index",
          "json.nl" => "arrarr",
          "terms.lower.incl" => "false",
          "terms" => "true"
        }
      )
    end
  end
  context "#get_batch" do
    it "returns the the terms field part of the response from solr" do
      params = subject.params("my_last_value")
      body = fixture("terms.json")
      stub_request(:get, ENV.fetch("BIBLIO_URL") + "/terms").with(query: params).
        to_return( body: body, headers: {content_type: "application/json"})
      expect(subject.get_batch("my_last_value")).to eq([
        ["Twain, Mark 1835-1910",3],
        ["Twain, Mark,",8],
        ["Twain, Mark, 1835-1910",1511],
        ["Twain, Matthew",1],
        ["Twain, Norman",1],
        ["Twain, Shania",6],
        ["Twainy, Fadi",1],
        ["Twait, Richard M",1],
        ["Twait, Rick",4],
        ["Twaite, Allison C., 1948-",1]]
                                                      )
    end
  end
  context "each" do
    it "returns expected values for one page of results" do
      params = subject.params("")
      body = fixture("terms.json")
      stub_request(:get, ENV.fetch("BIBLIO_URL") + "/terms").with(query: params).
        to_return( body: body, headers: {content_type: "application/json"})
      output = []
      subject.each do |val_count|
        output.push(val_count)
      end
      expect(output.first).to eq( ["Twain, Mark 1835-1910",3])
    end
    it "fetchs multiple pages of results" do
      @params[:batch_size] = 5
      params = subject.params("")
      second_page_params = subject.params("Twaite, Allison C., 1948-")
      body = fixture("terms.json")
      second_page_body = JSON.parse(body)
      second_page_body["terms"]["author_authoritative_browse"] = [[]]
      stub_request(:get, ENV.fetch("BIBLIO_URL") + "/terms").with(query: second_page_params).
        to_return( body: second_page_body.to_json, headers: {content_type: "application/json"})
      stub_request(:get, ENV.fetch("BIBLIO_URL") + "/terms").with(query: params).
        to_return( body: body, headers: {content_type: "application/json"})
      output = []
      subject.each do |val_count|
        output.push(val_count)
      end
      expect(output.first).to eq( ["Twain, Mark 1835-1910",3])
    end
  end
end
