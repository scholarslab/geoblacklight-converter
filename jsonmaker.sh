#!/usr/bin/env bash

DATA_DIR="$1"
if [ -z "${DATA_DIR}" ]; then
  echo "Please give the path to the geoblacklight xml or json files (edu.virginia)"
  exit 0
fi

make_json()
{
  for file in $(find $DATA_DIR -name "iso19139.xml"); do
    path=$(dirname $file)
    xsltproc xslt/iso2json.xsl $file > "$path/geoblacklight.json"
  done
}

fix_json()
{
  for file in $(find $DATA_DIR -name "geoblacklight.json"); do
    sed -i'' -e '1s/^/{ "add": { "doc": /' $file
    echo "} }" >> $file
  done
}


# Run the command to create the json files from the xml files
make_json

# Then run the command to add in the heading and ending for upload to solr.
#fix_json
