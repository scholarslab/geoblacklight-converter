<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:gmd="http://www.isotc211.org/2005/gmd"
                version="1.1">
    
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:template match="text()"></xsl:template>    
    
    
    <!-- baseName is given as a stringparam when called by xsltproc. 
            stringparam includes the directory to use.
            ex: dirname/fileName -->
    <xsl:param name="baseName"></xsl:param>

    

    <!-- match gmd:onLine elements -->
    <xsl:template match="gmd:onLine">
        <!-- create a variable to act as an incrementing counter to use in the file name. -->
        <xsl:variable name="n"><xsl:number count="*" format="1"/></xsl:variable>
        <!-- create file name at set to variable -->
        <xsl:variable name="outFile"><xsl:value-of select="$baseName"/>-<xsl:value-of select="$n"/>.xml</xsl:variable>
        <!-- begin creating the contents of the file -->
        <xsl:document href="{$outFile}">
            <xsl:apply-templates select="/" mode="copy">
                <!-- passes the value of the current onLine node to the variable/parameter named "layer" -->
                <xsl:with-param name="layer" select="."/>
            </xsl:apply-templates>
        </xsl:document>
    </xsl:template>
    
    


    <!-- begins copy of entire document -->
    <xsl:template match="node() | @*" mode="copy">
        <!-- declare the "layer" parameter -->
        <xsl:param name="layer"></xsl:param>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="copy">
                <!-- passes the value of the selected onLine layer -->
                <xsl:with-param name="layer" select="$layer"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <!-- copies the contents of the specified onLine node -->
    <xsl:template match="gmd:MD_DigitalTransferOptions" mode="copy">
        <xsl:param name="layer"></xsl:param>
        <xsl:copy>
            <!-- passes the value of the selected onLine layer -->
            <xsl:copy-of select="$layer"/>                
        </xsl:copy>        
    </xsl:template>
    
</xsl:stylesheet>