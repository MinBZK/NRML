<?xml version="1.0" encoding="UTF-8"?>
<!--
  Regelspraak Transformatie
  NRML UUID-based JSON naar Nederlandse Regelgeving Representatie
  
  Transformeert NRML specificaties naar leesbare Nederlandse regelspraak
  voor business rules, regelgroepen en condities met UUID support.
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
        <!-- Process facts - find rule groups -->
        <xsl:variable name="facts" select="fn:map[@key='facts']"/>
        
        <!-- Process rule groups -->
        <xsl:apply-templates select="$facts" mode="ruleGroups"/>
    </xsl:template>

    <!-- Rule groups sectie -->
    <xsl:template match="fn:map[@key='facts']" mode="ruleGroups">
        <!-- Select facts that are rule groups (have items with versions containing target, condition, or expression) -->
        <xsl:for-each select="fn:map[fn:map[@key='items']/fn:map/fn:array[@key='versions']/fn:map[fn:map[@key='target'] or fn:map[@key='condition'] or fn:map[@key='expression']]]">
            <xsl:variable name="rule-group-name" select="fn:map[@key='name']/fn:string[@key=$language]"/>
            
            <!-- Rule group header -->
            <xsl:text>Regelgroep </xsl:text>
            <xsl:value-of select="$rule-group-name"/>
            <xsl:text>&#10;&#10;</xsl:text>

            <!-- Process each rule in the group -->
            <xsl:for-each select="fn:map[@key='items']/fn:map">
                <xsl:variable name="rule-name" select="fn:map[@key='name']/fn:string[@key=$language]"/>
                
                <!-- Process each version of the rule -->
                <xsl:for-each select="fn:array[@key='versions']/fn:map">
                    <xsl:variable name="valid-from" select="fn:string[@key='validFrom']"/>
                    <xsl:variable name="valid-to" select="fn:string[@key='validTo']"/>
                    <xsl:variable name="target" select="fn:map[@key='target']"/>
                    <xsl:variable name="condition" select="fn:map[@key='condition']"/>
                    <xsl:variable name="value" select="fn:map[@key='value']"/>
                    
                    <!-- Rule header -->
                    <xsl:text>Regel </xsl:text>
                    <xsl:value-of select="$rule-name"/>
                    <xsl:text>&#10;</xsl:text>
                    
                    <!-- Validity period -->
                    <xsl:choose>
                        <xsl:when test="$valid-to">
                            <xsl:text>geldig van </xsl:text>
                            <xsl:value-of select="$valid-from"/>
                            <xsl:text> t/m </xsl:text>
                            <xsl:value-of select="$valid-to"/>
                            <xsl:text>&#10;</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>geldig vanaf </xsl:text>
                            <xsl:value-of select="$valid-from"/>
                            <xsl:text>&#10;</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    <!-- Rule description -->
                    <xsl:choose>
                        <!-- Initialization rules -->
                        <xsl:when test="$target and $value and not($condition)">
                            <xsl:call-template name="format-initialization-rule">
                                <xsl:with-param name="target" select="$target"/>
                                <xsl:with-param name="value" select="$value"/>
                            </xsl:call-template>
                        </xsl:when>
                        
                        <!-- Conditional rules -->
                        <xsl:when test="$condition">
                            <xsl:call-template name="format-conditional-rule">
                                <xsl:with-param name="target" select="$target"/>
                                <xsl:with-param name="condition" select="$condition"/>
                                <xsl:with-param name="value" select="$value"/>
                            </xsl:call-template>
                        </xsl:when>
                        
                        <!-- Calculation rules -->
                        <xsl:when test="$target and fn:map[@key='expression']">
                            <xsl:call-template name="format-calculation-rule">
                                <xsl:with-param name="target" select="$target"/>
                                <xsl:with-param name="expression" select="fn:map[@key='expression']"/>
                            </xsl:call-template>
                        </xsl:when>
                    </xsl:choose>
                    
                    <xsl:text>&#10;</xsl:text>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <!-- Format initialization rule -->
    <xsl:template name="format-initialization-rule">
        <xsl:param name="target"/>
        <xsl:param name="value"/>
        
        <xsl:call-template name="resolve-target">
            <xsl:with-param name="target" select="$target"/>
            <xsl:with-param name="article">De</xsl:with-param>
        </xsl:call-template>
        <xsl:text> moet geïnitialiseerd worden op </xsl:text>
        <xsl:call-template name="format-value">
            <xsl:with-param name="value" select="$value"/>
        </xsl:call-template>
        <xsl:text>.</xsl:text>
    </xsl:template>

    <!-- Format conditional rule -->
    <xsl:template name="format-conditional-rule">
        <xsl:param name="target"/>
        <xsl:param name="condition"/>
        <xsl:param name="value"/>
        
        <xsl:text>Een </xsl:text>
        <xsl:call-template name="resolve-target-subject">
            <xsl:with-param name="target" select="$target"/>
        </xsl:call-template>
        <xsl:text> is een </xsl:text>
        <xsl:call-template name="resolve-target-attribute">
            <xsl:with-param name="target" select="$target"/>
        </xsl:call-template>
        <xsl:text>&#10;</xsl:text>
        <xsl:call-template name="format-condition">
            <xsl:with-param name="condition" select="$condition"/>
        </xsl:call-template>
        <xsl:text>.</xsl:text>
    </xsl:template>

    <!-- Format calculation rule -->
    <xsl:template name="format-calculation-rule">
        <xsl:param name="target"/>
        <xsl:param name="expression"/>
        
        <xsl:call-template name="resolve-target">
            <xsl:with-param name="target" select="$target"/>
            <xsl:with-param name="article">De</xsl:with-param>
        </xsl:call-template>
        <xsl:text> moet berekend worden als </xsl:text>
        <xsl:call-template name="format-expression">
            <xsl:with-param name="expression" select="$expression"/>
        </xsl:call-template>
        <xsl:text>.</xsl:text>
    </xsl:template>

    <!-- Format condition -->
    <xsl:template name="format-condition">
        <xsl:param name="condition"/>
        <xsl:text>indien </xsl:text>
        <xsl:call-template name="format-expression">
            <xsl:with-param name="expression" select="$condition"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Format expression -->
    <xsl:template name="format-expression">
        <xsl:param name="expression"/>
        
        <xsl:choose>
            <xsl:when test="$expression/fn:string[@key='type'] = 'comparison'">
                <xsl:call-template name="format-comparison">
                    <xsl:with-param name="comparison" select="$expression"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$expression/fn:string[@key='type'] = 'aggregation'">
                <xsl:call-template name="format-aggregation">
                    <xsl:with-param name="aggregation" select="$expression"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$expression/fn:map[@key='role']">
                <xsl:call-template name="format-role-reference">
                    <xsl:with-param name="role" select="$expression"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$expression/fn:map[@key='attribute']">
                <xsl:call-template name="format-attribute-reference">
                    <xsl:with-param name="attr-ref" select="$expression"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>[Complex expression]</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Format aggregation -->
    <xsl:template name="format-aggregation">
        <xsl:param name="aggregation"/>
        <xsl:variable name="function" select="$aggregation/fn:string[@key='function']"/>
        <xsl:variable name="inner-expr" select="$aggregation/fn:map[@key='expression']"/>
        
        <xsl:choose>
            <xsl:when test="$function = 'count'">
                <xsl:text>het aantal </xsl:text>
                <xsl:call-template name="format-expression">
                    <xsl:with-param name="expression" select="$inner-expr"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$function = 'sum'">
                <xsl:text>de som van </xsl:text>
                <xsl:call-template name="format-expression">
                    <xsl:with-param name="expression" select="$inner-expr"/>
                </xsl:call-template>
                <xsl:variable name="default" select="$aggregation/fn:map[@key='default']"/>
                <xsl:if test="$default">
                    <xsl:text>, of </xsl:text>
                    <xsl:call-template name="format-value">
                        <xsl:with-param name="value" select="$default"/>
                    </xsl:call-template>
                    <xsl:text> als die er niet zijn</xsl:text>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>[</xsl:text>
                <xsl:value-of select="$function"/>
                <xsl:text> aggregation]</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Format role reference -->
    <xsl:template name="format-role-reference">
        <xsl:param name="role"/>
        <xsl:variable name="role-ref" select="$role/fn:map[@key='role']/fn:string[@key='$ref']"/>
        
        <xsl:text>de </xsl:text>
        <xsl:call-template name="resolve-path">
            <xsl:with-param name="path" select="$role-ref"/>
        </xsl:call-template>
        <xsl:text> van de </xsl:text>
        
        <!-- Get the subject by extracting fact and role info -->
        <xsl:variable name="path-parts" select="tokenize($role-ref, '/')"/>
        <xsl:variable name="fact-uuid" select="$path-parts[3]"/>
        <xsl:variable name="role-uuid" select="$path-parts[5]"/>
        <xsl:variable name="fact" select="//fn:map[@key='facts']/fn:map[@key=$fact-uuid]"/>
        
        <!-- Determine which role this is and get the other role's objectType -->
        <xsl:variable name="role-a" select="$fact/fn:map[@key='items']/fn:map[1]/fn:array[@key='versions']/fn:map[1]/fn:map[@key='a']"/>
        <xsl:variable name="role-b" select="$fact/fn:map[@key='items']/fn:map[1]/fn:array[@key='versions']/fn:map[1]/fn:map[@key='b']"/>
        
        <xsl:choose>
            <xsl:when test="$role-a/fn:string[@key='uuid'] = $role-uuid">
                <!-- This role is A, so the subject context comes from role B's objectType -->
                <xsl:variable name="object-ref" select="$role-b/fn:map[@key='objectType']/fn:string[@key='$ref']"/>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$object-ref"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$role-b/fn:string[@key='uuid'] = $role-uuid">
                <!-- This role is B, so the subject context comes from role A's objectType -->
                <xsl:variable name="object-ref" select="$role-a/fn:map[@key='objectType']/fn:string[@key='$ref']"/>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$object-ref"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>UNKNOWN_CONTEXT</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Format attribute reference with vias -->
    <xsl:template name="format-attribute-reference">
        <xsl:param name="attr-ref"/>
        <xsl:variable name="attribute" select="$attr-ref/fn:map[@key='attribute']/fn:string[@key='$ref']"/>
        <xsl:variable name="vias" select="$attr-ref/fn:array[@key='vias']"/>
        
        <xsl:text>de </xsl:text>
        <xsl:call-template name="resolve-path">
            <xsl:with-param name="path" select="$attribute"/>
        </xsl:call-template>
        
        <!-- Process vias chain -->
        <xsl:if test="$vias">
            <xsl:for-each select="$vias/fn:map">
                <xsl:variable name="via-ref" select="fn:string[@key='$ref']"/>
                <xsl:text> van </xsl:text>
                
                <!-- Determine if this is the last via -->
                <xsl:choose>
                    <xsl:when test="position() = last()">
                        <xsl:text>alle </xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>de </xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$via-ref"/>
                </xsl:call-template>
            </xsl:for-each>
            
            <!-- Add contextual subject -->
            <xsl:text> van de </xsl:text>
            
            <!-- Get the final context object from the last via -->
            <xsl:variable name="last-via" select="$vias/fn:map[last()]/fn:string[@key='$ref']"/>
            <xsl:variable name="last-via-parts" select="tokenize($last-via, '/')"/>
            <xsl:variable name="fact-uuid" select="$last-via-parts[3]"/>
            <xsl:variable name="role-uuid" select="$last-via-parts[5]"/>
            <xsl:variable name="fact" select="//fn:map[@key='facts']/fn:map[@key=$fact-uuid]"/>
            
            <!-- Get the opposite role's objectType -->
            <xsl:variable name="role-a" select="$fact/fn:map[@key='items']/fn:map[1]/fn:array[@key='versions']/fn:map[1]/fn:map[@key='a']"/>
            <xsl:variable name="role-b" select="$fact/fn:map[@key='items']/fn:map[1]/fn:array[@key='versions']/fn:map[1]/fn:map[@key='b']"/>
            
            <xsl:choose>
                <xsl:when test="$role-b/fn:string[@key='uuid'] = $role-uuid">
                    <!-- This is role B (passagier), context comes from role A (vlucht) -->
                    <xsl:variable name="object-ref" select="$role-a/fn:map[@key='objectType']/fn:string[@key='$ref']"/>
                    <xsl:call-template name="resolve-path">
                        <xsl:with-param name="path" select="$object-ref"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$role-a/fn:string[@key='uuid'] = $role-uuid">
                    <!-- This is role A (vlucht), context comes from role B (passagier) -->
                    <xsl:variable name="object-ref" select="$role-b/fn:map[@key='objectType']/fn:string[@key='$ref']"/>
                    <xsl:call-template name="resolve-path">
                        <xsl:with-param name="path" select="$object-ref"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>UNKNOWN_VIA_CONTEXT</xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- Format comparison -->
    <xsl:template name="format-comparison">
        <xsl:param name="comparison"/>
        <xsl:variable name="operator" select="$comparison/fn:string[@key='operator']"/>
        <xsl:variable name="left" select="$comparison/fn:map[@key='left']"/>
        <xsl:variable name="right" select="$comparison/fn:map[@key='right']"/>
        
        <xsl:call-template name="format-operand">
            <xsl:with-param name="operand" select="$left"/>
        </xsl:call-template>
        <xsl:text> </xsl:text>
        <xsl:call-template name="format-operator">
            <xsl:with-param name="operator" select="$operator"/>
        </xsl:call-template>
        <xsl:text> </xsl:text>
        <xsl:call-template name="format-operand">
            <xsl:with-param name="operand" select="$right"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Format operator -->
    <xsl:template name="format-operator">
        <xsl:param name="operator"/>
        <xsl:choose>
            <xsl:when test="$operator = 'equals'">gelijk is aan</xsl:when>
            <xsl:when test="$operator = 'notEquals'">ongelijk is aan</xsl:when>
            <xsl:when test="$operator = 'greaterThan'">groter is dan</xsl:when>
            <xsl:when test="$operator = 'lessThan'">kleiner is dan</xsl:when>
            <xsl:when test="$operator = 'greaterOrEqual'">groter of gelijk is aan</xsl:when>
            <xsl:when test="$operator = 'lessOrEqual'">kleiner of gelijk is aan</xsl:when>
            <xsl:otherwise><xsl:value-of select="$operator"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Format operand -->
    <xsl:template name="format-operand">
        <xsl:param name="operand"/>
        
        <xsl:choose>
            <xsl:when test="$operand/fn:string[@key='type'] = 'attributeReference'">
                <xsl:call-template name="resolve-attribute-reference">
                    <xsl:with-param name="ref" select="$operand"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$operand/fn:string[@key='type'] = 'literal'">
                <xsl:call-template name="format-value">
                    <xsl:with-param name="value" select="$operand"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>[Unknown operand]</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Format value -->
    <xsl:template name="format-value">
        <xsl:param name="value"/>
        <xsl:value-of select="$value/fn:string[@key='value'] | $value/fn:number[@key='value'] | $value/fn:boolean[@key='value']"/>
        <xsl:if test="$value/fn:string[@key='unit']">
            <xsl:text> </xsl:text>
            <xsl:value-of select="$value/fn:string[@key='unit']"/>
        </xsl:if>
    </xsl:template>

    <!-- Resolve target -->
    <xsl:template name="resolve-target">
        <xsl:param name="target"/>
        <xsl:param name="article"/>
        
        <xsl:value-of select="$article"/>
        <xsl:text> </xsl:text>
        <xsl:call-template name="resolve-attribute-reference">
            <xsl:with-param name="ref" select="$target/fn:map[@key='attribute']"/>
        </xsl:call-template>
        <xsl:text> van een </xsl:text>
        <!-- Get subject from attribute path - extract objectType from attribute reference -->
        <xsl:variable name="attr-path" select="$target/fn:map[@key='attribute']/fn:string[@key='$ref']"/>
        <xsl:variable name="attr-parts" select="tokenize($attr-path, '/')"/>
        <xsl:variable name="object-uuid" select="$attr-parts[3]"/>
        <xsl:call-template name="resolve-path">
            <xsl:with-param name="path" select="concat('#/facts/', $object-uuid)"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Resolve target subject only -->
    <xsl:template name="resolve-target-subject">
        <xsl:param name="target"/>
        <xsl:call-template name="resolve-subject-reference">
            <xsl:with-param name="ref" select="$target/fn:map[@key='subject']"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Resolve target attribute only -->
    <xsl:template name="resolve-target-attribute">
        <xsl:param name="target"/>
        <xsl:call-template name="resolve-attribute-reference">
            <xsl:with-param name="ref" select="$target/fn:map[@key='attribute']"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Resolve attribute reference -->
    <xsl:template name="resolve-attribute-reference">
        <xsl:param name="ref"/>
        <xsl:variable name="ref-path" select="$ref/fn:string[@key='$ref']"/>
        <xsl:call-template name="resolve-path">
            <xsl:with-param name="path" select="$ref-path"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Resolve subject reference -->
    <xsl:template name="resolve-subject-reference">
        <xsl:param name="ref"/>
        <xsl:variable name="ref-path" select="$ref/fn:string[@key='$ref']"/>
        <xsl:call-template name="resolve-subject-path">
            <xsl:with-param name="path" select="$ref-path"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Resolve subject path - follows objectType references -->
    <xsl:template name="resolve-subject-path">
        <xsl:param name="path"/>
        <xsl:variable name="path-parts" select="tokenize($path, '/')"/>
        <xsl:variable name="fact-uuid" select="$path-parts[3]"/>
        <xsl:variable name="fact" select="//fn:map[@key='facts']/fn:map[@key=$fact-uuid]"/>
        
        <xsl:choose>
            <xsl:when test="$fact and count($path-parts) > 3 and $path-parts[4] = 'roles'">
                <xsl:variable name="item-uuid" select="$path-parts[5]"/>
                <xsl:variable name="role-a" select="$fact/fn:map[@key='items']/fn:map[1]/fn:array[@key='versions']/fn:map[1]/fn:map[@key='a']"/>
                <xsl:variable name="role-b" select="$fact/fn:map[@key='items']/fn:map[1]/fn:array[@key='versions']/fn:map[1]/fn:map[@key='b']"/>
                
                <xsl:choose>
                    <xsl:when test="$role-a/fn:string[@key='uuid'] = $item-uuid">
                        <!-- Follow the objectType reference -->
                        <xsl:variable name="object-ref" select="$role-a/fn:map[@key='objectType']/fn:string[@key='$ref']"/>
                        <xsl:call-template name="resolve-path">
                            <xsl:with-param name="path" select="$object-ref"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="$role-b/fn:string[@key='uuid'] = $item-uuid">
                        <!-- Follow the objectType reference -->
                        <xsl:variable name="object-ref" select="$role-b/fn:map[@key='objectType']/fn:string[@key='$ref']"/>
                        <xsl:call-template name="resolve-path">
                            <xsl:with-param name="path" select="$object-ref"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>UNKNOWN_SUBJECT_ROLE</xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- Fall back to normal path resolution -->
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$path"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Resolve path to name -->
    <xsl:template name="resolve-path">
        <xsl:param name="path"/>
        <xsl:variable name="path-parts" select="tokenize($path, '/')"/>
        <xsl:variable name="fact-uuid" select="$path-parts[3]"/>
        <xsl:variable name="fact" select="//fn:map[@key='facts']/fn:map[@key=$fact-uuid]"/>
        
        <xsl:choose>
            <xsl:when test="$fact">
                <!-- Check if this is a path to a property/role within the fact -->
                <xsl:choose>
                    <xsl:when test="count($path-parts) > 3">
                        <!-- This is a reference to a property or role -->
                        <xsl:variable name="section-type" select="$path-parts[4]"/>  <!-- 'properties' or 'roles' -->
                        <xsl:variable name="item-uuid" select="$path-parts[5]"/>
                        
                        <xsl:choose>
                            <xsl:when test="$section-type = 'properties'">
                                <xsl:variable name="property" select="$fact/fn:map[@key='items']/fn:map[@key=$item-uuid]"/>
                                <xsl:choose>
                                    <xsl:when test="$property">
                                        <xsl:value-of select="$property/fn:map[@key='name']/fn:string[@key=$language]"/>
                                    </xsl:when>
                                    <xsl:otherwise>UNKNOWN_PROPERTY</xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:when test="$section-type = 'roles'">
                                <!-- For roles, need to look at factTypes structure -->
                                <xsl:variable name="role-a" select="$fact/fn:map[@key='items']/fn:map[1]/fn:array[@key='versions']/fn:map[1]/fn:map[@key='a']"/>
                                <xsl:variable name="role-b" select="$fact/fn:map[@key='items']/fn:map[1]/fn:array[@key='versions']/fn:map[1]/fn:map[@key='b']"/>
                                
                                <xsl:choose>
                                    <xsl:when test="$role-a/fn:string[@key='uuid'] = $item-uuid">
                                        <xsl:value-of select="$role-a/fn:map[@key='name']/fn:string[@key=$language]"/>
                                    </xsl:when>
                                    <xsl:when test="$role-b/fn:string[@key='uuid'] = $item-uuid">
                                        <xsl:value-of select="$role-b/fn:map[@key='name']/fn:string[@key=$language]"/>
                                    </xsl:when>
                                    <xsl:otherwise>UNKNOWN_ROLE</xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>UNKNOWN_SECTION</xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Direct fact reference -->
                        <xsl:variable name="name" select="$fact/fn:map[@key='name']/fn:string[@key=$language]"/>
                        <xsl:value-of select="if ($name) then $name else 'UNKNOWN_FACT'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>UNKNOWN_REFERENCE</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>