# NRML (Normalized Rule Model Language) Project

## Overview

NRML (uitspraak: /ˈnɔrməl/) is een JSON-gebaseerd formaat voor het beschrijven van bedrijfsregels, objectmodellen en hun
relaties op een gestructureerde manier.

## Key Files

- `toka.nrml.json` - Main NRML specification with rules and facts
- `transformations/regelspraak.xsl` - XSL transformation for Dutch rule output
- `toka.regelspraak.unified.txt` - Current transformation output
- `toka.regelspraak.groundtruth.txt` - Expected correct output for comparison
- `scripts/transform` - Transformation script

## Unified Reference Chain System

The project uses a **consistent array-based reference chain structure** instead of various separate reference patterns (
vias, attribute, property, parameter fields).

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

## 🚨 CRITICAL RULE: NO HARDCODED DOMAIN STRINGS IN XSL

**NEVER hardcode domain-specific text in XSL templates!**

❌ **WRONG - Hardcoded domain strings:**

```xsl
<xsl:template name="format-reference-condition">
    <xsl:text>zijn reis is een belaste reis</xsl:text>  <!-- WRONG! -->
</xsl:template>

<xsl:template name="format-condition-qualifier">
    <xsl:text>het lage tarief voor belasting op basis van afstand</xsl:text>  <!-- WRONG! -->
</xsl:template>
```

✅ **CORRECT - Use actual reference resolution:**

```xsl
<xsl:template name="format-reference-condition">
    <xsl:param name="condition"/>
    <!-- Resolve the actual references from JSON data -->
    <xsl:call-template name="resolve-reference-chain">
        <xsl:with-param name="chain" select="$condition"/>
    </xsl:call-template>
</xsl:template>
```

**Why this is critical:**

- XSL templates must be **generic language constructs**
- Domain knowledge comes from **JSON data only**
- Mixing domain concepts with language constructs breaks reusability
- Templates should work for ANY domain, not just flight taxes

**Always ask: "Would this template work for a different domain (e.g., banking, healthcare)?"**
If the answer is NO because of hardcoded strings, it's WRONG.

## Conditional Expression Structure with Explicit Types

### Exists Conditions for Characteristics

For conditions that express classifications like "zijn reis is een onbelaste reis", use explicit `exists` type:

❌ **WRONG - Implicit arrays:**

```json
"conditions": [
[
{"$ref": "#/facts/.../roles/role-uuid"},
{"$ref": "#/facts/.../properties/property-uuid"}
]
]
```

✅ **CORRECT - Explicit exists type:**

```json
"conditions": [
{
"type": "exists",
"characteristic": [
{"$ref": "#/facts/.../roles/role-uuid"},
{"$ref": "#/facts/.../properties/property-uuid"}
]
}
]
```

**Why explicit types are better:**

- **Clear intent**: `"type": "exists"` makes it obvious this checks for characteristic existence
- **Named fields**: `"characteristic"` is more descriptive than anonymous array position
- **Reusable**: XSL can have specific `format-exists` template for classification statements
- **Extensible**: Can add more fields like `"negated": true` for "is NOT a characteristic"

**XSL Processing:**

```xsl
<xsl:when test="$type = 'exists'">
    <xsl:call-template name="format-exists">
        <xsl:with-param name="exists" select="$condition"/>
    </xsl:call-template>
</xsl:when>
```

**Generated Output:**

- Input: `{"type": "exists", "characteristic": [role_ref, onbelaste_reis_ref]}`
- Output: `"zijn reis is een onbelaste reis"`

### Key Learning: Reuse Existing Constructs

**Always reuse existing templates and logic instead of creating new ones!**

Example: For conditions in anyOf/allOf, don't create special case handling - use the main `format-condition` template:

❌ **WRONG - Special case logic:**

```xsl
<xsl:choose>
    <xsl:when test="fn:array">
        <xsl:call-template name="format-reference-condition"/>
    </xsl:when>
    <xsl:otherwise>
        <xsl:call-template name="format-condition"/>
    </xsl:otherwise>
</xsl:choose>
```

✅ **CORRECT - Reuse existing:**

```xsl
<!-- Always use format-condition to handle all types -->
<xsl:call-template name="format-condition">
    <xsl:with-param name="condition" select="."/>
</xsl:call-template>
```

