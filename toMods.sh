#! /usr/bin/env bash
#export PATH='geoblacklight-schema/bin:$PATH'
set -x

WORKDIR="mods"

mkdir -p $WORKDIR

for file in data/*.xml; do
  ofn="$WORKDIR/`basename $file`"
  if [ ! -r "$ofn" ]; then
    xsltproc xslt/iso2mods.xsl "$file" > "$ofn"
  fi
done
