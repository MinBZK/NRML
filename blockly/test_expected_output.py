"""
Standalone test to verify conversion output matches expected JSON
"""

import json
import sys
from pathlib import Path

# Add nrml-conversion to path
sys.path.insert(0, str(Path(__file__).parent / "nrml-conversion"))

from converter import BlocklyToNRMLConverter


def normalize_uuids(data, uuid_map=None):
    """
    Replace all UUIDs in a JSON structure with deterministic placeholders.
    """
    if uuid_map is None:
        uuid_map = {"fact_counter": 0, "item_counter": 0, "mapping": {}}

    if isinstance(data, dict):
        normalized = {}
        for key, value in data.items():
            # Normalize UUID keys (in facts and items dictionaries)
            if key in ["facts", "items"] and isinstance(value, dict):
                normalized_dict = {}
                for uuid, content in value.items():
                    if uuid not in uuid_map["mapping"]:
                        if key == "facts":
                            uuid_map["fact_counter"] += 1
                            uuid_map["mapping"][uuid] = f"fact-uuid-{uuid_map['fact_counter']}"
                        else:  # items
                            uuid_map["item_counter"] += 1
                            uuid_map["mapping"][uuid] = f"item-uuid-{uuid_map['item_counter']}"
                    normalized_uuid = uuid_map["mapping"][uuid]
                    normalized_dict[normalized_uuid] = normalize_uuids(content, uuid_map)
                normalized[key] = normalized_dict
            else:
                normalized[key] = normalize_uuids(value, uuid_map)
        return normalized

    elif isinstance(data, list):
        return [normalize_uuids(item, uuid_map) for item in data]

    elif isinstance(data, str):
        # Replace UUIDs in $ref strings
        result = data
        for original_uuid, normalized_uuid in uuid_map["mapping"].items():
            result = result.replace(original_uuid, normalized_uuid)
        return result

    else:
        return data


def main():
    # Load expected output
    expected_path = Path(__file__).parent / "tests" / "fixtures" / "expected_output_basic.json"
    with open(expected_path) as f:
        expected = json.load(f)

    # Load test input
    test_input_path = Path(__file__).parent / "tests" / "fixtures" / "test_input_basic.json"
    with open(test_input_path) as f:
        blockly_json = json.load(f)

    # Convert
    converter = BlocklyToNRMLConverter()
    actual = converter.convert(blockly_json)

    # Normalize UUIDs
    normalized_expected = normalize_uuids(expected)
    normalized_actual = normalize_uuids(actual)

    # Compare
    print("=" * 80)
    print("NORMALIZED EXPECTED OUTPUT:")
    print("=" * 80)
    print(json.dumps(normalized_expected, indent=2))
    print()

    print("=" * 80)
    print("NORMALIZED ACTUAL OUTPUT:")
    print("=" * 80)
    print(json.dumps(normalized_actual, indent=2))
    print()

    print("=" * 80)
    print("COMPARISON RESULT:")
    print("=" * 80)

    if normalized_actual == normalized_expected:
        print("[PASS] Actual output matches expected output!")
        return 0
    else:
        print("[FAIL] Actual output does not match expected output")

        # Find differences
        def find_diffs(path, obj1, obj2):
            if isinstance(obj1, dict) and isinstance(obj2, dict):
                all_keys = set(obj1.keys()) | set(obj2.keys())
                for key in all_keys:
                    new_path = f"{path}.{key}" if path else key
                    if key not in obj1:
                        print(f"  Missing in actual: {new_path}")
                    elif key not in obj2:
                        print(f"  Extra in actual: {new_path}")
                    else:
                        find_diffs(new_path, obj1[key], obj2[key])
            elif isinstance(obj1, list) and isinstance(obj2, list):
                if len(obj1) != len(obj2):
                    print(f"  Different lengths at {path}: expected {len(obj1)}, got {len(obj2)}")
                for i, (item1, item2) in enumerate(zip(obj1, obj2)):
                    find_diffs(f"{path}[{i}]", item1, item2)
            elif obj1 != obj2:
                print(f"  Different value at {path}: expected {obj1!r}, got {obj2!r}")

        find_diffs("", normalized_expected, normalized_actual)
        return 1


if __name__ == "__main__":
    sys.exit(main())
