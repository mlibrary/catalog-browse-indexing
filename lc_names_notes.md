# Notes on the lcnas.skos.ndjson file

...as pulled from [the LoC id.loc.gov site](https://id.loc.gov/authorities/names.html).

There has _got_ to be documentation somewhere for these files. This is 
all just my guesses based on inspection.

Each record has two parts: a `@context` which is just repeated namespaces,
and `@graph` which has the good bits.

## The @graph

The `@graph` is a list of items, each identified by an `@id`.

* The "main" entry is the one that contains the k/v pairs
`"@type" => "skos:Concpet"` and 
`"skos:inScheme"=>{"@id"=>"http://id.loc.gov/authorities/names"}`. The `@id`
of that item gives the URI for this name.
* Not every item has a `@type`. Type are one of the following:
  * `skos:Concept`
  * `cs:ChangeSet`
  * `skosxl:Label`
* The following keys are present at the top level of an item:
  * @id
  * @type
  * cs:changeReason
  * cs:createdDate
  * cs:creatorName
  * cs:subjectOfChange
  * http://www.loc.gov/mads/rdf/v1#authoritativeLabel
  * http://www.loc.gov/mads/rdf/v1#hasCloseExternalAuthority
  * rdfs:seeAlso
  * skos:altLabel
  * skos:broader
  * skos:changeNote
  * skos:editorial
  * skos:exactMatch
  * skos:inScheme
  * skos:narrower
  * skos:note
  * skos:prefLabel
  * skos:related
  * skos:semanticRelation
  * skosxl:altLabel
  * skosxl:literalForm

## Breaking it down

We can probably ignore the change sets, change reasons, creator name/date, 
etc. Here's a sample record with all that stuff thrown out for readability:

```ruby

[{"@id"=>"http://id.loc.gov/authorities/names/n83199999",
  "@type"=>"skos:Concept",
  "http://www.loc.gov/mads/rdf/v1#hasCloseExternalAuthority"=>
   [{"@id"=>"http://id.worldcat.org/fast/119937"},
    {"@id"=>"http://id.worldcat.org/fast/1847633"},
    {"@id"=>"http://www.wikidata.org/entity/Q3961283"}],
  "skos:altLabel"=>
   ["Cascina, Simone da, -approximately 1420",
    "Simone, da Cascina, d. ca. 1420"],
  "skos:exactMatch"=>
   {"@id"=>"http://viaf.org/viaf/sourceID/LC%7Cn++83199999#skos:Concept"},
  "skos:inScheme"=>{"@id"=>"http://id.loc.gov/authorities/names"},
  "skos:prefLabel"=>"Simone, da Cascina, -approximately 1420",
  "skosxl:altLabel"=>
   [{"@id"=>"_:N9cca87c20c784c2da9835dc4c12a3566"},
    {"@id"=>"_:N2ad18edc62084ff39cc103bbeca89cf1"}]},
 
  
 {"@id"=>"_:N9cca87c20c784c2da9835dc4c12a3566",
  "@type"=>"skosxl:Label",
  "skosxl:literalForm"=>"Simone, da Cascina, d. ca. 1420"},
  
 {"@id"=>"_:N2ad18edc62084ff39cc103bbeca89cf1",
  "@type"=>"skosxl:Label",
  "skosxl:literalForm"=>"Cascina, Simone da, -approximately 1420"},
  
 {"@id"=>"http://www.wikidata.org/entity/Q3961283",
  "http://www.loc.gov/mads/rdf/v1#authoritativeLabel"=>
   "\"Simone da Cascina\" "},
  
 {"@id"=>"http://id.worldcat.org/fast/1847633",
  "http://www.loc.gov/mads/rdf/v1#authoritativeLabel"=>
   "\"Simone, da Cascina, -approximately 1420\" "},
  
 {"@id"=>"http://id.worldcat.org/fast/119937",
  "http://www.loc.gov/mads/rdf/v1#authoritativeLabel"=>
   "\"Simone, da Cascina, d. ca. 1420\" "}]

```

Let's take it one bit at a time:

```ruby
{"@id"=>"http://id.loc.gov/authorities/names/n83199999",
  "@type"=>"skos:Concept",
  "http://www.loc.gov/mads/rdf/v1#hasCloseExternalAuthority"=>
   [{"@id"=>"http://id.worldcat.org/fast/119937"},
    {"@id"=>"http://id.worldcat.org/fast/1847633"},
    {"@id"=>"http://www.wikidata.org/entity/Q3961283"}],
  "skos:altLabel"=>
   ["Cascina, Simone da, -approximately 1420",
    "Simone, da Cascina, d. ca. 1420"],
  "skos:exactMatch"=>
   {"@id"=>"http://viaf.org/viaf/sourceID/LC%7Cn++83199999#skos:Concept"},
  "skos:inScheme"=>{"@id"=>"http://id.loc.gov/authorities/names"},
  "skos:prefLabel"=>"Simone, da Cascina, -approximately 1420",
  "skosxl:altLabel"=>
   [{"@id"=>"_:N9cca87c20c784c2da9835dc4c12a3566"},
    {"@id"=>"_:N2ad18edc62084ff39cc103bbeca89cf1"}]}

```

Here we have the "main" entry (due to the `inscheme` being a name authority).
We get a `skos:prefLabel` and an array of `skos:altLabel`s. 

There are three close matches in other systems (two in FAST and one at wikidata) and one 
exact match at the VIAF. The close matches have corresponding entries at 
the bottom where they include a  `http://www.loc. gov/mads/rdf/v1#authoritativeLabel`, 
which are the same as the alt labels. No idea if that's always the case.

There's also _another_ set of alternate labels via
`skosxl:altLabel`, but those we need to find in other items in this entry's 
graph.

```ruby
 {"@id"=>"_:N9cca87c20c784c2da9835dc4c12a3566",
  "@type"=>"skosxl:Label",
  "skosxl:literalForm"=>"Simone, da Cascina, d. ca. 1420"},
  
 {"@id"=>"_:N2ad18edc62084ff39cc103bbeca89cf1",
  "@type"=>"skosxl:Label",
  "skosxl:literalForm"=>"Cascina, Simone da, -approximately 1420"},
```

In this example, the `skosxl:literalForm`s are (once again!) exactly the same 
as the `skos:altLabel`s. I have no idea if that's always the case and will 
have to write a script to find out (or find the damn documentation). 


## "See also" doesn't appear to be reciprocal

Here's the interesting bits of a record with a "see also" section.
Note how the referenced item is included (at least the prefLabel)
as another item on this entry.

```ruby

[{"@id"=>"http://id.loc.gov/authorities/names/no97009999",
  "@type"=>"skos:Concept",
  "rdfs:seeAlso"=>{"@id"=>"http://id.loc.gov/authorities/names/no97010003"},
  "skos:altLabel"=>
   "Reformed Church in the United States. Ohio Synod. Theological Seminary",
  "skos:editorial"=>"[Existed 1871-1872.]",
  "skos:prefLabel"=>
   "Theological Seminary of the Ohio Synod of the Reformed Church",
 },
 {"@id"=>"http://id.loc.gov/authorities/names/no97010003",
  "@type"=>"skos:Concept",
  "skos:prefLabel"=>"Heidelberg Theological Seminary"}]

```

OK, so it references no9101003. Let's look at that one.

```ruby
# no9101003

      "rdfs:seeAlso": {
        "@id": "http://id.loc.gov/authorities/names/no97010006"
      },


```

What the hell. How about _that_ one?

```ruby
#no9701008

"rdfs:seeAlso": {
    "@id": "http://id.loc.gov/authorities/names/n93084275"
  },

```

There's another record, `/no97010006`, that _also_ references `/no97010006`

Things finally peter out at `n93084275`. So, I guess it really is a graph, 
without reciprocal links, and we'll have to follow it all somehow.

## "Related"

And another, with both "see also" and "related." 

```ruby

[{"@id"=>"http://id.loc.gov/authorities/names/n80089995",
  "@type"=>"skos:Concept",
  "skos:prefLabel"=>"Rhodesia and Nyasaland"},
 
 {"@id"=>"http://id.loc.gov/authorities/names/n80089996",
  "@type"=>"skos:Concept",
  "skos:prefLabel"=>"Malawi"},
 
 {"@id"=>"http://id.loc.gov/authorities/names/n80089999",
  "@type"=>"skos:Concept",
  "rdfs:seeAlso"=>{"@id"=>"http://id.loc.gov/authorities/names/n80089996"},
  "skos:altLabel"=>["Nyasaland Protectorate", "Nʹi︠a︡saland"],
  "skos:exactMatch"=>
   {"@id"=>"http://viaf.org/viaf/sourceID/LC%7Cn++80089999#skos:Concept"},
  "skos:prefLabel"=>"Nyasaland",
  "skos:related"=>{"@id"=>"http://id.loc.gov/authorities/names/n80089995"},
  "skosxl:altLabel"=>
   [{"@id"=>"_:N46d60bf1ec734db09842b79760e3d9e7"},
    {"@id"=>"_:N477ac3756bbe44f6bb093697018e634c"}]},
 
 {"@id"=>"_:N46d60bf1ec734db09842b79760e3d9e7",
  "@type"=>"skosxl:Label",
  "skosxl:literalForm"=>"Nyasaland Protectorate"},
 
 {"@id"=>"_:N477ac3756bbe44f6bb093697018e634c",
  "@type"=>"skosxl:Label",
  "skosxl:literalForm"=>"Nʹi︠a︡saland"}]
```

Again the prefLabels are given us inline, without a need to look up 
anything in other parts of the file. 

## What do we want to extract?

Presumably:
* the URI
* all the labels, 
* the see also / related data, 
* the broader/ narrower terms
* URIs/URLs for the VIAF, wikidata, and FAST 

## Burning questions

* How to store all these data?
* How do we decide which of our 100/110/111 fields match which of these 
  entries?
* We've talked about displaying alt labels / see also in browse, but
should we be _indexing_ the alt labels? 
* I know some of our MARC records have URIs (or at least the unique ids)
in the 100/110. Can we use them for anything?
* Investigate:
  * Are the altLabels always the entire set of `skosxl:Label`s from 
    cross-linked items?
  * How many collisions are there among alt labels of different entries?
  