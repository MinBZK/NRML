# NRML Custom Blockly Blocks

This directory contains custom Blockly block definitions for visual programming of NRML (Normalized Rule Model Language) rules.

## Overview

NRML has several constructs that cannot be represented with standard Blockly blocks. This module provides three custom blocks to bridge that gap:

1. **`aggregation_count`** / **`aggregation_sum`** - Aggregation functions
2. **`property_access`** - Multi-hop reference chain navigation
3. **`conditional_value`** - Conditional assignment pattern

## Block Definitions

### 1. Aggregation Blocks

#### `aggregation_count`
Count items in a collection that match a condition.

**Inputs:**
- `COLLECTION` (Array/List) - The collection to count from
- `CONDITION` (Boolean) - Filter condition (optional)

**Output:** Number

**NRML Mapping:**
```json
{
  "type": "aggregation",
  "function": "count",
  "expression": [{"$ref": "..."}],
  "condition": {...},
  "default": {"value": 0}
}
```

**Example:**
```
count items in [kinderen]
where [kind.leeftijd <= 10]
→ Returns number of children age 10 or under
```

#### `aggregation_sum`
Sum a property across items in a collection.

**Inputs:**
- `COLLECTION` (Array/List) - The collection to sum from
- `PROPERTY` - The property to sum
- `CONDITION` (Boolean) - Filter condition (optional)

**Output:** Number

**NRML Mapping:**
```json
{
  "type": "aggregation",
  "function": "sum",
  "expression": [
    {"$ref": "#/facts/.../roles/..."},
    {"$ref": "#/facts/.../properties/..."}
  ],
  "condition": {...}
}
```

### 2. Property Access Blocks

#### `property_access`
Access a property through an NRML reference chain.

**Inputs:**
- `PROPERTY` (Field) - Property name to access
- `OBJECT` - Object to access property from

**Output:** Any (depends on property type)

**NRML Mapping:**
```json
[
  {"$ref": "#/facts/.../items/role-uuid"},
  {"$ref": "#/facts/.../items/property-uuid"}
]
```

**Example:**
```
property [leeftijd] of [kind]
→ Accesses kind.leeftijd via NRML reference chain
```

#### `property_access_direct`
Simplified version for direct property access without context object.

**Inputs:**
- `PROPERTY` (Field) - Property name

**Output:** Any

### 3. Conditional Value Block

#### `conditional_value`
Returns a value only if a condition is true.

**Inputs:**
- `VALUE` - The value to return
- `CONDITION` (Boolean) - When to return the value

**Output:** Any (or undefined)

**NRML Mapping:**
```json
{
  "value": {"value": true},
  "condition": {
    "type": "comparison",
    "operator": "greaterThan",
    "arguments": [...]
  }
}
```

**Example:**
```
value [true] if [totaal > 0]
→ Returns true only if totaal > 0, otherwise undefined
```

## Extra State / Metadata

Each custom block stores NRML-specific metadata in its `extraState` property:

### Common Fields

- **`nrmlRef`** (string) - Complete NRML reference path (e.g., `"#/facts/.../items/uuid"`)
- **`nrmlType`** (string) - NRML expression type (e.g., `"aggregation"`, `"arithmetic"`)

### Aggregation-Specific

- **`aggregationType`** (string) - Function type: `"count"`, `"sum"`, `"average"`, etc.
- **`expressionChain`** (array) - Array of `{$ref: "..."}` objects
- **`default`** (object) - Default value: `{"value": 0}` or `{"value": 0, "unit": "€"}`

### Property Access-Specific

- **`referenceChain`** (array) - Multi-hop chain: `[{$ref: role}, {$ref: property}]`
- **`propertyType`** (string) - Type of property: `"numeric"`, `"boolean"`, etc.
- **`unit`** (string) - Unit if numeric: `"€"`, `"jaar"`, etc.

### Conditional Value-Specific

- **`valueType`** (string) - Type of value being conditionally assigned

## Installation

### 1. Include the script in your HTML

```html
<script src="https://unpkg.com/blockly/blockly.min.js"></script>
<script src="custom_blocks/nrml_blocks.js"></script>
```

### 2. Or import as a module

```javascript
import { blocklyToNRML, nrmlToBlockly } from './custom_blocks/nrml_blocks.js';
```

## Usage

### Loading NRML into Blockly

```javascript
// Load NRML JSON
const nrmlData = await fetch('rules/kinderbijslag.nrml.json').then(r => r.json());

// Create Blockly workspace
const workspace = Blockly.inject('blocklyDiv', {
  toolbox: document.getElementById('toolbox')
});

// Convert NRML to Blockly blocks
nrmlToBlockly(nrmlData, workspace);
```

### Converting Blockly to NRML

```javascript
// Get current workspace
const workspace = Blockly.getMainWorkspace();

// Convert to NRML JSON
const nrmlOutput = blocklyToNRML(workspace);

// Save or process NRML
console.log(JSON.stringify(nrmlOutput, null, 2));
```

