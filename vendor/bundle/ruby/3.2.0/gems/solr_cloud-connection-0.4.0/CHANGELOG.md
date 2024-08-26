# Changelog

## [0.4.0] - 2023-12-07
- Fixed rules about what names are legal collections/configsets/aliases
- Update version and changelog

## [0.3.0] - 2023-12-06

- Major overhaul of the interface to use more-explicit and less-confusing method names
- Remove code that tried to "version" collections and configsets, since it was dumb
- Get github actions working to run tests
- Make aliases even more of a paper-thin wrapper around collections, such that, e.g.
  `coll = get_collection(alias_name)` will return the appropriate alias. Use
  `coll.alias?` to determine if it's an alias or collection if that becomes important.

## [0.2.0] - 2023-12-01

- Added options `:date` and `:datetime` to the `version:` argument to `create_collection`
  to automatically generate, e.g., "2023-12-01" or "2023-12-01-09-50-56" 
- Added utility method `legal_solr_name?` to check for validity for collection names

## [0.1.0] - 2023-11-29

- Initial release
