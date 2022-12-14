#!/bin/bash

local_dir=`dirname "${0}"`
bindir=`realpath ${local_dir}/..`
rootdir=`realpath "${bindir}/.."`
locdir="${rootdir}/data/LoC"
namesdir="${rootdir}/data/names"
subjectsdir="${rootdir}/data/subjects"

aab="${namesdir}/aab.tsv.gz"
db="${rootdir}/data/authorities.db"

biblio_url="http://bulleit-1:8026/solr/biblio"
name_field="author_authoritative_browse"

echo "Getting ${name_field} stats into ${aab}"
bundle exec ruby "${bindir}/dump_terms_and_counts.rb" "${biblio_url}" "${name_field}" "${aab}"
bundle exec ruby "${bindir}/names/add_counts_to_db_and_dump_unmatched_as_solr.rb"  "${aab}" "${db}" "${namesdir}/unmatched.jsonl.gz"
bundle exec ruby "${bindir}/names/unify_counts_with_xrefs_and_dump_matches_as_solr.rb "${db}" "${namesdir}/matched.jsonl.gz"
