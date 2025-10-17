# NRML Blockly Demo Guide

## Quick Start

1. **Open the demo:**
   ```bash
   # Open demo.html in your browser
   open blockly/custom_blocks/demo.html
   ```

2. **Try the examples:**
   - Click **📥 Simple Example** - Loads a basic aggregation example
   - Click **📚 Full Example** - Loads all kinderbijslag rules (43 blocks!)

3. **Import your own:**
   - Click **📂 Import JSON** - Upload any Blockly JSON file
   - Example: Load `blockly/tests/fixtures/kinderbijslag_blockly.json`

## Button Reference

| Button | Function | Description |
|--------|----------|-------------|
| 📥 Simple Example | `loadExample()` | Loads basic count aggregation demo |
| 📚 Full Example | `loadKinderbijslagExample()` | Loads complete kinderbijslag rules |
| 📂 Import JSON | `loadJSONFile()` | Upload and load Blockly JSON file |
| ⚙️ Generate Code | `showCode()` | Show executable JavaScript code |
| 📄 Show JSON | `showJSON()` | Show Blockly JSON structure |
| 💾 Export JSON | `exportJSON()` | Download workspace as JSON file |
| 🔄 To NRML | `toNRML()` | Convert to NRML format |
| 🗑️ Clear | `clearWorkspace()` | Clear all blocks |

## Import Formats

### Blockly JSON Format

The demo accepts JSON files in this format:

```json
{
  "blocks": {
    "languageVersion": 0,
    "blocks": [...]
  },
  "variables": [
    {
      "id": "var-id",
      "name": "variable_name",
      "type": "type"
    }
  ],
  "metadata": {
    "description": "Description of rules"
  }
}
```

### What Gets Imported

✅ **Imported:**
- All blocks and connections
- Block fields (numbers, text, dropdowns)
- Variable definitions
- Extra state (NRML references, metadata)
- Block positions

❌ **Not Imported:**
- Comments (not yet supported)
- Disabled blocks (not yet supported)
- Collapsed state (resets to expanded)

## Examples to Try

### 1. Simple Count Example (Built-in)

Click **📥 Simple Example** to load:

```
set aantal_jongere_kinderen to
  count items in kinderen
    where leeftijd <= 10
```

**Shows:**
- `variables_set` - Variable assignment
- `aggregation_count` - Custom aggregation block
- `logic_compare` - Comparison operator
- `property_access_direct` - Property reference

### 2. Full Kinderbijslag Example (From File)

Click **📚 Full Example** to load all 8 rules:

1. ✅ Bedrag per jong kind (€250.50)
2. ✅ Bedrag per oud kind (€300.75)
3. ✅ Aantal jongere kinderen (count with filter)
4. ✅ Aantal oudere kinderen (count with allOf)
5. ✅ Totaal kinderbijslag bedrag (nested arithmetic)
6. ✅ Brief versturen (conditional boolean)
7. ✅ Aantal kinderen (count with default)
8. ✅ Risico alarm (conditional boolean)

**Total:** 43 blocks, 10 variables

### 3. Import Your Own File

1. Click **📂 Import JSON**
2. Select `blockly/tests/fixtures/kinderbijslag_blockly.json`
3. Blocks load automatically

Or create your own:
1. Build blocks in the demo
2. Click **💾 Export JSON**
3. Save the file
4. Later, click **📂 Import JSON** to reload

## Troubleshooting

### Problem: "Full Example" button shows error

**Solution:** The demo is trying to fetch from relative path. Either:

1. **Option A - Use import instead:**
   - Click **📂 Import JSON**
   - Navigate to `blockly/tests/fixtures/kinderbijslag_blockly.json`

2. **Option B - Serve via web server:**
   ```bash
   # From blockly/custom_blocks/ directory
   python3 -m http.server 8000
   # Open http://localhost:8000/demo.html
   ```

### Problem: Custom blocks not showing

**Symptom:** Blocks show as "Unknown" or grey

**Solution:** Make sure `nrml_blocks.js` is loaded:
1. Check browser console for errors
2. Verify `nrml_blocks.js` is in same directory as `demo.html`
3. Check that `<script src="nrml_blocks.js">` loads before workspace init

### Problem: Variables not loading correctly

**Symptom:** Variables show as red/undefined

**Solution:** The JSON must include variable definitions:
```json
{
  "variables": [
    {"id": "var-x", "name": "x", "type": ""}
  ]
}
```

If variables are missing, they'll be created with default names.

### Problem: ExtraState lost on reload

**Symptom:** NRML references disappear after save/load

**Solution:** Make sure you're using `Blockly.serialization.workspaces.save()` not XML export:

```javascript
// ✅ CORRECT - Preserves extraState
const json = Blockly.serialization.workspaces.save(workspace);

// ❌ WRONG - Loses extraState
const xml = Blockly.Xml.workspaceToDom(workspace);
```

## Advanced Features

### Auto-Save

The demo automatically saves your workspace to browser localStorage:

- Saves on every change
- Persists across page refreshes
- Cleared when you use "Clear" button

To disable auto-save, comment out this code:
```javascript
// workspace.addChangeListener(function(event) { ... });
```

### Console Logging

Open browser console (F12) to see detailed logs:

```javascript
✅ NRML Blockly Demo loaded!
Custom blocks registered: ['aggregation_count', ...]
✅ Loaded Blockly JSON: {blocks: {...}, variables: [...]}
```

### Keyboard Shortcuts

- **Ctrl+C / Cmd+C** - Copy selected block
- **Ctrl+V / Cmd+V** - Paste copied block
- **Delete / Backspace** - Delete selected block
- **Ctrl+Z / Cmd+Z** - Undo
- **Ctrl+Shift+Z / Cmd+Shift+Z** - Redo

