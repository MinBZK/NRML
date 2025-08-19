# NRML XSLT 3.0 Transformatie

Declaratieve XSLT 3.0 transformatie voor het omzetten van NRML JSON naar Nederlandse objectmodel representaties.

## 📁 Bestanden

- **`transform-xslt.sh`** - Hoofd transformatie script (Saxon-JS)
- **`gegevensspraak-transformatie.xsl`** - XSLT 3.0 stylesheet
- **`package.json`** + **`node_modules/`** - Saxon-JS dependencies

## 🚀 Gebruik

```bash
# Setup (eenmalig)
cd scripts && npm install

# Basis transformatie
./scripts/transform-xslt.sh

# Custom XSLT stylesheet
./scripts/transform-xslt.sh my-transform.xsl

# Volledige parameters
./scripts/transform-xslt.sh stylesheet.xsl input.json output.txt

# Help
./scripts/transform-xslt.sh --help
```

## 🎯 Input/Output

**Input (NRML JSON):**
```json
{
  "objectTypes": {
    "vlucht": {
      "article": "de",
      "properties": {
        "belasteReis": {"type": "kenmerk"}
      }
    }
  }
}
```

**Output (Nederlandse Gegevensspraak):**
```
Objecttype de vlucht
de    belaste reis    kenmerk
```

## ⚡ Features

- **XSLT 3.0** - Declaratieve templates met pattern matching
- **JSON native** - Directe `json-to-xml()` support  
- **Saxon-JS** - Modern, snel, geen Java dependencies
- **Parametriseerbaar** - Custom XSLT stylesheets
- **Template matching** - Pattern-based transformatie logica

## 🔧 XSLT Voorbeeld

```xsl
<!-- Pattern matching op JSON structuur -->
<xsl:template match="fn:map[@key='objectTypes']">
  <xsl:for-each select="fn:map">
    <xsl:text>Objecttype </xsl:text>
    <xsl:value-of select="fn:string[@key='article']"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="replace(@key, '_', ' ')"/>
  </xsl:for-each>
</xsl:template>
```

## 🐛 Troubleshooting

```bash
# Dependencies ontbrekend
❌ NPM dependencies niet gevonden
→ cd scripts && npm install

# Node.js te oud
❌ Node.js niet gevonden  
→ Installeer Node.js 14+ via nodejs.org
```

---
**Pure declaratieve XSLT 3.0 - geen imperatieve code!** 🎨