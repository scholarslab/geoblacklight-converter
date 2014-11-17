#! /usr/bin/env bash

#set -x

ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

MODS_DIR="mods"
GEOB_DIR="geoblacklight"
DATA_DIR="data"
ISOS_DIR="layers"
GEOSERVER_ROOT="http://gis.lib.virginia.edu/geoserver"
STACKS_ROOT="http://gis.lib.virginia.edu"

make_dirs() {
  echo "${COL_CYAN}Making data directories... $COL_RESET"
  mkdir -p {$MODS_DIR,$GEOB_DIR,$DATA_DIR,$ISOS_DIR}
}

breakout_layers() {
    for file in $DATA_DIR/*.xml; do
        # create partial path and filename for new files.
        # get just the filename with basename, and remove .xml from the end
        ofn="$ISOS_DIR/$(basename "${file%.xml}")"
        if [ ! -r "$ofn" ]; then
            echo "$COL_GREEN Breaking out ${COL_BLUE}layers$COL_GREEN from$COL_YELLOW ${file}$COL_GREEN to individual XML files.$COL_RESET"
            xsltproc -stringparam baseName "$ofn" xslt/geonetwork2iso.xsl "$file"
        fi
    done
}

convert_mods() {
  for file in $ISOS_DIR/*.xml; do
    ofn="$MODS_DIR/$(basename "$file")"
    if [ ! -r "$ofn" ]; then
      echo "$COL_GREEN Converting ${COL_RED}ISO$COL_GREEN for$COL_YELLOW ${ofn}$COL_GREEN to ${COL_CYAN}MODS $COL_RESET"
      xsltproc \
        xslt/iso2mods.xsl "$file" > "$ofn"
    fi
  done
}

convert_solr()
{
  for file in $MODS_DIR/*.xml; do
    ofn="$GEOB_DIR/$(basename "$file")"
    if [ ! -r "$ofn" ]; then
      echo "$COL_GREEN  Converting ${COL_CYAN}MODS$COL_GREEN for$COL_YELLOW ${ofn}$COL_GREEN to ${COL_MAGENTA}Solr $COL_RESET"
      xsltproc \
        -stringparam geoserver_root $GEOSERVER_ROOT \
        -stringparam now "$(date -u "+%Y-%m-%dT%H:%M:00Z")" \
        -stringparam rights "Public" \
        -stringparam stacks_root $STACKS_ROOT \
        xslt/mods2geoblacklight.xsl "$file" > "$ofn"
    fi
  done
}

cleanup() {
  echo "${COL_CYAN}Cleaning up old files... $COL_RESET"
  rm -f $DATA_DIR/*.xml
  rm -f $MODS_DIR/*.xml
  rm -f $GEOB_DIR/*.xml
  rm -f $ISOS_DIR/*.xml
}

replace_server() {
  perl -i -pe 's/libsvr35/gis/' $DATA_DIR/*.xml
  perl -i -pe 's/ows/geoserver/' $DATA_DIR/*.xml
}

clear

if [ -d "$DATA_DIR" ]; then
    cleanup
else
    make_dirs
fi

ruby fetch-data.rb
replace_server
breakout_layers
convert_mods
convert_solr


exit $?
