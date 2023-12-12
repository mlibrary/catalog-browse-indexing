require "/app/lib/browse"

# uses cursorstream
# CallNumberBrowse::TermFetcher.run

# uses paging through results
CallNumberBrowse::TermFetcher.new.run_with_paging