## JSON Structure Examples

### Minimal Import

```json
{
  "blocks": {
    "languageVersion": 0,
    "blocks": [
      {
        "type": "variables_set",
        "id": "block-1",
        "fields": {
          "VAR": {"id": "var-x"}
        },
        "inputs": {
          "VALUE": {
            "block": {
              "type": "math_number",
              "id": "block-2",
              "fields": {"NUM": 42}
            }
          }
        }
      }
    ]
  },
  "variables": [
    {"id": "var-x", "name": "x", "type": ""}
  ]
}
```

### With Custom Block

```json
{
  "blocks": {
    "languageVersion": 0,
    "blocks": [
      {
        "type": "aggregation_count",
        "id": "block-1",
        "extraState": {
          "aggregationType": "count",
          "nrmlRef": "#/facts/.../items/...",
          "expressionChain": [
            {"$ref": "#/facts/.../items/..."}
          ],
          "default": {"value": 0}
        },
        "inputs": {
          "COLLECTION": {
            "block": {
              "type": "variables_get",
              "id": "block-2",
              "fields": {"VAR": {"id": "var-list"}}
            }
          }
        }
      }
    ]
  },
  "variables": [
    {"id": "var-list", "name": "items", "type": ""}
  ]
}
```

## Export Workflow

### 1. Build Rules Visually

1. Drag blocks from toolbox
2. Connect them together
3. Set values and variables

### 2. Test & Validate

1. Click **⚙️ Generate Code** - Check JavaScript output
2. Click **📄 Show JSON** - Verify structure
3. Click **🔄 To NRML** - Convert to NRML format

### 3. Export

1. Click **💾 Export JSON** - Download Blockly format
2. Or copy JSON from **📄 Show JSON** output

### 4. Use in Code

```javascript
// Load your exported JSON
const response = await fetch('my_rules.json');
const blocklyData = await response.json();

// Convert to NRML for execution
const nrml = blocklyToNRML(blocklyData);

// Execute rules
executeNRML(nrml, inputData);
```

## Performance Notes

| Workspace Size | Load Time | Edit Performance |
|----------------|-----------|------------------|
| < 50 blocks | Instant | Smooth |
| 50-100 blocks | < 1 second | Smooth |
| 100-500 blocks | 1-2 seconds | Good |
| 500+ blocks | 2-5 seconds | May need optimization |

**Tips for large workspaces:**
- Use procedures/functions to break down large rule sets
- Collapse unused blocks
- Use workspace search to find blocks
- Consider splitting into multiple files

## Browser Compatibility

| Browser | Supported | Notes |
|---------|-----------|-------|
| Chrome 90+ | ✅ Yes | Recommended |
| Firefox 88+ | ✅ Yes | Full support |
| Safari 14+ | ✅ Yes | Full support |
| Edge 90+ | ✅ Yes | Full support |
| IE 11 | ❌ No | Not supported |

## Next Steps

After using the demo:

1. **Integrate into your app:**
   - See `example.ts` for TypeScript examples
   - See `BLOCKLY_INTEGRATION_SUMMARY.md` for architecture

2. **Create custom blocks:**
   - Study `nrml_blocks.js` for examples
   - Add to `Blockly.Blocks['your_block']`

3. **Build converters:**
   - Implement `blocklyToNRML()` for your domain
   - Add validation and error handling

## Support

- **Documentation:** `README.md` in this directory
- **Type Definitions:** `nrml_blocks.d.ts` for TypeScript
- **Examples:** `example.ts` for code samples
- **Source:** `nrml_blocks.js` for block definitions

## Common Workflows

### Workflow 1: Edit Existing Rules

```
1. Click 📂 Import JSON
2. Select kinderbijslag_blockly.json
3. Edit blocks visually
4. Click 💾 Export JSON
5. Save as modified version
```

### Workflow 2: Create New Rules

```
1. Click 🗑️ Clear (if needed)
2. Drag blocks from toolbox
3. Connect and configure
4. Click 🔄 To NRML to preview
5. Click 💾 Export JSON to save
```

### Workflow 3: Debug Rules

```
1. Load rules via 📂 Import JSON
2. Click ⚙️ Generate Code
3. Review JavaScript output
4. Fix issues in visual editor
5. Re-generate until correct
```

## Tips & Tricks

### Tip 1: Quick Block Duplication
- Right-click a block → Duplicate
- Or Ctrl+C, Ctrl+V

### Tip 2: Block Cleanup
- Drag blocks to trash can (bottom right)
- Or select and press Delete

### Tip 3: Zoom Navigation
- Scroll wheel to zoom
- Ctrl+Scroll for fine control
- Reset zoom with zoom controls

### Tip 4: Finding Blocks
- Ctrl+F to search (if implemented)
- Or expand workspace and pan around

### Tip 5: Block Comments
- Right-click → Add Comment
- Great for documenting complex logic

## FAQ

**Q: Can I edit the NRML directly?**
A: Yes! Use 🔄 To NRML to see the NRML, copy it, edit in text editor, then convert back.

**Q: Are my changes saved automatically?**
A: Yes, to browser localStorage. Use 💾 Export to save to file.

**Q: Can I undo changes?**
A: Yes, Ctrl+Z / Cmd+Z for undo, Ctrl+Shift+Z for redo.

**Q: How do I share my rules?**
A: Click 💾 Export JSON and share the file. Others can import with 📂 Import JSON.

**Q: Can I use this offline?**
A: Yes, once loaded. Save the HTML and JS files locally.

**Q: How do I add new custom blocks?**
A: Edit `nrml_blocks.js` and add new block definitions. See documentation.
