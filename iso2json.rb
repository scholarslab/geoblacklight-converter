#! /usr/bin/env ruby

# usage: ./iso2json.rb [-v | --verbose]

require 'open-uri'
require 'json'
require 'pp'
require 'nokogiri'
require 'active_support/all' # deal with it

METADATA_URL = "https://opengeometadata.github.io/"
PREFIX = "http://gis.lib.virginia.edu:8080/geoserver/ows?service=WFS&version=1.0.0&request=GetFeature&maxfeatures=1&outputformat=json&typeName="
VERBOSE = ARGV.include?("-v") || ARGV.include?("--verbose")

module Utils
  def self.fetch_type(layer)
    url = "#{PREFIX}#{layer}"
    begin
      response = JSON.parse(open(url).read)
      response["features"].first["geometry"]["type"]
    rescue
      "Raster" # if it's not a geometry type, it's an image
      #pp "Something went wrong for #{layer}"
    end
  end

  def self.norm_space str
    str.split.join " "
  end

  def self.norm_text doc, xpath
    norm_space doc.xpath(xpath).text
  end
end

class Iso2Json
  def initialize input_file
    @input_file = input_file
    @doc = Nokogiri::XML(File.read input_file)
  end

  def institute
    institute_node = @doc.xpath(
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

    institute
  end

  def layer_name
    @doc.xpath(
      "/gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource/gmd:name"
    ).text.strip
  end

  def resource_name
    Utils::norm_text(
      @doc, "gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource/gmd:name"
    )
  end

  def y2
    bbox_point("north", "Latitude")
  end

  def y1
    bbox_point("south", "Latitude")
  end

  def x2
    bbox_point("east",  "Longitude")
  end

  def x1
    bbox_point("west",  "Longitude")
  end

  def bbox_point(direction, dimension)
    @doc.xpath(
      "/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:#{direction}Bound#{dimension}/gco:Decimal"
    ).text.to_f
  end

  def format_mime

    format_name = @doc.xpath(
      "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:spatialRepresentationType/gmd:MD_SpatialRepresentationTypeCode/@codeListValue"
    ).text

    case format_name
    when "vector"
      format_mime = "Shapefile"
    when "grid"
      format_mime = "GeoTIFF"
    else
      format_mime = "GeoTIFF" # this is temporary; there are 16 layers without this metadata
    end

    #format_name = @doc.xpath(
      #"gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat/gmd:MD_Format/gmd:name"
    #).text

    #if format_name.include? "Raster Dataset"
      #format_mime = "image/tiff"
    #elsif format_name.include? "GeoTIFF"
      #format_mime = "image/tiff"
    #elsif format_name.include? "Shapefile"
      #format_mime = "application/x-esri-shapefile"
    #elsif @doc.xpath("gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:spatialRepresentationType/gmd:MD_SpatialRepresentationTypeCode/@codeListValue").text == "vector"
      #format_mime = "application/x-esri-shapefile"
    #else
      ## abort("Invalid format: #{format_name}")
      #format_mime = ""
    #end

    format_mime
  end

  def uuid
    @doc
      .xpath("/gmd:MD_Metadata/gmd:fileIdentifier/gco:CharacterString")
      .text
  end

  def identifier
    identifier = uuid
    if institute == "Stanford"
      identifier = identifier[0..-10]
    end
    identifier
  end

  def dc_identifier_s
    Utils::norm_text(
      @doc, "/gmd:MD_Metadata/gmd:fileIdentifier/gco:CharacterString"
    )
  end

  def dc_title_s
    Utils::norm_text(
      @doc, "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title"
    )
  end

  def dc_description_s
    @doc.xpath(
      "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract"
    ).text.strip
  end

  def dc_rights_s
    "Public"
  end

  def dct_provenance_s
    institute
  end

  def download_url(format)
    url = 'http://gis.lib.virginia.edu/geoserver'

    case format
    when "Shapefile"
      url += "/ows?service=WFS&typeName=#{layer_name}&request=GetFeature&outputFormat=shape-zip"
    when "GeoTIFF"
      url += "/wms/reflect?layers=#{layer_name}&format=image/tiff&width=3000&height=3000"
    end

    url
  end

  def dct_references_s
    format = format_mime
    file_id = @input_file[3..-1]

    {
      "http://www.opengis.net/def/serviceType/ogc/wms" => "http://gis.lib.virginia.edu/geoserver/wms",
      "http://www.opengis.net/def/serviceType/ogc/wfs" => "http://gis.lib.virginia.edu/geoserver/wfs",
      "http://www.opengis.net/def/serviceType/ogc/wcs" => "http://gis.lib.virginia.edu/geoserver/wcs",
      #"http://schema.org/url" => "#{METADATA_URL}/#{file_id}/iso19139.html",
      #"http://schema.org/downloadUrl" => "http://gis.lib.virginia.edu/geoserver/ows?service=WFS&typeName=#{layer_name}&request=GetFeature&outputFormat=shape-zip",
      "http://schema.org/downloadUrl" => "#{download_url(format)}",
      "http://www.isotc211.org/schemas/2005/gmd/" => "#{METADATA_URL}#{file_id}",
    }.to_json
  end

  def layer_id_s
    resource_name
  end

  def layer_slug_s
    "uva-#{resource_name}"
  end

  def layer_geom_type_s
    Utils::fetch_type layer_id_s
  end

  def layer_modified_dt
    @doc.xpath("gmd:MD_Metadata/gmd:dateStamp")
  end

  def dc_format_s
    format_mime
  end

  def dc_language_s
    @doc.xpath(
      "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:language/gco:CharacterString"
    ).text
  end

  def dc_type_s
    dc_type = nil

    level_name = @doc.xpath(
      "gmd:MD_Metadata/gmd:hierarchyLevelName/gco:CharacterString"
    )
    unless level_name.nil?
      level_name = level_name.text
      if level_name.include? "dataset"
        dc_type = "Dataset"
      elsif level_name.include? "service"
        dc_type = "Service"
      end
    end

    dc_type
  end

  def dc_subject_sm
    dc_subject = nil

    keywords = @doc.xpath(
      "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode or gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords"
    )
    unless keywords.nil?
      dc_subject = @doc.xpath(
        "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory/gmd:MD_TopicCategoryCode"
      ).map { |node| node.text.strip.underscore.titleize }
    end

    dc_subject
  end

  def dc_spatial_sm
    dc_spatial = nil

    keywords = @doc.xpath(
      "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords"
    )
    keywords.each do |node|
      place = node.xpath(
        "gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='place']"
      )
      unless place.nil?
        dc_spatial = node.xpath("gmd:keyword").to_a
      end
    end

    dc_spatial
  end

  def dct_issued_s
    dct_issued = nil

    citation_date = @doc.xpath(
      "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"
    )
    if citation_date.nil?
      citation_date = @doc.xpath(
        "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date"
      )
      dct_issued = citation_date.text unless citation_date.nil?
    else
      dct_issued = citation_date.text.partition("T")[0]
    end

    dct_issued
  end

  def dct_temporal_sm
    dct_temporal = nil

    time_begin = @doc.xpath(
      "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition"
    )

    if time_begin.nil? || time_begin.text.empty?
      time_instant = @doc.xpath(
        "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant"
      )
      dct_temporal = time_instant.text[0..3] unless time_instant.nil?

    else
      time_begin = time_begin.text[0..3]
      time_end = @doc.xpath(
        "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:endPosition"
      )
      if (!time_end.nil?) && time_end.text != time_begin
        time_end = "-" + time_end.text[0..3]
      else
        time_end = ""
      end
      dct_temporal = time_begin + time_end
    end

    dct_temporal
  end

  def solr_year_i
    solr_year = nil

    time_begin = @doc.xpath(
      "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimePeriod/gml:beginPosition"
    )

    if time_begin.nil? || time_begin.text.empty?
      time_instant = @doc.xpath(
        "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent/gmd:extent/gml:TimeInstant"
      )
      dct_temporal = time_instant.text[0..3] unless time_instant.nil?
      solr_year = dct_temporal.to_i
    else
      solr_year = time_begin.text[0..3].to_i
    end

    solr_year
  end

  def dc_relation_sm
    dc_relation = nil

    assoc_type_code = @doc.xpath(
      "gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:aggregationInfo/gmd:MD_AggregateInformation/gmd:associationType/gmd:DS_AssociationTypeCode[@codeListValue='crossReference']"
    )
    unless assoc_type_code.nil?
      dc_relation = assoc_type_code.map do |node|
        node.xpath(
          "ancestor-or-self::*/gmd:aggregateDataSetName/gmd:CI_Citation/gmd:title"
        ).text
      end
    end

    dc_relation
  end

  def georss_polygon_s
    "#{y1} #{x1} #{y2} #{x1} #{y2} #{x2} #{y1} #{x2} #{y1} #{x1}"
  end

  def solr_geom
    "ENVELOPE(#{x1}, #{x2}, #{y2}, #{y1})"
  end

  def georss_box_s
    "#{y1} #{x1} #{y2} #{x2}"
  end

  def to_h
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

    data
  end

  def to_json
    to_h.to_json
  end
end

Dir.glob('../edu.virginia/**/iso19139.xml').each do |input_file|
  output_file = File::dirname(input_file) + "/geoblacklight.json"
  puts "#{input_file} => #{output_file}" if VERBOSE

  begin
    iso2json = Iso2Json.new(input_file)
    f = File.open(output_file, 'w')
    begin
      IO.write(f, JSON.pretty_generate(iso2json.to_h, {:indent => "    "}))
    ensure
      f.close
    end
  rescue
    puts "#{input_file} has an error"
  end
end
