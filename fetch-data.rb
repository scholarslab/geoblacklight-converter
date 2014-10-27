#! /usr/bin/env ruby

require 'csv'

CSV_FILE = 'uva.csv'
GN_PREFIX = 'http://gis.lib.virginia.edu:8080/geonetwork/srv/en/iso19139.xml?id='

@csv = CSV.read(CSV_FILE, headers: true)

@csv.each do |row|
  `curl -L #{GN_PREFIX}#{row['id']} -o data/#{row['id']}.xml`
end
