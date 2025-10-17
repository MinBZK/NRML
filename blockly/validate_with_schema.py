"""
Validate converter output against the official schema.json
"""

import json
import sys
from pathlib import Path

try:
    import jsonschema
except ImportError:
    print("ERROR: jsonschema module not found")
    print("Install with: pip install jsonschema")
    sys.exit(1)

# Add nrml-conversion to path
sys.path.insert(0, str(Path(__file__).parent / "nrml-conversion"))

from converter import BlocklyToNRMLConverter


def validate_against_schema():
    """Validate converter output against schema.json"""

    # Load schema
    schema_path = Path(__file__).parent.parent / "schema.json"
    with open(schema_path) as f:
        schema = json.load(f)

    # Load test input
    test_input_path = Path(__file__).parent / "tests" / "fixtures" / "test_input_basic.json"
    with open(test_input_path) as f:
        blockly_json = json.load(f)

    # Convert
    converter = BlocklyToNRMLConverter()
    result = converter.convert(blockly_json)

    # Print result
    print("=" * 80)
    print("CONVERSION OUTPUT:")
    print("=" * 80)
    print(json.dumps(result, indent=2))
    print()

    # Validate
    print("=" * 80)
    print("JSON SCHEMA VALIDATION:")
    print("=" * 80)

    try:
        jsonschema.validate(instance=result, schema=schema)
        print("[PASS] Output validates successfully against schema.json!")
        print("=" * 80)
        return True
    except jsonschema.exceptions.ValidationError as e:
        print(f"[FAIL] Validation error:")
        print(f"  Path: {' -> '.join(str(p) for p in e.path)}")
        print(f"  Message: {e.message}")
        print("=" * 80)
        return False
    except jsonschema.exceptions.SchemaError as e:
        print(f"[FAIL] Schema error: {e}")
        print("=" * 80)
        return False


if __name__ == "__main__":
    success = validate_against_schema()
    sys.exit(0 if success else 1)
