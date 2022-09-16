module AuthorityBrowse
  # Keep track of only what we need for a cross-reference:
  # the loc id, its label, the sort- and search-keys, and a count
  class GenericXRef

    attr_reader :id, :label
    attr_reader :count

    GXF = self.name.freeze

    def initialize(label:, id:, count: 0)
      @label = label
      @id = id
      @count = count
    end

    # Count defaults to 0, not nil

    def count=(cnt)
      @count = cnt || 0
    end

    def search_key
      AuthorityBrowse::Normalize.search_key(label)
    end

    def sort_key
      AuthorityBrowse::Normalize.sort_key(label)
    end

    def to_json(*args)
      {
        id: id,
        label: label,
        count: count,
        sort_key: sort_key,
        AuthorityBrowse::JSON_CREATE_ID => GXF
      }.to_json(*args)
    end

    def self.json_create(rec)
      self.new(id: rec["id"], label: rec["label"], count: rec["count"])
    end

  end
end

