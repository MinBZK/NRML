"""
Main Converter Module

Orchestrates the conversion from Blockly JSON to NRML format.
"""

import json
from typing import Dict, List, Any, Optional
from block_analyzer import BlockAnalyzer, NRMLType
from nrml_registry import NRMLRegistry
from nrml_generators import NRMLGenerators
from metadata_parser import MetadataParser


class BlocklyToNRMLConverter:
    """
    Main converter class that orchestrates the conversion process.

    Process:
    1. Parse Blockly JSON
    2. Iterate through blocks
    3. Analyze each block type
    4. Generate appropriate NRML structures
    5. Build in-memory registry
    6. Export to NRML JSON
    """

    def __init__(self):
        self.analyzer = BlockAnalyzer()
        self.registry = NRMLRegistry()
        self.generators = NRMLGenerators()
        self.metadata_parser = MetadataParser()
        self.inputs = {}
        self.outputs = {}
        self.includes = []

    def convert(self, blockly_json: Dict[str, Any]) -> Dict[str, Any]:
        """
        Convert Blockly JSON to NRML format.

        Args:
            blockly_json: Blockly workspace JSON

        Returns:
            NRML JSON structure
        """
        # Extract blocks and variables
        blocks = blockly_json.get('blocks', {}).get('blocks', [])
        variables = blockly_json.get('variables', [])

        # Process metadata from variables
        self._process_metadata(variables)

        # First pass: Process all variable definitions (constants)
        self._process_constants(blocks, variables)

        # Second pass: Process calculations
        self._process_calculations(blocks, variables)

        # Third pass: Process aggregations from metadata
        self._process_aggregations(variables)

        # Generate final NRML with inputs/outputs/includes
        return self.registry.to_nrml(
            inputs=self.inputs if self.inputs else None,
            outputs=self.outputs if self.outputs else None,
            includes=self.includes if self.includes else None
        )

    def _process_constants(self, blocks: List[Dict[str, Any]], variables: List[Dict[str, Any]]):
        """
        First pass: Process all constant value assignments.

        Creates:
        - "Constants" fact
        - Items with type definitions and value initializations
        """
        constants_fact = None

        # Iterate through all blocks
        current_block = blocks[0] if blocks else None

        while current_block:
            block_type = current_block.get('type')

            if block_type == 'variables_set':
                nrml_types = self.analyzer.analyze_block(current_block)

                # Check if this is a constant (TYPE_DEFINITION + VALUE_INITIALIZATION)
                if (NRMLType.TYPE_DEFINITION in nrml_types and
                    NRMLType.VALUE_INITIALIZATION in nrml_types):

                    # Create constants fact if needed
                    if constants_fact is None:
                        constants_fact = self.registry.get_or_create_fact("Constants")

                    # Get variable name
                    var_name = self.analyzer.get_variable_name(current_block, variables)
                    if not var_name:
                        current_block = current_block.get('next', {}).get('block')
                        continue

                    # Get value block
                    value_block = self.analyzer._get_input_block(current_block, 'VALUE')
                    if not value_block:
                        current_block = current_block.get('next', {}).get('block')
                        continue

                    # Generate type definition
                    if value_block.get('type') == 'math_number':
                        value = self.analyzer.get_numeric_value(value_block)
                        precision = self.analyzer.count_decimal_places(value)

                        # Create item for type definition
                        type_item_uuid = self.registry.create_item(
                            fact_uuid=constants_fact,
                            reference_key=var_name,
                            name=""
                        )

                        type_def = self.generators.create_type_definition_numeric(
                            precision=precision
                        )
                        self.registry.add_version_to_item(constants_fact, type_item_uuid, type_def)

                        # Create separate item for value initialization
                        value_item_uuid = self.registry.create_item(
                            fact_uuid=constants_fact,
                            reference_key=f"{var_name}-value",
                            name=""
                        )

                        # Generate value initialization (referencing the type definition item)
                        item_path = self.registry.get_item_path(var_name)
                        value_init = self.generators.create_value_initialization(
                            target_path=item_path,
                            value=value
                        )
                        self.registry.add_version_to_item(constants_fact, value_item_uuid, value_init)

                    elif value_block.get('type') == 'text':
                        value = self.analyzer.get_text_value(value_block)

                        # Create item for type definition
                        type_item_uuid = self.registry.create_item(
                            fact_uuid=constants_fact,
                            reference_key=var_name,
                            name=""
                        )

                        type_def = self.generators.create_type_definition_text()
                        self.registry.add_version_to_item(constants_fact, type_item_uuid, type_def)

                        # Create separate item for value initialization
                        value_item_uuid = self.registry.create_item(
                            fact_uuid=constants_fact,
                            reference_key=f"{var_name}-value",
                            name=""
                        )

                        # Generate value initialization (referencing the type definition item)
                        item_path = self.registry.get_item_path(var_name)
                        value_init = self.generators.create_value_initialization(
                            target_path=item_path,
                            value=value
                        )
                        self.registry.add_version_to_item(constants_fact, value_item_uuid, value_init)

            # Move to next block
            current_block = current_block.get('next', {}).get('block')

    def _process_calculations(self, blocks: List[Dict[str, Any]], variables: List[Dict[str, Any]]):
        """
        Second pass: Process calculated values.

        Creates:
        - "Calculation" fact
        - Items with calculated value expressions
        """
        calc_fact = None

        # Iterate through all blocks
        current_block = blocks[0] if blocks else None

        while current_block:
            block_type = current_block.get('type')

            if block_type == 'variables_set':
                nrml_types = self.analyzer.analyze_block(current_block)

                # Check if this is a calculation
                if NRMLType.CALCULATED_VALUE in nrml_types:

                    # Create calculation fact if needed
                    if calc_fact is None:
                        calc_fact = self.registry.get_or_create_fact("Calculation")

                    # Get variable name
                    var_name = self.analyzer.get_variable_name(current_block, variables)
                    if not var_name:
                        current_block = current_block.get('next', {}).get('block')
                        continue

                    # Get expression block
                    expr_block = self.analyzer._get_input_block(current_block, 'VALUE')
                    if not expr_block:
                        current_block = current_block.get('next', {}).get('block')
                        continue

                    # Create item
                    item_uuid = self.registry.create_item(
                        fact_uuid=calc_fact,
                        reference_key=var_name,
                        name=""
                    )

                    # Parse expression
                    expression = self._parse_expression(expr_block, variables)

                    if expression:
                        # Generate calculated value
                        item_path = self.registry.get_item_path(var_name)
                        calc_value = self.generators.create_calculated_value(
                            target_path=item_path,
                            expression=expression
                        )
                        self.registry.add_version_to_item(calc_fact, item_uuid, calc_value)

            # Move to next block
            current_block = current_block.get('next', {}).get('block')

    def _parse_expression(self, block: Dict[str, Any], variables: List[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
        """
        Parse an expression block into NRML expression format.

        Args:
            block: Expression block (math_arithmetic, etc.)
            variables: Variable definitions

        Returns:
            NRML expression dictionary or None
        """
        if block.get('type') == 'math_arithmetic':
            operator = block.get('fields', {}).get('OP', 'ADD')
            nrml_operator = self.generators.map_blockly_operator(operator)

            # Parse operands A and B
            arg_a = self._parse_operand(self.analyzer._get_input_block(block, 'A'), variables)
            arg_b = self._parse_operand(self.analyzer._get_input_block(block, 'B'), variables)

            arguments = []
            if arg_a is not None:
                arguments.append(arg_a)
            if arg_b is not None:
                arguments.append(arg_b)

            return self.generators.create_arithmetic_expression(
                operator=nrml_operator,
                arguments=arguments
            )

        return None

    def _parse_operand(self, block: Optional[Dict[str, Any]], variables: List[Dict[str, Any]]) -> Optional[Any]:
        """
        Parse an operand (can be variable reference or literal).

        Args:
            block: Operand block
            variables: Variable definitions

        Returns:
            NRML operand (reference array or literal value)
        """
        if not block:
            return None

        block_type = block.get('type')

        # Variable reference
        if block_type == 'variables_get':
            var_id = block.get('fields', {}).get('VAR', {}).get('id')
            var_name = None

            for var in variables:
                if var.get('id') == var_id:
                    var_name = var.get('name')
                    break

            if var_name:
                item_path = self.registry.get_item_path(var_name)
                if item_path:
                    return self.generators.create_reference(item_path)

        # Literal number
        elif block_type == 'math_number':
            value = self.analyzer.get_numeric_value(block)
            if value is not None:
                return self.generators.create_literal_value(value)

        # Nested expression
        elif block_type == 'math_arithmetic':
            return self._parse_expression(block, variables)

        return None

    def get_statistics(self) -> Dict[str, int]:
        """Get conversion statistics"""
        return self.registry.get_statistics()

    def _process_metadata(self, variables: List[Dict[str, Any]]):
        """
        Process variable metadata to extract inputs, outputs, and includes.

        Args:
            variables: List of variable definitions from workspace
        """
        for var in variables:
            var_name = var.get('name')

            # Process inputs
            if self.metadata_parser.is_input(var):
                input_spec = self.metadata_parser.parse_input(var)
                self.inputs[var_name] = input_spec

            # Process includes
            elif self.metadata_parser.is_include(var):
                include_spec = self.metadata_parser.parse_include(var)
                # Create includes fact if needed
                includes_fact = self.registry.get_or_create_fact("Verwijzingen")

                # Create item for include value
                item_uuid = self.registry.create_item(
                    fact_uuid=includes_fact,
                    reference_key=var_name,
                    name=include_spec.get('output', var_name)
                )

                # Add type definition
                type_def = self.generators.create_type_definition_numeric()
                self.registry.add_version_to_item(includes_fact, item_uuid, type_def)

                # Add to includes list with target reference
                item_path = self.registry.get_item_path(var_name)
                include_spec["target"] = {"$ref": item_path}
                self.includes.append(include_spec)

    def _process_aggregations(self, variables: List[Dict[str, Any]]):
        """
        Process aggregation variables from metadata.

        Args:
            variables: List of variable definitions
        """
        calc_fact = None

        for var in variables:
            if not self.metadata_parser.is_aggregation(var):
                continue

            var_name = var.get('name')
            agg_spec = self.metadata_parser.parse_aggregation(var)

            # Create calculated fact if needed
            if calc_fact is None:
                calc_fact = self.registry.get_or_create_fact("berekend")

            # Create item for aggregation result
            item_uuid = self.registry.create_item(
                fact_uuid=calc_fact,
                reference_key=var_name,
                name=var_name
            )

            # Build aggregation expression
            # Expression array contains reference to the collection/relationship
            collection_name = agg_spec.get('collection')
            expression = []

            # For now, use a simple reference - in real implementation would need
            # to resolve to proper relationship fact
            # expression.append({"$ref": f"#/facts/kinderen_van/items/relatie_definitie"})

            # Build filter condition if present
            condition = None
            if 'filter' in agg_spec:
                filter_spec = agg_spec['filter']
                property_name = filter_spec.get('property')
                operator = filter_spec.get('operator')
                value_var = filter_spec.get('value')

                # Build left side: property reference
                # In real implementation would resolve actual fact/item paths
                left = [
                    {"$ref": "#/facts/child"},
                    {"$ref": f"#/facts/child/items/{property_name}"}
                ]

                # Build right side: variable reference
                right_path = self.registry.get_item_path(value_var)
                if right_path:
                    right = {"$ref": right_path}
                else:
                    right = {"value": value_var}  # Fallback to literal

                # Create comparison condition
                nrml_operator = self.generators.map_comparison_operator(operator)
                condition = self.generators.create_comparison_condition(
                    operator=nrml_operator,
                    left=left,
                    right=right
                )

            # Create aggregation expression
            aggr_expr = self.generators.create_aggregation_expression(
                function=agg_spec['function'],
                expression=expression,
                condition=condition
            )

            # Get target path and create calculated value version
            item_path = self.registry.get_item_path(var_name)
            calc_value = self.generators.create_calculated_value(
                target_path=item_path,
                expression=aggr_expr
            )

            self.registry.add_version_to_item(calc_fact, item_uuid, calc_value)

            # Mark as output if it's an aggregation
            if self.metadata_parser.is_output(var):
                self.outputs[var_name] = {
                    "source": {"$ref": item_path}
                }
