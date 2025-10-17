"""
NRML Generators Module

Methods to create NRML structures (type definitions, value initializations, etc.)
"""

from typing import Dict, Any, Optional
from datetime import date


class NRMLGenerators:
    """
    Factory class for generating NRML version entries.

    Each method creates a specific type of NRML version structure:
    - Type definitions (numeric, text, boolean, enumeration)
    - Value initializations
    - Calculated values
    - Conditional values
    """

    @staticmethod
    def create_type_definition_numeric(
        precision: int = 0,
        unit: Optional[str] = None,
        valid_from: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create a numeric type definition.

        Args:
            precision: Number of decimal places
            unit: Unit of measurement (optional)
            valid_from: Valid from date (YYYY-MM-DD format)

        Returns:
            Type definition dictionary
        """
        if valid_from is None:
            valid_from = date.today().isoformat()

        type_def = {
            "validFrom": valid_from,
            "type": "numeric"
        }

        if precision > 0:
            type_def["precision"] = precision

        if unit:
            type_def["unit"] = unit

        return type_def

    @staticmethod
    def create_type_definition_text(valid_from: Optional[str] = None) -> Dict[str, Any]:
        """
        Create a text type definition.

        Args:
            valid_from: Valid from date

        Returns:
            Type definition dictionary
        """
        if valid_from is None:
            valid_from = date.today().isoformat()

        return {
            "validFrom": valid_from,
            "type": "text"
        }

    @staticmethod
    def create_type_definition_boolean(valid_from: Optional[str] = None) -> Dict[str, Any]:
        """
        Create a boolean type definition.

        Args:
            valid_from: Valid from date

        Returns:
            Type definition dictionary
        """
        if valid_from is None:
            valid_from = date.today().isoformat()

        return {
            "validFrom": valid_from,
            "type": "boolean"
        }

    @staticmethod
    def create_type_definition_enumeration(
        values: list,
        valid_from: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create an enumeration type definition.

        Args:
            values: List of allowed values
            valid_from: Valid from date

        Returns:
            Type definition dictionary
        """
        if valid_from is None:
            valid_from = date.today().isoformat()

        return {
            "validFrom": valid_from,
            "type": "enumeration",
            "values": values
        }

    @staticmethod
    def create_value_initialization(
        target_path: str,
        value: Any,
        unit: Optional[str] = None,
        valid_from: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create a value initialization version entry.

        Args:
            target_path: Full path to target item (#/facts/{uuid}/items/{uuid})
            value: Initial value
            unit: Unit of measurement (optional)
            valid_from: Valid from date

        Returns:
            Value initialization dictionary
        """
        if valid_from is None:
            valid_from = date.today().isoformat()

        value_obj = {"value": value}
        if unit:
            value_obj["unit"] = unit

        return {
            "validFrom": valid_from,
            "target": [{"$ref": target_path}],
            "value": value_obj
        }

    @staticmethod
    def create_calculated_value(
        target_path: str,
        expression: Dict[str, Any],
        valid_from: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create a calculated value version entry.

        Args:
            target_path: Full path to target item
            expression: Expression dictionary (arithmetic, etc.)
            valid_from: Valid from date

        Returns:
            Calculated value dictionary
        """
        if valid_from is None:
            valid_from = date.today().isoformat()

        return {
            "validFrom": valid_from,
            "target": [{"$ref": target_path}],
            "expression": expression
        }

    @staticmethod
    def create_arithmetic_expression(
        operator: str,
        arguments: list
    ) -> Dict[str, Any]:
        """
        Create an arithmetic expression.

        Args:
            operator: Operator (add, subtract, multiply, divide, etc.)
            arguments: List of arguments (can be references or values)

        Returns:
            Arithmetic expression dictionary
        """
        return {
            "type": "arithmetic",
            "operator": operator,
            "arguments": arguments
        }

    @staticmethod
    def create_reference(path: str) -> list:
        """
        Create a reference to an item.

        Args:
            path: Full path to item

        Returns:
            Reference array with $ref object
        """
        return [{"$ref": path}]

    @staticmethod
    def create_literal_value(value: Any) -> Dict[str, Any]:
        """
        Create a literal value object.

        Args:
            value: Literal value (number, string, boolean)

        Returns:
            Value object
        """
        return {"value": value}

    @staticmethod
    def map_blockly_operator(blockly_op: str) -> str:
        """
        Map Blockly operator to NRML operator.

        Args:
            blockly_op: Blockly operator (ADD, MINUS, MULTIPLY, DIVIDE, etc.)

        Returns:
            NRML operator string
        """
        operator_map = {
            'ADD': 'add',
            'MINUS': 'subtract',
            'MULTIPLY': 'multiply',
            'DIVIDE': 'divide',
            'POWER': 'power',
            'MOD': 'modulo',
            'MIN': 'min',
            'MAX': 'max'
        }

        return operator_map.get(blockly_op, 'add')

    @staticmethod
    def infer_type_from_value(value: Any) -> str:
        """
        Infer NRML type from a value.

        Args:
            value: Any value

        Returns:
            NRML type string (numeric, text, boolean)
        """
        if isinstance(value, bool):
            return "boolean"
        elif isinstance(value, (int, float)):
            return "numeric"
        elif isinstance(value, str):
            return "text"
        else:
            return "text"  # Default fallback

    @staticmethod
    def create_aggregation_expression(
        function: str,
        expression: list,
        condition: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Create an aggregation expression (count, sum, etc.).

        Args:
            function: Aggregation function (count, sum, avg, min, max)
            expression: Expression array (collection reference)
            condition: Optional filter condition

        Returns:
            Aggregation expression dictionary
        """
        result = {
            "type": "aggregation",
            "function": function,
            "expression": expression
        }

        if condition:
            result["condition"] = condition

        return result

    @staticmethod
    def create_comparison_condition(
        operator: str,
        left: list,
        right: Any
    ) -> Dict[str, Any]:
        """
        Create a comparison condition for filtering.

        Args:
            operator: Comparison operator (lessThan, lessThanOrEqual, equal, etc.)
            left: Left side (reference array or value)
            right: Right side (reference array or value)

        Returns:
            Comparison condition dictionary
        """
        return {
            "type": "comparison",
            "operator": operator,
            "arguments": [left, right]
        }

    @staticmethod
    def map_comparison_operator(op: str) -> str:
        """
        Map comparison operator symbols to NRML operators.

        Args:
            op: Operator symbol (<=, >=, ==, !=, <, >)

        Returns:
            NRML operator string
        """
        operator_map = {
            '<=': 'lessThanOrEqual',
            '>=': 'greaterThanOrEqual',
            '==': 'equal',
            '!=': 'notEqual',
            '<': 'lessThan',
            '>': 'greaterThan'
        }

        return operator_map.get(op, 'equal')