### Creating Blocks Programmatically

```javascript
// Create an aggregation count block
const countBlock = workspace.newBlock('aggregation_count');

// Set NRML metadata
countBlock.extraState = {
  aggregationType: 'count',
  nrmlRef: '#/facts/28b83711-2080-469f-be02-ae8f963affb9/items/1100dac1-6d75-498a-b5db-6b4faacf77b0',
  expressionChain: [
    {"$ref": "#/facts/43d7495f-da13-4bbf-a485-676cbfe7cedc/items/47b9bf9b-e998-421a-8725-3e2335c9c234"}
  ],
  default: {value: 0}
};

// Initialize and render
countBlock.initSvg();
countBlock.render();
```

## Toolbox Configuration

Add custom blocks to your Blockly toolbox:

```xml
<xml id="toolbox" style="display: none">
  <!-- Standard blocks -->
  <category name="Logic" colour="210">
    <block type="controls_if"></block>
    <block type="logic_compare"></block>
  </category>

  <category name="Math" colour="230">
    <block type="math_number"></block>
    <block type="math_arithmetic"></block>
  </category>

  <!-- NRML custom blocks -->
  <category name="NRML Aggregation" colour="230">
    <block type="aggregation_count">
      <value name="COLLECTION">
        <shadow type="variables_get"></shadow>
      </value>
    </block>
    <block type="aggregation_sum">
      <value name="COLLECTION">
        <shadow type="variables_get"></shadow>
      </value>
    </block>
  </category>

  <category name="NRML Properties" colour="160">
    <block type="property_access">
      <field name="PROPERTY">property_name</field>
    </block>
    <block type="property_access_direct">
      <field name="PROPERTY">property_name</field>
    </block>
  </category>

  <category name="NRML Conditions" colour="210">
    <block type="conditional_value"></block>
  </category>
</xml>
```

## Code Generation

The blocks include JavaScript code generators. To generate executable code:

```javascript
// Generate JavaScript from workspace
const code = Blockly.JavaScript.workspaceToCode(workspace);

// Execute generated code
const result = eval(code);
```

### Example Generated Code

From this Blockly configuration:
```
count items in [kinderen]
where [kind.leeftijd <= 10]
```

Generates:
```javascript
(function() {
  const coll = kinderen;
  if (!coll || coll.length === 0) return 0;
  return coll.filter(item => item.leeftijd <= 10).length;
})()
```

## Round-Trip Conversion

The system supports **lossless round-trip conversion**:

```
NRML JSON → Blockly → NRML JSON
```

All NRML-specific information is preserved through the `extraState` mechanism:

1. **UUIDs** - All fact/property references preserved
2. **Reference chains** - Multi-hop paths maintained
3. **Type information** - Units, precision, types stored
4. **Default values** - Aggregation defaults preserved
5. **Metadata** - Validation dates, legal basis, etc.

## Type System Integration

The blocks respect NRML's type system:

| NRML Type | Blockly Type | Notes |
|-----------|--------------|-------|
| `numeric` | `Number` | Includes `integer` and `decimal` subtypes |
| `boolean` | `Boolean` | true/false values |
| `string` | `String` | Text values |
| `array` | `Array` | Collections for aggregation |
| `characteristic` | Custom | Special classification type |

## Testing

See `blockly/tests/fixtures/` for example configurations:

- **`test_input_aggregation.json`** - Standard Blockly blocks example
- **`kinderbijslag_blockly.json`** - Full NRML example with custom blocks

## Limitations

### What Standard Blockly CAN Handle

✅ Variable assignments (`variables_set`)
✅ Numeric constants (`math_number`)
✅ Arithmetic operations (`math_arithmetic`)
✅ Comparisons (`logic_compare`)
✅ Boolean operations (`logic_operation`)
✅ Control flow (`controls_if`, `controls_forEach`)

### What Requires Custom Blocks

❌ Aggregations with filters (no standard block)
❌ Multi-hop reference chains (complex data navigation)
❌ Conditional assignments (value + condition pattern)
❌ NRML-specific metadata (UUIDs, legal references)

## Future Enhancements

Potential additions for fuller NRML support:

1. **`characteristic_check`** - Block for `exists`/`notExists` conditions
2. **`reference_chain_builder`** - Visual builder for multi-hop chains
3. **`temporal_validity`** - Block for `validFrom`/`validTo` dates
4. **`multi_language`** - Support for multilingual text fields
5. **`fact_definition`** - Blocks for defining facts/properties visually

## Contributing

When adding new custom blocks:

1. Define block structure in `init()` function
2. Implement `extraState` for NRML metadata
3. Add serialization: `mutationToDom()` / `domToMutation()`
4. Add JSON serialization: `saveExtraState()` / `loadExtraState()`
5. Create code generator (JavaScript/Python)
6. Update `blocklyToNRML()` and `nrmlToBlockly()` converters
7. Add tests in `blockly/tests/`

## License

Part of the NRML project. See main repository for license details.
