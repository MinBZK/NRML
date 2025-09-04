# NRML (Natural Rule Markup Language) Project

## Overview
This project implements a unified reference chain system for transforming NRML JSON specifications into Dutch natural language rule descriptions using XSL transformations.

## Key Files
- `toka.nrml.json` - Main NRML specification with rules and facts
- `transformations/regelspraak.xsl` - XSL transformation for Dutch rule output
- `toka.regelspraak.unified.txt` - Current transformation output
- `toka.regelspraak.groundtruth.txt` - Expected correct output for comparison
- `scripts/transform` - Transformation script

## Unified Reference Chain System
The project uses a **consistent array-based reference chain structure** instead of various separate reference patterns (vias, attribute, property, parameter fields).

### How Reference Chaining Works

#### Single Reference (Direct Property)
```json
"target": [
  {
    "$ref": "#/facts/48c6ed9c-0911-43d8-b6ef-47d2b406ea35/properties/d72ead33-2e0c-450a-ba71-b83940c8e926"
  }
]
```
**Generates**: "de [property-name] van een [fact-name]"
**Example**: "de afstand tot bestemming van een vlucht"

#### Multi-hop Reference Chain (Role → Property)
```json
"target": [
  {
    "$ref": "#/facts/ef9e731c-4f81-4905-a902-2a533e1eebc5/roles/0cc7c4b4-2855-4c8b-93f0-5403cf286af0"
  },
  {
    "$ref": "#/facts/4c72dc9d-78d4-4f0b-a0cd-6037944f26ce/properties/ab9cc7dc-7be7-412d-ae46-0224ceef3153"
  }
]
```
**Chain Logic**: 
1. First reference = ROLE (provides context/subject)
2. Second reference = PROPERTY (what we're talking about)

**Generates**: "Een [role-name] is een [property-name]"
**Example**: "Een passagier is een te betalen belasting"

#### Aggregation Multi-hop Chain
```json
"expression": [
  {
    "$ref": "#/facts/ef9e731c-4f81-4905-a902-2a533e1eebc5/roles/0cc7c4b4-2855-4c8b-93f0-5403cf286af0"
  },
  {
    "$ref": "#/facts/4c72dc9d-78d4-4f0b-a0cd-6037944f26ce/properties/ab9cc7dc-7be7-412d-ae46-0224ceef3153"
  }
]
```
**Chain Logic**:
1. First reference = ROLE (what collection to aggregate from)
2. Second reference = PROPERTY (what property to sum/count)

**Generates**: "de som van de [property-plural] van alle [role-plural] van de [parent-context]"
**Example**: "de som van de te betalen belastingen van alle passagiers van de vlucht"

### Why Chaining is Essential

#### Without Role Chain (BROKEN):
```json
"expression": [
  {
    "$ref": "#/facts/4c72dc9d-78d4-4f0b-a0cd-6037944f26ce/properties/ab9cc7dc-7be7-412d-ae46-0224ceef3153"
  }
]
```
**Result**: "de som van de onbekende rol van de vlucht" ❌

#### With Role Chain (CORRECT):
```json
"expression": [
  {
    "$ref": "#/facts/ef9e731c-4f81-4905-a902-2a533e1eebc5/roles/0cc7c4b4-2855-4c8b-93f0-5403cf286af0"
  },
  {
    "$ref": "#/facts/4c72dc9d-78d4-4f0b-a0cd-6037944f26ce/properties/ab9cc7dc-7be7-412d-ae46-0224ceef3153"
  }
]
```
**Result**: "de som van de te betalen belastingen van alle passagiers van de vlucht" ✅

## Key Transformations

### Rule Types
1. **Initialization Rules**: Set initial values for properties
2. **Classification Rules**: Define when entities belong to categories (with role context)
3. **Aggregation Rules**: Calculate sums/counts with multi-hop references and defaults
4. **Conditional Assignment Rules**: Set values based on conditions

### Critical Implementation Details

#### Multi-hop Aggregation Rules
For aggregation rules like "totaal te betalen belasting", the expression must include:
1. **Role reference** (first): `#/facts/.../roles/0cc7c4b4-2855-4c8b-93f0-5403cf286af0` (passagier)
2. **Property reference** (second): `#/facts/.../properties/property-uuid`
3. **Default value without currency**: `{"value": 0}` (not `{"value": 0, "unit": "€"}`)

This generates correct Dutch: "de som van de [property-plural] van alle [role-plural] van de vlucht"

#### XSL Template Chain Processing
The XSL transformation processes chains through these templates:

**format-aggregation template**:
```xsl
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
```

**Chain Position Logic**:
- `$expression/fn:map[1]` = First in chain (ROLE)
- `$expression/fn:map[last()]` = Last in chain (PROPERTY)  
- `count($expression/fn:map) > 1` = Multi-hop chain detected

#### Plural Form Support
Properties need plural forms defined in JSON:
```json
"plural": {
  "nl": "te betalen belastingen",
  "en": "taxes payable"
}
```

The XSL uses `resolve-path-plural` and `resolve-property-name-plural` templates for multi-hop aggregations.

### Key UUID References
**Common Role UUID** (passagier):
- `0cc7c4b4-2855-4c8b-93f0-5403cf286af0` = passagier role

**Common Property UUIDs**:
- `ab9cc7dc-7be7-412d-ae46-0224ceef3153` = te betalen belasting
- `199d696e-a168-4584-8f80-35d737e5e1ba` = belasting op basis van afstand  
- `b802e897-8854-4ad3-97b4-3ed4b04f9b16` = belasting op basis van reisduur

**Common Fact UUIDs**:
- `ef9e731c-4f81-4905-a902-2a533e1eebc5` = vlucht (with roles)
- `4c72dc9d-78d4-4f0b-a0cd-6037944f26ce` = natuurlijk persoon (with properties)
- `48c6ed9c-0911-43d8-b6ef-47d2b406ea35` = vlucht (with properties)

## Common Commands
```bash
# Run transformation - ALWAYS use the unified file
./scripts/transform transformations/regelspraak.xsl toka.nrml.json toka.regelspraak.unified.txt

# Compare with ground truth
diff toka.regelspraak.unified.txt toka.regelspraak.groundtruth.txt

# Check specific rule lines
sed -n '30,33p' toka.regelspraak.unified.txt
```

## IMPORTANT: File Usage Rules
🚨 **NEVER create new test files** - Always write to `toka.regelspraak.unified.txt`
- ❌ DON'T: `toka.regelspraak.test-something.txt`
- ❌ DON'T: `toka.regelspraak.fixed.txt` 
- ✅ DO: `toka.regelspraak.unified.txt`

The unified file is the single source of truth for current transformation output.
