#! /usr/bin/env bash

DATA_DIR="$1"
#local_solr="http://localhost:8983/solr/update"
#SOLR_URL=${$1:-local_solr}
#local_solr="http://geoblacklight.lib.virginia.edu/solr/geoblacklight/update"
local_solr="http://libsvr40.lib.virginia.edu:8080/solrgis/gis"
SOLR_URL=$local_solr


add_docs()
{
  for file in edu.virginia/**/geoblacklight.xml; do
    echo "Posting $f to $SOLR_URL..."
    curl "$SOLR_URL" --data-binary "@$file" -H 'Content-type:text/xml; charset=utf-8'
  done
}

add_json()
{
  for file in $(find $DATA_DIR -name "geoblacklight.json"); do
    echo "Posting $file to $SOLR_URL ..."
   echo " curl "$SOLR_URL/update/?commit=true" --data-binary "@$file" -H 'Content-type:application/json'"
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

#clean
#add_docs
add_json
#optimize
