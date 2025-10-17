"""
Block Analyzer Module

Analyzes Blockly blocks and determines their NRML type mappings.
"""

from enum import Enum
from typing import Dict, List, Optional, Any


class NRMLType(Enum):
    """NRML types that can be generated from Blockly blocks"""
    TYPE_DEFINITION = "type_definition"
    VALUE_INITIALIZATION = "value_initialization"
    CALCULATED_VALUE = "calculated_value"
    CONDITIONAL_VALUE = "conditional_value"
    AGGREGATION = "aggregation"
    INPUT_DECLARATION = "input_declaration"
    OUTPUT_DECLARATION = "output_declaration"
    INCLUDE_REFERENCE = "include_reference"
    UNKNOWN = "unknown"


class BlockAnalyzer:
    """
    Analyzes Blockly blocks to determine their NRML type mappings.

    Main rules:
    - variables_set with math_number → TYPE_DEFINITION + VALUE_INITIALIZATION
    - variables_set with math_arithmetic → CALCULATED_VALUE
    - variables_set with logic → CONDITIONAL_VALUE
    """

    def __init__(self):
        self.block_type_mappings = {
            'variables_set': self._analyze_variable_set,
            'math_number': self._analyze_math_number,
            'math_arithmetic': self._analyze_arithmetic,
            'variables_get': self._analyze_variable_get,
        }

    def analyze_block(self, block: Dict[str, Any]) -> List[NRMLType]:
        """
        Analyze a block and return list of NRML types it generates.

        Args:
            block: Blockly block dictionary

        Returns:
            List of NRMLType enums indicating what NRML structures to create
        """
        block_type = block.get('type')

        if block_type in self.block_type_mappings:
            return self.block_type_mappings[block_type](block)

        return [NRMLType.UNKNOWN]

    def _analyze_variable_set(self, block: Dict[str, Any]) -> List[NRMLType]:
        """
        Analyze a variables_set block.

        Logic:
        - If VALUE input is math_number → TYPE_DEFINITION + VALUE_INITIALIZATION
        - If VALUE input is math_arithmetic → CALCULATED_VALUE
        - If VALUE input is controls_if/logic → CONDITIONAL_VALUE

        Args:
            block: variables_set block

        Returns:
            List of NRML types to generate
        """
        value_block = self._get_input_block(block, 'VALUE')

        if not value_block:
            return [NRMLType.UNKNOWN]

        value_type = value_block.get('type')

        # Simple value assignment → Type definition + Value initialization
        if value_type == 'math_number':
            return [NRMLType.TYPE_DEFINITION, NRMLType.VALUE_INITIALIZATION]

        # Text value
        elif value_type == 'text':
            return [NRMLType.TYPE_DEFINITION, NRMLType.VALUE_INITIALIZATION]

        # Arithmetic expression → Calculated value
        elif value_type == 'math_arithmetic':
            return [NRMLType.CALCULATED_VALUE]

        # Conditional logic → Conditional value
        elif value_type in ['controls_if', 'logic_compare', 'logic_operation']:
            return [NRMLType.CONDITIONAL_VALUE]

        return [NRMLType.UNKNOWN]

    def _analyze_math_number(self, block: Dict[str, Any]) -> List[NRMLType]:
        """Analyze a math_number block - these are simple literals"""
        return [NRMLType.TYPE_DEFINITION, NRMLType.VALUE_INITIALIZATION]

    def _analyze_arithmetic(self, block: Dict[str, Any]) -> List[NRMLType]:
        """Analyze arithmetic expression - generates calculated value"""
        return [NRMLType.CALCULATED_VALUE]

    def _analyze_variable_get(self, block: Dict[str, Any]) -> List[NRMLType]:
        """Analyze variable reference - not a definition"""
        return []

    @staticmethod
    def _get_input_block(block: Dict[str, Any], input_name: str) -> Optional[Dict[str, Any]]:
        """
        Get the block connected to a specific input.

        Args:
            block: Parent block
            input_name: Name of the input (e.g., 'VALUE', 'A', 'B')

        Returns:
            Connected block or None
        """
        inputs = block.get('inputs', {})
        if input_name in inputs:
            return inputs[input_name].get('block')
        return None

    def get_variable_name(self, block: Dict[str, Any], variables: List[Dict[str, Any]]) -> Optional[str]:
        """
        Get the variable name for a variables_set block.

        Args:
            block: variables_set block
            variables: List of variable definitions from workspace

        Returns:
            Variable name or None
        """
        if block.get('type') != 'variables_set':
            return None

        var_id = block.get('fields', {}).get('VAR', {}).get('id')
        if not var_id:
            return None

        # Find variable by ID
        for var in variables:
            if var.get('id') == var_id:
                return var.get('name')

        return None

    def get_numeric_value(self, block: Dict[str, Any]) -> Optional[float]:
        """
        Extract numeric value from math_number block.

        Args:
            block: math_number block

        Returns:
            Numeric value or None
        """
        if block.get('type') != 'math_number':
            return None

        return block.get('fields', {}).get('NUM')

    def get_text_value(self, block: Dict[str, Any]) -> Optional[str]:
        """
        Extract text value from text block.

        Args:
            block: text block

        Returns:
            Text value or None
        """
        if block.get('type') != 'text':
            return None

        return block.get('fields', {}).get('TEXT')

    def count_decimal_places(self, value: float) -> int:
        """
        Count decimal places in a number for precision.

        Args:
            value: Numeric value

        Returns:
            Number of decimal places
        """
        if isinstance(value, int) or value == int(value):
            return 0

        str_value = str(value)
        if '.' in str_value:
            return len(str_value.split('.')[1])

        return 0

    def analyze_variable_metadata(self, variable: Dict[str, Any]) -> List[NRMLType]:
        """
        Analyze variable metadata to determine NRML types.

        Metadata-driven approach where variable definitions contain:
        - type: "input:list", "input:object", "include:*", "count", "sum", etc.
        - collection: For aggregations, which collection to aggregate over
        - filter: Filter conditions for aggregations

        Args:
            variable: Variable definition with metadata

        Returns:
            List of NRML types to generate
        """
        var_type = variable.get('type', '')

        # Input declarations
        if var_type.startswith('input:'):
            return [NRMLType.INPUT_DECLARATION]

        # Include references
        elif var_type.startswith('include:'):
            return [NRMLType.INCLUDE_REFERENCE]

        # Aggregations (count, sum, etc.)
        elif var_type in ['count', 'sum', 'avg', 'min', 'max']:
            return [NRMLType.AGGREGATION]

        # Default: treat as regular variable
        return []

    def get_variable_by_id(self, var_id: str, variables: List[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
        """
        Get variable definition by ID.

        Args:
            var_id: Variable ID
            variables: List of variable definitions

        Returns:
            Variable dict or None
        """
        for var in variables:
            if var.get('id') == var_id:
                return var
        return None
