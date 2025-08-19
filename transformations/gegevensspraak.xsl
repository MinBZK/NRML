<?xml version="1.0" encoding="UTF-8"?>
<!--
  Gegevensspraak Transformatie
  NRML JSON naar Nederlandse Objectmodel Representatie
  
  Transformeert NRML specificaties naar leesbare Nederlandse gegevensspraak
  voor objectmodellen, feittypes en parameters.
-->
<xsl:stylesheet version="3.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fn="http://www.w3.org/2005/xpath-functions"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="fn xs">

  <!-- Output configuratie voor platte tekst -->
  <xsl:output method="text" encoding="UTF-8" indent="no"/>
  
  <!-- Initial template voor JSON transformatie -->
  <xsl:template name="main">
    <xsl:param name="json-input" as="xs:string?" select="unparsed-text('../toka.nrml.json')"/>
    <xsl:variable name="xml-data" select="json-to-xml($json-input)"/>
    <xsl:apply-templates select="$xml-data"/>
  </xsl:template>
  
  <!-- Root template -->
  <xsl:template match="fn:map[fn:string[@key='$schema']]">
    <!-- Objecttypes verwerken -->
    <xsl:apply-templates select="fn:map[@key='objectTypes']"/>
    
    <!-- Feittypes verwerken -->
    <xsl:apply-templates select="fn:map[@key='factTypes']"/>
    
    <!-- Parameters verwerken -->
    <xsl:apply-templates select="fn:map[@key='parameters']"/>
    
    <!-- Domeinen verwerken -->
    <xsl:apply-templates select="fn:map[@key='domains']"/>
  </xsl:template>

  <!-- Objecttypes sectie -->
  <xsl:template match="fn:map[@key='objectTypes']">
    <xsl:for-each select="fn:map">
      <xsl:variable name="object-name" select="@key"/>
      <xsl:variable name="article" select="fn:string[@key='article']"/>
      <xsl:variable name="animated" select="fn:boolean[@key='animated'] = true()"/>
      
      <!-- Objecttype header -->
      <xsl:text>Objecttype </xsl:text>
      <xsl:value-of select="$article"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="replace($object-name, '_', ' ')"/>
      <xsl:if test="$animated">
        <xsl:text> (bezield)</xsl:text>
      </xsl:if>
      <xsl:text>&#10;</xsl:text>
      
      <!-- Properties verwerken -->
      <xsl:apply-templates select="fn:map[@key='properties']">
        <xsl:with-param name="object-name" select="$object-name"/>
      </xsl:apply-templates>
      
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- Properties binnen objecttype -->
  <xsl:template match="fn:map[@key='properties']">
    <xsl:param name="object-name"/>
    
    <xsl:for-each select="fn:map">
      <xsl:variable name="property-name" select="@key"/>
      <xsl:variable name="property-type" select="fn:string[@key='type']"/>
      <xsl:variable name="property-article" select="fn:string[@key='article']"/>
      <xsl:variable name="subtype" select="fn:string[@key='subtype']"/>
      <xsl:variable name="plural" select="fn:string[@key='plural']"/>
      
      <xsl:choose>
        <!-- Kenmerken -->
        <xsl:when test="$property-type = 'kenmerk'">
          <xsl:choose>
            <xsl:when test="$subtype = 'bezittelijk'">
              <xsl:value-of select="if ($property-article) then $property-article else 'het'"/>
              <xsl:text>&#9;</xsl:text>
              <xsl:value-of select="replace($property-name, '_', ' ')"/>
              <xsl:text>&#9;kenmerk (bezittelijk)&#10;</xsl:text>
            </xsl:when>
            <xsl:when test="$subtype = 'bijvoeglijk'">
              <xsl:text>is&#9;</xsl:text>
              <xsl:value-of select="replace($property-name, '_', ' ')"/>
              <xsl:text>&#9;kenmerk (bijvoeglijk)&#10;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="if ($property-article) then $property-article else 'de'"/>
              <xsl:text>&#9;</xsl:text>
              <xsl:value-of select="replace($property-name, '_', ' ')"/>
              <xsl:text>&#9;kenmerk&#10;</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        
        <!-- Attributen -->
        <xsl:otherwise>
          <xsl:value-of select="$property-article"/>
          <xsl:text>&#9;</xsl:text>
          <xsl:value-of select="replace($property-name, '_', ' ')"/>
          <xsl:if test="$plural">
            <xsl:text> (mv: </xsl:text>
            <xsl:value-of select="$plural"/>
            <xsl:text>)</xsl:text>
          </xsl:if>
          <xsl:text>&#9;</xsl:text>
          <xsl:apply-templates select="fn:map[@key='datatype']" mode="format-datatype"/>
          <xsl:text>&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- Datatype formatting -->
  <xsl:template match="fn:map" mode="format-datatype">
    <xsl:choose>
      <!-- Reference naar domein -->
      <xsl:when test="fn:string[@key='$ref']">
        <xsl:variable name="ref-parts" select="tokenize(fn:string[@key='$ref'], '/')"/>
        <xsl:value-of select="$ref-parts[last()]"/>
      </xsl:when>
      
      <!-- Numeriek type -->
      <xsl:when test="fn:string[@key='type'] = 'numeric'">
        <xsl:variable name="subtype" select="fn:string[@key='subtype']"/>
        <xsl:variable name="precision" select="fn:number[@key='precision']"/>
        <xsl:variable name="unit" select="fn:string[@key='unit']"/>
        
        <xsl:text>Numeriek ( </xsl:text>
        <xsl:choose>
          <xsl:when test="$subtype = 'integer'">
            <xsl:text>geheel getal</xsl:text>
          </xsl:when>
          <xsl:when test="$precision > 0">
            <xsl:text>getal met </xsl:text>
            <xsl:value-of select="$precision"/>
            <xsl:text> decimalen</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>getal</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text> )</xsl:text>
        
        <xsl:if test="$unit">
          <xsl:text> met eenheid </xsl:text>
          <xsl:value-of select="$unit"/>
        </xsl:if>
      </xsl:when>
      
      <!-- Datum type -->
      <xsl:when test="fn:string[@key='type'] = 'date'">
        <xsl:variable name="precision" select="fn:string[@key='precision']"/>
        <xsl:choose>
          <xsl:when test="$precision = 'days'">
            <xsl:text>Datum in dagen</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>Datum en tijd in milliseconden</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      
      <!-- Andere types -->
      <xsl:when test="fn:string[@key='type'] = 'boolean'">
        <xsl:text>Boolean</xsl:text>
      </xsl:when>
      <xsl:when test="fn:string[@key='type'] = 'text'">
        <xsl:text>Tekst</xsl:text>
      </xsl:when>
      <xsl:when test="fn:string[@key='type'] = 'percentage'">
        <xsl:text>Percentage</xsl:text>
      </xsl:when>
      
      <!-- Fallback -->
      <xsl:otherwise>
        <xsl:value-of select="fn:string[@key='type']"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Feittypes sectie -->
  <xsl:template match="fn:map[@key='factTypes']">
    <xsl:for-each select="fn:map">
      <xsl:variable name="fact-name" select="@key"/>
      <xsl:variable name="relation" select="fn:string[@key='relation']"/>
      
      <!-- Feittype header -->
      <xsl:text>Feittype </xsl:text>
      <xsl:call-template name="format-name">
        <xsl:with-param name="name" select="$fact-name"/>
      </xsl:call-template>
      <xsl:text>&#10;</xsl:text>
      
      <!-- Rollen verwerken -->
      <xsl:variable name="roles" select="fn:array[@key='roles']/fn:map"/>
      <xsl:for-each select="$roles">
        <xsl:variable name="role-name" select="fn:string[@key='name']"/>
        <xsl:variable name="role-article" select="fn:string[@key='article']"/>
        <xsl:variable name="role-plural" select="fn:string[@key='plural']"/>
        <xsl:variable name="object-type-ref" select="fn:map[@key='objectType']/fn:string[@key='$ref']"/>
        <xsl:variable name="object-type-name" select="tokenize($object-type-ref, '/')[last()]"/>
        
        <xsl:value-of select="$role-article"/>
        <xsl:text>&#9;</xsl:text>
        <xsl:value-of select="$role-name"/>
        <xsl:if test="$role-plural">
          <xsl:text> (mv: </xsl:text>
          <xsl:value-of select="$role-plural"/>
          <xsl:text>)</xsl:text>
        </xsl:if>
        <xsl:text>&#9;</xsl:text>
        <xsl:value-of select="replace($object-type-name, '_', ' ')"/>
        <xsl:text>&#10;</xsl:text>
      </xsl:for-each>
      
      <!-- Relatie beschrijving -->
      <xsl:if test="count($roles) >= 2 and $relation">
        <xsl:variable name="first-role" select="$roles[1]"/>
        <xsl:variable name="second-role" select="$roles[2]"/>
        <xsl:variable name="first-cardinality" select="$first-role/fn:string[@key='cardinality']"/>
        <xsl:variable name="second-cardinality" select="$second-role/fn:string[@key='cardinality']"/>
        
        <xsl:choose>
          <xsl:when test="$first-cardinality = 'one'">één</xsl:when>
          <xsl:otherwise>meerdere</xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$first-role/fn:string[@key='name']"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$relation"/>
        <xsl:text> </xsl:text>
        <xsl:choose>
          <xsl:when test="$second-cardinality = 'one'">één</xsl:when>
          <xsl:otherwise>meerdere</xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$second-role/fn:string[@key='name']"/>
        <xsl:text>&#10;</xsl:text>
      </xsl:if>
      
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- Parameters sectie -->
  <xsl:template match="fn:map[@key='parameters']">
    <xsl:for-each select="fn:map">
      <xsl:variable name="param-name" select="@key"/>
      <xsl:variable name="param-article" select="fn:string[@key='article']"/>
      
      <xsl:text>Parameter </xsl:text>
      <xsl:value-of select="$param-article"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="replace($param-name, '_', ' ')"/>
      <xsl:text> : </xsl:text>
      <xsl:apply-templates select="fn:map[@key='datatype']" mode="format-datatype"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
    
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- Domeinen sectie -->
  <xsl:template match="fn:map[@key='domains']">
    <xsl:text>// DOMEINEN&#10;</xsl:text>
    
    <xsl:for-each select="fn:map[not(fn:array[@key='values'])]">
      <xsl:variable name="domain-name" select="@key"/>
      <xsl:variable name="domain-type" select="fn:string[@key='type']"/>
      <xsl:variable name="precision" select="fn:number[@key='precision']"/>
      <xsl:variable name="unit" select="fn:string[@key='unit']"/>
      
      <xsl:text>Domein </xsl:text>
      <xsl:value-of select="$domain-name"/>
      <xsl:text> is van het type </xsl:text>
      
      <xsl:choose>
        <xsl:when test="$domain-type = 'numeric' and $precision > 0">
          <xsl:text>Numeriek ( getal met </xsl:text>
          <xsl:value-of select="$precision"/>
          <xsl:text> decimalen )</xsl:text>
        </xsl:when>
        <xsl:when test="$domain-type = 'percentage'">
          <xsl:text>Percentage ( geheel getal )</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="format-name">
            <xsl:with-param name="name" select="$domain-type"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
      
      <xsl:if test="$unit">
        <xsl:text> met eenheid </xsl:text>
        <xsl:value-of select="replace($unit, '/', ' / ')"/>
      </xsl:if>
      
      <xsl:text>&#10;&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- Hulp template voor naam formatting -->
  <xsl:template name="format-name">
    <xsl:param name="name"/>
    <xsl:value-of select="replace(replace($name, '_', ' '), '(\w)(\w*)', '$1$2', 'i')"/>
  </xsl:template>

</xsl:stylesheet>