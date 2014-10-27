#! /usr/bin/env bash

rm -f data/*.xml
rm -f mods/*.xml
rm -f geoblacklight/*.xml

ruby fetch-data.rb
sh toMods.sh
sh toSolr.sh
