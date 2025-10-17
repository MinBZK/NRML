# PyCharm Setup for Running Tests

## Quick Start

1. **Restart PyCharm** if you just added the run configurations
2. Look for the **run configuration dropdown** in the top-right toolbar
3. You should see:
   - `pytest: All Blockly Tests`
   - `pytest: Integration Test`
4. Select one and click the green play button ▶️

## If Run Configurations Don't Appear

### Step 1: Set pytest as Default Test Runner

1. Open PyCharm Settings:
   - Windows/Linux: `File` → `Settings` (or press `Ctrl+Alt+S`)
   - Mac: `PyCharm` → `Preferences` (or press `Cmd+,`)

2. Navigate to: `Tools` → `Python Integrated Tools`

3. Find the **Testing** section

4. Change **Default test runner** dropdown from `Unittests` to `pytest`

5. Click `Apply` and `OK`

### Step 2: Mark Directory as Sources Root

1. In the Project view (left panel), navigate to `blockly/`
2. Right-click on the `blockly` folder
3. Select `Mark Directory as` → `Sources Root`
4. The folder icon should turn blue/highlighted

### Step 3: Run Tests

After completing Steps 1 and 2, try one of these methods:

**Method A: Right-click on test file**
1. Navigate to `blockly/tests/test_conversion.py`
2. Right-click on the file
3. Select `Run 'pytest in test_conversion.py'`

**Method B: Right-click on test function**
1. Open `blockly/tests/test_conversion.py`
2. Find any test function (e.g., `test_basic_conversion_structure`)
3. Right-click on the function name
4. Select `Run 'pytest for test_basic_conversion_structure'`

**Method C: Use gutter icons**
1. Open `blockly/tests/test_conversion.py`
2. Look for green play button icons ▶️ in the left margin (gutter) next to test functions
3. Click the icon to run that specific test

**Method D: Create manual run configuration**
1. Click `Run` → `Edit Configurations...`
2. Click `+` (top-left) → `Python tests` → `pytest`
3. Fill in:
   - **Name**: `All Blockly Tests`
   - **Target**: Select `Script path` radio button
   - **Script path**: Click folder icon and navigate to `blockly/tests/test_conversion.py`
   - **Working directory**: Should auto-fill, if not: `C:\Users\timde\Documents\Code\NRML\blockly`
   - **Python interpreter**: Use project default (should be `.venv`)
4. Click `OK`
5. Select your configuration from dropdown and click play ▶️

## Troubleshooting

### Error: "No module named pytest"

**Solution**: Install pytest in your virtual environment:
```bash
cd C:\Users\timde\Documents\Code\NRML
.venv\Scripts\python.exe -m pip install pytest
```

Or in PyCharm Terminal:
```bash
pip install pytest
```

### Error: "No tests were found"

**Solution**: Make sure working directory is set to `blockly/`:
1. Edit your run configuration (`Run` → `Edit Configurations...`)
2. Check **Working directory** is set to: `C:\Users\timde\Documents\Code\NRML\blockly`
3. Apply and run again

### Error: "ModuleNotFoundError: No module named 'converter'"

**Solution**: Working directory is wrong. Should be `blockly/` not `blockly/tests/`:
1. Edit run configuration
2. Set **Working directory** to `C:\Users\timde\Documents\Code\NRML\blockly`

### Tests still won't run

**Nuclear option**:
1. Close PyCharm
2. Delete `.idea/` folder in project root
3. Reopen project in PyCharm
4. Follow Steps 1-3 above again

## Expected Output

When tests run successfully, you should see:

```
============================= test session starts =============================
platform win32 -- Python 3.13.7, pytest-8.4.2, pluggy-1.6.0
collecting ... collected 9 items

tests/test_conversion.py::test_basic_conversion_structure PASSED         [ 11%]
tests/test_conversion.py::test_basic_conversion_constants_fact PASSED    [ 22%]
tests/test_conversion.py::test_basic_conversion_calculation_fact PASSED  [ 33%]
tests/test_conversion.py::test_basic_conversion_references PASSED        [ 44%]
tests/test_conversion.py::test_basic_conversion_precision PASSED         [ 55%]
tests/test_conversion.py::test_basic_conversion_values PASSED            [ 66%]
tests/test_conversion.py::test_conversion_statistics PASSED              [ 77%]
tests/test_conversion.py::test_target_paths_match_items PASSED           [ 88%]
tests/test_conversion_matches_expected_output PASSED                     [100%]

============================== 9 passed in 0.01s ==========================
```

All tests should show **PASSED** in green ✅

## Command Line Alternative

If PyCharm is giving you trouble, you can always run tests from the command line:

```bash
cd C:\Users\timde\Documents\Code\NRML\blockly
python -m pytest tests/test_conversion.py -v
```

This always works and doesn't depend on IDE configuration.
