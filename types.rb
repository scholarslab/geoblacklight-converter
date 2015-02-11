#! /usr/bin/env ruby

require 'open-uri'
require 'json'
require 'pp'
require 'nokogiri'

PREFIX = "http://gis.lib.virginia.edu:8080/geoserver/ows?service=WFS&version=1.0.0&request=GetFeature&maxfeatures=1&outputformat=json&typeName="

def fetch_type(layer)
  url = "#{PREFIX}#{layer}"
  begin
    response = JSON.parse(open(url).read)
    response["features"].first["geometry"]["type"]
  rescue
    "Polygon"
    #pp "Something went wrong for #{layer}"
  end
end

Dir.glob("edu.virginia/**/geoblacklight.xml").each do |solr_doc|
  text = File.open(solr_doc)
  doc = Nokogiri::XML(text)
  text.close

  layer = doc.css("field[@name='layer_id_s']").text

  geometry_type = fetch_type(layer)

  geometry_node = doc.css("field[@name='layer_geom_type_s']")
  geometry_node.first.content = geometry_type

  pp "Writing #{solr_doc}"

  File.open(solr_doc, 'w') {|f| f.print(doc.to_xml) }

end