### Key Learning: Support Nested Expressions

**The `format-operand` template must handle nested arithmetic expressions.**

Complex arithmetic expressions like "A min (B maal C)" require the operand formatter to recursively handle arithmetic expressions within arithmetic expressions.

❌ **WRONG - Missing arithmetic support:**
```xsl
<!-- format-operand template without arithmetic case -->
<xsl:choose>
    <xsl:when test="$operand/fn:map[@key='parameter']">
        <!-- handle parameter -->
    </xsl:when>
    <xsl:otherwise>
        <xsl:text>onbekende operand</xsl:text> <!-- FAILS for nested arithmetic -->
    </xsl:otherwise>
</xsl:choose>
```

✅ **CORRECT - Recursive arithmetic support:**
```xsl
<!-- format-operand template with arithmetic case -->
<xsl:when test="$operand/fn:string[@key='type'] = 'arithmetic'">
    <xsl:call-template name="format-arithmetic">
        <xsl:with-param name="arithmetic" select="$operand"/>
    </xsl:call-template>
</xsl:when>
```

**Generated Output:**
- Before: "A min onbekende operand"  
- After: "A min B maal C"

### Key Learning: Classification Condition Negation

**Negative classifications should render as "zijn X is geen Y" format, not "niet (zijn X is een Y)".**

Extended `format-not` template to handle `exists` conditions specially:

```xsl
<xsl:when test="$condition/fn:string[@key='type'] = 'exists'">
    <!-- Generate "zijn X is geen Y" format -->
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
```

## Property-of-Characteristic Chains (Characteristic-as-Root Pattern)

### Problem: Rules with Characteristic Subjects

Some rules apply to specific characteristics of entities rather than general entities. For example:

❌ **WRONG - Generic role as root:**
```
"De belasting op basis van afstand van een passagier waarvoor de voorwaarden van toepassing is moet berekend worden als..."
```

✅ **CORRECT - Characteristic as root:**
```
"De belasting op basis van afstand van een passagier waarvoor het lage tarief voor belasting op basis van afstand van toepassing is moet berekend worden als..."
```

### Solution: Characteristic-as-Root Pattern

**When a rule applies to a specific characteristic, make the characteristic the ROOT (first element) of the target chain:**

❌ **WRONG - 3-element chain with role as root:**
```json
"target": [
  {"$ref": "#/facts/.../roles/0cc7c4b4-2855-4c8b-93f0-5403cf286af0"},      // passagier (role)
  {"$ref": "#/facts/.../properties/ef64a2f2-6dd5-46cb-bd4e-6708e70021dc"},  // lage tarief characteristic  
  {"$ref": "#/facts/.../properties/199d696e-a168-4584-8f80-35d737e5e1ba"}   // belasting property
]
```

✅ **CORRECT - 2-element chain with characteristic as root:**
```json
"target": [
  {"$ref": "#/facts/.../properties/ef64a2f2-6dd5-46cb-bd4e-6708e70021dc"},  // lage tarief characteristic (ROOT)
  {"$ref": "#/facts/.../properties/199d696e-a168-4584-8f80-35d737e5e1ba"}   // belasting property
]
```

### XSL Template Support

The `format-conditional-expression-rule` template detects characteristic roots using the `is-characteristic` helper:

```xsl
<xsl:variable name="is-root-characteristic">
    <xsl:call-template name="is-characteristic">
        <xsl:with-param name="ref" select="$root-ref"/>
    </xsl:call-template>
</xsl:variable>

<xsl:choose>
    <xsl:when test="$is-root-characteristic = 'true'">
        <!-- Use characteristic name directly -->
        <xsl:call-template name="resolve-path">
            <xsl:with-param name="path" select="$root-ref"/>
        </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
        <!-- Regular role with condition qualifier -->
        <!-- ... -->
    </xsl:otherwise>
</xsl:choose>
```

### How to Identify Characteristics

Characteristics are identified in JSON by `"type": "characteristic"`:

```json
"ef64a2f2-6dd5-46cb-bd4e-6708e70021dc": {
  "name": {
    "nl": "passagier waarvoor het lage tarief voor belasting op basis van afstand van toepassing is"
  },
  "versions": [
    {
      "validFrom": "2018",
      "type": "characteristic"  // ← This identifies it as a characteristic
    }
  ]
}
```
