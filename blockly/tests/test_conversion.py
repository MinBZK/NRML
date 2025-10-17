"""
Pytest tests for Blockly to NRML conversion
"""

import json
import sys
from pathlib import Path

import pytest

# Add nrml-conversion to path
sys.path.insert(0, str(Path(__file__).parent.parent / "nrml-conversion"))

from converter import BlocklyToNRMLConverter


def normalize_uuids(data, uuid_map=None):
    """
    Replace all UUIDs in a JSON structure with deterministic placeholders.

    Args:
        data: JSON data (dict, list, or primitive)
        uuid_map: Dictionary mapping original UUIDs to normalized ones

    Returns:
        Normalized JSON with UUIDs replaced by fact-uuid-N or item-uuid-N
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


@pytest.fixture
def converter():
    """Create a converter instance"""
    return BlocklyToNRMLConverter()


@pytest.fixture
def fixtures_dir():
    """Get fixtures directory path"""
    return Path(__file__).parent / "fixtures"


@pytest.fixture
def test_input_basic(fixtures_dir):
    """Load basic test input"""
    with open(fixtures_dir / "test_input_basic.json", "r", encoding="utf-8") as f:
        return json.load(f)


@pytest.fixture
def test_input_aggregation(fixtures_dir):
    """Load aggregation test input"""
    with open(fixtures_dir / "test_input_aggregation.json", "r", encoding="utf-8") as f:
        return json.load(f)


def test_basic_conversion_structure(converter, test_input_basic):
    """Test that basic conversion produces valid NRML structure"""
    result = converter.convert(test_input_basic)

    # Check top-level structure
    assert "$schema" in result
    assert "version" in result
    assert "language" in result
    assert "facts" in result

    # Check schema and version
    assert result["$schema"] == "https://example.com/nrml-facts-schema.json"
    assert result["version"] == "1.0"
    assert result["language"] == "nl"

    # Check facts exist
    facts = result["facts"]
    assert len(facts) == 2, "Should have 2 facts (Constants and Calculation)"


def test_basic_conversion_constants_fact(converter, test_input_basic):
    """Test that Constants fact is generated correctly"""
    result = converter.convert(test_input_basic)
    facts = result["facts"]

    # Find Constants fact
    constants_fact = None
    for fact_uuid, fact in facts.items():
        if fact.get("name", {}).get("nl") == "Constants":
            constants_fact = fact
            break

    assert constants_fact is not None, "Constants fact should exist"

    # Check items - now we have 4 items (2 type defs + 2 value inits)
    items = constants_fact["items"]
    assert len(items) == 4, "Should have 4 constant items (2 type defs + 2 value inits)"

    # Separate type definition items from value initialization items
    type_def_items = []
    value_init_items = []

    for item in items.values():
        versions = item["versions"]
        assert len(versions) == 1, "Each item should have 1 version (split structure)"

        version = versions[0]
        if "type" in version:
            type_def_items.append(item)
        elif "target" in version and "value" in version:
            value_init_items.append(item)

    assert len(type_def_items) == 2, "Should have 2 type definition items"
    assert len(value_init_items) == 2, "Should have 2 value initialization items"

    # Check that we can identify items by their values
    values_found = []
    for item in value_init_items:
        version = item["versions"][0]
        if "value" in version and "value" in version["value"]:
            values_found.append(version["value"]["value"])

    assert 0.21 in values_found, "Should have km_vergoeding with value 0.21"
    assert 12 in values_found, "Should have afstand with value 12"

    # Check type definitions are correct
    for item in type_def_items:
        version = item["versions"][0]
        assert "type" in version
        assert version["type"] == "numeric"
        assert "validFrom" in version

    # Check value initializations are correct
    for item in value_init_items:
        version = item["versions"][0]
        assert "target" in version
        assert "value" in version
        assert "validFrom" in version


def test_basic_conversion_calculation_fact(converter, test_input_basic):
    """Test that Calculation fact is generated correctly"""
    result = converter.convert(test_input_basic)
    facts = result["facts"]

    # Find Calculation fact
    calc_fact = None
    for fact_uuid, fact in facts.items():
        if fact.get("name", {}).get("nl") == "Calculation":
            calc_fact = fact
            break

    assert calc_fact is not None, "Calculation fact should exist"

    # Check items
    items = calc_fact["items"]
    assert len(items) == 1, "Should have 1 calculated item"

    # Get the item
    item = list(items.values())[0]

    # Check has 1 version (calculated value)
    versions = item["versions"]
    assert len(versions) == 1

    # Check calculated value structure
    calc_version = versions[0]
    assert "target" in calc_version
    assert "expression" in calc_version
    assert "validFrom" in calc_version

    # Check expression
    expr = calc_version["expression"]
    assert expr["type"] == "arithmetic"
    assert expr["operator"] == "multiply"
    assert len(expr["arguments"]) == 2


def test_basic_conversion_references(converter, test_input_basic):
    """Test that references use full paths with UUIDs"""
    result = converter.convert(test_input_basic)
    facts = result["facts"]

    # Get calculation fact
    calc_fact = None
    for fact_uuid, fact in facts.items():
        if fact.get("name", {}).get("nl") == "Calculation":
            calc_fact = fact
            break

    assert calc_fact is not None

    # Get calculated item
    item = list(calc_fact["items"].values())[0]
    expr = item["versions"][0]["expression"]

    # Check that arguments contain references
    for arg in expr["arguments"]:
        assert isinstance(arg, list), "Arguments should be arrays"
        assert len(arg) == 1, "Reference array should have one element"
        assert "$ref" in arg[0], "Should contain $ref"

        # Check reference format
        ref = arg[0]["$ref"]
        assert ref.startswith("#/facts/"), "Reference should start with #/facts/"
        assert "/items/" in ref, "Reference should contain /items/"


def test_basic_conversion_precision(converter, test_input_basic):
    """Test that numeric precision is correctly detected"""
    result = converter.convert(test_input_basic)
    facts = result["facts"]

    # Find Constants fact
    constants_fact = None
    for fact_uuid, fact in facts.items():
        if fact.get("name", {}).get("nl") == "Constants":
            constants_fact = fact
            break

    items = constants_fact["items"]

    # Build a map from item target references to their type definitions
    # First, find type definitions and their references
    type_defs = {}  # Maps item reference to type definition
    for item in items.values():
        version = item["versions"][0]
        if "type" in version:
            # This is a type definition - we'll need to match it to values later
            # Store for now indexed by position
            pass

    # Find value items and their corresponding type precision
    # In the new structure, we need to match values with their type definitions
    # by checking which type def they reference
    for item in items.values():
        version = item["versions"][0]
        if "value" in version and "value" in version["value"]:
            value = version["value"]["value"]
            # The target should reference the type definition item
            if "target" in version and len(version["target"]) > 0:
                ref_path = version["target"][0]["$ref"]
                # Extract the item UUID from the reference
                # Format: #/facts/{fact_uuid}/items/{item_uuid}
                parts = ref_path.split("/")
                if len(parts) >= 5:
                    type_item_uuid = parts[4]
                    # Find the type definition for this UUID
                    if type_item_uuid in items:
                        type_def = items[type_item_uuid]["versions"][0]

                        # Check precision based on value
                        if value == 0.21:
                            assert type_def.get("precision") == 2, "0.21 should have precision 2"
                        elif value == 12:
                            # precision field may be omitted for integers (0 precision)
                            assert type_def.get("precision", 0) == 0, "12 should have precision 0 (or omitted)"


def test_basic_conversion_values(converter, test_input_basic):
    """Test that values are correctly stored"""
    result = converter.convert(test_input_basic)
    facts = result["facts"]

    # Find Constants fact
    constants_fact = None
    for fact_uuid, fact in facts.items():
        if fact.get("name", {}).get("nl") == "Constants":
            constants_fact = fact
            break

    items = constants_fact["items"]

    # Collect all values from value initialization items
    values_found = []
    for item in items.values():
        version = item["versions"][0]
        if "value" in version and "value" in version["value"]:
            values_found.append(version["value"]["value"])

    # Check that expected values are present
    assert 0.21 in values_found, "Should have value 0.21"
    assert 12 in values_found, "Should have value 12"
    assert len(values_found) == 2, "Should have exactly 2 values"


def test_conversion_statistics(converter, test_input_basic):
    """Test that statistics are correctly generated"""
    converter.convert(test_input_basic)
    stats = converter.get_statistics()

    assert stats["facts"] == 2
    assert stats["items"] == 5  # 2 constants * 2 items each + 1 calculation
    assert stats["versions"] == 5  # 4 constant items * 1 version + 1 calculation * 1 version
    assert stats["variables"] == 5  # Now counts type def + value items separately


def test_target_paths_match_items(converter, test_input_basic):
    """Test that target paths correctly reference appropriate items"""
    result = converter.convert(test_input_basic)
    facts = result["facts"]

    # For each fact, check target references
    for fact_uuid, fact in facts.items():
        fact_name = fact.get("name", {}).get("nl", "")

        # Separate type def items and items with targets
        type_def_items = {}
        items_with_targets = {}

        for item_uuid, item in fact["items"].items():
            version = item["versions"][0]
            if "type" in version:
                type_def_items[item_uuid] = item
            if "target" in version:
                items_with_targets[item_uuid] = item

        # For Constants fact: value init items should reference type def items
        # For Calculation fact: items self-reference
        for item_uuid, item in items_with_targets.items():
            version = item["versions"][0]
            if "target" in version:
                actual_path = version["target"][0]["$ref"]
                # Extract referenced item UUID
                parts = actual_path.split("/")
                if len(parts) >= 5:
                    referenced_item_uuid = parts[4]

                    if fact_name == "Constants":
                        # Value init items should reference type def items
                        assert referenced_item_uuid in type_def_items, \
                            f"Value init item {item_uuid} should reference a type def item, but references {referenced_item_uuid}"
                    elif fact_name == "Calculation":
                        # Calculation items self-reference
                        assert referenced_item_uuid == item_uuid, \
                            f"Calculation item {item_uuid} should self-reference, but references {referenced_item_uuid}"


def test_basic_conversion_matches_expected_output(converter, test_input_basic, fixtures_dir):
    """Test that conversion output matches expected JSON structure"""
    # Load expected output
    with open(fixtures_dir / "expected_output_basic.json", "r", encoding="utf-8") as f:
        expected = json.load(f)

    # Convert input
    actual = converter.convert(test_input_basic)

    # Normalize UUIDs in both for comparison
    normalized_expected = normalize_uuids(expected)
    normalized_actual = normalize_uuids(actual)

    # Compare
    assert normalized_actual == normalized_expected, \
        f"Actual output does not match expected.\n\nExpected:\n{json.dumps(normalized_expected, indent=2)}\n\nActual:\n{json.dumps(normalized_actual, indent=2)}"


def test_aggregation_has_inputs_section(converter, test_input_aggregation):
    """Test that aggregation conversion generates inputs section"""
    result = converter.convert(test_input_aggregation)

    assert "inputs" in result, "Should have inputs section"
    assert "kinderen" in result["inputs"], "Should have kinderen input"
    assert "aanvrager" in result["inputs"], "Should have aanvrager input"


def test_aggregation_has_outputs_section(converter, test_input_aggregation):
    """Test that aggregation conversion generates outputs section"""
    result = converter.convert(test_input_aggregation)

    assert "outputs" in result, "Should have outputs section"
    assert "young_children_count" in result["outputs"], "Should have young_children_count output"


def test_aggregation_has_includes_section(converter, test_input_aggregation):
    """Test that aggregation conversion generates includes section"""
    result = converter.convert(test_input_aggregation)

    assert "includes" in result, "Should have includes section"
    assert len(result["includes"]) > 0, "Should have at least one include"

    include = result["includes"][0]
    assert "law" in include, "Include should have law field"
    assert "output" in include, "Include should have output field"
    assert "target" in include, "Include should have target field"


def test_aggregation_generates_expression(converter, test_input_aggregation):
    """Test that aggregation generates proper aggregation expression"""
    result = converter.convert(test_input_aggregation)
    facts = result["facts"]

    # Find calculated fact
    calc_fact = None
    for fact_uuid, fact in facts.items():
        if fact.get("name", {}).get("nl") == "berekend":
            calc_fact = fact
            break

    assert calc_fact is not None, "Should have calculated fact"

    # Get aggregation item
    items = calc_fact["items"]
    assert len(items) > 0, "Should have at least one calculated item"

    item = list(items.values())[0]
    version = item["versions"][0]

    assert "expression" in version, "Should have expression"
    expr = version["expression"]

    assert expr["type"] == "aggregation", "Should be aggregation type"
    assert expr["function"] == "count", "Should be count function"
    assert "condition" in expr, "Should have filter condition"


def test_aggregation_condition_structure(converter, test_input_aggregation):
    """Test that aggregation condition is properly structured"""
    result = converter.convert(test_input_aggregation)
    facts = result["facts"]

    # Find calculated fact and extract condition
    calc_fact = None
    for fact_uuid, fact in facts.items():
        if fact.get("name", {}).get("nl") == "berekend":
            calc_fact = fact
            break

    item = list(calc_fact["items"].values())[0]
    version = item["versions"][0]
    condition = version["expression"]["condition"]

    assert condition["type"] == "comparison", "Condition should be comparison"
    assert condition["operator"] == "lessThanOrEqual", "Should use lessThanOrEqual operator"
    assert len(condition["arguments"]) == 2, "Should have two arguments"
