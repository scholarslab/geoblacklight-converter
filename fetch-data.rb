#! /usr/bin/env ruby

require 'csv'

class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def cyan
    colorize(36)
  end

end

CSV_FILE = 'uva.csv'
GN_PREFIX = 'http://gis.lib.virginia.edu:8080/geonetwork/srv/en/iso19139.xml?id='

@csv = CSV.read(CSV_FILE, headers: true)

@csv.each do |row|
  puts "Downloading record ".green + "#{row['id']}".cyan + " from".green + " Geonetwork...".yellow
  `curl -s -L #{GN_PREFIX}#{row['id']} -o data/#{row['id']}.xml`
end


