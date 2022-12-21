#!/bin/bash

local_dir=`dirname "${0}"`
bindir=`realpath ${local_dir}`
rootdir=`realpath "${bindir}/.."`
locdir="${rootdir}/data/LoC/source"

names_url="https://id.loc.gov/download/authorities/names.skosrdf.jsonld.gz"
subjects_url="https://id.loc.gov/download/authorities/subjects.skosrdf.jsonld.gz"

names_file="${locdir}/names.skosrdf.jsonld.gz"
subjects_file="${locdir}/subjects.skosrdf.jsonld.gz"

db="${rootdir}/data/authorities.db"
subjects_dumpfile="${rootdir}/data/subjects/subjects.jsonl.gz"

#echo
#echo "Getting ${names_file}"
#echo
#curl -L "${names_url}" -o "${names_file}"
#
#echo
#echo "Getting ${subjects_file}"
#curl -L "${subjects_url}" -o "${subjects_file}"
#echo

cd "${rootdir}"

echo
echo "Generating dumpfile for subjects"
bundle exec ruby "${bindir}/subjects/skos_to_dumpfile.rb" "${subjects_file}" "${subjects_dumpfile}"

echo
echo "Generating ${db} from names skos file"
bundle exec ruby "${bindir}/names/skos_to_db.rb" "${names_file}" "${db}"


echo
echo
