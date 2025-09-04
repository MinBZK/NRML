<?xml version="1.0" encoding="UTF-8"?>
<!--
  Regelspraak Transformatie - Unified Reference Chains
  NRML UUID-based JSON naar Nederlandse Regelgeving Representatie
  
  Transformeert NRML specificaties naar leesbare Nederlandse regelspraak
  voor business rules, regelgroepen en condities met unified reference chains.
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
        <xsl:for-each select="fn:map[fn:map[@key='items']/fn:map/fn:array[@key='versions']/fn:map[fn:array[@key='target'] or fn:map[@key='condition'] or fn:map[@key='expression']]]">
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
                    <xsl:variable name="target" select="fn:array[@key='target']"/>
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
                        
                        <!-- Conditional assignment rules (target + value + condition) -->
                        <xsl:when test="$target and $value and $condition">
                            <xsl:call-template name="format-conditional-assignment-rule">
                                <xsl:with-param name="target" select="$target"/>
                                <xsl:with-param name="value" select="$value"/>
                                <xsl:with-param name="condition" select="$condition"/>
                            </xsl:call-template>
                        </xsl:when>
                        
                        <!-- Classification rules (target + condition, no value) -->
                        <xsl:when test="$target and $condition and not($value)">
                            <xsl:call-template name="format-classification-rule">
                                <xsl:with-param name="target" select="$target"/>
                                <xsl:with-param name="condition" select="$condition"/>
                            </xsl:call-template>
                        </xsl:when>
                        
                        <!-- Aggregation rules (target + expression) -->
                        <xsl:when test="$target and fn:map[@key='expression']">
                            <xsl:call-template name="format-aggregation-rule">
                                <xsl:with-param name="target" select="$target"/>
                                <xsl:with-param name="expression" select="fn:map[@key='expression']"/>
                            </xsl:call-template>
                        </xsl:when>
                        
                        <!-- Conditional rules (only condition) -->
                        <xsl:when test="$condition and not($target) and not($value)">
                            <xsl:call-template name="format-conditional-rule">
                                <xsl:with-param name="condition" select="$condition"/>
                            </xsl:call-template>
                        </xsl:when>
                        
                        <xsl:otherwise>
                            <xsl:text>Rule type not recognized</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    <xsl:text>&#10;&#10;</xsl:text>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <!-- Format initialization rule -->
    <xsl:template name="format-initialization-rule">
        <xsl:param name="target"/>
        <xsl:param name="value"/>
        
        <xsl:text>De </xsl:text>
        <xsl:call-template name="resolve-path">
            <xsl:with-param name="path" select="$target/fn:map/fn:string[@key='$ref']"/>
        </xsl:call-template>
        <xsl:text> van een </xsl:text>
        <xsl:call-template name="resolve-fact-from-property-ref">
            <xsl:with-param name="ref" select="$target/fn:map/fn:string[@key='$ref']"/>
        </xsl:call-template>
        <xsl:text> moet geïnitialiseerd worden op </xsl:text>
        <xsl:call-template name="format-value">
            <xsl:with-param name="value" select="$value"/>
        </xsl:call-template>
        <xsl:text>.</xsl:text>
    </xsl:template>

    <!-- Format conditional assignment rule -->
    <xsl:template name="format-conditional-assignment-rule">
        <xsl:param name="target"/>
        <xsl:param name="value"/>
        <xsl:param name="condition"/>
        
        <xsl:text>Als </xsl:text>
        <xsl:call-template name="format-condition">
            <xsl:with-param name="condition" select="$condition"/>
        </xsl:call-template>
        <xsl:text>, dan wordt </xsl:text>
        <xsl:call-template name="resolve-reference-chain">
            <xsl:with-param name="chain" select="$target"/>
        </xsl:call-template>
        <xsl:text> ingesteld op </xsl:text>
        <xsl:call-template name="format-value">
            <xsl:with-param name="value" select="$value"/>
        </xsl:call-template>
        <xsl:text>.</xsl:text>
    </xsl:template>

    <!-- Format classification rule -->
    <xsl:template name="format-classification-rule">
        <xsl:param name="target"/>
        <xsl:param name="condition"/>
        
        <xsl:choose>
            <xsl:when test="count($target/fn:map) > 1">
                <!-- Multi-reference: role + property -->
                <xsl:text>Een </xsl:text>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$target/fn:map[1]/fn:string[@key='$ref']"/>
                </xsl:call-template>
                <xsl:text> is een </xsl:text>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$target/fn:map[last()]/fn:string[@key='$ref']"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- Single reference: direct property of fact -->
                <xsl:text>Een </xsl:text>
                <xsl:call-template name="resolve-fact-from-property-ref">
                    <xsl:with-param name="ref" select="$target/fn:map/fn:string[@key='$ref']"/>
                </xsl:call-template>
                <xsl:text> is een </xsl:text>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$target/fn:map/fn:string[@key='$ref']"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>&#10;indien </xsl:text>
        <xsl:call-template name="format-condition">
            <xsl:with-param name="condition" select="$condition"/>
        </xsl:call-template>
        <xsl:text>.</xsl:text>
    </xsl:template>

    <!-- Format aggregation rule -->
    <xsl:template name="format-aggregation-rule">
        <xsl:param name="target"/>
        <xsl:param name="expression"/>
        
        <xsl:text>Het </xsl:text>
        <xsl:call-template name="resolve-path">
            <xsl:with-param name="path" select="$target/fn:map/fn:string[@key='$ref']"/>
        </xsl:call-template>
        <xsl:text> van een </xsl:text>
        <xsl:call-template name="resolve-fact-from-property-ref">
            <xsl:with-param name="ref" select="$target/fn:map/fn:string[@key='$ref']"/>
        </xsl:call-template>
        <xsl:text> moet berekend worden als </xsl:text>
        <xsl:call-template name="format-expression">
            <xsl:with-param name="expression" select="$expression"/>
        </xsl:call-template>
        <xsl:text>.</xsl:text>
    </xsl:template>

    <!-- Format conditional rule -->
    <xsl:template name="format-conditional-rule">
        <xsl:param name="condition"/>
        
        <xsl:call-template name="format-condition">
            <xsl:with-param name="condition" select="$condition"/>
        </xsl:call-template>
        <xsl:text>.</xsl:text>
    </xsl:template>

    <!-- Format expression -->
    <xsl:template name="format-expression">
        <xsl:param name="expression"/>
        <xsl:variable name="type" select="$expression/fn:string[@key='type']"/>
        
        <xsl:choose>
            <xsl:when test="$type = 'aggregation'">
                <xsl:call-template name="format-aggregation">
                    <xsl:with-param name="aggregation" select="$expression"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'conditional'">
                <xsl:call-template name="format-conditional-expression">
                    <xsl:with-param name="conditional" select="$expression"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$expression/fn:array">
                <!-- Direct reference chain -->
                <xsl:call-template name="resolve-reference-chain">
                    <xsl:with-param name="chain" select="$expression"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Onbekende expressie type: </xsl:text>
                <xsl:value-of select="$type"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Format aggregation -->
    <xsl:template name="format-aggregation">
        <xsl:param name="aggregation"/>
        <xsl:variable name="function" select="$aggregation/fn:string[@key='function']"/>
        <xsl:variable name="expression" select="$aggregation/fn:array[@key='expression']"/>
        <xsl:variable name="condition" select="$aggregation/fn:map[@key='condition']"/>
        
        <xsl:choose>
            <xsl:when test="$function = 'sum'">de som van</xsl:when>
            <xsl:when test="$function = 'count'">het aantal</xsl:when>
            <xsl:when test="$function = 'average'">het gemiddelde van</xsl:when>
            <xsl:when test="$function = 'min'">het minimum van</xsl:when>
            <xsl:when test="$function = 'max'">het maximum van</xsl:when>
            <xsl:otherwise><xsl:value-of select="$function"/></xsl:otherwise>
        </xsl:choose>
        
        <xsl:text> de </xsl:text>
        <xsl:call-template name="resolve-role-name-plural">
            <xsl:with-param name="path" select="$expression/fn:map/fn:string[@key='$ref']"/>
        </xsl:call-template>
        <xsl:text> van de vlucht</xsl:text>
        
        <xsl:if test="$condition">
            <xsl:text> waar </xsl:text>
            <xsl:call-template name="format-condition">
                <xsl:with-param name="condition" select="$condition"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- Format conditional expression -->
    <xsl:template name="format-conditional-expression">
        <xsl:param name="conditional"/>
        <xsl:variable name="condition" select="$conditional/fn:map[@key='condition']"/>
        <xsl:variable name="then" select="$conditional/fn:array[@key='then']"/>
        <xsl:variable name="else" select="$conditional/fn:array[@key='else']"/>
        
        <xsl:text>als </xsl:text>
        <xsl:call-template name="format-condition">
            <xsl:with-param name="condition" select="$condition"/>
        </xsl:call-template>
        <xsl:text> dan </xsl:text>
        <xsl:call-template name="resolve-reference-chain">
            <xsl:with-param name="chain" select="$then"/>
        </xsl:call-template>
        
        <xsl:if test="$else">
            <xsl:text> anders </xsl:text>
            <xsl:call-template name="resolve-reference-chain">
                <xsl:with-param name="chain" select="$else"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- Format condition -->
    <xsl:template name="format-condition">
        <xsl:param name="condition"/>
        <xsl:variable name="type" select="$condition/fn:string[@key='type']"/>
        
        <xsl:choose>
            <xsl:when test="$type = 'comparison'">
                <xsl:call-template name="format-comparison">
                    <xsl:with-param name="comparison" select="$condition"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'logical'">
                <xsl:call-template name="format-logical">
                    <xsl:with-param name="logical" select="$condition"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Onbekende conditie type: </xsl:text>
                <xsl:value-of select="$type"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Format comparison -->
    <xsl:template name="format-comparison">
        <xsl:param name="comparison"/>
        <xsl:variable name="operator" select="$comparison/fn:string[@key='operator']"/>
        <xsl:variable name="left" select="$comparison/fn:array[@key='left'] | $comparison/fn:map[@key='left']"/>
        <xsl:variable name="right" select="$comparison/fn:array[@key='right'] | $comparison/fn:map[@key='right']"/>
        
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
            <xsl:when test="$operator = 'greaterThan'">is groter dan</xsl:when>
            <xsl:when test="$operator = 'lessThan'">is kleiner dan</xsl:when>
            <xsl:when test="$operator = 'greaterOrEqual'">is groter of gelijk aan</xsl:when>
            <xsl:when test="$operator = 'lessThanOrEquals'">is kleiner of gelijk aan</xsl:when>
            <xsl:otherwise><xsl:value-of select="$operator"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Format logical -->
    <xsl:template name="format-logical">
        <xsl:param name="logical"/>
        <xsl:variable name="operator" select="$logical/fn:string[@key='operator']"/>
        <xsl:variable name="operands" select="$logical/fn:array[@key='operands']"/>
        
        <xsl:for-each select="$operands/fn:map">
            <xsl:if test="position() > 1">
                <xsl:choose>
                    <xsl:when test="$operator = 'and'"> en </xsl:when>
                    <xsl:when test="$operator = 'or'"> of </xsl:when>
                    <xsl:otherwise> <xsl:value-of select="$operator"/> </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:call-template name="format-condition">
                <xsl:with-param name="condition" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- Format operand -->
    <xsl:template name="format-operand">
        <xsl:param name="operand"/>
        
        <xsl:choose>
            <!-- Reference chain (array of references) -->
            <xsl:when test="$operand[self::fn:array]">
                <xsl:call-template name="resolve-reference-chain">
                    <xsl:with-param name="chain" select="$operand"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Value object -->
            <xsl:when test="$operand/fn:boolean[@key='value'] or $operand/fn:number[@key='value'] or $operand/fn:string[@key='value']">
                <xsl:call-template name="format-value">
                    <xsl:with-param name="value" select="$operand"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Literal value -->
            <xsl:when test="$operand/fn:string[@key='type'] = 'literal'">
                <xsl:call-template name="format-value">
                    <xsl:with-param name="value" select="$operand"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>onbekende operand</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Resolve reference chain -->
    <xsl:template name="resolve-reference-chain">
        <xsl:param name="chain"/>
        
        <xsl:choose>
            <xsl:when test="count($chain/fn:map) = 1">
                <!-- Single reference -->
                <xsl:text>de </xsl:text>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$chain/fn:map/fn:string[@key='$ref']"/>
                </xsl:call-template>
                <xsl:text> van de </xsl:text>
                <xsl:call-template name="resolve-fact-from-property-ref">
                    <xsl:with-param name="ref" select="$chain/fn:map/fn:string[@key='$ref']"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="count($chain/fn:map) > 1">
                <!-- Multiple references - chain -->
                <xsl:text>de </xsl:text>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$chain/fn:map[last()]/fn:string[@key='$ref']"/>
                </xsl:call-template>
                <xsl:text> van de </xsl:text>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$chain/fn:map[1]/fn:string[@key='$ref']"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>lege referentieketen</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Resolve chain context recursively -->
    <xsl:template name="resolve-chain-context">
        <xsl:param name="chain"/>
        <xsl:param name="position"/>
        
        <xsl:if test="$position > 0">
            <xsl:if test="$position < count($chain/fn:map) - 1">
                <xsl:call-template name="resolve-chain-context">
                    <xsl:with-param name="chain" select="$chain"/>
                    <xsl:with-param name="position" select="$position - 1"/>
                </xsl:call-template>
                <xsl:text> van </xsl:text>
            </xsl:if>
            <xsl:call-template name="resolve-path">
                <xsl:with-param name="path" select="$chain/fn:map[$position]/fn:string[@key='$ref']"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- Resolve reference context (for determining the subject) -->
    <xsl:template name="resolve-reference-context">
        <xsl:param name="chain"/>
        
        <xsl:choose>
            <xsl:when test="count($chain/fn:map) = 1">
                <!-- Single reference - get the fact name -->
                <xsl:variable name="ref" select="$chain/fn:map/fn:string[@key='$ref']"/>
                <xsl:variable name="fact-uuid" select="substring-before(substring-after($ref, '#/facts/'), '/properties/')"/>
                <xsl:variable name="fact-name" select="//fn:map[@key='facts']/fn:map[@key=$fact-uuid]/fn:map[@key='name']/fn:string[@key=$language]"/>
                <xsl:value-of select="$fact-name"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- Multi-hop - use the first reference as context -->
                <xsl:variable name="ref" select="$chain/fn:map[1]/fn:string[@key='$ref']"/>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$ref"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Format value -->
    <xsl:template name="format-value">
        <xsl:param name="value"/>
        
        <xsl:choose>
            <xsl:when test="$value/fn:boolean[@key='value']">
                <xsl:choose>
                    <xsl:when test="$value/fn:boolean[@key='value'] = true()">waar</xsl:when>
                    <xsl:otherwise>onwaar</xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$value/fn:number[@key='value']">
                <xsl:value-of select="$value/fn:number[@key='value']"/>
                <xsl:if test="$value/fn:string[@key='unit']">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$value/fn:string[@key='unit']"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$value/fn:string[@key='value']">
                <xsl:value-of select="$value/fn:string[@key='value']"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>onbekende waarde</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Resolve path - enhanced to handle all reference types -->
    <xsl:template name="resolve-path">
        <xsl:param name="path"/>
        
        <xsl:variable name="single-path" select="$path[1]"/>
        
        <xsl:choose>
            <xsl:when test="contains($single-path, '/properties/')">
                <xsl:call-template name="resolve-property-name">
                    <xsl:with-param name="path" select="$single-path"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="contains($single-path, '/roles/')">
                <xsl:call-template name="resolve-role-name">
                    <xsl:with-param name="path" select="$single-path"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="contains($single-path, '/facts/')">
                <xsl:call-template name="resolve-fact-name">
                    <xsl:with-param name="path" select="$single-path"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>onbekende referentie: </xsl:text>
                <xsl:value-of select="$single-path"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Resolve property name -->
    <xsl:template name="resolve-property-name">
        <xsl:param name="path"/>
        <!-- Extract fact UUID and property UUID from path -->
        <xsl:variable name="fact-uuid" select="substring-before(substring-after($path, '#/facts/'), '/properties/')"/>
        <xsl:variable name="property-uuid" select="substring-after($path, '/properties/')"/>
        
        <!-- Look up the property name in the facts -->
        <xsl:variable name="property-name" select="//fn:map[@key='facts']/fn:map[@key=$fact-uuid]/fn:map[@key='items']/fn:map[@key=$property-uuid]/fn:map[@key='name']/fn:string[@key=$language]"/>
        
        <xsl:choose>
            <xsl:when test="$property-name">
                <xsl:value-of select="$property-name"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>onbekende eigenschap</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Resolve role name -->
    <xsl:template name="resolve-role-name">
        <xsl:param name="path"/>
        <!-- Extract fact UUID and role UUID from path -->
        <xsl:variable name="fact-uuid" select="substring-before(substring-after($path, '#/facts/'), '/roles/')"/>
        <xsl:variable name="role-uuid" select="substring-after($path, '/roles/')"/>
        
        <!-- Look up the role in the fact's items/versions -->
        <xsl:variable name="role-name">
            <xsl:for-each select="//fn:map[@key='facts']/fn:map[@key=$fact-uuid]/fn:map[@key='items']/fn:map/fn:array[@key='versions']/fn:map">
                <xsl:choose>
                    <xsl:when test="fn:map[@key='a']/fn:string[@key='uuid'] = $role-uuid">
                        <xsl:value-of select="fn:map[@key='a']/fn:map[@key='name']/fn:string[@key=$language]"/>
                    </xsl:when>
                    <xsl:when test="fn:map[@key='b']/fn:string[@key='uuid'] = $role-uuid">
                        <xsl:value-of select="fn:map[@key='b']/fn:map[@key='name']/fn:string[@key=$language]"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$role-name != ''">
                <xsl:value-of select="$role-name"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>onbekende rol</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Resolve role name plural for aggregations -->
    <xsl:template name="resolve-role-name-plural">
        <xsl:param name="path"/>
        <xsl:variable name="single-path" select="$path[1]"/>
        <!-- Extract fact UUID and role UUID from path -->
        <xsl:variable name="fact-uuid" select="substring-before(substring-after($single-path, '#/facts/'), '/roles/')"/>
        <xsl:variable name="role-uuid" select="substring-after($single-path, '/roles/')"/>
        
        <!-- Look up the role in the fact's items/versions -->
        <xsl:variable name="role-plural">
            <xsl:for-each select="//fn:map[@key='facts']/fn:map[@key=$fact-uuid]/fn:map[@key='items']/fn:map/fn:array[@key='versions']/fn:map">
                <xsl:choose>
                    <xsl:when test="fn:map[@key='a']/fn:string[@key='uuid'] = $role-uuid">
                        <xsl:value-of select="fn:map[@key='a']/fn:map[@key='plural']/fn:string[@key=$language]"/>
                    </xsl:when>
                    <xsl:when test="fn:map[@key='b']/fn:string[@key='uuid'] = $role-uuid">
                        <xsl:value-of select="fn:map[@key='b']/fn:map[@key='plural']/fn:string[@key=$language]"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$role-plural != ''">
                <xsl:value-of select="$role-plural"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- Fallback to singular if no plural found -->
                <xsl:call-template name="resolve-role-name">
                    <xsl:with-param name="path" select="$path"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Resolve fact name -->
    <xsl:template name="resolve-fact-name">
        <xsl:param name="path"/>
        <xsl:variable name="fact-uuid" select="substring-after($path, '#/facts/')"/>
        
        <xsl:variable name="fact-name" select="//fn:map[@key='facts']/fn:map[@key=$fact-uuid]/fn:map[@key='name']/fn:string[@key=$language]"/>
        
        <xsl:choose>
            <xsl:when test="$fact-name">
                <xsl:value-of select="$fact-name"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>onbekend feit</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Resolve fact name from property reference -->
    <xsl:template name="resolve-fact-from-property-ref">
        <xsl:param name="ref"/>
        <xsl:variable name="single-ref" select="$ref[1]"/>
        <xsl:variable name="fact-uuid" select="substring-before(substring-after($single-ref, '#/facts/'), '/properties/')"/>
        
        <xsl:variable name="fact-name" select="//fn:map[@key='facts']/fn:map[@key=$fact-uuid]/fn:map[@key='name']/fn:string[@key=$language]"/>
        
        <xsl:choose>
            <xsl:when test="$fact-name">
                <xsl:value-of select="$fact-name"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>onbekend object</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>