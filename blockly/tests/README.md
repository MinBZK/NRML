# Blockly to NRML Conversion Tests

Pytest-based test suite for the Blockly to NRML converter.

## Structure

```
tests/
├── __init__.py           # Package marker
├── conftest.py           # Pytest configuration and fixtures
├── test_conversion.py    # Main conversion tests
├── fixtures/             # Test input/output files
│   └── test_input_basic.json
└── README.md            # This file
```

## Running Tests

### Run all tests1

```bash
cd blockly
python -m pytest tests/
```

### Run with verbose output

```bash
python -m pytest tests/ -v
```

### Run specific test

```bash
python -m pytest tests/test_conversion.py::test_basic_conversion_structure -v
```

### Run with coverage (if pytest-cov installed)

```bash
python -m pytest tests/ --cov=nrml-conversion --cov-report=html
```

## Test Cases

### `test_basic_conversion_structure`
Tests that basic conversion produces valid NRML structure with correct top-level fields.

### `test_basic_conversion_constants_fact`
Tests that the "Constants" fact is generated correctly with:
- 2 items (km_vergoeding, afstand)
- Each item has 2 versions (type definition + value initialization)
- Proper reference keys

### `test_basic_conversion_calculation_fact`
Tests that the "Calculation" fact is generated correctly with:
- 1 item (totaal_vergoeding)
- Calculated value with arithmetic expression
- Proper expression structure (type, operator, arguments)

### `test_basic_conversion_references`
Tests that all references use full UUID paths:
- Format: `#/facts/{uuid}/items/{uuid}`
- References are in array format
- Contains `$ref` key

### `test_basic_conversion_precision`
Tests automatic precision detection:
- 0.21 → precision 2
- 12 → precision 0

### `test_basic_conversion_values`
Tests that values are correctly stored in value initialization versions.

### `test_conversion_statistics`
Tests that statistics are correctly calculated:
- Facts: 2
- Items: 3
- Versions: 5
- Variables: 3

### `test_target_paths_match_items`
Tests that target paths correctly reference their own items (value initializations and calculated values point to their parent item).

## Test Fixtures

### `test_input_basic.json`
Basic test case with:
- 2 constants: km_vergoeding = 0.21, afstand = 12
- 1 calculation: totaal_vergoeding = afstand × km_vergoeding

## Adding New Tests

1. **Create test input file** in `fixtures/`
   ```bash
   tests/fixtures/test_input_new_feature.json
   ```

2. **Add fixture in `test_conversion.py`**
   ```python
   @pytest.fixture
   def test_input_new_feature(fixtures_dir):
       with open(fixtures_dir / "test_input_new_feature.json") as f:
           return json.load(f)
   ```

3. **Write test function**
   ```python
   def test_new_feature(converter, test_input_new_feature):
       result = converter.convert(test_input_new_feature)
       # Add assertions
       assert ...
   ```

## Requirements

```bash
pip install pytest
```

Optional:
```bash
pip install pytest-cov  # For coverage reports
pip install pytest-xdist  # For parallel test execution
```

## CI Integration

Example GitHub Actions workflow:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: '3.8'
      - run: pip install pytest
      - run: pytest tests/ -v
```

## Test Output

Successful test run:
```
============================= test session starts =============================
tests/test_conversion.py::test_basic_conversion_structure PASSED         [ 12%]
tests/test_conversion.py::test_basic_conversion_constants_fact PASSED    [ 25%]
tests/test_conversion.py::test_basic_conversion_calculation_fact PASSED  [ 37%]
tests/test_conversion.py::test_basic_conversion_references PASSED        [ 50%]
tests/test_conversion.py::test_basic_conversion_precision PASSED         [ 62%]
tests/test_conversion.py::test_basic_conversion_values PASSED            [ 75%]
tests/test_conversion.py::test_conversion_statistics PASSED              [ 87%]
tests/test_conversion.py::test_target_paths_match_items PASSED           [100%]

============================== 8 passed in 0.03s
```
