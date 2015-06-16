#! /usr/bin/env ruby

require 'json'
require 'pp'
require 'nokogiri'

def norm_space str
  str.split.join " "
end

def norm_text doc, xpath
  norm_space doc.xpath(xpath).text
end

# input
input = ARGV[0]
doc = Nokogiri::XML(File.read(input))

# institute name
institute_node = doc.xpath(
  "/gmd:MD_Metadata/gmd:contact/gmd:CI_ResponsibleParty/gmd:organisationName/gco:CharacterString"
).text

if institute_node.include? "Stanford"
  institute = "Stanford"
elsif institute_node.include? "Virginia"
  institute = "UVa"
elsif institute_node.include? "Scholars"
  institute = "UVa"
else
  abort("Unknown institution: #{institute_node}")
end

# layer name
layer_name = doc.xpath(
  "/gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource/gmd:name"
).text.strip

# resource_name
resource_name = norm_text(
  doc, "gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource/gmd:name"
)

# bounding box
def bbox_point(doc, direction, dimension)
  doc.xpath(
    "/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:#{direction}Bound#{dimension}/gco:Decimal"
  ).text.to_f
end

y2 = bbox_point(doc, "north", "Latitude")
y1 = bbox_point(doc, "south", "Latitude")
x2 = bbox_point(doc, "east",  "Longitude")
x1 = bbox_point(doc, "west",  "Longitude")

# format_name
format_name = doc.xpath(
  "gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name"
).text

if format_name.include? "Raster Dataset"
  format_mime = "image/tiff"
elsif format_name.include? "GeoTIFF"
  format_mime = "image/tiff"
elsif format_name.include? "Shapefile"
  format_mime = "application/x-esri-shapefile"
elsif doc.xpath("gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:spatialRepresentationType/gmd:MD_SpatialRepresentationTypeCode/@codeListValue").text == "vector"
  format_mime = "application/x-esri-shapefile"
else
  abort("Invalid format: #{format_name}")
end

# uuid
uuid = doc
  .xpath("/gmd:MD_Metadata/gmd:fileIdentifier/gco:CharacterString")
  .text

# identifier
if institute == "Stanford"
  identifier = uuid[0..-10]
else
  identifier = uuid
end

# dc_identifier_s
dc_identifier_s = norm_text(
  doc, "/gmd:MD_Metadata/gmd:fileIdentifier/gco:CharacterString"
)

# dc_title_s
dc_title_s = norm_text(
  doc, "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title"
)

# dc_description_s
dc_description_s = doc.xpath(
  "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract"
).text.strip

# TODO: dc_rights_s
dc_rights_s = "Public"

# dct_provenance_s
dct_provenance_s = institute

# dct_references_s
file_id = doc.xpath(
  "gmd:MD_Metadata/gmd:fileIdentifier/gco:CharacterString"
).text.strip

dct_references_s = {
  "http://www.opengis.net/def/serviceType/ogc/wms" => "http://gis.lib.virginia.edu/geoserver/wms",
  "http://www.opengis.net/def/serviceType/ogc/wfs" => "http://gis.lib.virginia.edu/geoserver/wfs",
  "http://www.opengis.net/def/serviceType/ogc/wcs" => "http://gis.lib.virginia.edu/geoserver/wcs",
  "http://schema.org/url" => "https://geoblacklight.lib.virginia.edu/metadata/edu.virginia/#{file_id}/iso19139.html",
  "http://schema.org/downloadUrl" => "http://gis.lib.virginia.edu/geoserver/ows?service=WFS&typeName=#{layer_name}&request=GetFeature&outputFormat=shape-zip",
  "http://www.isotc211.org/schemas/2005/gmd/" => "https://geoblacklight.lib.virginia.edu/metadata/edu.virginia/#{file_id}/iso19139.xml",
}.to_json

# layer_id_s
layer_id_s = resource_name

# layer_slug_s
layer_slug_s = "uva-#{resource_name}"

# TODO: layer_geom_type_s
layer_geom_type_s = "Polygon"

# layer_modified_dt
layer_modified_dt = doc.xpath("gmd:MD_Metadata/gmd:dateStamp")

# dc_format_s
dc_format_s = format_mime

# dc_language_s
dc_language_s = doc.xpath(
  "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:language/gco:CharacterString"
).text

