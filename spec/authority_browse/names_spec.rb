RSpec.describe AuthorityBrowse::Names do
  context ".reset_db" do
    it "fetches and loads a skos file into names and names see also" do
      # This stup has three lines. All of the lines have xrefs. The third is a
      # deprecated xref that has an identical match text to one of the others.
      # That deprecated one gets pruned from :names but doesn't get pruned from
      # :names_see_also
      file_fetcher_stub = lambda { `cp spec/fixtures/twain_skos2.json.gz scratch/names.skosrdf.jsonld.gz` }
      described_class.reset_db(file_fetcher_stub)
      expect(AuthorityBrowse.db[:names].count).to eq(2)
      expect(AuthorityBrowse.db[:names_see_also].count).to eq(5)
    end
  end
  context ".load_solr_with_matched" do
    it "loads the terms in the names db with counts into solr" do
      solr_uploader_double = instance_double(AuthorityBrowse::SolrUploader, upload: nil, commit: nil)
      names = AuthorityBrowse.db[:names]
      nsa = AuthorityBrowse.db[:names_see_also]

      names.insert(id: "id1", label: "First", match_text: "match", count: 1)
      names.insert(id: "id2", label: "Second", match_text: "match2", count: 2)
      names.insert(id: "id3", label: "Third", match_text: "match3", count: 3)
      names.insert(id: "id4", label: "Fourth", match_text: "match4", count: 0)
      nsa.insert(name_id: "id1", see_also_id: "id2")
      nsa.insert(name_id: "id1", see_also_id: "id3")
      described_class.load_solr_with_matched(solr_uploader_double)
      expect(solr_uploader_double).to have_received(:upload).with(
        [
          {
            id: "first\u001fname",
            loc_id: "id1",
            browse_field: "name",
            term: "First",
            see_also: ["Second||2", "Third||3"],
            count: 1,
            date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
          }.to_json + "\n",
          {
            id: "second\u001fname",
            loc_id: "id2",
            browse_field: "name",
            term: "Second",
            count: 2,
            date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
          }.to_json + "\n",
          {
            id: "third\u001fname",
            loc_id: "id3",
            browse_field: "name",
            term: "Third",
            count: 3,
            date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
          }.to_json + "\n"
        ]
      )
    end
  end
  context ".load_solr_with_unmatched" do
    it "sends solr the expected docs" do
      solr_uploader_double = instance_double(AuthorityBrowse::SolrUploader, upload: nil, commit: nil)
      nfb = AuthorityBrowse.db[:names_from_biblio]
      nfb.insert(term: "term1", count: 1, match_text: "match_text")
      nfb.insert(term: "term2", count: 2, match_text: "match_text")
      nfb.insert(term: "term3", count: 0, match_text: "no_items")
      nfb.insert(term: "term4", count: 4, match_text: "not_matchable")
      nfb.insert(term: "term5", count: 5, match_text: "has_a_match_text", name_id: "id1")
      described_class.load_solr_with_unmatched(solr_uploader_double)
      # TODO Should the counts for term1 and term2 both be 3?
      expect(solr_uploader_double).to have_received(:upload).with(
        [
          {
            id: "term1\u001fname",
            browse_field: "name",
            term: "term1",
            count: 1,
            date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
          }.to_json + "\n",
          {
            id: "term2\u001fname",
            browse_field: "name",
            term: "term2",
            count: 2,
            date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
          }.to_json + "\n",
          {
            id: "term4\u001fname",
            browse_field: "name",
            term: "term4",
            count: 4,
            date_of_index: Date.today.strftime("%Y-%m-%d") + "T00:00:00Z"
          }.to_json + "\n"
        ]
      )
    end
  end
  after(:each) do
    `rm scratch/*`
  end
end
