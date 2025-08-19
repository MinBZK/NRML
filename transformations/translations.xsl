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
          <xsl:otherwise><xsl:value-of select="$key"/></xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>