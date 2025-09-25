#!/usr/bin/env python3
"""
Script to update XSL transformations to use unified "arguments" instead of left/right/operands patterns.
"""

import re
from pathlib import Path

def update_xsl_file(file_path):
    """Update a single XSL file"""
    print(f"\nProcessing: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    changes = 0

    # Update comparison conditions: left/right -> arguments[0]/arguments[1]
    patterns = [
        # left variable selection
        (r'<xsl:variable name="left" select="\$comparison/fn:array\[@key=\'left\'\].*?"/>',
         '<xsl:variable name="left" select="$comparison/fn:array[@key=\'arguments\']/fn:array[1] | $comparison/fn:array[@key=\'arguments\']/fn:map[1]"/>'),

        # right variable selection
        (r'<xsl:variable name="right" select="\$comparison/fn:array\[@key=\'right\'\].*?"/>',
         '<xsl:variable name="right" select="$comparison/fn:array[@key=\'arguments\']/fn:array[2] | $comparison/fn:array[@key=\'arguments\']/fn:map[2]"/>'),

        # operands variable selection
        (r'<xsl:variable name="operands" select="\$([^/]+)/fn:array\[@key=\'operands\'\]"/>',
         r'<xsl:variable name="operands" select="$\1/fn:array[@key=\'arguments\']"/>'),
    ]

    for old_pattern, new_pattern in patterns:
        old_matches = len(re.findall(old_pattern, content))
        content = re.sub(old_pattern, new_pattern, content)
        new_matches = old_matches - len(re.findall(old_pattern, content))
        if new_matches > 0:
            changes += new_matches
            print(f"  Updated {new_matches} instances of pattern: {old_pattern[:50]}...")

    # Update relation processing for a/b -> arguments[0]/arguments[1]
    relation_patterns = [
        # a field access
        (r'\$role-a\b', '$role-a'),  # Keep variable name for now
        (r'fn:map\[@key=\'a\'\]', "fn:array[@key='arguments']/fn:map[1]"),

        # b field access
        (r'\$role-b\b', '$role-b'),  # Keep variable name for now
        (r'fn:map\[@key=\'b\'\]', "fn:array[@key='arguments']/fn:map[2]"),
    ]

    for old_pattern, new_pattern in relation_patterns:
        old_matches = len(re.findall(old_pattern, content))
        content = re.sub(old_pattern, new_pattern, content)
        new_matches = old_matches - len(re.findall(old_pattern, content))
        if new_matches > 0:
            changes += new_matches
            print(f"  Updated {new_matches} instances of relation pattern: {old_pattern}")

    # Check if any changes were made
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ Updated {file_path} with {changes} changes")
    else:
        print(f"ℹ️  No changes needed for {file_path}")

def main():
    """Main function"""
    xsl_files = [
        "transformations/regelspraak.xsl",
        "transformations/gegevensspraak.xsl"
    ]

    print("🔄 Starting XSL transformation updates...")

    for file_path in xsl_files:
        full_path = Path(file_path)
        if full_path.exists():
            update_xsl_file(full_path)
        else:
            print(f"❌ File not found: {file_path}")

    print("\n🎉 XSL transformation updates completed!")
    print("\nNext steps:")
    print("1. Update viewer.html")
    print("2. Test transformation output")
    print("3. Validate schema")

if __name__ == "__main__":
    main()