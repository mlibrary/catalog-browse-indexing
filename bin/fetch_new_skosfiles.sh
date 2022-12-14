#!/bin/bash

local_dir=`dirname "${0}"`
bindir=`realpath ${local_dir}`
rootdir=`realpath "${bindir}/.."`
locdir="${rootdir}/data/LoC/source"



names_url="https://id.loc.gov/download/authorities/names.skosrdf.jsonld.gz"
subjects_url="https://id.loc.gov/download/authorities/subjects.skosrdf.jsonld.gz"

names_file="${locdir}/names.skosrdf.jsonld.gz"
subjects_file="${locdir}/subjects.skosrdf.jsonld.gz"

echo "Getting ${names_file}"
curl -L "${names_url}" > "${names_file}"

echo "Getting ${subjects_file}"
curl -L "${subjects_url}" > "${subjects_file}"

