<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="fn xs">

    <xsl:output method="text" encoding="UTF-8" indent="no"/>

    <!-- Parameters -->
    <xsl:param name="language" select="'nl'" as="xs:string"/>
    <xsl:param name="input-file" as="xs:string"/>
    
    <!-- Initial template for JSON transformation -->
    <xsl:template name="main">
        <xsl:param name="json-input" as="xs:string?" select="unparsed-text($input-file)"/>
        <xsl:variable name="xml-data" select="json-to-xml($json-input)"/>
        <xsl:apply-templates select="$xml-data"/>
    </xsl:template>
    
    <!-- Match the actual root structure: a map with facts key -->
    <xsl:template match="fn:map[fn:map[@key='facts']]">
        <xsl:text>// Generated from NRML JSON to Souffle Datalog&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>.pragma "provenance" "explain"&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        
        <!-- Dynamic Declarations based on NRML structure -->
        <xsl:text>// Declarations&#10;</xsl:text>
        <xsl:text>.decl entity(id: symbol, type: symbol)&#10;</xsl:text>
        <xsl:text>.decl numeric_property(entity: symbol, name: symbol, value: number)&#10;</xsl:text>
        <xsl:text>.decl property(entity: symbol, name: symbol, value: symbol)&#10;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        
        <!-- Generate declarations for each rule target -->
        <xsl:variable name="facts" select="fn:map[@key='facts']"/>
        <xsl:for-each select="$facts/fn:map[fn:string[@key='_source'] = 'ruleGroup']">
            <xsl:for-each select="fn:map[@key='items']/fn:map">
                <xsl:variable name="rule-id" select="@key"/>
                <xsl:variable name="rule-version" select="fn:array[@key='versions']/fn:map[1]"/>
                <xsl:variable name="target-ref" select="$rule-version/fn:array[@key='target']/fn:map[1]/fn:string[@key='$ref']"/>
                
                <xsl:variable name="target-name">
                    <xsl:call-template name="resolve-reference-name">
                        <xsl:with-param name="ref" select="$target-ref"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <xsl:variable name="target-type">
                    <xsl:call-template name="get-reference-type">
                        <xsl:with-param name="ref" select="$target-ref"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <xsl:text>.decl </xsl:text>
                <xsl:call-template name="sanitize-identifier">
                    <xsl:with-param name="name" select="$target-name"/>
                </xsl:call-template>
                <xsl:text>(</xsl:text>
                
                <xsl:choose>
                    <xsl:when test="$target-type = 'characteristic'">
                        <xsl:text>entity: symbol</xsl:text>
                    </xsl:when>
                    <xsl:when test="$target-type = 'numeric'">
                        <xsl:text>entity: symbol, value: number, source: symbol</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>entity: symbol</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:text>)&#10;</xsl:text>
            </xsl:for-each>
        </xsl:for-each>
        
        <xsl:text>&#10;</xsl:text>
        
        <!-- Generate output declarations -->
        <xsl:for-each select="$facts/fn:map[fn:string[@key='_source'] = 'ruleGroup']">
            <xsl:for-each select="fn:map[@key='items']/fn:map">
                <xsl:variable name="target-ref" select="fn:array[@key='versions']/fn:map[1]/fn:array[@key='target']/fn:map[1]/fn:string[@key='$ref']"/>
                <xsl:variable name="target-name">
                    <xsl:call-template name="resolve-reference-name">
                        <xsl:with-param name="ref" select="$target-ref"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <xsl:text>.output </xsl:text>
                <xsl:call-template name="sanitize-identifier">
                    <xsl:with-param name="name" select="$target-name"/>
                </xsl:call-template>
                <xsl:text>&#10;</xsl:text>
            </xsl:for-each>
        </xsl:for-each>
        <xsl:text>&#10;</xsl:text>
        
        <!-- Use the instances data if available, otherwise extract from facts -->
        <xsl:variable name="instances" select="fn:array[@key='instances']"/>
        <xsl:choose>
            <xsl:when test="$instances">
                <xsl:text>// Input Facts from Generated Instances&#10;</xsl:text>
                <xsl:for-each select="$instances/fn:map">
                    <xsl:variable name="person-id" select="fn:string[@key='id']"/>
                    <xsl:variable name="person-name" select="fn:string[@key='name']"/>
                    <xsl:variable name="person-age" select="fn:number[@key='age']"/>
                    <xsl:variable name="person-distance" select="fn:number[@key='distance']"/>
                    
                    <xsl:text>entity("</xsl:text>
                    <xsl:value-of select="$person-id"/>
                    <xsl:text>", "natural_person").&#10;</xsl:text>
                    <xsl:text>property("</xsl:text>
                    <xsl:value-of select="$person-id"/>
                    <xsl:text>", "naam", "</xsl:text>
                    <xsl:value-of select="$person-name"/>
                    <xsl:text>").&#10;</xsl:text>
                    <xsl:text>numeric_property("</xsl:text>
                    <xsl:value-of select="$person-id"/>
                    <xsl:text>", "leeftijd", </xsl:text>
                    <xsl:value-of select="$person-age"/>
                    <xsl:text>).&#10;</xsl:text>
                    <xsl:text>numeric_property("</xsl:text>
                    <xsl:value-of select="$person-id"/>
                    <xsl:text>", "afstand", </xsl:text>
                    <xsl:value-of select="$person-distance"/>
                    <xsl:text>).&#10;</xsl:text>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>// No instances found, using default facts&#10;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        
        <!-- Dynamic System Parameters from JSON -->
        <xsl:text>&#10;</xsl:text>
        <xsl:text>// System Parameters&#10;</xsl:text>
        <xsl:text>entity("system", "system_params").&#10;</xsl:text>
        
        <!-- Generate parameters from parameter-facts -->
        <xsl:for-each select="$facts/fn:map[@key='parameter-facts']/fn:map[@key='items']/fn:map">
            <xsl:variable name="param-name" select="fn:map[@key='name']/fn:string[@key='nl']"/>
            <xsl:variable name="param-value" select="fn:array[@key='versions']/fn:map[1]/fn:map[@key='value']/fn:number[@key='value']"/>
            <xsl:variable name="param-type" select="fn:array[@key='versions']/fn:map[1]/fn:string[@key='type']"/>
            
            <xsl:text>numeric_property("system", "</xsl:text>
            <xsl:call-template name="sanitize-identifier">
                <xsl:with-param name="name" select="$param-name"/>
            </xsl:call-template>
            <xsl:text>", </xsl:text>
            <!-- Convert all parameter values to integers for Souffle -->
            <xsl:choose>
                <xsl:when test="$param-type = 'percentage' and $param-value &lt; 1">
                    <xsl:value-of select="round($param-value * 100)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="round($param-value)"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>).&#10;</xsl:text>
        </xsl:for-each>
        
        <!-- Also generate from system-params if present -->
        <xsl:for-each select="$facts/fn:map[@key='system-params']/fn:map[@key='properties']/fn:map">
            <xsl:variable name="param-name" select="fn:map[@key='name']/fn:string[@key='nl']"/>
            <xsl:variable name="param-value" select="fn:array[@key='versions']/fn:map[1]/fn:number[@key='defaultValue']"/>
            
            <xsl:text>numeric_property("system", "</xsl:text>
            <xsl:call-template name="sanitize-identifier">
                <xsl:with-param name="name" select="$param-name"/>
            </xsl:call-template>
            <xsl:text>", </xsl:text>
            <xsl:value-of select="round($param-value)"/>
            <xsl:text>).&#10;</xsl:text>
        </xsl:for-each>
        
        <xsl:text>&#10;</xsl:text>
        
        <!-- Transform NRML Rules -->
        <xsl:text>// Rules generated from NRML rule structures&#10;</xsl:text>
        <xsl:variable name="facts" select="fn:map[@key='facts']"/>
        <xsl:apply-templates select="$facts/fn:map[fn:string[@key='_source'] = 'ruleGroup']"/>
    </xsl:template>
    
    <!-- Transform NRML Rule Groups -->
    <xsl:template match="fn:map[fn:string[@key='_source'] = 'ruleGroup']">
        <xsl:text>&#10;</xsl:text>
        <xsl:for-each select="fn:map[@key='items']/fn:map">
            <xsl:variable name="rule-id" select="@key"/>
            <xsl:apply-templates select="fn:array[@key='versions']/fn:map[1]">
                <xsl:with-param name="rule-id" select="$rule-id"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Transform Individual NRML Rules -->
    <xsl:template match="fn:map[fn:array[@key='target']]">
        <xsl:param name="rule-id"/>
        
        <!-- Extract rule components -->
        <xsl:variable name="target" select="fn:array[@key='target']/fn:map[1]/fn:string[@key='$ref']"/>
        <xsl:variable name="condition" select="fn:map[@key='condition']"/>
        <xsl:variable name="expression" select="fn:map[@key='expression']"/>
        
        <!-- Generate rule head from target reference -->
        <xsl:variable name="rule-head">
            <xsl:call-template name="generate-rule-head">
                <xsl:with-param name="target-ref" select="$target"/>
                <xsl:with-param name="rule-id" select="$rule-id"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:value-of select="$rule-head"/>
        <xsl:text> :-&#10;</xsl:text>
        
        <!-- Generate rule body from condition -->
        <xsl:if test="$condition">
            <xsl:call-template name="generate-condition">
                <xsl:with-param name="condition" select="$condition"/>
            </xsl:call-template>
        </xsl:if>
        
        <!-- Generate assignment from expression -->
        <xsl:if test="$expression">
            <xsl:call-template name="generate-expression">
                <xsl:with-param name="expression" select="$expression"/>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:text>.&#10;&#10;</xsl:text>
    </xsl:template>
    
    <!-- Generate rule head from target reference - completely generic -->
    <xsl:template name="generate-rule-head">
        <xsl:param name="target-ref"/>
        <xsl:param name="rule-id"/>
        
        <!-- Extract target name dynamically from JSON structure -->
        <xsl:variable name="target-name">
            <xsl:call-template name="resolve-reference-name">
                <xsl:with-param name="ref" select="$target-ref"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- Generate rule head based on target type -->
        <xsl:variable name="target-type">
            <xsl:call-template name="get-reference-type">
                <xsl:with-param name="ref" select="$target-ref"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$target-type = 'characteristic'">
                <!-- Characteristic rules: rule_name(Entity) -->
                <xsl:call-template name="sanitize-identifier">
                    <xsl:with-param name="name" select="$target-name"/>
                </xsl:call-template>
                <xsl:text>(P)</xsl:text>
            </xsl:when>
            <xsl:when test="$target-type = 'numeric'">
                <!-- Numeric calculation rules: rule_name(Entity, Value, Source) -->
                <xsl:call-template name="sanitize-identifier">
                    <xsl:with-param name="name" select="$target-name"/>
                </xsl:call-template>
                <xsl:text>(P, Value, Source)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!-- Generic rule: rule_name(Entity) -->
                <xsl:text>rule_</xsl:text>
                <xsl:call-template name="sanitize-identifier">
                    <xsl:with-param name="name" select="$rule-id"/>
                </xsl:call-template>
                <xsl:text>(P)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Generate condition from NRML condition structure - completely generic -->
    <xsl:template name="generate-condition">
        <xsl:param name="condition"/>
        
        <xsl:variable name="type" select="$condition/fn:string[@key='type']"/>
        
        <xsl:choose>
            <xsl:when test="$type = 'comparison'">
                <xsl:call-template name="generate-comparison-condition">
                    <xsl:with-param name="condition" select="$condition"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'exists'">
                <xsl:call-template name="generate-exists-condition">
                    <xsl:with-param name="condition" select="$condition"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>    true</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Generate comparison condition dynamically -->
    <xsl:template name="generate-comparison-condition">
        <xsl:param name="condition"/>
        
        <xsl:variable name="operator" select="$condition/fn:string[@key='operator']"/>
        <xsl:variable name="left" select="$condition/fn:array[@key='left']/fn:map[1]/fn:string[@key='$ref']"/>
        <xsl:variable name="right" select="$condition/fn:map[@key='right']"/>
        
        <!-- Determine entity type from left reference -->
        <xsl:variable name="entity-type">
            <xsl:call-template name="get-entity-type-from-reference">
                <xsl:with-param name="ref" select="$left"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- Entity constraint -->
        <xsl:text>    entity(P, "</xsl:text>
        <xsl:value-of select="$entity-type"/>
        <xsl:text>"),&#10;</xsl:text>
        
        <!-- Left side - dynamic property access -->
        <xsl:variable name="left-property-name">
            <xsl:call-template name="resolve-reference-name">
                <xsl:with-param name="ref" select="$left"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:text>    numeric_property(P, "</xsl:text>
        <xsl:call-template name="sanitize-identifier">
            <xsl:with-param name="name" select="$left-property-name"/>
        </xsl:call-template>
        <xsl:text>", LeftValue),&#10;</xsl:text>
        
        <!-- Right side - dynamic parameter access -->
        <xsl:variable name="right-ref" select="$right/fn:map[@key='parameter']/fn:string[@key='$ref']"/>
        <xsl:variable name="right-property-name">
            <xsl:call-template name="resolve-reference-name">
                <xsl:with-param name="ref" select="$right-ref"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:text>    numeric_property("system", "</xsl:text>
        <xsl:call-template name="sanitize-identifier">
            <xsl:with-param name="name" select="$right-property-name"/>
        </xsl:call-template>
        <xsl:text>", RightValue),&#10;</xsl:text>
        
        <!-- Comparison -->
        <xsl:text>    LeftValue </xsl:text>
        <xsl:call-template name="convert-operator">
            <xsl:with-param name="operator" select="$operator"/>
        </xsl:call-template>
        <xsl:text> RightValue</xsl:text>
    </xsl:template>
    
    <!-- Generate exists condition -->
    <xsl:template name="generate-exists-condition">
        <xsl:param name="condition"/>
        
        <xsl:variable name="characteristic-ref" select="$condition/fn:array[@key='characteristic']/fn:map[1]/fn:string[@key='$ref']"/>
        <xsl:variable name="characteristic-name">
            <xsl:call-template name="resolve-reference-name">
                <xsl:with-param name="ref" select="$characteristic-ref"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- Check if the characteristic predicate exists for this entity -->
        <xsl:call-template name="sanitize-identifier">
            <xsl:with-param name="name" select="$characteristic-name"/>
        </xsl:call-template>
        <xsl:text>(P)</xsl:text>
    </xsl:template>
    
    <!-- Get entity type from reference path - use consistent naming with instances -->
    <xsl:template name="get-entity-type-from-reference">
        <xsl:param name="ref"/>
        <!-- For consistency with instance generation, use standardized entity types -->
        <xsl:variable name="path-parts" select="tokenize(substring-after($ref, '#/'), '/')"/>
        <xsl:variable name="fact-id" select="$path-parts[2]"/>
        
        <!-- Map specific fact IDs to consistent entity types -->
        <xsl:choose>
            <xsl:when test="$fact-id = '4c72dc9d-78d4-4f0b-a0cd-6037944f26ce'">
                <xsl:text>natural_person</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!-- Generic entity type based on fact name -->
                <xsl:variable name="facts" select="ancestor::fn:map/fn:map[@key='facts']"/>
                <xsl:variable name="parent-fact" select="$facts/fn:map[@key=$fact-id]"/>
                <xsl:call-template name="sanitize-identifier">
                    <xsl:with-param name="name" select="$parent-fact/fn:map[@key='name']/fn:string[@key='en']"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Resolve reference name dynamically from JSON structure -->
    <xsl:template name="resolve-reference-name">
        <xsl:param name="ref"/>
        
        <!-- Simple approach: extract the fragment identifier and look it up directly -->
        <xsl:variable name="path-parts" select="tokenize(substring-after($ref, '#/'), '/')"/>
        <!-- Path format: facts/fact-id/items|properties/item-id -->
        
        <xsl:choose>
            <xsl:when test="count($path-parts) >= 4">
                <xsl:variable name="fact-id" select="$path-parts[2]"/>
                <xsl:variable name="container" select="$path-parts[3]"/>  <!-- items or properties -->
                <xsl:variable name="item-id" select="$path-parts[4]"/>
                
                <!-- Navigate to the root and find facts -->
                <xsl:variable name="root" select="ancestor-or-self::fn:map[last()]"/>
                <xsl:variable name="facts" select="$root/fn:map[@key='facts']"/>
                <xsl:variable name="target-fact" select="$facts/fn:map[@key=$fact-id]"/>
                <xsl:variable name="target-container" select="$target-fact/fn:map[@key=$container]"/>
                <xsl:variable name="target-item" select="$target-container/fn:map[@key=$item-id]"/>
                
                <!-- Return the Dutch name -->
                <xsl:value-of select="$target-item/fn:map[@key='name']/fn:string[@key='nl']"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>unknown_reference</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Get reference type from JSON structure -->
    <xsl:template name="get-reference-type">
        <xsl:param name="ref"/>
        
        <xsl:variable name="path-parts" select="tokenize(substring-after($ref, '#/'), '/')"/>
        
        <xsl:choose>
            <xsl:when test="count($path-parts) >= 4">
                <xsl:variable name="fact-id" select="$path-parts[2]"/>
                <xsl:variable name="container" select="$path-parts[3]"/>
                <xsl:variable name="item-id" select="$path-parts[4]"/>
                
                <!-- Navigate to the root and find facts -->
                <xsl:variable name="root" select="ancestor-or-self::fn:map[last()]"/>
                <xsl:variable name="facts" select="$root/fn:map[@key='facts']"/>
                <xsl:variable name="target-fact" select="$facts/fn:map[@key=$fact-id]"/>
                <xsl:variable name="target-container" select="$target-fact/fn:map[@key=$container]"/>
                <xsl:variable name="target-item" select="$target-container/fn:map[@key=$item-id]"/>
                
                <!-- Return the type from versions array -->
                <xsl:value-of select="$target-item/fn:array[@key='versions']/fn:map[1]/fn:string[@key='type']"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>unknown</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Navigate JSON path recursively -->
    <xsl:template name="navigate-json-path">
        <xsl:param name="current"/>
        <xsl:param name="path-parts"/>
        <xsl:param name="index"/>
        
        <xsl:choose>
            <xsl:when test="$index > count($path-parts)">
                <xsl:copy-of select="$current"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="part" select="$path-parts[$index]"/>
                <xsl:choose>
                    <xsl:when test="$part = 'items' or $part = 'properties'">
                        <xsl:call-template name="navigate-json-path">
                            <xsl:with-param name="current" select="$current/fn:map[@key=$part]"/>
                            <xsl:with-param name="path-parts" select="$path-parts"/>
                            <xsl:with-param name="index" select="$index + 1"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="navigate-json-path">
                            <xsl:with-param name="current" select="$current/fn:map[@key=$part]"/>
                            <xsl:with-param name="path-parts" select="$path-parts"/>
                            <xsl:with-param name="index" select="$index + 1"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Sanitize identifier for Souffle -->
    <xsl:template name="sanitize-identifier">
        <xsl:param name="name"/>
        <!-- Convert name to valid Souffle identifier -->
        <xsl:value-of select="replace(replace(translate($name, ' ', '_'), '[^a-zA-Z0-9_]', ''), '^([0-9])', '_$1')"/>
    </xsl:template>
    
    <!-- Convert NRML operators to Souffle operators -->
    <xsl:template name="convert-operator">
        <xsl:param name="operator"/>
        <xsl:choose>
            <xsl:when test="$operator = 'greaterThanOrEquals'">>=</xsl:when>
            <xsl:when test="$operator = 'greaterThan'">&gt;</xsl:when>
            <xsl:when test="$operator = 'lessThanOrEquals'">&lt;=</xsl:when>
            <xsl:when test="$operator = 'lessThan'">&lt;</xsl:when>
            <xsl:when test="$operator = 'equals'">=</xsl:when>
            <xsl:otherwise>=</xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Generate expression from NRML arithmetic expressions - completely generic -->
    <xsl:template name="generate-expression">
        <xsl:param name="expression"/>
        
        <xsl:variable name="type" select="$expression/fn:string[@key='type']"/>
        
        <xsl:choose>
            <xsl:when test="$type = 'arithmetic'">
                <!-- Generate parameter lookups first -->
                <xsl:call-template name="generate-parameter-lookups">
                    <xsl:with-param name="expr" select="$expression"/>
                </xsl:call-template>
                
                <xsl:text>,&#10;    Value = </xsl:text>
                <xsl:call-template name="generate-arithmetic-expression">
                    <xsl:with-param name="expr" select="$expression"/>
                </xsl:call-template>
                <xsl:text>,&#10;    Source = "calculated"</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <!-- Static value -->
                <xsl:text>,&#10;    Value = </xsl:text>
                <xsl:value-of select="$expression/fn:number[@key='value']"/>
                <xsl:text>,&#10;    Source = "static"</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Generate parameter lookups for arithmetic expressions -->
    <xsl:template name="generate-parameter-lookups">
        <xsl:param name="expr"/>
        
        <xsl:for-each select="$expr//fn:map[@key='parameter']">
            <xsl:variable name="param-ref" select="fn:string[@key='$ref']"/>
            <xsl:variable name="param-name">
                <xsl:call-template name="resolve-reference-name">
                    <xsl:with-param name="ref" select="$param-ref"/>
                </xsl:call-template>
            </xsl:variable>
            
            <xsl:text>,&#10;    numeric_property("system", "</xsl:text>
            <xsl:call-template name="sanitize-identifier">
                <xsl:with-param name="name" select="$param-name"/>
            </xsl:call-template>
            <xsl:text>", </xsl:text>
            <xsl:call-template name="sanitize-identifier">
                <xsl:with-param name="name" select="$param-name"/>
            </xsl:call-template>
            <xsl:text>Var)</xsl:text>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Generate arithmetic expressions recursively -->
    <xsl:template name="generate-arithmetic-expression">
        <xsl:param name="expr"/>
        
        <xsl:variable name="operator" select="$expr/fn:string[@key='operator']"/>
        <xsl:variable name="operands" select="$expr/fn:array[@key='operands']/fn:map"/>
        
        <xsl:choose>
            <xsl:when test="count($operands) = 2">
                <!-- Binary operation -->
                <xsl:call-template name="generate-operand">
                    <xsl:with-param name="operand" select="$operands[1]"/>
                </xsl:call-template>
                
                <xsl:text> </xsl:text>
                <xsl:call-template name="convert-arithmetic-operator">
                    <xsl:with-param name="operator" select="$operator"/>
                </xsl:call-template>
                <xsl:text> </xsl:text>
                
                <xsl:call-template name="generate-operand">
                    <xsl:with-param name="operand" select="$operands[2]"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- Single operand or complex expression -->
                <xsl:call-template name="generate-operand">
                    <xsl:with-param name="operand" select="$operands[1]"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Generate individual operands -->
    <xsl:template name="generate-operand">
        <xsl:param name="operand"/>
        
        <xsl:choose>
            <xsl:when test="$operand/fn:map[@key='parameter']">
                <!-- Parameter reference - generate variable name -->
                <xsl:variable name="param-ref" select="$operand/fn:map[@key='parameter']/fn:string[@key='$ref']"/>
                <xsl:variable name="param-name">
                    <xsl:call-template name="resolve-reference-name">
                        <xsl:with-param name="ref" select="$param-ref"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <!-- Use sanitized variable name -->
                <xsl:call-template name="sanitize-identifier">
                    <xsl:with-param name="name" select="$param-name"/>
                </xsl:call-template>
                <xsl:text>Var</xsl:text>
            </xsl:when>
            <xsl:when test="$operand/fn:number[@key='value']">
                <!-- Static number -->
                <xsl:value-of select="$operand/fn:number[@key='value']"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- Nested expression -->
                <xsl:text>(</xsl:text>
                <xsl:call-template name="generate-arithmetic-expression">
                    <xsl:with-param name="expr" select="$operand"/>
                </xsl:call-template>
                <xsl:text>)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Convert arithmetic operators -->
    <xsl:template name="convert-arithmetic-operator">
        <xsl:param name="operator"/>
        <xsl:choose>
            <xsl:when test="$operator = 'add'">+</xsl:when>
            <xsl:when test="$operator = 'subtract'">-</xsl:when>
            <xsl:when test="$operator = 'multiply'">*</xsl:when>
            <xsl:when test="$operator = 'divide'">/</xsl:when>
            <xsl:otherwise>+</xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Suppress all other text output -->
    <xsl:template match="text()"/>
    
</xsl:stylesheet>