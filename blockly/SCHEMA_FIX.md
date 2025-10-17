# Schema Compliance Fix

## Issue

The Blockly to NRML converter was outputting a `"reference-key"` field in items, which is **not allowed** by `schema.json`:

```json
"items": {
  "uuid": {
    "name": {"nl": ""},
    "reference-key": "km_vergoeding",  // ❌ NOT IN SCHEMA
    "versions": [...]
  }
}
```

According to `schema.json` line 100, items have `"additionalProperties": false` and only allow:
- `name` (required)
- `article` (optional)
- `plural` (optional)
- `versions` (required)

## Root Cause

The `reference-key` field was added in `nrml_registry.py` for internal tracking purposes (mapping variable names to item UUIDs), but it was incorrectly being included in the final NRML output when calling `to_nrml()`.

## Fix Applied

### 1. Modified `nrml_registry.py`

Updated the `to_nrml()` method to:
- Create a clean copy of the facts structure
- **Exclude `reference-key`** from items in the output
- Keep `reference-key` internally for lookups (in `self.facts`)
- Only include schema-compliant fields in the output

**Key changes:**
```python
# Before (line 161):
"facts": self.facts  # Included reference-key

# After (lines 159-194):
# Create clean copy without reference-key
clean_facts = {}
for fact_uuid, fact in self.facts.items():
    # ... copy only schema-compliant fields
    clean_item = {
        "name": item["name"],
        "versions": item["versions"]
    }
    # reference-key is NOT included
```

### 2. Updated Tests

Modified `tests/test_conversion.py` to not rely on `reference-key` in output:
- **test_basic_conversion_constants_fact** - Now identifies items by their values (0.21, 12)
- **test_basic_conversion_calculation_fact** - Removed reference-key check
- **test_basic_conversion_precision** - Identifies items by values to check precision
- **test_basic_conversion_values** - Collects values without using reference-key
- **test_target_paths_match_items** - Updated error message

### 3. Updated Validation Scripts

Updated `test_schema_compliance.py`:
- Changed allowed item fields from `["name", "article", "plural", "versions", "reference-key"]`
- To: `["name", "article", "plural", "versions"]`

Created `validate_with_schema.py`:
- Validates converter output against official `schema.json` using `jsonschema` library
- Provides detailed validation error messages

## Validation Results

### ✅ Custom Compliance Check
```bash
cd blockly && python test_schema_compliance.py
```
**Result:** `[PASS] ALL SCHEMA COMPLIANCE CHECKS PASSED!`

### ✅ Official JSON Schema Validation
```bash
cd blockly && python validate_with_schema.py
```
**Result:** `[PASS] Output validates successfully against schema.json!`

## Internal vs External Fields

The fix maintains a clear separation:

| Field | Internal Use | NRML Output |
|-------|-------------|-------------|
| `reference-key` | ✅ Stored in registry | ❌ Excluded from output |
| `name` | ✅ Stored | ✅ Included |
| `versions` | ✅ Stored | ✅ Included |
| `article` | ✅ Stored | ✅ Included (if present) |
| `plural` | ✅ Stored | ✅ Included (if present) |

## Benefits

1. **Schema Compliant** - Output now validates against official schema
2. **Backward Compatible** - Internal lookup mechanisms still work
3. **Clean Separation** - Internal tracking vs external output
4. **Test Coverage** - Tests now validate actual output structure

## Testing

Run all validations:
```bash
# Custom compliance check
python blockly/test_schema_compliance.py

# JSON Schema validation
python blockly/validate_with_schema.py

# Full test suite (requires pytest)
cd blockly && pytest tests/test_conversion.py -v
```

## Files Modified

1. `blockly/nrml-conversion/nrml_registry.py` - Fixed `to_nrml()` method
2. `blockly/tests/test_conversion.py` - Updated 5 tests
3. `blockly/test_schema_compliance.py` - Updated allowed fields
4. `blockly/validate_with_schema.py` - Created (new file)

## Summary

The `reference-key` field was an internal implementation detail that leaked into the output. It has been properly isolated to internal use only, ensuring the converter now produces 100% schema-compliant NRML JSON.
