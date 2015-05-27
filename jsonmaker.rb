#!/usr/bin/env ruby

dir = ARGV[0]
Dir.glob("#{dir}/**/**/*iso19139.xml") do |file|
  abs_path = File.absolute_path(file)
  path = File.dirname(abs_path)

  %x[xsltproc xslt/iso2json.xsl "#{file}" > "#{path}/geoblacklight.json"]
end



