#! /usr/bin/env bash
#export PATH='geoblacklight-schema/bin:$PATH'
set -x

GEOSERVER_ROOT="http://gis.lib.virginia.edu/geoserver"
STACKS_ROOT="http://gis.lib.virginia.edu"
WORKDIR="geoblacklight"

mkdir -p $WORKDIR

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

