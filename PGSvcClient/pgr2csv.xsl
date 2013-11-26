<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet 
  version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:msxsl="urn:schemas-microsoft-com:xslt" 
  xmlns:pgr="urn:uk-gov-hsl-msu:pgsvc-v03">

  <xsl:output method="text" encoding="us-ascii"/>

  <xsl:strip-space elements="*"/>

  <xsl:template name="writeNewLine">
    <xsl:text>&#x000D;</xsl:text>
  </xsl:template>

  <xsl:template match="/">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="pgr:PopGenRes">
    <xsl:apply-templates select="pgr:Individuals"/>
    <xsl:apply-templates select="pgr:Summary"/>
    <xsl:apply-templates select="pgr:Parameters"/>
  </xsl:template>

  <xsl:template match="pgr:Individuals">

    <xsl:text>Id,Age,Sex,Ethnicity,Body Mass,Height,Cardiac Output</xsl:text>

    <xsl:for-each select="pgr:Individual[1]/pgr:Tissues/pgr:Tissue">
      <xsl:text>,</xsl:text>
      <xsl:value-of select="pgr:Type"/>
      <xsl:text> mass,</xsl:text>
      <xsl:value-of select="pgr:Type"/>
      <xsl:text> flow</xsl:text>
    </xsl:for-each>

    <xsl:if test="pgr:Individual[1]/pgr:Enzymes">
      <xsl:text>,MPPGL</xsl:text>

      <xsl:for-each select="pgr:Individual[1]/pgr:Enzymes/pgr:Enzyme/pgr:Enzyme">
        <xsl:text>,</xsl:text>
        <xsl:value-of select="pgr:Name" />
      </xsl:for-each>
    </xsl:if>

    <xsl:call-template name="writeNewLine"/>

    <xsl:for-each select="pgr:Individual">
      <xsl:value-of select="position()"/>
      <xsl:text>,</xsl:text>
      <xsl:value-of select="pgr:Age"/>
      <xsl:text>,</xsl:text>
      <xsl:value-of select="pgr:Sex"/>
      <xsl:text>,</xsl:text>
      <xsl:value-of select="pgr:Ethnicity"/>
      <xsl:text>,</xsl:text>
      <xsl:value-of select="pgr:BodyMass"/>
      <xsl:text>,</xsl:text>
      <xsl:value-of select="pgr:Height"/>
      <xsl:text>,</xsl:text>
      <xsl:value-of select="pgr:CardiacOutput"/>

      <xsl:for-each select="pgr:Tissues/pgr:Tissue">
        <xsl:text>,</xsl:text>
        <xsl:value-of select="pgr:Mass"/>
        <xsl:text>,</xsl:text>
        <xsl:value-of select="pgr:Flow"/>
      </xsl:for-each>

      <xsl:if test="pgr:Enzymes">
        <xsl:text>,</xsl:text>
        <xsl:value-of select="pgr:Enzymes/pgr:Mppgl"/>

        <xsl:for-each select="pgr:Enzymes/pgr:Enzyme/pgr:Enzyme">
          <xsl:text>,</xsl:text>
          <xsl:value-of select="pgr:InVivoEnzymeRate"/>
        </xsl:for-each>
      </xsl:if>

      <xsl:call-template name="writeNewLine"/>
    </xsl:for-each>

    <xsl:call-template name="writeNewLine"/>

  </xsl:template>

  <xsl:template match="pgr:Summary">
    
    <xsl:call-template name="writeStats">
      <xsl:with-param name="sex" select="'Male'"/>
    </xsl:call-template>
    <xsl:call-template name="writeStats">
      <xsl:with-param name="sex" select="'Female'"/>
    </xsl:call-template>
    <xsl:call-template name="writeNewLine" />
  </xsl:template>

  <xsl:variable name="rtfStatsOutputTemplate">
    <row heading="Mean" />
    <row heading="StdDev" />
    <row heading="GeoMean" />
    <row heading="GeoStdDev" />
    <row heading="P2pt5" />
    <row heading="P5" />
    <row heading="Median" />
    <row heading="P95" />
    <row heading="P97pt5" />
  </xsl:variable>

  <xsl:variable name="nsStatsOutputTemplate" select="msxsl:node-set($rtfStatsOutputTemplate)" />

  <xsl:template name="writeStats">
    <xsl:param name="sex" />

    <xsl:variable name="context" select="*[local-name() = $sex]"/>

    <xsl:for-each select="$nsStatsOutputTemplate/row">
      <xsl:text>,,,,,</xsl:text>
      <xsl:value-of select="$sex"/>
      <xsl:text>,</xsl:text>
      <xsl:value-of select="@heading"/>

      <xsl:variable name="targetStat" select="@heading"/>

      <xsl:for-each select="$context/pgr:Mass/pgr:Stats">
        <xsl:text>,</xsl:text>
        <xsl:value-of select="*[local-name() = $targetStat]" />
        <xsl:text>,</xsl:text>
        <xsl:variable name="currentTissue" select="pgr:Name" />
        <xsl:value-of select="../../pgr:Flow/pgr:Stats[pgr:Name = $currentTissue]/*[local-name() = $targetStat]" />
      </xsl:for-each>

      <xsl:text>,</xsl:text>
      <xsl:value-of select="$context/pgr:Mppgl/pgr:Stats/*[local-name() = $targetStat]"/>

      <xsl:for-each select="$context/*[contains(local-name(), 'EnzymeRate')]/pgr:Stats">
        <xsl:text>,</xsl:text>
        <xsl:value-of select="*[local-name() = $targetStat]" />
      </xsl:for-each>

      <xsl:call-template name="writeNewLine" />
    </xsl:for-each>

  </xsl:template>

  <xsl:template match="pgr:Parameters">

    <xsl:text>Population,Size,</xsl:text>
    <xsl:value-of select="pgr:Population/pgr:Size"/>
    <xsl:call-template name="writeNewLine" />

    <xsl:text>,Dataset,</xsl:text>
    <xsl:value-of select="pgr:Population/pgr:Dataset"/>
    <xsl:call-template name="writeNewLine" />

    <xsl:text>,Seed,</xsl:text>
    <xsl:value-of select="pgr:Population/pgr:Seed"/>
    <xsl:call-template name="writeNewLine" />

    <xsl:text>Filter,Age,</xsl:text>
    <xsl:value-of select="pgr:Filter/pgr:AgeLowerLimit"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="pgr:Filter/pgr:AgeUpperLimit"/>
    <xsl:call-template name="writeNewLine" />

    <xsl:text>,BMI,</xsl:text>
    <xsl:value-of select="pgr:Filter/pgr:BmiLowerLimit"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="pgr:Filter/pgr:BmiUpperLimit"/>
    <xsl:call-template name="writeNewLine" />

    <xsl:text>,Height,</xsl:text>
    <xsl:value-of select="pgr:Filter/pgr:HeightLowerLimit"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="pgr:Filter/pgr:HeightUpperLimit"/>
    <xsl:call-template name="writeNewLine" />

    <xsl:text>Probability,Male,</xsl:text>
    <xsl:value-of select="pgr:Probability/pgr:Male"/>
    <xsl:call-template name="writeNewLine" />

    <xsl:if test="pgr:Probability/pgr:EthnicityWhite">
      <xsl:text>,Ethnicity (white),</xsl:text>
      <xsl:value-of select="pgr:Probability/pgr:EthnicityWhite"/>
      <xsl:call-template name="writeNewLine" />
    </xsl:if>

    <xsl:if test="pgr:Probability/pgr:EthnicityBlack">
      <xsl:text>,Ethnicity (black),</xsl:text>
      <xsl:value-of select="pgr:Probability/pgr:EthnicityBlack"/>
      <xsl:call-template name="writeNewLine" />
    </xsl:if>

    <xsl:if test="pgr:Probability/pgr:EthnicityNonBlackOrWhite">
      <xsl:text>,Ethnicity (non-black or white),</xsl:text>
      <xsl:value-of select="pgr:Probability/pgr:EthnicityNonBlackOrWhite"/>
      <xsl:call-template name="writeNewLine" />
    </xsl:if>

    <xsl:text>Units,Flow,</xsl:text>
    <xsl:value-of select="pgr:Units/pgr:Flow"/>
    <xsl:call-template name="writeNewLine" />

    <xsl:text>,Enzyme Rate,</xsl:text>
    <xsl:value-of select="pgr:Units/pgr:EnzymeRate"/>
    <xsl:call-template name="writeNewLine" />

  </xsl:template>
</xsl:stylesheet>
