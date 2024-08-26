# SolrCloud::Connection

Do basic administrative tasks on a running Solr cloud instance, including:

* create (i.e., upload) a configSet when given a `conf` directory
* list, create, and delete configsets, collections, and aliases
* get basic version information for the running solr
* check on the health of individual collections
* treat an alias (mostly) as a collection
* TODO automatically generate methods to talk to defined requestHandlers
* TODO Add something useful for configsets to do

In almost all cases, you can treat an alias to a collection like the underlying collection. 

## A note about deleting things

Collections, aliases, and configsets all have a `#delete!` method. Keep in mind that solr 
enforces a rule that nothing in-use can be deleted. This gem will throw appropriate errors
if you try to delete a configset that's being used by a collection, or try to delete
a collections that's pointed to by an alias.

## Caveats

* At this point the API is unstable
* Performance is desperately, hilariously terrible. Solr has no sense of an atomic action and plenty of other ways
  (e.g, the admin interface) to mess with things, so nothing is cached. 
  This means that individual actions can involve several round-trips to solr. If you're doing so much admin
  that this becomes a bottleneck, you're well outside this gem's target case.
* While solr aliases can point to more than one collection at a time, this gem enforces one collection
  per alias (although many aliases can point to the same collection)

## Usage

The code below covers all the basics. See the docs for full sets of parameters, which errors are
thrown, etc. 

```ruby

require "solr_cloud/connection"

server = SolrCloud::connect.new(url: "http://localhost:8023", username: "user", password: "password")
#    #=> <SolrCloud::Connection http://localhost:8023/>

# or bring your own Faraday object
# server = SolrCloud::connect.new_with_faraday(faraday_connection)

server.configset_names #=> ["_default"]
default = server.get_configset("_default") #=> <SolrCloud::Configset '_default' at http://localhost:8983>

# Create a new one by taking a directory, zipping it up, and sending it to solr
cset = server.create_configset(name: "my_awesome_configset_for_cars", confdir: "/path/to/mycore/conf")
server.configset_names #=> ["_default", "my_awesome_configset_for_cars"]

# That's a dumb name. We'll try again.
cset.delete!
cset = server.create_configset(name: "cars_config", confdir: "/path/to/mycore/conf")

# Collections and aliases are mostly treated the same
server.collection_names #=> ["cars_v1", "cars_v2", "cars"] -- collections AND aliases
server.only_collection_names #=> ["cars_v1", "cars_v2"]
server.alias_names #=> ["cars"]

typo = server.get_collection("cars__V2") #=> nil, doesn't exist
cars_v2 = server.get_collection("cars_v2")

cars_v2.alive? #=> true
cars_v2.count #=> 133 -- we're assuming there's stuff in it.


# Find out about its aliases, if any
cars_v2.alias? #=> false. It's a true collection
cars_v2.aliased? #=> true
cars_v2.aliases #=> [<SolrCloud::Alias "cars" (alias of "cars_v2")> ]
cars_v2.has_alias?("cars") #=> true

cars_v2.delete! #=> SolrCloud::CollectionAliasedError: Collection 'cars_v2' can't be deleted; it's in use by aliases ["cars"]

# Make a new collection
cars_v3 = server.create_collection(name: "cars_v3", configset: "cars_config")
cars_v3.aliased? #=> false
cars_v3.count #=> 0
cars_v3.configset #=> <SolrCloud::Configset 'cars_config' at http://localhost:8023>

# Work directly with an alias as if it's a collection
cars = server.get_collection("cars")
cars.alias? #=> true
cars.collection #=> <SolrCloud::Collection 'cars_v2' (aliased by 'cars')>

# Make a new alias to v2
old_cars = cars_v2.alias_as("old_cars") #=> <SolrCloud::Alias "old_cars" (alias of "cars_v2")>
cars_v2.aliases #=> [<SolrCloud::Alias "cars" (alias of "cars_v2")>, <SolrCloud::Alias "old_cars" (alias of "cars_v2")>]

# Now lets point the "cars" alias at cars_v3
cars.switch_collection_to cars_v3

cars.collection.name #=> "cars_v3"
cars_v2.alias_names #=> ["old_cars"]

# cars_v1 isn't doing anything for us anymore. Ditch it.
cars_v1.delete!

```

## Documentation

Run `bundle exec rake docs` to generate the documentation in `docs/`

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add solr_cloud-connection

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install solr_cloud-connection

## Testing

This repository is set up to run tests under docker.

1. docker compose build
2. docker compose run app bundle install
3. docker compose up
4. docker compose run app bundle exec rspec

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mlibrary/solr_cloud-connection.
