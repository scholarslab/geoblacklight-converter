<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:gmd="http://www.isotc211.org/2005/gmd"
                xmlns:gco="http://www.isotc211.org/2005/gco" 
                version="1.1">
    
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:template match="text()"/>    
    
    
    <!-- baseName is given as a stringparam when called by xsltproc. 
            stringparam includes the directory to use.
            ex: dirname/fileName -->
    <xsl:param name="baseName"/>

    

    <!-- match gmd:onLine elements -->
    <xsl:template match="gmd:onLine">
        <!-- create a variable to act as an incrementing counter to use in the file name. -->
        <xsl:variable name="n"><xsl:number count="*" format="1"/></xsl:variable>
        
        <xsl:variable name="check">
            <xsl:choose>
                <xsl:when test="$n &lt; 5">-check</xsl:when>
                <xsl:otherwise></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- create file name and set to variable -->
        <xsl:variable name="outFile"><xsl:value-of select="$baseName"/>-<xsl:value-of select="$n"/><xsl:value-of select="$check"/>.xml</xsl:variable>
        <!-- begin creating the contents of the file -->
        <xsl:document href="{$outFile}">
            <xsl:apply-templates select="/" mode="copy">
                <!-- passes the value of the current onLine node to the variable/parameter named "layer" -->
                <xsl:with-param name="layer" select="."/>
                <xsl:with-param name="n" select="$n"/>
            </xsl:apply-templates>
        </xsl:document>
    </xsl:template>
    
    <!-- Empty template so that we do not copy keywords -->
    <xsl:template match="gmd:descriptiveKeywords" mode="copy"/>

    <!-- begins copy of entire document -->
    <xsl:template match="node() | @*" mode="copy">
        <!-- declare the "layer" parameter -->
        <xsl:param name="layer"/>
        <xsl:param name="n"/>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="copy">
                <!-- passes the value of the selected onLine layer -->
                <xsl:with-param name="layer" select="$layer"/>
                <xsl:with-param name="n" select="$n"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <!-- copies the contents of the specified onLine node -->
    <xsl:template match="gmd:MD_DigitalTransferOptions" mode="copy">
        <xsl:param name="layer"/>
        <xsl:param name="n"/>
        <xsl:copy>
            <!-- passes the value of the selected onLine layer -->
            <xsl:copy-of select="$layer"/>
            <xsl:copy-of select="$n"/>
        </xsl:copy>        
    </xsl:template>
    
    <!-- Grab the fileIdentifier and append an incremental number to create a UUID -->
    <xsl:template match="gmd:fileIdentifier/gco:CharacterString" mode="copy">
        <xsl:param name="n"/>
        <gco:CharacterString xmlns:srv="http://www.isotc211.org/2005/srv"><xsl:value-of select="text()"/>-<xsl:value-of select="$n"/></gco:CharacterString>
    </xsl:template>
</xsl:stylesheet>