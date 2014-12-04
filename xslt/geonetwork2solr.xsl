<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gmd="http://www.isotc211.org/2005/gmd"
    xmlns:gco="http://www.isotc211.org/2005/gco" 
    xmlns:solr="http://lucene.apache.org/solr/4/document"
    version="1.1">
    
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:template match="/">
        <add xmlns="http://lucene.apache.org/solr/4/document">
            <doc>
                <field name="uuid"><xsl:value-of select="/gmd:MD_Metadata/gmd:fileIdentifier/gco:CharacterString"/></field>
                <field name="dc_identifier_s"><xsl:value-of select="/gmd:MD_Metadata/gmd:fileIdentifier/gco:CharacterString"/></field>
                <!-- concat layer name with this -->
                <field name="dc_title_s">
                    <xsl:value-of select="/gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource/gmd:description/gco:CharacterString"/>: <xsl:value-of select="/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title/gco:CharacterString"/>
                </field>
                <field name="dc_description_s"><xsl:value-of select="/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract"/></field>
                <field name="dc_rights_s">Public</field>
                <field name="dct_provenance_s">UVa</field>
                <field name="dct_references_d"><!-- todo --></field>
                <field name="layer_id_s"><xsl:value-of select="/gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource/gmd:name"/></field>
                <field name="layer_slug_s">uva-<xsl:value-of select="/gmd:MD_Metadata/gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource/gmd:name"/></field>
                <field name="layer_geom_type_s">Polygon<!-- todo: there doesn't appear to be any info on the type in the ISO metadata --></field>
                <field name="layer_modified_dt"><xsl:value-of select="/gmd:MD_Metadata/gmd:dateStamp/gco:DateTime"/></field>
                <field name="dc_format_s">Shapefile <!-- todo: this isn't in the metdata --></field>
                <field name="dc_language_s"><xsl:value-of select="/gmd:MD_Metadata/gmd:language/gco:CharacterString"/></field>
      
                <field name="dc_type_s">Dataset</field>
                <xsl:for-each select="/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:pointOfContact/gmd:CI_ResponsibleParty/gmd:organisationName/gco:CharacterString">
                    <field name="dc_publisher_s"><xsl:value-of select="node()"/></field>
                </xsl:for-each>
                
                <xsl:for-each select="/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:topicCategory">
                    <field name="dc_subject_sm"><xsl:value-of select="node()"/></field>
                </xsl:for-each>
                
                <field name="dct_issued_s"><xsl:value-of select="substring(/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime, 1, 4)"/></field>
                
                <xsl:variable name="west" select="/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:westBoundLongitude/gco:Decimal"/>
                <xsl:variable name="east" select="/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:eastBoundLongitude/gco:Decimal"/>
                <xsl:variable name="north" select="/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:northBoundLatitude/gco:Decimal"/>
                <xsl:variable name="south" select="/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox/gmd:southBoundLatitude/gco:Decimal"/>
                
                <field name="georss_box_s">
                    <xsl:value-of select="$south"/><xsl:text> </xsl:text><xsl:value-of select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$north"/><xsl:text> </xsl:text><xsl:value-of select="$east"/>
                </field>
                
                <field name="georss_polygon_s">
                    <xsl:value-of select="$south"/><xsl:text> </xsl:text><xsl:value-of select="$west"/><xsl:text> </xsl:text>
                    <xsl:value-of select="$south"/><xsl:text> </xsl:text><xsl:value-of select="$east"/><xsl:text> </xsl:text>
                    <xsl:value-of select="$north"/><xsl:text> </xsl:text><xsl:value-of select="$east"/><xsl:text> </xsl:text>
                    <xsl:value-of select="$north"/><xsl:text> </xsl:text><xsl:value-of select="$west"/><xsl:text> </xsl:text>
                    <xsl:value-of select="$south"/><xsl:text> </xsl:text><xsl:value-of select="$west"/>
                    <!-- 37.97745 -78.67702 38.19625 -78.67702 38.19625 -78.34292 37.97745 -78.34292 37.97745 -78.67702--></field>
                <field name="solr_geom">ENVELOPE(<xsl:value-of select="$south"/><xsl:text> </xsl:text><xsl:value-of select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$north"/><xsl:text> </xsl:text><xsl:value-of select="$east"/>)</field>
                <field name="solr_bbox"><xsl:value-of select="$south"/><xsl:text> </xsl:text><xsl:value-of select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$north"/><xsl:text> </xsl:text><xsl:value-of select="$east"/></field>
                <field name="solr_sw_pt"><xsl:value-of select="$south"/>,<xsl:value-of select="$west"/></field>
                <field name="solr_ne_pt"><xsl:value-of select="$north"/>,<xsl:value-of select="$east"/></field>
                <field name="solr_year_i">2014</field>
                <field name="solr_wms_url">http://gis.lib.virginia.edu/geoserver/wms</field>
                <field name="solr_wfs_url">http://gis.lib.virginia.edu/geoserver/wfs</field>
                <field name="solr_wcs_url">http://gis.lib.virginia.edu/geoserver/wcs</field>
            </doc>
        </add>
    </xsl:template>
</xsl:stylesheet>