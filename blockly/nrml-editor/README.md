# Standard Blockly Editor

A clean, standard Blockly editor with JSON import/export functionality.

## Features

- **Standard Blockly Blocks**: All standard categories (Logic, Loops, Math, Text, Lists, Variables, Functions)
- **Live JSON Preview**: Real-time display of workspace JSON structure
- **Import/Export**: Import and export Blockly workspace JSON
- **No Custom Blocks**: Pure standard Blockly implementation

## Usage

### Opening the Editor

Simply open `index.html` in your web browser:

```bash
# Windows
start index.html

# Mac/Linux
open index.html
```

Or use a local server:

```bash
# Python
python -m http.server 8000

# Node.js (if you have http-server)
npx http-server
```

Then navigate to http://localhost:8000

### Features

#### JSON Preview Panel
- Right side panel shows live JSON representation of workspace
- Updates automatically as you build with blocks
- Copy button to quickly copy JSON to clipboard

#### Export Workspace
Click **Export JSON** to download the current workspace as a JSON file.

#### Import Workspace
Click **Import JSON** to load a previously saved workspace JSON file.

#### Clear Workspace
Click **Clear** to remove all blocks from the workspace.

### Example Workflow

1. Drag blocks from the toolbox to build your logic
2. Watch the JSON update in real-time on the right panel
3. Export the JSON when you're satisfied
4. Use the exported JSON with conversion scripts:
   ```bash
   node scripts/standard-blockly-to-nrml.js workspace.json output.nrml.json
   ```

## Standard Blocks Available

### Logic
- If/Else statements
- Comparisons (=, ≠, <, >, ≤, ≥)
- Boolean operations (and, or)
- Boolean values (true, false)
- Null value
- Ternary operator

### Loops
- Repeat n times
- While/Until loops
- For loops
- For each loops
- Break/Continue statements

### Math
- Numbers
- Arithmetic operations (+, −, ×, ÷)
- Functions (square root, absolute, etc.)
- Trigonometry
- Constants (π, e, φ, etc.)
- Rounding, modulo, random numbers

### Text
- Text strings
- Text concatenation
- String length, empty check
- Find substring
- Extract characters
- Case conversion
- Print text

### Lists
- Create lists
- List operations (length, empty, indexOf)
- Get/set list items
- Split/join strings
- Sort lists

### Variables
- Create and use variables
- Set variable values
- Get variable values

### Functions
- Define custom functions
- Call functions
- Return values
- Function parameters

## JSON Format

The workspace JSON follows Blockly's standard serialization format:

```json
{
  "blocks": {
    "languageVersion": 0,
    "blocks": [
      {
        "type": "block_type",
        "id": "block_id",
        "x": 100,
        "y": 100,
        "fields": {},
        "inputs": {},
        "next": {}
      }
    ]
  },
  "variables": []
}
```

## Converting to NRML

After creating your workspace, use the conversion script:

```bash
node scripts/standard-blockly-to-nrml.js workspace.json output.nrml.json
```

This will convert standard Blockly blocks (variables, math, etc.) into proper NRML structure with facts, items, and versions.
