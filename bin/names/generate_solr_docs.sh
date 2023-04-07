#!/bin/bash

local_dir=`dirname "${0}"`
bindir=`realpath ${local_dir}/..`
rootdir=`realpath "${bindir}/.."`
locdir="${rootdir}/data/LoC"

today=`date +"%Y%m%d"`
namesdir="${rootdir}/data/names/${today}"

mkdir -p $namesdir
aab="${namesdir}/aab.tsv.gz"
db="${rootdir}/data/authorities.db"
matched="${namesdir}/matched.jsonl.gz"
unmatched="${namesdir}/unmatched.jsonl.gz"

biblio_url="http://bulleit-1:8026/solr/biblio"
name_field="author_authoritative_browse"

echo "Exporting ${name_field} stats from biblio into ${aab}"
#bundle exec ruby "${bindir}/dump_terms_and_counts.rb" "${biblio_url}" "${name_field}" "${aab}"
bundle exec ruby "${bindir}/names/add_counts_to_db_and_dump_unmatched_as_solr.rb"  "${aab}" "${db}" "${unmatched}"
bundle exec ruby "${bindir}/names/unify_counts_with_xrefs_and_dump_matches_as_solr.rb "${db}" "${matched}"

