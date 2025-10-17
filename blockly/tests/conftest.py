"""
Pytest configuration and shared fixtures
"""

import sys
from pathlib import Path

# Add nrml-conversion to Python path
nrml_conversion_path = Path(__file__).parent.parent / "nrml-conversion"
if str(nrml_conversion_path) not in sys.path:
    sys.path.insert(0, str(nrml_conversion_path))
