<?xml version="1.0" encoding="UTF-8"?>
<!--
  Gegevensspraak Transformatie v2.0
  NRML Multilingual UUID-based JSON naar Nederlandse Objectmodel Representatie
  
  Transformeert NRML v2 specificaties naar leesbare Nederlandse gegevensspraak
  voor objectmodellen, feittypes en parameters met UUID support en meertaligheid.
-->
<xsl:stylesheet version="3.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fn="http://www.w3.org/2005/xpath-functions"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="fn xs">

  <!-- Output configuratie voor platte tekst -->
  <xsl:output method="text" encoding="UTF-8" indent="no"/>
  
  <!-- Parameters -->
  <xsl:param name="language" select="'nl'" as="xs:string"/>
  <xsl:param name="input-file" select="'../toka.nrml.json'" as="xs:string"/>
  
  <!-- Initial template voor JSON transformatie -->
  <xsl:template name="main">
    <xsl:param name="json-input" as="xs:string?" select="unparsed-text($input-file)"/>
    <xsl:variable name="xml-data" select="json-to-xml($json-input)"/>
    <xsl:apply-templates select="$xml-data"/>
  </xsl:template>
  
  <!-- Root template - detecteert automatisch het formaat -->
  <xsl:template match="fn:map[fn:string[@key='$schema']]">
    <xsl:choose>
      <!-- Nieuwe v2 formaat met version en language -->
      <xsl:when test="fn:string[@key='version'] and fn:string[@key='language']">
        <xsl:call-template name="process-v2-format"/>
      </xsl:when>
      <!-- Oude formaat (fallback) -->
      <xsl:otherwise>
        <xsl:call-template name="process-v1-format"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Verwerk nieuwe v2 formaat -->
  <xsl:template name="process-v2-format">
    <!-- Objecttypes verwerken -->
    <xsl:apply-templates select="fn:map[@key='objectTypes']" mode="v2"/>
    
    <!-- Feittypes verwerken -->
    <xsl:apply-templates select="fn:map[@key='factTypes']" mode="v2"/>
    
    <!-- Parameters verwerken -->
    <xsl:apply-templates select="fn:map[@key='parameters']" mode="v2"/>
    
    <!-- Domeinen verwerken -->
    <xsl:apply-templates select="fn:map[@key='domains']" mode="v2"/>
  </xsl:template>

  <!-- Verwerk oude v1 formaat (fallback) -->
  <xsl:template name="process-v1-format">
    <!-- Objecttypes verwerken -->
    <xsl:apply-templates select="fn:map[@key='objectTypes']" mode="v1"/>
    
    <!-- Feittypes verwerken -->
    <xsl:apply-templates select="fn:map[@key='factTypes']" mode="v1"/>
    
    <!-- Parameters verwerken -->
    <xsl:apply-templates select="fn:map[@key='parameters']" mode="v1"/>
    
    <!-- Domeinen verwerken -->
    <xsl:apply-templates select="fn:map[@key='domains']" mode="v1"/>
  </xsl:template>

  <!-- ====================== V2 FORMAT TEMPLATES ====================== -->

  <!-- V2 Objecttypes sectie -->
  <xsl:template match="fn:map[@key='objectTypes']" mode="v2">
    <xsl:for-each select="fn:map">
      <xsl:variable name="object-uuid" select="@key"/>
      <xsl:variable name="object-name" select="fn:map[@key='name']/fn:string[@key=$language]"/>
      <xsl:variable name="article" select="fn:map[@key='definite_article']/fn:string[@key=$language]"/>
      <xsl:variable name="animated" select="fn:boolean[@key='animated'] = true()"/>
      
      <!-- Objecttype header -->
      <xsl:text>Objecttype </xsl:text>
      <xsl:value-of select="$article"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="$object-name"/>
      <xsl:if test="$animated">
        <xsl:text> (bezield)</xsl:text>
      </xsl:if>
      <xsl:text>&#10;</xsl:text>
      
      <!-- Properties verwerken -->
      <xsl:apply-templates select="fn:map[@key='properties']" mode="v2">
        <xsl:with-param name="object-name" select="$object-name"/>
      </xsl:apply-templates>
      
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- V2 Properties binnen objecttype -->
  <xsl:template match="fn:map[@key='properties']" mode="v2">
    <xsl:param name="object-name"/>
    
    <xsl:for-each select="fn:map">
      <xsl:variable name="property-uuid" select="@key"/>
      <xsl:variable name="property-name" select="fn:map[@key='name']/fn:string[@key=$language]"/>
      <xsl:variable name="property-type" select="fn:string[@key='type']"/>
      <xsl:variable name="property-article" select="fn:map[@key='article']/fn:string[@key=$language]"/>
      <xsl:variable name="subtype" select="fn:string[@key='subtype']"/>
      <xsl:variable name="plural" select="fn:map[@key='plural']/fn:string[@key=$language]"/>
      
      <xsl:choose>
        <!-- Characteristics -->
        <xsl:when test="$property-type = 'characteristic'">
          <xsl:choose>
            <xsl:when test="$subtype = 'possessive'">
              <xsl:value-of select="if ($property-article) then $property-article else 'het'"/>
              <xsl:text>&#9;</xsl:text>
              <xsl:value-of select="$property-name"/>
              <xsl:text>&#9;kenmerk (bezittelijk)&#10;</xsl:text>
            </xsl:when>
            <xsl:when test="$subtype = 'adjective'">
              <xsl:text>is&#9;</xsl:text>
              <xsl:value-of select="$property-name"/>
              <xsl:text>&#9;kenmerk (bijvoeglijk)&#10;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="if ($property-article) then $property-article else 'de'"/>
              <xsl:text>&#9;</xsl:text>
              <xsl:value-of select="$property-name"/>
              <xsl:text>&#9;kenmerk&#10;</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        
        <!-- Attributes (now type is the datatype content directly) -->
        <xsl:otherwise>
          <xsl:value-of select="if ($property-article) then $property-article else 'de'"/>
          <xsl:text>&#9;</xsl:text>
          <xsl:value-of select="$property-name"/>
          <xsl:if test="$plural">
            <xsl:text> (mv: </xsl:text>
            <xsl:value-of select="$plural"/>
            <xsl:text>)</xsl:text>
          </xsl:if>
          <xsl:text>&#9;</xsl:text>
          <xsl:apply-templates select="." mode="format-direct-datatype"/>
          <xsl:text>&#10;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- V2 Feittypes sectie -->
  <xsl:template match="fn:map[@key='factTypes']" mode="v2">
    <xsl:for-each select="fn:map">
      <xsl:variable name="fact-uuid" select="@key"/>
      <xsl:variable name="fact-name" select="fn:map[@key='name']/fn:string[@key=$language]"/>
      <xsl:variable name="relation" select="fn:string[@key='relation']"/>
      
      <!-- Feittype header -->
      <xsl:text>Feittype </xsl:text>
      <xsl:value-of select="$fact-name"/>
      <xsl:text>&#10;</xsl:text>
      
      <!-- Rollen verwerken (nu een map in plaats van array) -->
      <xsl:variable name="roles" select="fn:map[@key='roles']/fn:map"/>
      <xsl:for-each select="$roles">
        <xsl:variable name="role-name" select="fn:map[@key='name']/fn:string[@key=$language]"/>
        <xsl:variable name="role-article" select="fn:map[@key='article']/fn:string[@key=$language]"/>
        <xsl:variable name="role-plural" select="fn:map[@key='plural']/fn:string[@key=$language]"/>
        <xsl:variable name="role-cardinality" select="fn:string[@key='cardinality']"/>
        <xsl:variable name="object-type-ref" select="fn:map[@key='objectType']/fn:string[@key='$ref']"/>
        
        <xsl:value-of select="if ($role-article) then $role-article else 'de'"/>
        <xsl:text>&#9;</xsl:text>
        <xsl:value-of select="$role-name"/>
        <xsl:if test="$role-plural">
          <xsl:text> (mv: </xsl:text>
          <xsl:value-of select="$role-plural"/>
          <xsl:text>)</xsl:text>
        </xsl:if>
        <xsl:text>&#9;</xsl:text>
        <!-- Voor v2 kunnen we de naam uit de referentie halen -->
        <xsl:call-template name="resolve-object-name">
          <xsl:with-param name="ref" select="$object-type-ref"/>
        </xsl:call-template>
        <xsl:text>&#10;</xsl:text>
      </xsl:for-each>
      
      <!-- Relatie beschrijving -->
      <xsl:if test="count($roles) >= 2 and $relation">
        <xsl:variable name="role-list" select="$roles"/>
        <xsl:variable name="first-role" select="$role-list[1]"/>
        <xsl:variable name="second-role" select="$role-list[2]"/>
        <xsl:variable name="first-cardinality" select="$first-role/fn:string[@key='cardinality']"/>
        <xsl:variable name="second-cardinality" select="$second-role/fn:string[@key='cardinality']"/>
        
        <xsl:choose>
          <xsl:when test="$first-cardinality = 'one'">één</xsl:when>
          <xsl:otherwise>meerdere</xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>
        <xsl:choose>
          <xsl:when test="$first-cardinality = 'many' and $first-role/fn:map[@key='plural']/fn:string[@key=$language]">
            <xsl:value-of select="$first-role/fn:map[@key='plural']/fn:string[@key=$language]"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$first-role/fn:map[@key='name']/fn:string[@key=$language]"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$relation"/>
        <xsl:text> </xsl:text>
        <xsl:choose>
          <xsl:when test="$second-cardinality = 'one'">één</xsl:when>
          <xsl:otherwise>meerdere</xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>
        <xsl:choose>
          <xsl:when test="$second-cardinality = 'many' and $second-role/fn:map[@key='plural']/fn:string[@key=$language]">
            <xsl:value-of select="$second-role/fn:map[@key='plural']/fn:string[@key=$language]"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$second-role/fn:map[@key='name']/fn:string[@key=$language]"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>&#10;</xsl:text>
      </xsl:if>
      
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- V2 Parameters sectie -->
  <xsl:template match="fn:map[@key='parameters']" mode="v2">
    <xsl:for-each select="fn:map">
      <xsl:variable name="param-uuid" select="@key"/>
      <xsl:variable name="param-name" select="fn:map[@key='name']/fn:string[@key=$language]"/>
      <xsl:variable name="param-article" select="fn:map[@key='article']/fn:string[@key=$language]"/>
      
      <xsl:text>Parameter </xsl:text>
      <xsl:value-of select="if ($param-article) then $param-article else 'het'"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="$param-name"/>
      <xsl:text> : </xsl:text>
      <xsl:apply-templates select="." mode="format-direct-datatype"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
    
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- V2 Domeinen sectie -->
  <xsl:template match="fn:map[@key='domains']" mode="v2">
    <xsl:text>// DOMEINEN&#10;</xsl:text>
    
    <xsl:for-each select="fn:map[not(fn:array[@key='values'])]">
      <xsl:variable name="domain-uuid" select="@key"/>
      <xsl:variable name="domain-name" select="fn:map[@key='name']/fn:string[@key=$language]"/>
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
          <xsl:value-of select="$domain-type"/>
        </xsl:otherwise>
      </xsl:choose>
      
      <xsl:if test="$unit">
        <xsl:text> met eenheid </xsl:text>
        <xsl:value-of select="replace($unit, '/', ' / ')"/>
      </xsl:if>
      
      <xsl:text>&#10;&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- ====================== V1 FORMAT TEMPLATES (FALLBACK) ====================== -->

  <!-- V1 Objecttypes sectie -->
  <xsl:template match="fn:map[@key='objectTypes']" mode="v1">
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
      <xsl:apply-templates select="fn:map[@key='properties']" mode="v1">
        <xsl:with-param name="object-name" select="$object-name"/>
      </xsl:apply-templates>
      
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- V1 Properties binnen objecttype -->
  <xsl:template match="fn:map[@key='properties']" mode="v1">
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

  <!-- V1 Feittypes sectie -->
  <xsl:template match="fn:map[@key='factTypes']" mode="v1">
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
        <xsl:variable name="role-cardinality" select="fn:string[@key='cardinality']"/>
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
        <xsl:choose>
          <xsl:when test="$first-cardinality = 'many' and $first-role/fn:string[@key='plural']">
            <xsl:value-of select="$first-role/fn:string[@key='plural']"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$first-role/fn:string[@key='name']"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$relation"/>
        <xsl:text> </xsl:text>
        <xsl:choose>
          <xsl:when test="$second-cardinality = 'one'">één</xsl:when>
          <xsl:otherwise>meerdere</xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>
        <xsl:choose>
          <xsl:when test="$second-cardinality = 'many' and $second-role/fn:string[@key='plural']">
            <xsl:value-of select="$second-role/fn:string[@key='plural']"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$second-role/fn:string[@key='name']"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>&#10;</xsl:text>
      </xsl:if>
      
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- V1 Parameters sectie -->
  <xsl:template match="fn:map[@key='parameters']" mode="v1">
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

  <!-- V1 Domeinen sectie -->
  <xsl:template match="fn:map[@key='domains']" mode="v1">
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

  <!-- ====================== HELPER TEMPLATES ====================== -->

  <!-- Direct datatype formatting for v2 format (where type is directly in property) -->
  <xsl:template match="fn:map" mode="format-direct-datatype">
    <xsl:choose>
      <!-- Nested type with reference -->
      <xsl:when test="fn:map[@key='type']/fn:string[@key='$ref']">
        <xsl:variable name="ref-parts" select="tokenize(fn:map[@key='type']/fn:string[@key='$ref'], '/')"/>
        <xsl:call-template name="resolve-domain-name">
          <xsl:with-param name="uuid" select="$ref-parts[last()]"/>
        </xsl:call-template>
      </xsl:when>
      
      <!-- Direct type field -->
      <xsl:when test="fn:string[@key='type']">
        <xsl:call-template name="format-type">
          <xsl:with-param name="type" select="fn:string[@key='type']"/>
          <xsl:with-param name="subtype" select="fn:string[@key='subtype']"/>
          <xsl:with-param name="precision" select="fn:string[@key='precision']"/>
          <xsl:with-param name="unit" select="fn:string[@key='unit']"/>
        </xsl:call-template>
      </xsl:when>
      
      <!-- Nested type object -->
      <xsl:when test="fn:map[@key='type']">
        <xsl:apply-templates select="fn:map[@key='type']" mode="format-datatype"/>
      </xsl:when>
      
      <!-- Legacy: Reference naar domein directly in root (for backwards compatibility) -->
      <xsl:when test="fn:string[@key='$ref']">
        <xsl:variable name="ref-parts" select="tokenize(fn:string[@key='$ref'], '/')"/>
        <xsl:call-template name="resolve-domain-name">
          <xsl:with-param name="uuid" select="$ref-parts[last()]"/>
        </xsl:call-template>
      </xsl:when>
      
      <!-- Fallback -->
      <xsl:otherwise>
        <xsl:text>UNKNOWN_TYPE</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Datatype formatting -->
  <xsl:template match="fn:map" mode="format-datatype">
    <xsl:choose>
      <!-- Reference naar domein -->
      <xsl:when test="fn:string[@key='$ref']">
        <xsl:variable name="ref-parts" select="tokenize(fn:string[@key='$ref'], '/')"/>
        <xsl:choose>
          <!-- UUID reference (v2) -->
          <xsl:when test="matches($ref-parts[last()], '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$')">
            <xsl:call-template name="resolve-domain-name">
              <xsl:with-param name="uuid" select="$ref-parts[last()]"/>
            </xsl:call-template>
          </xsl:when>
          <!-- String reference (v1) -->
          <xsl:otherwise>
            <xsl:value-of select="$ref-parts[last()]"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      
      <!-- Direct type -->
      <xsl:when test="fn:string[@key='type']">
        <xsl:call-template name="format-type">
          <xsl:with-param name="type" select="fn:string[@key='type']"/>
          <xsl:with-param name="subtype" select="fn:string[@key='subtype']"/>
          <xsl:with-param name="precision" select="fn:string[@key='precision']"/>
          <xsl:with-param name="unit" select="fn:string[@key='unit']"/>
        </xsl:call-template>
      </xsl:when>
      
      <!-- Fallback -->
      <xsl:otherwise>
        <xsl:value-of select="fn:string[@key='type']"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Shared type formatting template -->
  <xsl:template name="format-type">
    <xsl:param name="type"/>
    <xsl:param name="subtype"/>
    <xsl:param name="precision"/>
    <xsl:param name="unit"/>
    
    <xsl:choose>
      <!-- Numeriek type -->
      <xsl:when test="$type = 'numeric'">
        <xsl:text>Numeriek ( </xsl:text>
        <xsl:choose>
          <xsl:when test="$subtype = 'integer'">
            <xsl:text>geheel getal</xsl:text>
          </xsl:when>
          <xsl:when test="number($precision) > 0">
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
      <xsl:when test="$type = 'date'">
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
      <xsl:when test="$type = 'boolean'">
        <xsl:text>Boolean</xsl:text>
      </xsl:when>
      <xsl:when test="$type = 'text'">
        <xsl:text>Tekst</xsl:text>
      </xsl:when>
      <xsl:when test="$type = 'percentage'">
        <xsl:text>Percentage ( </xsl:text>
        <xsl:choose>
          <xsl:when test="$subtype = 'integer'">
            <xsl:text>geheel getal</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>percentage</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text> )</xsl:text>
      </xsl:when>
      
      <!-- Fallback -->
      <xsl:otherwise>
        <xsl:value-of select="$type"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Resolve object name from UUID reference -->
  <xsl:template name="resolve-object-name">
    <xsl:param name="ref"/>
    <xsl:variable name="uuid" select="substring-after($ref, '#/')"/>
    
    <!-- Look up in objectTypes -->
    <xsl:variable name="object-type" select="//fn:map[@key='objectTypes']/fn:map[@key=$uuid]"/>
    <xsl:choose>
      <xsl:when test="$object-type">
        <xsl:variable name="name" select="$object-type/fn:map[@key='name']/fn:string[@key=$language]"/>
        <xsl:value-of select="if ($name) then $name else 'UNKNOWN_OBJECT'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>UNKNOWN_OBJECT</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Resolve domain name from UUID reference -->
  <xsl:template name="resolve-domain-name">
    <xsl:param name="uuid"/>
    
    <!-- Look up in domains -->
    <xsl:variable name="domain" select="//fn:map[@key='domains']/fn:map[@key=$uuid]"/>
    <xsl:choose>
      <xsl:when test="$domain">
        <xsl:variable name="name" select="$domain/fn:map[@key='name']/fn:string[@key=$language]"/>
        <xsl:value-of select="if ($name) then $name else 'UNKNOWN_DOMAIN'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>UNKNOWN_DOMAIN</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Hulp template voor naam formatting -->
  <xsl:template name="format-name">
    <xsl:param name="name"/>
    <xsl:value-of select="replace(replace($name, '_', ' '), '(\w)(\w*)', '$1$2', 'i')"/>
  </xsl:template>

</xsl:stylesheet>