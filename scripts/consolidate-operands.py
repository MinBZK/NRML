#!/usr/bin/env python3
"""
Script to consolidate all operand patterns in NRML JSON files to use unified "arguments" array.

Converts:
- left/right -> arguments[0]/arguments[1]
- a/b -> arguments[0]/arguments[1]
- from/to -> arguments[0]/arguments[1]
- operands -> arguments
"""

import json
import sys
from pathlib import Path

def convert_comparison_condition(obj):
    """Convert comparison condition from left/right to arguments"""
    if obj.get("type") == "comparison" and ("left" in obj or "right" in obj):
        left = obj.pop("left", None)
        right = obj.pop("right", None)
        obj["arguments"] = [left, right]
        print(f"  Converted comparison condition: left/right -> arguments")
    return obj

def convert_relation_definition(obj):
    """Convert relation definition from a/b to arguments"""
    if "a" in obj and "b" in obj and "validFrom" in obj:
        a = obj.pop("a")
        b = obj.pop("b")
        obj["arguments"] = [a, b]
        print(f"  Converted relation definition: a/b -> arguments")
    return obj

def convert_function_expression(obj):
    """Convert function expressions from from/to to arguments"""
    if obj.get("type") == "function" and obj.get("function") == "timeDuration":
        if "from" in obj and "to" in obj:
            from_val = obj.pop("from")
            to_val = obj.pop("to")
            obj["arguments"] = [from_val, to_val]
            print(f"  Converted timeDuration function: from/to -> arguments")
    return obj

def convert_arithmetic_expression(obj):
    """Convert arithmetic expressions from left/right or operands to arguments"""
    if obj.get("type") == "arithmetic":
        # Handle left/right pattern
        if "left" in obj and "right" in obj:
            left = obj.pop("left")
            right = obj.pop("right")
            obj["arguments"] = [left, right]
            print(f"  Converted arithmetic expression: left/right -> arguments")
        # Handle operands pattern
        elif "operands" in obj:
            operands = obj.pop("operands")
            obj["arguments"] = operands
            print(f"  Converted arithmetic expression: operands -> arguments")
    return obj

def convert_logical_expression(obj):
    """Convert logical expressions from operands to arguments"""
    if obj.get("type") == "logical" and "operands" in obj:
        operands = obj.pop("operands")
        obj["arguments"] = operands
        print(f"  Converted logical expression: operands -> arguments")
    return obj

def process_object(obj, path="root"):
    """Recursively process JSON object to convert operand patterns"""
    if isinstance(obj, dict):
        # Apply conversions
        obj = convert_comparison_condition(obj)
        obj = convert_relation_definition(obj)
        obj = convert_function_expression(obj)
        obj = convert_arithmetic_expression(obj)
        obj = convert_logical_expression(obj)

        # Recursively process nested objects
        for key, value in obj.items():
            obj[key] = process_object(value, f"{path}.{key}")
    elif isinstance(obj, list):
        # Process list elements
        for i, item in enumerate(obj):
            obj[i] = process_object(item, f"{path}[{i}]")

    return obj

def convert_file(file_path):
    """Convert a single NRML JSON file"""
    print(f"\nProcessing: {file_path}")

    # Read file
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Convert
    data = process_object(data)

    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"✅ Completed: {file_path}")

def main():
    """Main function"""
    files_to_convert = [
        "rules/toka.nrml.json",
        "rules/kinderbijslag.nrml.json"
    ]

    print("🔄 Starting operand consolidation...")

    for file_path in files_to_convert:
        full_path = Path(file_path)
        if full_path.exists():
            convert_file(full_path)
        else:
            print(f"❌ File not found: {file_path}")

    print("\n🎉 Operand consolidation completed!")
    print("\nNext steps:")
    print("1. Update XSL transformations")
    print("2. Update viewer.html")
    print("3. Test transformation output")
    print("4. Validate schema")

if __name__ == "__main__":
    main()