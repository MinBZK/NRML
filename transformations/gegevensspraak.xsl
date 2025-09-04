<?xml version="1.0" encoding="UTF-8"?>
<!--
  Gegevensspraak Transformatie - Simplified
  NRML UUID-based JSON naar Nederlandse Objectmodel Representatie
  
  Transformeert NRML specificaties naar leesbare Nederlandse gegevensspraak
  voor objectmodellen, feittypes en parameters met UUID support en meertaligheid.
-->
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fn="http://www.w3.org/2005/xpath-functions"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="fn xs">

    <!-- Include translations module -->
    <xsl:include href="translations.xsl"/>

    <!-- Output configuratie voor platte tekst -->
    <xsl:output method="text" encoding="UTF-8" indent="no"/>

    <!-- Parameters -->
    <xsl:param name="language" select="'nl'" as="xs:string"/>
    <xsl:param name="input-file" as="xs:string"/>


    <!-- Initial template voor JSON transformatie -->
    <xsl:template name="main">
        <xsl:param name="json-input" as="xs:string?" select="unparsed-text($input-file)"/>
        <xsl:variable name="xml-data" select="json-to-xml($json-input)"/>
        <xsl:apply-templates select="$xml-data"/>
    </xsl:template>

    <!-- Root template -->
    <xsl:template match="fn:map[fn:string[@key='$schema']]">
        <!-- Process facts - filter by type -->
        <xsl:variable name="facts" select="fn:map[@key='facts']"/>
        
        <!-- Objecttypes verwerken -->
        <xsl:apply-templates select="$facts" mode="objectTypes"/>

        <!-- Feittypes verwerken -->
        <xsl:apply-templates select="$facts" mode="factTypes"/>

        <!-- Parameters verwerken -->
        <xsl:apply-templates select="$facts" mode="parameters"/>

        <!-- Domeinen verwerken -->
        <xsl:apply-templates select="$facts" mode="domains"/>
    </xsl:template>

    <!-- Objecttypes sectie -->
    <xsl:template match="fn:map[@key='facts']" mode="objectTypes">
        <!-- Select facts that are object types (have definite_article or animated) -->
        <xsl:for-each select="fn:map[fn:map[@key='definite_article'] or fn:boolean[@key='animated']]">
            <xsl:variable name="object-name" select="fn:map[@key='name']/fn:string[@key=$language]"/>
            <xsl:variable name="article" select="fn:map[@key='definite_article']/fn:string[@key=$language]"/>
            <xsl:variable name="animated" select="fn:boolean[@key='animated'] = true()"/>

            <!-- Objecttype header -->
            <xsl:call-template name="translate">
              <xsl:with-param name="key">objecttype</xsl:with-param>
              <xsl:with-param name="language" select="$language"/>
            </xsl:call-template>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$article"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$object-name"/>
            <xsl:if test="$animated">
                <xsl:text> </xsl:text>
                <xsl:call-template name="translate">
                  <xsl:with-param name="key">animated</xsl:with-param>
                  <xsl:with-param name="language" select="$language"/>
                </xsl:call-template>
            </xsl:if>
            <xsl:text>&#10;</xsl:text>

            <!-- Properties verwerken -->
            <xsl:apply-templates select="fn:map[@key='items']" mode="properties"/>

            <xsl:text>&#10;</xsl:text>
        </xsl:for-each>
    </xsl:template>

    <!-- Properties binnen objecttype -->
    <xsl:template match="fn:map[@key='items']" mode="properties">
        <xsl:for-each select="fn:map">
            <xsl:variable name="property-name" select="fn:map[@key='name']/fn:string[@key=$language]"/>
            <xsl:variable name="property-article" select="fn:map[@key='article']/fn:string[@key=$language]"/>
            <xsl:variable name="plural" select="fn:map[@key='plural']/fn:string[@key=$language]"/>
            <xsl:variable name="version" select="fn:array[@key='versions']/fn:map[1]"/>
            <xsl:variable name="property-type" select="$version/fn:string[@key='type']"/>
            <xsl:variable name="subtype" select="$version/fn:string[@key='subtype']"/>

            <xsl:choose>
                <!-- Characteristics -->
                <xsl:when test="$property-type = 'characteristic'">
                    <xsl:choose>
                        <xsl:when test="$subtype = 'possessive'">
                            <xsl:value-of select="if ($property-article) then $property-article else 'het'"/>
                            <xsl:text>&#9;</xsl:text>
                            <xsl:value-of select="$property-name"/>
                            <xsl:text>&#9;</xsl:text>
                            <xsl:call-template name="translate">
                              <xsl:with-param name="key">characteristic-possessive</xsl:with-param>
                              <xsl:with-param name="language" select="$language"/>
                            </xsl:call-template>
                            <xsl:text>&#10;</xsl:text>
                        </xsl:when>
                        <xsl:when test="$subtype = 'adjective'">
                            <xsl:text>is&#9;</xsl:text>
                            <xsl:value-of select="$property-name"/>
                            <xsl:text>&#9;</xsl:text>
                            <xsl:call-template name="translate">
                              <xsl:with-param name="key">characteristic-adjective</xsl:with-param>
                              <xsl:with-param name="language" select="$language"/>
                            </xsl:call-template>
                            <xsl:text>&#10;</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="if ($property-article) then $property-article else 'de'"/>
                            <xsl:text>&#9;</xsl:text>
                            <xsl:value-of select="$property-name"/>
                            <xsl:text>&#9;</xsl:text>
                            <xsl:call-template name="translate">
                              <xsl:with-param name="key">characteristic</xsl:with-param>
                              <xsl:with-param name="language" select="$language"/>
                            </xsl:call-template>
                            <xsl:text>&#10;</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>

                <!-- Attributes -->
                <xsl:otherwise>
                    <xsl:value-of select="if ($property-article) then $property-article else 'de'"/>
                    <xsl:text>&#9;</xsl:text>
                    <xsl:value-of select="$property-name"/>
                    <xsl:if test="$plural">
                        <xsl:text> (</xsl:text>
                        <xsl:call-template name="translate">
                          <xsl:with-param name="key">plural-indicator</xsl:with-param>
                          <xsl:with-param name="language" select="$language"/>
                        </xsl:call-template>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$plural"/>
                        <xsl:text>)</xsl:text>
                    </xsl:if>
                    <xsl:text>&#9;</xsl:text>
                    <xsl:call-template name="format-datatype">
                        <xsl:with-param name="property" select="$version"/>
                    </xsl:call-template>
                    <xsl:text>&#10;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <!-- Feittypes sectie -->
    <xsl:template match="fn:map[@key='facts']" mode="factTypes">
        <!-- Select facts that are fact types (have relation field) -->
        <xsl:for-each select="fn:map[fn:string[@key='relation']]">
            <xsl:variable name="fact-name" select="fn:map[@key='name']/fn:string[@key=$language]"/>
            <xsl:variable name="relation" select="fn:string[@key='relation']"/>
            <xsl:variable name="relation-item" select="fn:map[@key='items']/fn:map[1]"/>
            <xsl:variable name="version" select="$relation-item/fn:array[@key='versions']/fn:map[1]"/>
            <xsl:variable name="role-a" select="$version/fn:map[@key='a']"/>
            <xsl:variable name="role-b" select="$version/fn:map[@key='b']"/>

            <!-- Feittype header -->
            <xsl:call-template name="translate">
              <xsl:with-param name="key">facttype</xsl:with-param>
              <xsl:with-param name="language" select="$language"/>
            </xsl:call-template>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$fact-name"/>
            <xsl:text>&#10;</xsl:text>

            <!-- Display roles -->
            <xsl:if test="$role-a">
                <xsl:variable name="role-name" select="$role-a/fn:map[@key='name']/fn:string[@key=$language]"/>
                <xsl:variable name="role-article" select="$role-a/fn:map[@key='article']/fn:string[@key=$language]"/>
                <xsl:variable name="role-plural" select="$role-a/fn:map[@key='plural']/fn:string[@key=$language]"/>

                <xsl:value-of select="if ($role-article) then $role-article else 'de'"/>
                <xsl:text>&#9;</xsl:text>
                <xsl:value-of select="$role-name"/>
                <xsl:if test="$role-plural">
                    <xsl:text> (</xsl:text>
                    <xsl:call-template name="translate">
                      <xsl:with-param name="key">plural-indicator</xsl:with-param>
                      <xsl:with-param name="language" select="$language"/>
                    </xsl:call-template>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$role-plural"/>
                    <xsl:text>)</xsl:text>
                </xsl:if>
                <xsl:text>&#9;</xsl:text>
                <!-- Resolve object name from UUID reference -->
                <xsl:call-template name="resolve-fact-name">
                    <xsl:with-param name="ref" select="$role-a/fn:map[@key='objectType']/fn:string[@key='$ref']"/>
                </xsl:call-template>
                <xsl:text>&#10;</xsl:text>
            </xsl:if>

            <xsl:if test="$role-b">
                <xsl:variable name="role-name" select="$role-b/fn:map[@key='name']/fn:string[@key=$language]"/>
                <xsl:variable name="role-article" select="$role-b/fn:map[@key='article']/fn:string[@key=$language]"/>
                <xsl:variable name="role-plural" select="$role-b/fn:map[@key='plural']/fn:string[@key=$language]"/>

                <xsl:value-of select="if ($role-article) then $role-article else 'de'"/>
                <xsl:text>&#9;</xsl:text>
                <xsl:value-of select="$role-name"/>
                <xsl:if test="$role-plural">
                    <xsl:text> (</xsl:text>
                    <xsl:call-template name="translate">
                      <xsl:with-param name="key">plural-indicator</xsl:with-param>
                      <xsl:with-param name="language" select="$language"/>
                    </xsl:call-template>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$role-plural"/>
                    <xsl:text>)</xsl:text>
                </xsl:if>
                <xsl:text>&#9;</xsl:text>
                <!-- Resolve object name from UUID reference -->
                <xsl:call-template name="resolve-fact-name">
                    <xsl:with-param name="ref" select="$role-b/fn:map[@key='objectType']/fn:string[@key='$ref']"/>
                </xsl:call-template>
                <xsl:text>&#10;</xsl:text>
            </xsl:if>

            <!-- Relatie beschrijving -->
            <xsl:if test="$role-a and $role-b and $relation">
                <xsl:variable name="first-cardinality" select="$role-a/fn:string[@key='cardinality']"/>
                <xsl:variable name="second-cardinality" select="$role-b/fn:string[@key='cardinality']"/>

                <xsl:choose>
                    <xsl:when test="$first-cardinality = 'one'">
                        <xsl:call-template name="translate">
                          <xsl:with-param name="key">one</xsl:with-param>
                          <xsl:with-param name="language" select="$language"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="translate">
                          <xsl:with-param name="key">multiple</xsl:with-param>
                          <xsl:with-param name="language" select="$language"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> </xsl:text>
                <xsl:choose>
                    <xsl:when test="$first-cardinality = 'many' and $role-a/fn:map[@key='plural']/fn:string[@key=$language]">
                        <xsl:value-of select="$role-a/fn:map[@key='plural']/fn:string[@key=$language]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$role-a/fn:map[@key='name']/fn:string[@key=$language]"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> </xsl:text>
                <xsl:value-of select="$relation"/>
                <xsl:text> </xsl:text>
                <xsl:choose>
                    <xsl:when test="$second-cardinality = 'one'">
                        <xsl:call-template name="translate">
                          <xsl:with-param name="key">one</xsl:with-param>
                          <xsl:with-param name="language" select="$language"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="translate">
                          <xsl:with-param name="key">multiple</xsl:with-param>
                          <xsl:with-param name="language" select="$language"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> </xsl:text>
                <xsl:choose>
                    <xsl:when test="$second-cardinality = 'many' and $role-b/fn:map[@key='plural']/fn:string[@key=$language]">
                        <xsl:value-of select="$role-b/fn:map[@key='plural']/fn:string[@key=$language]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$role-b/fn:map[@key='name']/fn:string[@key=$language]"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text>&#10;</xsl:text>
            </xsl:if>

            <xsl:text>&#10;</xsl:text>
        </xsl:for-each>
    </xsl:template>

    <!-- Parameters sectie -->
    <xsl:template match="fn:map[@key='facts']" mode="parameters">
        <!-- Select facts that are parameters (ALL CAPS names in Dutch) -->
        <xsl:for-each select="fn:map[matches(fn:map[@key='name']/fn:string[@key='nl'], '^[A-Z][A-Z0-9\s]*$')]">
            <xsl:variable name="param-name" select="fn:map[@key='name']/fn:string[@key=$language]"/>
            <xsl:variable name="item" select="fn:map[@key='items']/fn:map[1]"/>
            <xsl:variable name="param-article" select="$item/fn:map[@key='article']/fn:string[@key=$language]"/>
            <xsl:variable name="version" select="$item/fn:array[@key='versions']/fn:map[1]"/>

            <xsl:call-template name="translate">
              <xsl:with-param name="key">parameter</xsl:with-param>
              <xsl:with-param name="language" select="$language"/>
            </xsl:call-template>
            <xsl:text> </xsl:text>
            <xsl:value-of select="if ($param-article) then $param-article else 'het'"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$param-name"/>
            <xsl:text> : </xsl:text>
            <xsl:call-template name="format-datatype">
                <xsl:with-param name="property" select="$version"/>
            </xsl:call-template>
            <xsl:text>&#10;</xsl:text>
        </xsl:for-each>

        <xsl:text>&#10;</xsl:text>
    </xsl:template>

    <!-- Domeinen sectie -->
    <xsl:template match="fn:map[@key='facts']" mode="domains">
        <xsl:call-template name="translate">
          <xsl:with-param name="key">domains-header</xsl:with-param>
          <xsl:with-param name="language" select="$language"/>
        </xsl:call-template>
        <xsl:text>&#10;</xsl:text>

        <!-- Select facts that are domains (not objectTypes, factTypes, parameters, ruleGroups, or enumerations) -->
        <xsl:for-each select="fn:map[not(fn:map[@key='definite_article'] or fn:boolean[@key='animated'] or fn:string[@key='relation'] or matches(fn:map[@key='name']/fn:string[@key='nl'], '^[A-Z][A-Z0-9\s]*$') or fn:map[@key='items']/fn:map/fn:array[@key='versions']/fn:map[fn:map[@key='target'] or fn:map[@key='condition'] or fn:map[@key='expression']]) and not(fn:array[@key='values']) and not(fn:map[@key='items']/fn:map/fn:array[@key='versions']/fn:map[fn:string[@key='type'] = 'enumeration'])]">
            <xsl:variable name="domain-name" select="fn:map[@key='name']/fn:string[@key=$language]"/>
            <xsl:variable name="version" select="fn:map[@key='items']/fn:map[1]/fn:array[@key='versions']/fn:map[1]"/>
            <xsl:variable name="domain-type" select="$version/fn:string[@key='type']"/>
            <xsl:variable name="precision" select="if ($version/fn:number[@key='precision']) then $version/fn:number[@key='precision'] else number($version/fn:string[@key='precision'])"/>
            <xsl:variable name="unit" select="$version/fn:string[@key='unit']"/>

            <xsl:call-template name="translate">
              <xsl:with-param name="key">domain</xsl:with-param>
              <xsl:with-param name="language" select="$language"/>
            </xsl:call-template>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$domain-name"/>
            <xsl:text> </xsl:text>
            <xsl:call-template name="translate">
              <xsl:with-param name="key">domain-type</xsl:with-param>
              <xsl:with-param name="language" select="$language"/>
            </xsl:call-template>
            <xsl:text> </xsl:text>

            <xsl:choose>
                <xsl:when test="$domain-type = 'numeric' and $precision > 0">
                    <xsl:call-template name="translate">
                      <xsl:with-param name="key">numeric-decimal</xsl:with-param>
                      <xsl:with-param name="language" select="$language"/>
                    </xsl:call-template>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$precision"/>
                    <xsl:text> </xsl:text>
                    <xsl:call-template name="translate">
                      <xsl:with-param name="key">decimals</xsl:with-param>
                      <xsl:with-param name="language" select="$language"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$domain-type = 'percentage'">
                    <xsl:call-template name="translate">
                      <xsl:with-param name="key">percentage-integer</xsl:with-param>
                      <xsl:with-param name="language" select="$language"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$domain-type"/>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:if test="$unit">
                <xsl:text> </xsl:text>
                <xsl:call-template name="translate">
                  <xsl:with-param name="key">with-unit</xsl:with-param>
                  <xsl:with-param name="language" select="$language"/>
                </xsl:call-template>
                <xsl:text> </xsl:text>
                <xsl:value-of select="replace($unit, '/', ' / ')"/>
            </xsl:if>

            <xsl:text>&#10;&#10;</xsl:text>
        </xsl:for-each>
    </xsl:template>

    <!-- Helper: Format datatype -->
    <xsl:template name="format-datatype">
        <xsl:param name="property"/>

        <xsl:choose>
            <!-- Nested type with reference -->
            <xsl:when test="$property/fn:map[@key='type']/fn:string[@key='$ref']">
                <xsl:variable name="ref-parts"
                              select="tokenize($property/fn:map[@key='type']/fn:string[@key='$ref'], '/')"/>
                <xsl:call-template name="resolve-fact-name">
                    <xsl:with-param name="ref" select="$property/fn:map[@key='type']/fn:string[@key='$ref']"/>
                </xsl:call-template>
            </xsl:when>

            <!-- Direct type field -->
            <xsl:when test="$property/fn:string[@key='type']">
                <xsl:call-template name="format-type">
                    <xsl:with-param name="type" select="$property/fn:string[@key='type']"/>
                    <xsl:with-param name="subtype" select="$property/fn:string[@key='subtype']"/>
                    <xsl:with-param name="precision" select="$property/fn:string[@key='precision']"/>
                    <xsl:with-param name="unit" select="$property/fn:string[@key='unit']"/>
                </xsl:call-template>
            </xsl:when>

            <!-- Fallback -->
            <xsl:otherwise>
                <xsl:text>UNKNOWN_TYPE</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Helper: Format type -->
    <xsl:template name="format-type">
        <xsl:param name="type"/>
        <xsl:param name="subtype"/>
        <xsl:param name="precision"/>
        <xsl:param name="unit"/>

        <xsl:choose>
            <!-- Numeriek type -->
            <xsl:when test="$type = 'numeric'">
                <xsl:call-template name="translate">
                  <xsl:with-param name="key">numeric-type</xsl:with-param>
                  <xsl:with-param name="language" select="$language"/>
                </xsl:call-template>
                <xsl:text> </xsl:text>
                <xsl:choose>
                    <xsl:when test="$subtype = 'integer'">
                        <xsl:call-template name="translate">
                          <xsl:with-param name="key">whole-number</xsl:with-param>
                          <xsl:with-param name="language" select="$language"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="number($precision) > 0">
                        <xsl:call-template name="translate">
                          <xsl:with-param name="key">number-with</xsl:with-param>
                          <xsl:with-param name="language" select="$language"/>
                        </xsl:call-template>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$precision"/>
                        <xsl:text> </xsl:text>
                        <xsl:call-template name="translate">
                          <xsl:with-param name="key">decimals</xsl:with-param>
                          <xsl:with-param name="language" select="$language"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="translate">
                          <xsl:with-param name="key">number</xsl:with-param>
                          <xsl:with-param name="language" select="$language"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> )</xsl:text>

                <xsl:if test="$unit">
                    <xsl:text> </xsl:text>
                    <xsl:call-template name="translate">
                      <xsl:with-param name="key">with-unit</xsl:with-param>
                      <xsl:with-param name="language" select="$language"/>
                    </xsl:call-template>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$unit"/>
                </xsl:if>
            </xsl:when>

            <!-- Datum type -->
            <xsl:when test="$type = 'date'">
                <xsl:choose>
                    <xsl:when test="$precision = 'days'">
                        <xsl:call-template name="translate">
                          <xsl:with-param name="key">date-in-days</xsl:with-param>
                          <xsl:with-param name="language" select="$language"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="translate">
                          <xsl:with-param name="key">datetime-milliseconds</xsl:with-param>
                          <xsl:with-param name="language" select="$language"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!-- Percentage type -->
            <xsl:when test="$type = 'percentage'">
                <xsl:call-template name="translate">
                  <xsl:with-param name="key">percentage-type</xsl:with-param>
                  <xsl:with-param name="language" select="$language"/>
                </xsl:call-template>
                <xsl:text> </xsl:text>
                <xsl:choose>
                    <xsl:when test="$subtype = 'integer'">
                        <xsl:call-template name="translate">
                          <xsl:with-param name="key">whole-number</xsl:with-param>
                          <xsl:with-param name="language" select="$language"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="translate">
                          <xsl:with-param name="key">percentage-value</xsl:with-param>
                          <xsl:with-param name="language" select="$language"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> )</xsl:text>
            </xsl:when>

            <!-- Andere types -->
            <xsl:when test="$type = 'boolean'">
                <xsl:call-template name="translate">
                  <xsl:with-param name="key">boolean-type</xsl:with-param>
                  <xsl:with-param name="language" select="$language"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'text'">
                <xsl:call-template name="translate">
                  <xsl:with-param name="key">text-type</xsl:with-param>
                  <xsl:with-param name="language" select="$language"/>
                </xsl:call-template>
            </xsl:when>

            <!-- Fallback -->
            <xsl:otherwise>
                <xsl:value-of select="$type"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Helper: Resolve fact name from UUID reference -->
    <xsl:template name="resolve-fact-name">
        <xsl:param name="ref"/>
        <xsl:variable name="ref-parts" select="tokenize($ref, '/')"/>
        <xsl:variable name="uuid" select="$ref-parts[last()]"/>

        <!-- Look up in facts -->
        <xsl:variable name="fact" select="//fn:map[@key='facts']/fn:map[@key=$uuid]"/>
        <xsl:choose>
            <xsl:when test="$fact">
                <xsl:variable name="name" select="$fact/fn:map[@key='name']/fn:string[@key=$language]"/>
                <xsl:value-of select="if ($name) then $name else 'UNKNOWN_FACT'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>UNKNOWN_FACT</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>