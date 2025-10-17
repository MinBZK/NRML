# Blockly to NRML Converter Testing

## Quick Start

Run all tests:
```bash
cd blockly
python -m pytest tests/test_conversion.py -v
```

Run specific integration test:
```bash
cd blockly
python -m pytest tests/test_conversion.py::test_basic_conversion_matches_expected_output -v
```

Run schema validation:
```bash
cd blockly
python test_schema_compliance.py
python validate_with_schema.py
```

## PyCharm Configuration

### Method 1: Use Pre-configured Run Configurations (Recommended)

Pre-configured pytest run configurations are available in the run dropdown menu:

1. Click the run configuration dropdown (top-right, next to the play button)
2. Select either:
   - **`pytest: All Blockly Tests`** - Runs all 9 tests
   - **`pytest: Integration Test`** - Runs just the integration test
3. Click the green play button to run

These configurations are stored in `.idea/runConfigurations/` and should appear automatically.

### Method 2: Configure PyCharm Default Test Runner

If the pre-configured options don't appear, set pytest as default:

1. **Open Settings**: `File` → `Settings` (or `Ctrl+Alt+S`)
2. **Navigate to**: `Tools` → `Python Integrated Tools`
3. **Set Default test runner**: Select `pytest` from dropdown
4. **Apply**: Click `Apply` and `OK`

After setting pytest as default, you can:
- Right-click on `blockly/tests/test_conversion.py` → `Run 'pytest in test_conversion...'`
- Right-click on individual test functions → `Run 'pytest for test_...'`
- Use the green play buttons next to test functions

### Method 3: Create Manual Configuration

If methods 1 and 2 don't work:

1. Click `Run` → `Edit Configurations...`
2. Click `+` (Add New Configuration) → `Python tests` → `pytest`
3. Configure:
   - **Name**: `All Blockly Tests`
   - **Target**: `Script path`
   - **Script path**: Browse to `blockly/tests/test_conversion.py`
   - **Working directory**: `C:\Users\timde\Documents\Code\NRML\blockly`
   - **Python interpreter**: Select your project interpreter
4. Click `OK`
5. Run from the dropdown menu

## Test Structure

The converter has two types of tests:

### 1. **Unit Tests** (Structural Validation)

These tests verify specific aspects of the conversion:

- `test_basic_conversion_structure` - Validates top-level NRML structure
- `test_basic_conversion_constants_fact` - Validates Constants fact generation
- `test_basic_conversion_calculation_fact` - Validates Calculation fact generation
- `test_basic_conversion_references` - Validates reference path format
- `test_basic_conversion_precision` - Validates numeric precision detection
- `test_basic_conversion_values` - Validates value storage
- `test_conversion_statistics` - Validates conversion statistics
- `test_target_paths_match_items` - Validates target path correctness

### 2. **Integration Test** (Full Output Validation)

**`test_basic_conversion_matches_expected_output`** compares the entire conversion output against an expected JSON file.

#### How It Works

1. **Expected Output File**: `tests/fixtures/expected_output_basic.json`
   - Contains the expected NRML structure with normalized UUIDs (`fact-uuid-1`, `item-uuid-1`, etc.)

2. **UUID Normalization**: The `normalize_uuids()` function replaces random UUIDs with deterministic placeholders:
   ```python
   # Before normalization:
   "facts": {
     "3a480321-1e0e-4df6-b3ca-5e671ab10851": { ... }
   }

   # After normalization:
   "facts": {
     "fact-uuid-1": { ... }
   }
   ```

3. **Comparison**: Both actual and expected outputs are normalized before comparison

#### Running the Integration Test

**With pytest** (recommended):
```bash
cd blockly
python -m pytest tests/test_conversion.py::test_basic_conversion_matches_expected_output -v
```

**Run all tests**:
```bash
cd blockly
python -m pytest tests/test_conversion.py -v
```

**Standalone script** (for detailed output):
```bash
cd blockly
python test_expected_output.py
```

The standalone script provides detailed output:
- Normalized expected output
- Normalized actual output
- Comparison result
- Detailed diff if outputs don't match

## Schema Compliance

Two additional validation scripts ensure schema compliance:

### Custom Compliance Check
```bash
cd blockly
python test_schema_compliance.py
```

Validates:
- Required root fields (`$schema`, `version`, `language`, `facts`)
- Allowed root fields (no extras)
- Required fact fields (`name`, `items`)
- Allowed fact fields
- Required item fields (`name`, `versions`)
- **Allowed item fields** (excludes `reference-key` - internal only)
- Required version fields (`validFrom`)
- Version type combinations

### JSON Schema Validation
```bash
cd blockly
python validate_with_schema.py
```

Uses the `jsonschema` library to validate against `schema.json`:
- Structural validation
- Type validation
- Required field validation
- Additional properties validation

## Test Fixtures

### Input Fixture
**`tests/fixtures/test_input_basic.json`** - Blockly workspace JSON with:
- 2 constant blocks (km_vergoeding = 0.21, afstand = 12)
- 1 calculation block (km_vergoeding * afstand)

### Expected Output Fixture
**`tests/fixtures/expected_output_basic.json`** - Expected NRML output with:
- 2 facts (Constants, Calculation)
- 3 items (2 constants, 1 calculated)
- 5 versions (2 type defs + 2 value inits + 1 calculated expression)

## Benefits of JSON-based Expected Output

1. **Readability**: Expected output is clearly visible in JSON format
2. **Maintainability**: Easy to update when converter output changes
3. **Completeness**: Validates entire structure, not just specific fields
4. **Documentation**: Expected output serves as specification
5. **UUID-agnostic**: Normalization handles random UUID generation

## Adding New Test Cases

To add a new integration test:

1. Create input fixture in `tests/fixtures/test_input_*.json`
2. Run converter manually to generate output
3. Normalize the output (replace UUIDs with `fact-uuid-N`, `item-uuid-N`)
4. Save as `tests/fixtures/expected_output_*.json`
5. Add test function using the same pattern as `test_basic_conversion_matches_expected_output`

Example:
```python
def test_complex_conversion_matches_expected(converter, fixtures_dir):
    """Test complex conversion output"""
    # Load fixtures
    with open(fixtures_dir / "test_input_complex.json") as f:
        test_input = json.load(f)
    with open(fixtures_dir / "expected_output_complex.json") as f:
        expected = json.load(f)

    # Convert and compare
    actual = converter.convert(test_input)
    assert normalize_uuids(actual) == normalize_uuids(expected)
```
