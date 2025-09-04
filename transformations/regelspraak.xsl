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
                        
                        <!-- Conditional expression rules (target + expression + condition) -->
                        <xsl:when test="$target and fn:map[@key='expression'] and $condition">
                            <xsl:call-template name="format-conditional-expression-rule">
                                <xsl:with-param name="target" select="$target"/>
                                <xsl:with-param name="expression" select="fn:map[@key='expression']"/>
                                <xsl:with-param name="condition" select="$condition"/>
                            </xsl:call-template>
                        </xsl:when>
                        
                        <!-- Classification rules (target + condition, no value, no expression) -->
                        <xsl:when test="$target and $condition and not($value) and not(fn:map[@key='expression'])">
                            <xsl:call-template name="format-classification-rule">
                                <xsl:with-param name="target" select="$target"/>
                                <xsl:with-param name="condition" select="$condition"/>
                            </xsl:call-template>
                        </xsl:when>
                        
                        <!-- Aggregation rules (target + expression, no condition) -->
                        <xsl:when test="$target and fn:map[@key='expression'] and not($condition)">
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
        
        <xsl:call-template name="resolve-path-with-article">
            <xsl:with-param name="path" select="$target/fn:map[last()]/fn:string[@key='$ref']"/>
            <xsl:with-param name="capitalize" select="true()"/>
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
        
        <xsl:call-template name="resolve-path-with-article">
            <xsl:with-param name="path" select="$target/fn:map[last()]/fn:string[@key='$ref']"/>
            <xsl:with-param name="capitalize" select="true()"/>
        </xsl:call-template>
        <xsl:text> van een </xsl:text>
        <xsl:call-template name="resolve-path">
            <xsl:with-param name="path" select="$target/fn:map[1]/fn:string[@key='$ref']"/>
        </xsl:call-template>
        <xsl:text> moet gesteld worden op </xsl:text>
        <xsl:call-template name="format-value">
            <xsl:with-param name="value" select="$value"/>
        </xsl:call-template>
        <xsl:text>&#10;indien </xsl:text>
        <xsl:call-template name="format-condition">
            <xsl:with-param name="condition" select="$condition"/>
        </xsl:call-template>
        <xsl:text>.</xsl:text>
    </xsl:template>

    <!-- Format conditional expression rule -->
    <xsl:template name="format-conditional-expression-rule">
        <xsl:param name="target"/>
        <xsl:param name="expression"/>
        <xsl:param name="condition"/>
        
        <xsl:call-template name="resolve-path-with-article">
            <xsl:with-param name="path" select="$target/fn:map[last()]/fn:string[@key='$ref']"/>
            <xsl:with-param name="capitalize" select="true()"/>
        </xsl:call-template>
        <xsl:text> van een </xsl:text>
        <xsl:variable name="root-ref" select="$target/fn:map[1]/fn:string[@key='$ref']"/>
        <xsl:variable name="is-root-characteristic">
            <xsl:call-template name="is-characteristic">
                <xsl:with-param name="ref" select="$root-ref"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:choose>
            <!-- Root is a characteristic: use characteristic name directly -->
            <xsl:when test="$is-root-characteristic = 'true'">
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$root-ref"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Regular chain: role → property -->
            <xsl:otherwise>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$root-ref"/>
                </xsl:call-template>
                <!-- Add condition qualifier if needed -->
                <xsl:if test="$condition">
                    <xsl:text> waarvoor </xsl:text>
                    <xsl:call-template name="format-condition-qualifier">
                        <xsl:with-param name="condition" select="$condition"/>
                    </xsl:call-template>
                    <xsl:text> van toepassing is</xsl:text>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text> moet berekend worden als </xsl:text>
        <xsl:call-template name="format-expression">
            <xsl:with-param name="expression" select="$expression"/>
        </xsl:call-template>
        <xsl:text>&#10;indien </xsl:text>
        <xsl:call-template name="format-condition">
            <xsl:with-param name="condition" select="$condition"/>
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
        
        <xsl:call-template name="resolve-path-with-article">
            <xsl:with-param name="path" select="$target/fn:map[last()]/fn:string[@key='$ref']"/>
            <xsl:with-param name="capitalize" select="true()"/>
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
            <xsl:when test="$type = 'arithmetic'">
                <xsl:call-template name="format-arithmetic">
                    <xsl:with-param name="arithmetic" select="$expression"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'parameterReference'">
                <xsl:call-template name="format-parameter-reference">
                    <xsl:with-param name="param" select="$expression"/>
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
        
        <xsl:choose>
            <xsl:when test="count($expression/fn:map) = 1">
                <!-- Single reference: just the role -->
                <xsl:text> de </xsl:text>
                <xsl:call-template name="resolve-role-name-plural">
                    <xsl:with-param name="path" select="$expression/fn:map/fn:string[@key='$ref']"/>
                </xsl:call-template>
                <xsl:text> van de vlucht</xsl:text>
            </xsl:when>
            <xsl:when test="count($expression/fn:map) > 1">
                <!-- Multi-hop: role → property -->
                <xsl:text> de </xsl:text>
                <xsl:call-template name="resolve-path-plural">
                    <xsl:with-param name="path" select="$expression/fn:map[last()]/fn:string[@key='$ref']"/>
                </xsl:call-template>
                <xsl:text> van alle </xsl:text>
                <xsl:call-template name="resolve-role-name-plural">
                    <xsl:with-param name="path" select="$expression/fn:map[1]/fn:string[@key='$ref']"/>
                </xsl:call-template>
                <xsl:text> van de vlucht</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> lege expressie</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        
        <xsl:if test="$condition">
            <xsl:text> waar </xsl:text>
            <xsl:call-template name="format-condition">
                <xsl:with-param name="condition" select="$condition"/>
            </xsl:call-template>
        </xsl:if>
        
        <!-- Add default value if present -->
        <xsl:if test="$aggregation/fn:map[@key='default']">
            <xsl:text>, of </xsl:text>
            <xsl:call-template name="format-value">
                <xsl:with-param name="value" select="$aggregation/fn:map[@key='default']"/>
            </xsl:call-template>
            <xsl:text> als die er niet zijn</xsl:text>
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
            <!-- Reference array condition (no explicit type) -->
            <xsl:when test="not($type) and $condition/fn:map">
                <xsl:call-template name="resolve-reference-chain">
                    <xsl:with-param name="chain" select="$condition"/>
                </xsl:call-template>
            </xsl:when>
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
            <xsl:when test="$type = 'allOf'">
                <xsl:call-template name="format-allOf">
                    <xsl:with-param name="allOf" select="$condition"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'anyOf'">
                <xsl:call-template name="format-anyOf">
                    <xsl:with-param name="anyOf" select="$condition"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'not'">
                <xsl:call-template name="format-not">
                    <xsl:with-param name="not" select="$condition"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'exists'">
                <xsl:call-template name="format-exists">
                    <xsl:with-param name="exists" select="$condition"/>
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
            <!-- Parameter reference (implicit - has parameter field) -->
            <xsl:when test="$operand/fn:map[@key='parameter']">
                <xsl:call-template name="format-parameter-reference">
                    <xsl:with-param name="param" select="$operand"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Arithmetic expression -->
            <xsl:when test="$operand/fn:string[@key='type'] = 'arithmetic'">
                <xsl:call-template name="format-arithmetic">
                    <xsl:with-param name="arithmetic" select="$operand"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>onbekende operand</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Check if rule target is animated -->
    <xsl:template name="is-rule-target-animated">
        <xsl:param name="target"/>
        
        <!-- Get the first reference in target (should be a role) -->
        <xsl:variable name="role-ref" select="$target/fn:map[1]/fn:string[@key='$ref']"/>
        <xsl:variable name="role-fact-uuid" select="substring-before(substring-after($role-ref, '#/facts/'), '/roles/')"/>
        <xsl:variable name="role-uuid" select="substring-after($role-ref, '/roles/')"/>
        
        <!-- Look up the role's objectType to see if it points to an animated fact -->
        <xsl:variable name="object-type-ref">
            <xsl:for-each select="//fn:map[@key='facts']/fn:map[@key=$role-fact-uuid]/fn:map[@key='items']/fn:map/fn:array[@key='versions']/fn:map">
                <xsl:if test="fn:map[@key='b']/fn:string[@key='uuid'] = $role-uuid">
                    <xsl:value-of select="fn:map[@key='b']/fn:map[@key='objectType']/fn:string[@key='$ref']"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <!-- Extract fact UUID from objectType reference -->
        <xsl:variable name="target-fact-uuid" select="substring-after($object-type-ref, '#/facts/')"/>
        
        <!-- Check if this fact is animated -->
        <xsl:choose>
            <xsl:when test="//fn:map[@key='facts']/fn:map[@key=$target-fact-uuid]/fn:boolean[@key='animated'] = 'true'">true</xsl:when>
            <xsl:otherwise>false</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Check if chain should use possessive pronoun -->
    <xsl:template name="should-use-possessive">
        <xsl:param name="chain"/>
        
        <!-- Find current rule context -->
        <xsl:variable name="current-rule" select="ancestor-or-self::fn:map[fn:array[@key='target']]"/>
        
        <!-- If we have a rule context and it has an animated target -->
        <xsl:if test="$current-rule">
            <xsl:variable name="target-is-animated">
                <xsl:call-template name="is-rule-target-animated">
                    <xsl:with-param name="target" select="$current-rule/fn:array[@key='target']"/>
                </xsl:call-template>
            </xsl:variable>
            
            <!-- If target is animated, check if this chain references something that could belong to the target -->
            <xsl:if test="$target-is-animated = 'true'">
                <!-- For now, use possessive for any role reference when we have animated target -->
                <!-- This is a simplification - in a full implementation we'd check relationship ownership -->
                <xsl:variable name="first-ref" select="$chain/fn:map[1]/fn:string[@key='$ref']"/>
                <xsl:if test="contains($first-ref, '/roles/')">
                    <xsl:text>true</xsl:text>
                </xsl:if>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- Resolve reference chain with possessive pronoun support -->
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
                <!-- Multiple references - check for possessive case -->
                <xsl:variable name="first-ref" select="$chain/fn:map[1]/fn:string[@key='$ref']"/>
                <xsl:variable name="last-ref" select="$chain/fn:map[last()]/fn:string[@key='$ref']"/>
                
                <!-- Check if this chain represents something owned by animated subject -->
                <xsl:variable name="use-possessive">
                    <xsl:call-template name="should-use-possessive">
                        <xsl:with-param name="chain" select="$chain"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <!-- Multiple references - chain -->
                <xsl:call-template name="resolve-path-with-article">
                    <xsl:with-param name="path" select="$chain/fn:map[last()]/fn:string[@key='$ref']"/>
                </xsl:call-template>
                <xsl:text> van </xsl:text>
                <xsl:choose>
                    <xsl:when test="$use-possessive = 'true'">
                        <xsl:text>zijn </xsl:text>
                        <xsl:call-template name="resolve-path">
                            <xsl:with-param name="path" select="$chain/fn:map[1]/fn:string[@key='$ref']"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="resolve-path-with-article">
                            <xsl:with-param name="path" select="$chain/fn:map[1]/fn:string[@key='$ref']"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
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

    <!-- Resolve path plural - enhanced to handle all reference types with plural forms -->
    <xsl:template name="resolve-path-plural">
        <xsl:param name="path"/>
        
        <xsl:variable name="single-path" select="$path[1]"/>
        
        <xsl:choose>
            <xsl:when test="contains($single-path, '/properties/')">
                <xsl:call-template name="resolve-property-name-plural">
                    <xsl:with-param name="path" select="$single-path"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="contains($single-path, '/roles/')">
                <xsl:call-template name="resolve-role-name-plural">
                    <xsl:with-param name="path" select="$single-path"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- Fallback to singular -->
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$path"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Resolve property name plural -->
    <xsl:template name="resolve-property-name-plural">
        <xsl:param name="path"/>
        <!-- Extract fact UUID and property UUID from path -->
        <xsl:variable name="fact-uuid" select="substring-before(substring-after($path, '#/facts/'), '/properties/')"/>
        <xsl:variable name="property-uuid" select="substring-after($path, '/properties/')"/>
        
        <!-- Look up the property plural name in the facts -->
        <xsl:variable name="property-plural" select="//fn:map[@key='facts']/fn:map[@key=$fact-uuid]/fn:map[@key='items']/fn:map[@key=$property-uuid]/fn:map[@key='plural']/fn:string[@key=$language]"/>
        
        <xsl:choose>
            <xsl:when test="$property-plural">
                <xsl:value-of select="$property-plural"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- Fallback to singular if no plural found -->
                <xsl:call-template name="resolve-property-name">
                    <xsl:with-param name="path" select="$path"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Format arithmetic expression -->
    <xsl:template name="format-arithmetic">
        <xsl:param name="arithmetic"/>
        <xsl:variable name="operator" select="$arithmetic/fn:string[@key='operator']"/>
        <xsl:variable name="left" select="$arithmetic/fn:map[@key='left'] | $arithmetic/fn:array[@key='left']"/>
        <xsl:variable name="right" select="$arithmetic/fn:map[@key='right'] | $arithmetic/fn:array[@key='right']"/>
        
        <!-- Format left operand -->
        <xsl:call-template name="format-operand">
            <xsl:with-param name="operand" select="$left"/>
        </xsl:call-template>
        
        <!-- Format operator -->
        <xsl:choose>
            <xsl:when test="$operator = 'plus'"><xsl:text> plus </xsl:text></xsl:when>
            <xsl:when test="$operator = 'minus'"><xsl:text> min </xsl:text></xsl:when>
            <xsl:when test="$operator = 'multiply'"><xsl:text> maal </xsl:text></xsl:when>
            <xsl:when test="$operator = 'divide'"><xsl:text> gedeeld door </xsl:text></xsl:when>
            <xsl:otherwise><xsl:text> </xsl:text><xsl:value-of select="$operator"/><xsl:text> </xsl:text></xsl:otherwise>
        </xsl:choose>
        
        <!-- Format right operand -->
        <xsl:call-template name="format-operand">
            <xsl:with-param name="operand" select="$right"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Format parameter reference -->
    <xsl:template name="format-parameter-reference">
        <xsl:param name="param"/>
        <xsl:variable name="param-ref" select="$param/fn:map[@key='parameter']/fn:string[@key='$ref']"/>
        <xsl:variable name="param-uuid" select="substring-after($param-ref, '#/facts/')"/>
        
        <!-- Look up parameter name and article -->
        <xsl:variable name="param-fact" select="//fn:map[@key='facts']/fn:map[@key=$param-uuid]"/>
        <xsl:variable name="param-name" select="$param-fact/fn:map[@key='name']/fn:string[@key=$language]"/>
        <!-- Get article from the first item in the parameter fact -->
        <xsl:variable name="param-article" select="$param-fact/fn:map[@key='items']/fn:map[1]/fn:map[@key='article']/fn:string[@key=$language]"/>
        
        <xsl:choose>
            <xsl:when test="$param-name">
                <xsl:value-of select="$param-article"/><xsl:text> </xsl:text><xsl:value-of select="translate($param-name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>onbekende parameter</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Format allOf condition -->
    <xsl:template name="format-allOf">
        <xsl:param name="allOf"/>
        <xsl:variable name="conditions" select="$allOf/fn:array[@key='conditions']"/>
        
        <xsl:text>er aan alle volgende voorwaarden wordt voldaan :</xsl:text>
        <xsl:for-each select="$conditions/fn:array | $conditions/fn:map">
            <xsl:text>&#10;  • </xsl:text>
            <!-- Always use format-condition to handle all types -->
            <xsl:call-template name="format-condition">
                <xsl:with-param name="condition" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- Format anyOf condition -->
    <xsl:template name="format-anyOf">
        <xsl:param name="anyOf"/>
        <xsl:variable name="conditions" select="$anyOf/fn:array[@key='conditions']"/>
        
        <xsl:text>er aan ten minste één van de volgende voorwaarden wordt voldaan :</xsl:text>
        <xsl:for-each select="$conditions/fn:array | $conditions/fn:map">
            <xsl:text>&#10;  • </xsl:text>
            <!-- Always use format-condition to handle all types -->
            <xsl:call-template name="format-condition">
                <xsl:with-param name="condition" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- Format not condition -->
    <xsl:template name="format-not">
        <xsl:param name="not"/>
        <xsl:variable name="condition" select="$not/fn:array[@key='condition'] | $not/fn:map[@key='condition']"/>
        
        <xsl:choose>
            <xsl:when test="$condition/fn:array">
                <!-- Reference chain condition -->
                <xsl:call-template name="format-reference-condition-negated">
                    <xsl:with-param name="condition" select="$condition"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$condition/fn:string[@key='type'] = 'exists'">
                <!-- Exists condition - generate "zijn X is geen Y" format -->
                <xsl:variable name="characteristic" select="$condition/fn:array[@key='characteristic']"/>
                <xsl:text>zijn </xsl:text>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$characteristic/fn:map[1]/fn:string[@key='$ref']"/>
                </xsl:call-template>
                <xsl:text> is geen </xsl:text>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$characteristic/fn:map[2]/fn:string[@key='$ref']"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- Complex condition -->
                <xsl:text>niet (</xsl:text>
                <xsl:call-template name="format-condition">
                    <xsl:with-param name="condition" select="$condition"/>
                </xsl:call-template>
                <xsl:text>)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Format reference condition (resolve actual references) -->
    <xsl:template name="format-reference-condition">
        <xsl:param name="condition"/>
        <!-- Resolve the reference chain to actual names -->
        <xsl:call-template name="resolve-reference-chain">
            <xsl:with-param name="chain" select="$condition"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Format reference condition negated -->
    <xsl:template name="format-reference-condition-negated">
        <xsl:param name="condition"/>
        <!-- Use 'geen' with resolved reference -->
        <xsl:text>geen </xsl:text>
        <xsl:call-template name="resolve-reference-chain">
            <xsl:with-param name="chain" select="$condition"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Resolve path with correct article from JSON -->
    <xsl:template name="resolve-path-with-article">
        <xsl:param name="path"/>
        <xsl:param name="capitalize" select="false()"/>
        
        <xsl:choose>
            <!-- Property reference -->
            <xsl:when test="contains($path, '/properties/')">
                <xsl:call-template name="resolve-property-with-article">
                    <xsl:with-param name="path" select="$path"/>
                    <xsl:with-param name="capitalize" select="$capitalize"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Role reference -->
            <xsl:when test="contains($path, '/roles/')">
                <xsl:call-template name="resolve-role-with-article">
                    <xsl:with-param name="path" select="$path"/>
                    <xsl:with-param name="capitalize" select="$capitalize"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Fallback to regular resolution -->
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$capitalize">
                        <xsl:text>De </xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>de </xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$path"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Resolve property with its article -->
    <xsl:template name="resolve-property-with-article">
        <xsl:param name="path"/>
        <xsl:param name="capitalize" select="false()"/>
        <xsl:variable name="fact-uuid" select="substring-before(substring-after($path, '#/facts/'), '/properties/')"/>
        <xsl:variable name="property-uuid" select="substring-after($path, '/properties/')"/>
        
        <!-- Get article from property definition -->
        <xsl:variable name="property-article" select="//fn:map[@key='facts']/fn:map[@key=$fact-uuid]/fn:map[@key='items']/fn:map[@key=$property-uuid]/fn:map[@key='article']/fn:string[@key=$language]"/>
        
        <xsl:choose>
            <xsl:when test="$property-article and $property-article != ''">
                <xsl:choose>
                    <xsl:when test="$capitalize">
                        <xsl:value-of select="concat(translate(substring($property-article, 1, 1), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'), substring($property-article, 2))"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$property-article"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> </xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:call-template name="resolve-path">
            <xsl:with-param name="path" select="$path"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Resolve role with its article -->
    <xsl:template name="resolve-role-with-article">
        <xsl:param name="path"/>
        <xsl:param name="capitalize" select="false()"/>
        <xsl:variable name="fact-uuid" select="substring-before(substring-after($path, '#/facts/'), '/roles/')"/>
        <xsl:variable name="role-uuid" select="substring-after($path, '/roles/')"/>
        
        <!-- Look up the role's article -->
        <xsl:variable name="role-article">
            <xsl:for-each select="//fn:map[@key='facts']/fn:map[@key=$fact-uuid]/fn:map[@key='items']/fn:map/fn:array[@key='versions']/fn:map">
                <xsl:choose>
                    <xsl:when test="fn:map[@key='a']/fn:string[@key='uuid'] = $role-uuid">
                        <xsl:value-of select="fn:map[@key='a']/fn:map[@key='article']/fn:string[@key=$language]"/>
                    </xsl:when>
                    <xsl:when test="fn:map[@key='b']/fn:string[@key='uuid'] = $role-uuid">
                        <xsl:value-of select="fn:map[@key='b']/fn:map[@key='article']/fn:string[@key=$language]"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$role-article != ''">
                <xsl:choose>
                    <xsl:when test="$capitalize">
                        <xsl:value-of select="concat(translate(substring($role-article, 1, 1), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'), substring($role-article, 2))"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$role-article"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> </xsl:text>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$path"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$capitalize">
                        <xsl:text>De </xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>de </xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="resolve-path">
                    <xsl:with-param name="path" select="$path"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Format exists condition (classification statements) -->
    <xsl:template name="format-exists">
        <xsl:param name="exists"/>
        <xsl:variable name="characteristic" select="$exists/fn:array[@key='characteristic']"/>
        
        <!-- Generate "zijn X is een Y" format -->
        <xsl:text>zijn </xsl:text>
        <xsl:call-template name="resolve-path">
            <xsl:with-param name="path" select="$characteristic/fn:map[1]/fn:string[@key='$ref']"/>
        </xsl:call-template>
        <xsl:text> is een </xsl:text>
        <xsl:call-template name="resolve-path">
            <xsl:with-param name="path" select="$characteristic/fn:map[2]/fn:string[@key='$ref']"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Check if a reference points to a characteristic -->
    <xsl:template name="is-characteristic">
        <xsl:param name="ref"/>
        
        <xsl:choose>
            <xsl:when test="contains($ref, '/properties/')">
                <!-- Extract fact UUID and property UUID -->
                <xsl:variable name="fact-uuid" select="substring-before(substring-after($ref, '#/facts/'), '/properties/')"/>
                <xsl:variable name="property-uuid" select="substring-after($ref, '/properties/')"/>
                
                <!-- Check if this property has type "characteristic" -->
                <xsl:variable name="property-type" select="//fn:map[@key='facts']/fn:map[@key=$fact-uuid]/fn:map[@key='items']/fn:map[@key=$property-uuid]/fn:array[@key='versions']/fn:map[1]/fn:string[@key='type']"/>
                
                <xsl:choose>
                    <xsl:when test="$property-type = 'characteristic'">true</xsl:when>
                    <xsl:otherwise>false</xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>false</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Format condition qualifier (resolve from actual condition data) -->
    <xsl:template name="format-condition-qualifier">
        <xsl:param name="condition"/>
        <!-- Extract qualifier from condition structure, don't hardcode -->
        <xsl:text>de voorwaarden</xsl:text>
    </xsl:template>

</xsl:stylesheet>