

# Blockly to NRML Converter (Python)

A modular, reusable Python converter that transforms standard Blockly JSON to NRML format.

## Architecture

### Modular Design

The converter uses a clean separation of concerns:

```
┌─────────────────────┐
│  Blockly JSON Input │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   BlockAnalyzer     │  ← Determines NRML types from block types
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   NRMLRegistry      │  ← In-memory dictionary of facts/items
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  NRMLGenerators     │  ← Creates NRML structures
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   NRML JSON Output  │
└─────────────────────┘
```

### Modules

#### 1. `block_analyzer.py`
**Purpose**: Analyze Blockly blocks and determine NRML type mappings

**Key Functions**:
- `analyze_block(block)` → Returns list of `NRMLType` enums
- `get_variable_name(block, variables)` → Extracts variable name
- `get_numeric_value(block)` → Extracts numeric value
- `count_decimal_places(value)` → Determines precision

**Mapping Rules**:
- `variables_set` + `math_number` → `TYPE_DEFINITION` + `VALUE_INITIALIZATION`
- `variables_set` + `math_arithmetic` → `CALCULATED_VALUE`
- `variables_set` + logic → `CONDITIONAL_VALUE`

#### 2. `nrml_registry.py`
**Purpose**: In-memory dictionary manager for NRML structures

**Key Functions**:
- `create_fact(name)` → Creates new fact, returns UUID
- `create_item(fact_uuid, reference_key)` → Creates item, returns UUID
- `add_version_to_item(fact_uuid, item_uuid, version)` → Adds version entry
- `get_item_path(reference_key)` → Gets full path with UUIDs
- `to_nrml()` → Exports complete NRML JSON

**Data Structure**:
```python
{
    'facts': {
        'uuid-1': {
            'name': {'nl': 'Constants'},
            'items': {
                'uuid-2': {
                    'reference-key': 'km_vergoeding',
                    'versions': [...]
                }
            }
        }
    }
}
```

#### 3. `nrml_generators.py`
**Purpose**: Factory methods for creating NRML structures

**Key Functions**:
- `create_type_definition_numeric(precision, unit)` → Type definition
- `create_type_definition_text()` → Text type
- `create_value_initialization(target_path, value, unit)` → Value init
- `create_calculated_value(target_path, expression)` → Calculated value
- `create_arithmetic_expression(operator, arguments)` → Expression
- `map_blockly_operator(blockly_op)` → Operator mapping

#### 4. `converter.py`
**Purpose**: Main orchestration of conversion process

**Process**:
1. Parse Blockly JSON (blocks + variables)
2. **First Pass**: Process constants (variables_set + math_number)
   - Create "Constants" fact
   - Generate type definitions + value initializations
3. **Second Pass**: Process calculations (variables_set + math_arithmetic)
   - Create "Calculation" fact
   - Generate calculated values with expressions
4. Export to NRML JSON

#### 5. `convert.py`
**Purpose**: CLI interface

## Usage

### Basic Conversion

```bash
# Convert file to file
python convert.py input.json output.nrml.json

# Convert to stdout
python convert.py input.json

# With verbose output
python convert.py input.json output.nrml.json -v

# Custom indentation
python convert.py input.json output.nrml.json --indent 4
```

### As a Module

```python
from converter import BlocklyToNRMLConverter
import json

# Load Blockly JSON
with open('input.json') as f:
    blockly_json = json.load(f)

# Convert
converter = BlocklyToNRMLConverter()
nrml_json = converter.convert(blockly_json)

# Get statistics
stats = converter.get_statistics()
print(f"Generated {stats['facts']} facts with {stats['items']} items")
```

## Examples

### Input (Blockly JSON)

```json
{
  "blocks": {
    "blocks": [
      {
        "type": "variables_set",
        "fields": { "VAR": { "id": "var1" } },
        "inputs": {
          "VALUE": {
            "block": { "type": "math_number", "fields": { "NUM": 0.21 } }
          }
        }
      }
    ]
  },
  "variables": [
    { "name": "km_vergoeding", "id": "var1" }
  ]
}
```

### Output (NRML JSON)

```json
{
  "$schema": "https://example.com/nrml-facts-schema.json",
  "version": "1.0",
  "language": "nl",
  "facts": {
    "uuid-1": {
      "name": { "nl": "Constants" },
      "items": {
        "uuid-2": {
          "name": { "nl": "" },
          "reference-key": "km_vergoeding",
          "versions": [
            {
              "validFrom": "2025-10-15",
              "type": "numeric",
              "precision": 2
            },
            {
              "validFrom": "2025-10-15",
              "target": [{ "$ref": "#/facts/uuid-1/items/uuid-2" }],
              "value": { "value": 0.21 }
            }
          ]
        }
      }
    }
  }
}
```

## Block Type Mappings

| Blockly Block | NRML Structure | Description |
|---------------|----------------|-------------|
| `variables_set` + `math_number` | Type Definition + Value Initialization | Constant value |
| `variables_set` + `text` | Type Definition + Value Initialization | Text constant |
| `variables_set` + `math_arithmetic` | Calculated Value | Arithmetic expression |
| `math_arithmetic` | Arithmetic Expression | Operator + arguments |
| `variables_get` | Reference | Variable reference |

## Supported Operators

| Blockly | NRML |
|---------|------|
| ADD | add |
| MINUS | subtract |
| MULTIPLY | multiply |
| DIVIDE | divide |
| POWER | power |
| MOD | modulo |
| MIN | min |
| MAX | max |

## Extension Points

### Adding New Block Types

1. **Add to `block_analyzer.py`**:
```python
def _analyze_new_block_type(self, block: Dict[str, Any]) -> List[NRMLType]:
    # Determine what NRML structures this creates
    return [NRMLType.SOME_TYPE]
```

2. **Register in mapping**:
```python
self.block_type_mappings['new_block_type'] = self._analyze_new_block_type
```

3. **Add generator in `nrml_generators.py`**:
```python
@staticmethod
def create_new_structure(params):
    return {"type": "new_type", ...}
```

4. **Handle in `converter.py`**:
```python
if NRMLType.SOME_TYPE in nrml_types:
    # Generate NRML structure
    new_struct = self.generators.create_new_structure(...)
    self.registry.add_version_to_item(...)
```

## Testing

```bash
# Run tests
pytest

# Test with sample file
python convert.py ../nrml-editor/test-standard-blockly.json test-output.json -v
```

## Design Principles

1. **Separation of Concerns**: Each module has a single responsibility
2. **Reusability**: Modules can be used independently
3. **Extensibility**: Easy to add new block types and NRML structures
4. **Type Safety**: Uses enums and type hints
5. **Testability**: Pure functions with clear inputs/outputs
