"""
Check if converter output complies with schema.json
"""

import json
import sys
from pathlib import Path

# Add nrml-conversion to path
sys.path.insert(0, str(Path(__file__).parent / "nrml-conversion"))

from converter import BlocklyToNRMLConverter


def check_schema_compliance():
    """Check if conversion output complies with schema"""

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

    # Check against schema requirements
    print("=" * 80)
    print("SCHEMA COMPLIANCE CHECK:")
    print("=" * 80)

    issues = []

    # Check root level required fields
    required_root = ["$schema", "version", "language", "facts"]
    for field in required_root:
        if field not in result:
            issues.append(f"[FAIL] Missing required root field: {field}")
        else:
            print(f"[PASS] Has required root field: {field}")

    # Check for invalid root fields
    allowed_root = ["$schema", "version", "language", "facts", "metadata"]
    for field in result:
        if field not in allowed_root:
            issues.append(f"[FAIL] Invalid root field (not in schema): {field}")
        else:
            print(f"[PASS] Valid root field: {field}")

    # Check facts structure
    if "facts" in result:
        facts = result["facts"]
        print(f"\n[PASS] Has {len(facts)} fact(s)")

        for fact_uuid, fact in facts.items():
            print(f"\n  Fact: {fact_uuid}")

            # Check required fact fields
            if "name" not in fact:
                issues.append(f"[FAIL] Fact {fact_uuid} missing required field: name")
            else:
                print(f"    [PASS] Has name: {fact.get('name')}")

            if "items" not in fact:
                issues.append(f"[FAIL] Fact {fact_uuid} missing required field: items")
            else:
                print(f"    [PASS] Has items")

            # Check for invalid fact fields
            allowed_fact_fields = ["name", "definite_article", "animated", "relation", "items"]
            for field in fact:
                if field not in allowed_fact_fields:
                    issues.append(f"[FAIL] Fact {fact_uuid} has invalid field: {field}")
                    print(f"    [FAIL] Invalid field: {field}")

            # Check items
            if "items" in fact:
                items = fact["items"]
                print(f"    [PASS] Has {len(items)} item(s)")

                for item_uuid, item in items.items():
                    print(f"\n      Item: {item_uuid}")

                    # Check required item fields
                    if "name" not in item:
                        issues.append(f"[FAIL] Item {item_uuid} missing required field: name")
                    else:
                        print(f"        [PASS] Has name: {item.get('name')}")

                    if "versions" not in item:
                        issues.append(f"[FAIL] Item {item_uuid} missing required field: versions")
                    else:
                        print(f"        [PASS] Has versions: {len(item['versions'])} version(s)")

                    # Check for invalid item fields (reference-key is internal only, not in schema)
                    allowed_item_fields = ["name", "article", "plural", "versions"]
                    for field in item:
                        if field not in allowed_item_fields:
                            issues.append(f"[FAIL] Item {item_uuid} has invalid field: {field}")
                            print(f"        [FAIL] Invalid field: {field}")

                    # Check versions
                    if "versions" in item:
                        for i, version in enumerate(item["versions"]):
                            print(f"\n          Version {i}:")

                            # Check validFrom
                            if "validFrom" not in version:
                                issues.append(f"[FAIL] Version {i} missing required field: validFrom")
                            else:
                                print(f"            [PASS] Has validFrom: {version['validFrom']}")

                            # Determine version type
                            has_type = "type" in version
                            has_target = "target" in version
                            has_value = "value" in version
                            has_expression = "expression" in version
                            has_condition = "condition" in version
                            has_arguments = "arguments" in version

                            print(f"            Fields: type={has_type}, target={has_target}, value={has_value}, expression={has_expression}, condition={has_condition}, arguments={has_arguments}")

                            # Type definition
                            if has_type and not has_target:
                                print(f"            [PASS] Type definition")
                            # Value initialization
                            elif has_target and has_value and not has_condition and not has_expression:
                                print(f"            [PASS] Value initialization")
                            # Calculated value
                            elif has_target and has_expression and not has_condition and not has_value:
                                print(f"            [PASS] Calculated value")
                            # Conditional value
                            elif has_target and has_value and has_condition:
                                print(f"            [PASS] Conditional value")
                            # Conditional calculated value
                            elif has_target and has_expression and has_condition:
                                print(f"            [PASS] Conditional calculated value")
                            # Relation definition
                            elif has_arguments:
                                print(f"            [PASS] Relation definition")
                            else:
                                issues.append(f"[FAIL] Version {i} has invalid combination of fields")
                                print(f"            [FAIL] Unknown version type")

    # Summary
    print("\n" + "=" * 80)
    if issues:
        print(f"[FAIL] FOUND {len(issues)} SCHEMA COMPLIANCE ISSUE(S):")
        print("=" * 80)
        for issue in issues:
            print(issue)
        return False
    else:
        print("[PASS] ALL SCHEMA COMPLIANCE CHECKS PASSED!")
        print("=" * 80)
        return True


if __name__ == "__main__":
    success = check_schema_compliance()
    sys.exit(0 if success else 1)
