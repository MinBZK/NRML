<?xml version="1.0" encoding="UTF-8"?>
<!--
  NRML Translations Module
  Multilingual support for NRML transformations
-->
<xsl:stylesheet version="3.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema">

  <!-- Translation template -->
  <xsl:template name="translate">
    <xsl:param name="key" as="xs:string"/>
    <xsl:param name="language" select="'nl'" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$language = 'en'">
        <xsl:choose>
          <xsl:when test="$key = 'objecttype'">Object type</xsl:when>
          <xsl:when test="$key = 'animated'">(animate)</xsl:when>
          <xsl:when test="$key = 'characteristic'">characteristic</xsl:when>
          <xsl:when test="$key = 'characteristic-possessive'">characteristic (possessive)</xsl:when>
          <xsl:when test="$key = 'characteristic-adjective'">characteristic (adjective)</xsl:when>
          <xsl:when test="$key = 'facttype'">Fact type</xsl:when>
          <xsl:when test="$key = 'parameter'">Parameter</xsl:when>
          <xsl:when test="$key = 'domain'">Domain</xsl:when>
          <xsl:when test="$key = 'domain-type'">is of type</xsl:when>
          <xsl:when test="$key = 'one'">one</xsl:when>
          <xsl:when test="$key = 'multiple'">multiple</xsl:when>
          <xsl:when test="$key = 'domains-header'">// DOMAINS</xsl:when>
          <xsl:when test="$key = 'numeric-decimal'">Numeric ( number with</xsl:when>
          <xsl:when test="$key = 'decimals'">decimals )</xsl:when>
          <xsl:when test="$key = 'percentage-integer'">Percentage ( whole number )</xsl:when>
          <xsl:when test="$key = 'with-unit'">with unit</xsl:when>
          <xsl:when test="$key = 'numeric-type'">Numeric (</xsl:when>
          <xsl:when test="$key = 'whole-number'">whole number</xsl:when>
          <xsl:when test="$key = 'number'">number</xsl:when>
          <xsl:when test="$key = 'number-with'">number with</xsl:when>
          <xsl:when test="$key = 'date-in-days'">Date in days</xsl:when>
          <xsl:when test="$key = 'datetime-milliseconds'">Date and time in milliseconds</xsl:when>
          <xsl:when test="$key = 'percentage-type'">Percentage (</xsl:when>
          <xsl:when test="$key = 'percentage-value'">percentage</xsl:when>
          <xsl:when test="$key = 'boolean-type'">Boolean</xsl:when>
          <xsl:when test="$key = 'text-type'">Text</xsl:when>
          <xsl:when test="$key = 'plural-indicator'">pl:</xsl:when>
          <xsl:when test="$key = 'valid-from'">valid from</xsl:when>
          <xsl:when test="$key = 'must-be-set-to'">must be set to</xsl:when>
          <xsl:when test="$key = 'must-be-calculated-as'">must be calculated as</xsl:when>
          <xsl:when test="$key = 'all-conditions-met'">all of the following conditions are met :</xsl:when>
          <xsl:when test="$key = 'at-least-one-condition-met'">at least one of the following conditions is met :</xsl:when>
          <xsl:when test="$key = 'exactly-one-condition-met'">exactly one of the following conditions is met :</xsl:when>
          <xsl:when test="$key = 'meets-all-conditions'">meets all of the following conditions :</xsl:when>
          <xsl:when test="$key = 'of-a'">of a</xsl:when>
          <xsl:when test="$key = 'is-a'">is a</xsl:when>
          <xsl:when test="$key = 'his'">his</xsl:when>
          <xsl:when test="$key = 'the'">the</xsl:when>
          <xsl:when test="$key = 'of-the'">of the</xsl:when>
          <xsl:when test="$key = 'is-not-a'">is not a</xsl:when>
          <xsl:when test="$key = 'no'">no</xsl:when>
          <xsl:when test="$key = 'unknown-value'">unknown value</xsl:when>
          <xsl:when test="$key = 'unknown-reference'">unknown reference:</xsl:when>
          <xsl:when test="$key = 'unknown-property'">unknown property</xsl:when>
          <xsl:when test="$key = 'unknown-role'">unknown role</xsl:when>
          <xsl:when test="$key = 'unknown-parameter'">unknown parameter</xsl:when>
          <xsl:when test="$key = 'unknown-operand'">unknown operand</xsl:when>
          <xsl:when test="$key = 'unknown-condition-type'">Unknown condition type:</xsl:when>
          <xsl:when test="$key = 'unknown-expression-type'">Unknown expression type:</xsl:when>
          <xsl:when test="$key = 'of-the-flight'">of the flight</xsl:when>
          <xsl:when test="$key = 'the-conditions'">the conditions</xsl:when>
          <xsl:when test="$key = 'valid-from-to'">valid from</xsl:when>
          <xsl:when test="$key = 'must-be-initialized-to'">must be initialized to</xsl:when>
          <xsl:when test="$key = 'if'">if</xsl:when>
          <xsl:when test="$key = 'is-applicable'">is applicable</xsl:when>
          <xsl:when test="$key = 'of-all'">of all</xsl:when>
          <xsl:when test="$key = 'where'">where</xsl:when>
          <xsl:when test="$key = 'or'">or</xsl:when>
          <xsl:when test="$key = 'if-none-exist'">if none exist</xsl:when>
          <xsl:when test="$key = 'as'">as</xsl:when>
          <xsl:when test="$key = 'then'">then</xsl:when>
          <xsl:when test="$key = 'of'">of</xsl:when>
          <xsl:when test="$key = 'divided-by'">divided by</xsl:when>
          <xsl:when test="$key = 'has'">has</xsl:when>
          <xsl:when test="$key = 'rule-group'">Rule Group</xsl:when>
          <xsl:when test="$key = 'rule'">Rule</xsl:when>
          <xsl:when test="$key = 'rule-type-not-recognized'">Rule type not recognized</xsl:when>
          <xsl:when test="$key = 'plus'">plus</xsl:when>
          <xsl:when test="$key = 'minus'">minus</xsl:when>
          <xsl:when test="$key = 'multiply'">times</xsl:when>
          <xsl:when test="$key = 'greater-than'">is greater than</xsl:when>
          <xsl:when test="$key = 'less-than'">is less than</xsl:when>
          <xsl:when test="$key = 'greater-or-equal'">is greater or equal to</xsl:when>
          <xsl:when test="$key = 'less-or-equal'">is less or equal to</xsl:when>
          <xsl:when test="$key = 'minimum-of'">the minimum of</xsl:when>
          <xsl:when test="$key = 'rounded-down'">rounded down</xsl:when>
          <xsl:when test="$key = 'with-minimum-of'">with a minimum of</xsl:when>
          <xsl:when test="$key = 'equals'">is equal to</xsl:when>
          <xsl:when test="$key = 'not-equals'">is not equal to</xsl:when>
          <xsl:when test="$key = 'and'">and</xsl:when>
          <xsl:when test="$key = 'or'">or</xsl:when>
          <xsl:when test="$key = 'greater-than-inverted'">greater is than</xsl:when>
          <xsl:when test="$key = 'less-than-inverted'">less is than</xsl:when>
          <xsl:when test="$key = 'greater-or-equal-inverted'">greater or equal is to</xsl:when>
          <xsl:when test="$key = 'less-or-equal-inverted'">less or equal is to</xsl:when>
          <xsl:otherwise><xsl:value-of select="$key"/></xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <!-- Default Dutch -->
        <xsl:choose>
          <xsl:when test="$key = 'objecttype'">Objecttype</xsl:when>
          <xsl:when test="$key = 'animated'">(bezield)</xsl:when>
          <xsl:when test="$key = 'characteristic'">kenmerk</xsl:when>
          <xsl:when test="$key = 'characteristic-possessive'">kenmerk (bezittelijk)</xsl:when>
          <xsl:when test="$key = 'characteristic-adjective'">kenmerk (bijvoeglijk)</xsl:when>
          <xsl:when test="$key = 'facttype'">Feittype</xsl:when>
          <xsl:when test="$key = 'parameter'">Parameter</xsl:when>
          <xsl:when test="$key = 'domain'">Domein</xsl:when>
          <xsl:when test="$key = 'domain-type'">is van het type</xsl:when>
          <xsl:when test="$key = 'one'">één</xsl:when>
          <xsl:when test="$key = 'multiple'">meerdere</xsl:when>
          <xsl:when test="$key = 'domains-header'">// DOMEINEN</xsl:when>
          <xsl:when test="$key = 'numeric-decimal'">Numeriek ( getal met</xsl:when>
          <xsl:when test="$key = 'decimals'">decimalen )</xsl:when>
          <xsl:when test="$key = 'percentage-integer'">Percentage ( geheel getal )</xsl:when>
          <xsl:when test="$key = 'with-unit'">met eenheid</xsl:when>
          <xsl:when test="$key = 'numeric-type'">Numeriek (</xsl:when>
          <xsl:when test="$key = 'whole-number'">geheel getal</xsl:when>
          <xsl:when test="$key = 'number'">getal</xsl:when>
          <xsl:when test="$key = 'number-with'">getal met</xsl:when>
          <xsl:when test="$key = 'date-in-days'">Datum in dagen</xsl:when>
          <xsl:when test="$key = 'datetime-milliseconds'">Datum en tijd in milliseconden</xsl:when>
          <xsl:when test="$key = 'percentage-type'">Percentage (</xsl:when>
          <xsl:when test="$key = 'percentage-value'">percentage</xsl:when>
          <xsl:when test="$key = 'boolean-type'">Boolean</xsl:when>
          <xsl:when test="$key = 'text-type'">Tekst</xsl:when>
          <xsl:when test="$key = 'plural-indicator'">mv:</xsl:when>
          <xsl:when test="$key = 'valid-from'">geldig vanaf</xsl:when>
          <xsl:when test="$key = 'must-be-set-to'">moet gesteld worden op</xsl:when>
          <xsl:when test="$key = 'must-be-calculated-as'">moet berekend worden als</xsl:when>
          <xsl:when test="$key = 'all-conditions-met'">er aan alle volgende voorwaarden wordt voldaan :</xsl:when>
          <xsl:when test="$key = 'at-least-one-condition-met'">er aan ten minste één van de volgende voorwaarden wordt voldaan :</xsl:when>
          <xsl:when test="$key = 'exactly-one-condition-met'">er aan precies één van de volgende voorwaarden wordt voldaan :</xsl:when>
          <xsl:when test="$key = 'meets-all-conditions'">voldoet aan alle volgende voorwaarden :</xsl:when>
          <xsl:when test="$key = 'of-a'">van een</xsl:when>
          <xsl:when test="$key = 'is-a'">is een</xsl:when>
          <xsl:when test="$key = 'his'">zijn</xsl:when>
          <xsl:when test="$key = 'the'">de</xsl:when>
          <xsl:when test="$key = 'of-the'">van de</xsl:when>
          <xsl:when test="$key = 'is-not-a'">is geen</xsl:when>
          <xsl:when test="$key = 'no'">geen</xsl:when>
          <xsl:when test="$key = 'unknown-value'">onbekende waarde</xsl:when>
          <xsl:when test="$key = 'unknown-reference'">onbekende referentie:</xsl:when>
          <xsl:when test="$key = 'unknown-property'">onbekende eigenschap</xsl:when>
          <xsl:when test="$key = 'unknown-role'">onbekende rol</xsl:when>
          <xsl:when test="$key = 'unknown-parameter'">onbekende parameter</xsl:when>
          <xsl:when test="$key = 'unknown-operand'">onbekende operand</xsl:when>
          <xsl:when test="$key = 'unknown-condition-type'">Onbekende conditie type:</xsl:when>
          <xsl:when test="$key = 'unknown-expression-type'">Onbekende expressie type:</xsl:when>
          <xsl:when test="$key = 'of-the-flight'">van de vlucht</xsl:when>
          <xsl:when test="$key = 'the-conditions'">de voorwaarden</xsl:when>
          <xsl:when test="$key = 'valid-from-to'">geldig van</xsl:when>
          <xsl:when test="$key = 'must-be-initialized-to'">moet geïnitialiseerd worden op</xsl:when>
          <xsl:when test="$key = 'if'">indien</xsl:when>
          <xsl:when test="$key = 'is-applicable'">van toepassing is</xsl:when>
          <xsl:when test="$key = 'of-all'">van alle</xsl:when>
          <xsl:when test="$key = 'where'">waar</xsl:when>
          <xsl:when test="$key = 'or'">of</xsl:when>
          <xsl:when test="$key = 'if-none-exist'">als die er niet zijn</xsl:when>
          <xsl:when test="$key = 'as'">als</xsl:when>
          <xsl:when test="$key = 'then'">dan</xsl:when>
          <xsl:when test="$key = 'of'">van</xsl:when>
          <xsl:when test="$key = 'divided-by'">gedeeld door</xsl:when>
          <xsl:when test="$key = 'has'">heeft</xsl:when>
          <xsl:when test="$key = 'he'">hij</xsl:when>
          <xsl:when test="$key = 'has-no'">heeft geen</xsl:when>
          <xsl:when test="$key = 'is-not'">is niet</xsl:when>
          <xsl:when test="$key = 'rule-group'">Regelgroep</xsl:when>
          <xsl:when test="$key = 'rule'">Regel</xsl:when>
          <xsl:when test="$key = 'rule-type-not-recognized'">Rule type not recognized</xsl:when>
          <xsl:when test="$key = 'plus'">plus</xsl:when>
          <xsl:when test="$key = 'minus'">min</xsl:when>
          <xsl:when test="$key = 'multiply'">maal</xsl:when>
          <xsl:when test="$key = 'greater-than'">is groter dan</xsl:when>
          <xsl:when test="$key = 'less-than'">is kleiner dan</xsl:when>
          <xsl:when test="$key = 'greater-or-equal'">is groter of gelijk aan</xsl:when>
          <xsl:when test="$key = 'less-or-equal'">is kleiner of gelijk aan</xsl:when>
          <xsl:when test="$key = 'minimum-of'">het minimum van</xsl:when>
          <xsl:when test="$key = 'rounded-down'">naar beneden afgerond</xsl:when>
          <xsl:when test="$key = 'with-minimum-of'">met een minimum van</xsl:when>
          <xsl:when test="$key = 'equals'">gelijk is aan</xsl:when>
          <xsl:when test="$key = 'not-equals'">ongelijk is aan</xsl:when>
          <xsl:when test="$key = 'and'">en</xsl:when>
          <xsl:when test="$key = 'or'">of</xsl:when>
          <xsl:when test="$key = 'greater-than-inverted'">groter is dan</xsl:when>
          <xsl:when test="$key = 'less-than-inverted'">kleiner is dan</xsl:when>
          <xsl:when test="$key = 'greater-or-equal-inverted'">groter of gelijk is aan</xsl:when>
          <xsl:when test="$key = 'less-or-equal-inverted'">kleiner of gelijk is aan</xsl:when>
          <xsl:otherwise><xsl:value-of select="$key"/></xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>