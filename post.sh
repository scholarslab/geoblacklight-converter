#! /usr/bin/env bash

DATA_DIR="$1"
if [ -z "${DATA_DIR}" ]; then
  echo "Please give the path to the geoblacklight xml or json files (edu.virginia)"
  exit 0
fi

#local_solr="http://localhost:8983/solr/update"
local_solr="http://libsvr40.lib.virginia.edu:8080/solrgis/gis/update"
#local_solr="http://192.168.33.23:8080/solr/update"
SOLR_URL=$local_solr


add_docs()
{
  for file in $(find $DATA_DIR -name "geoblacklight.xml"); do
    echo "Posting $f to Solr"
    curl "$SOLR_URL" --data-binary "@$file" -H 'Content-type:text/xml; charset=utf-8'
  done
}

add_json()
{
  for file in $(find $DATA_DIR -name "geoblacklight.json"); do
    echo "Posting $file to Solr ..."
    # libsvr40
    curl "$SOLR_URL/?commit=true" --data-binary "[$( < $file)]" -H 'Content-type:application/json'
    # local
    #curl "$SOLR_URL/json?commit=true" -H 'Content-type:application/json' -d "[$(< $file)]"
  done
}

optimize()
{
  curl $SOLR_URL --data-binary '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
  echo "Optimizing"
  curl $SOLR_URL --data-binary '<optimize/>' -H 'Content-type:text/xml; charset=utf-8'
}

clean()
{
  echo "Clearing Solr docs"
  curl $SOLR_URL -H "Content-Type: text/xml" --data-binary '<delete><query>*:*</query></delete>'
}

# Clear out the Solr index
clean

# Uncomment the format used to update Solr
#add_docs
add_json

# Optimize Solr
optimize
