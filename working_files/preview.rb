#! /usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'colorize'
require 'logger'

class Preview

  attr_accessor :doc, :layer

  def initialize(file = null)
    read_file(file)
    @dir = File.dirname(file)
    @logger = Logger.new('previews.log')
  end

  def read_file(file)
    f = File.open(file)
    @doc = Nokogiri::XML(f)
    f.close
  end

  def thumbnail
    get_layer
    wms_request = "http://gis.lib.virginia.edu:8080/geoserver/wms/reflect?layers=#{@layer}&format=image/jpeg"

    begin
      file = File.open("#{@dir}/preview.jpg", 'wb')
      file.write open(wms_request).read
    rescue Exception => e
      @logger.error e.message
      @logger.error e.backtrace.join("\n")
      #puts "#{e.message}".red
    ensure
      file.close unless file == nil
    end

  end

  def get_layer
    search = "/gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource/gmd:name"
    @layer = @doc.xpath(search).text
  end
end

files = Dir.glob('edu.virginia/**/iso19139.xml')
counter = 0.0

puts "Downloading preview images".yellow

files.each do |record|
  doc = Preview.new(record)
  doc.thumbnail
  counter += 1
  percent = ((counter / files.size) * 100).to_i
  print "\r#{percent}% complete".green
end

