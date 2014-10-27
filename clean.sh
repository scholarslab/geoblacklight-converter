#! /usr/bin/env bash

set -x

MODS_DIR="mods"
GEOSERVER_ROOT="http://gis.lib.virginia.edu/geoserver"
STACKS_ROOT="http://gis.lib.virginia.edu"
WORKDIR="geoblacklight"

make_dirs() {
  mkdir -p $MODS_DIR
  mkdir -p $WORKDIR
}

convert_mods() {
  for file in data/*.xml; do
    ofn="$WORKDIR/`basename $file`"
    if [ ! -r "$ofn" ]; then
      xsltproc xslt/iso2mods.xsl "$file" > "$ofn"
    fi
  done
}

convert_solr()
{
  for file in mods/*.xml; do
    ofn="$WORKDIR/`basename $file`"
    if [ ! -r "$ofn" ]; then
      xsltproc \
        -stringparam geoserver_root $GEOSERVER_ROOT \
        -stringparam now `date -u "+%Y-%m-%dT%H:%M:00Z"` \
        -stringparam rights "Public" \
        -stringparam stacks_root $STACKS_ROOT \
        xslt/mods2geoblacklight.xsl "$file" > "$ofn"
    fi
  done
}

cleanup() {
  rm -f data/*.xml
  rm -f mods/*.xml
  rm -f geoblacklight/*.xml
}

cleanup
ruby fetch-data.rb
convert_mods
convert_solr


exit $?

#ruby fetch-data.rb
#sh toMods.sh
#sh toSolr.sh
