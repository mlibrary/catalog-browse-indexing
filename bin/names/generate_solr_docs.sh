#!/bin/bash

local_dir=`dirname "${0}"`

# the directory with scripts
bindir=`realpath ${local_dir}/..`

# the root directory
rootdir=`realpath "${bindir}/.."`

# the library of congress info directory
locdir="${rootdir}/data/LoC"

today=`date +"%Y%m%d"`
namesdir="${rootdir}/data/names/${today}"

mkdir -p $namesdir

#aab = author authoritative browse" 
aab="${namesdir}/aab.tsv.gz"

# this is a seqel db 
db="${rootdir}/data/authorities.db"

# this is matched something or other
matched="${namesdir}/matched.jsonl.gz"

# this is unmatched something or other
unmatched="${namesdir}/unmatched.jsonl.gz"

# this is a field in biblio
name_field="author_authoritative_browse"

echo "Exporting ${name_field} stats from biblio into ${aab}"
bundle exec ruby "${bindir}/dump_terms_and_counts.rb" "${BIBLIO_URL}" "${name_field}" "${aab}"
#bundle exec ruby "${bindir}/names/add_counts_to_db_and_dump_unmatched_as_solr.rb"  "${aab}" "${db}" "${unmatched}"
#bundle exec ruby "${bindir}/names/unify_counts_with_xrefs_and_dump_matches_as_solr.rb "${db}" "${matched}"