# dc_type_s
dc_type_s = nil
level_name = doc.xpath(
  "gmd:MD_Metadata/gmd:hierarchyLevelName/gco:CharacterString"
)
unless level_name.nil?
  level_name = level_name.text
  if level_name.include? "dataset"
    dc_type_s = "Dataset"
  elsif level_name.include? "service"
    dc_type_s = "Service"
  end
end

# dc_subject_sm
dc_subject_sm = nil
keywords = doc.xpath(
  "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode or gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords"
)
unless keywords.nil?
  dc_subject_sm = doc.xpath(
    "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode"
  ).map { |node| node.text.strip }
end

# dc_spatial_sm
dc_spatial_sm = nil
keywords = doc.xpath(
  "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords"
)
keywords.each do |node|
  place = node.xpath(
    "gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='place']"
  )
  unless place.nil?
    dc_spatial_sm = node.xpath("gmd:keyword").to_a
  end
end

# dct_issued_s
dct_issued_s = nil
citation_date = doc.xpath(
  "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"
)
if citation_date.nil?
  citation_date = doc.xpath(
    "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date"
  )
  dct_issued_s = citation_date.text unless citation_date.nil?
else
  dct_issued_s = citation_date.text.partition("T")[0]
end

# dct_temporal_sm
# solr_year_i
dct_temporal_sm = nil
solr_year_i = nil
time_begin = doc.xpath(
  "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition"
)

if time_begin.nil? || time_begin.text.empty?
  time_instant = doc.xpath(
    "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant"
  )
  dct_temporal_sm = time_instant.text[0..3] unless time_instant.nil?
  solr_year_i = dct_temporal_sm.to_i

else
  time_begin = time_begin.text[0..3]
  solr_year_i = time_begin.to_i
  time_end = doc.xpath(
    "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:endPosition"
  )
  if (!time_end.nil?) && time_end.text != time_begin
    time_end = "-" + time_end.text[0..3]
  else
    time_end = ""
  end
  dct_temporal_sm = time_begin + time_end
end

# dc_relation_sm
dc_relation_sm = nil
assoc_type_code = doc.xpath(
  "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:aggregationInfo/gmd:MD_AggregateInformation/gmd:associationType/gmd:DS_AssociationTypeCode[@codeListValue='crossReference']"
)
unless assoc_type_code.nil?
  dc_relation_sm = assoc_type_code.map do |node|
    node.xpath(
      "ancestor-or-self::*/gmd:aggregateDataSetName/gmd:CI_Citation/gmd:title"
    ).text
  end
end

# georss_polygon_s
georss_polygon_s = "#{y1} #{x1} #{y2} #{x1} #{y2} #{x2} #{y1} #{x2} #{y1} #{x1}"

# solr_geom
solr_geom = "ENVELOPE(#{x1}, #{x2}, #{y2}, #{y1})"

# georss_box_s
georss_box_s = "#{y1} #{x1} #{y2} #{x2}"

# data hash
data = {
  "uuid"              => uuid,
  "dc_identifier_s"   => dc_identifier_s,
  "dc_title_s"        => dc_title_s,
  "dc_description_s"  => dc_description_s,
  "dc_rights_s"       => dc_rights_s,
  "dct_provenance_s"  => dct_provenance_s,
  "dct_references_s"  => dct_references_s,
  "layer_id_s"        => layer_id_s,
  "layer_slug_s"      => layer_slug_s,
  "layer_geom_type_s" => layer_geom_type_s,
  "dc_format_s"       => dc_format_s,
  "dc_language_s"     => dc_language_s,
  "georss_polygon_s"  => georss_polygon_s,
  "solr_geom"         => solr_geom,
  "georss_box_s"      => georss_box_s,
}

unless layer_modified_dt.nil?
  data["layer_modified_dt"] = layer_modified_dt.text.strip + "Z"
end
unless dc_relation_sm.nil? || dc_relation_sm.empty?
  data["dc_relation_sm"] = dc_relation_sm
end
data["dc_type_s"]       = dc_type_s       unless dc_type_s.nil?
data["dc_subject_sm"]   = dc_subject_sm   unless dc_subject_sm.nil?
data["dc_spatial_sm"]   = dc_spatial_sm   unless dc_spatial_sm.nil?
data["dct_issued_s"]    = dct_issued_s    unless dct_issued_s.nil?
data["dct_temporal_sm"] = dct_temporal_sm unless dct_temporal_sm.nil?
data["solr_year_i"]     = solr_year_i     unless solr_year_i.nil?

puts data.to_json
