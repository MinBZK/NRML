#!/usr/bin/env python3
"""
Blockly to NRML Converter

Command-line tool to convert standard Blockly JSON to NRML format.

Usage:
    python convert.py input.json output.json
    python convert.py input.json  # Output to stdout
"""

import sys
import json
import argparse
from pathlib import Path
from converter import BlocklyToNRMLConverter


def main():
    parser = argparse.ArgumentParser(
        description='Convert standard Blockly JSON to NRML format'
    )
    parser.add_argument(
        'input',
        type=str,
        help='Input Blockly JSON file'
    )
    parser.add_argument(
        'output',
        type=str,
        nargs='?',
        help='Output NRML JSON file (optional, defaults to stdout)'
    )
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Show conversion statistics'
    )
    parser.add_argument(
        '--indent',
        type=int,
        default=2,
        help='JSON indentation (default: 2)'
    )

    args = parser.parse_args()

    # Read input file
    try:
        input_path = Path(args.input)
        with open(input_path, 'r', encoding='utf-8') as f:
            blockly_json = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file '{args.input}' not found", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in input file: {e}", file=sys.stderr)
        sys.exit(1)

    # Convert
    converter = BlocklyToNRMLConverter()

    try:
        nrml_json = converter.convert(blockly_json)
    except Exception as e:
        print(f"Error during conversion: {e}", file=sys.stderr)
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)

    # Format output
    output_json = json.dumps(nrml_json, indent=args.indent, ensure_ascii=False)

    # Write output
    if args.output:
        try:
            output_path = Path(args.output)
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(output_json)

            if args.verbose:
                stats = converter.get_statistics()
                print(f"✓ Conversion complete", file=sys.stderr)
                print(f"  Facts: {stats['facts']}", file=sys.stderr)
                print(f"  Items: {stats['items']}", file=sys.stderr)
                print(f"  Versions: {stats['versions']}", file=sys.stderr)
                print(f"  Variables: {stats['variables']}", file=sys.stderr)
                print(f"✓ Written to {args.output}", file=sys.stderr)

        except IOError as e:
            print(f"Error writing output file: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        # Output to stdout
        print(output_json)

        if args.verbose:
            stats = converter.get_statistics()
            print(f"\n✓ Conversion complete", file=sys.stderr)
            print(f"  Facts: {stats['facts']}", file=sys.stderr)
            print(f"  Items: {stats['items']}", file=sys.stderr)
            print(f"  Versions: {stats['versions']}", file=sys.stderr)
            print(f"  Variables: {stats['variables']}", file=sys.stderr)


if __name__ == '__main__':
    main()
