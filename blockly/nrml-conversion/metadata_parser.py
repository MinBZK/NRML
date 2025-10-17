"""
Metadata Parser Module

Parses extended variable metadata to extract NRML-specific information
for inputs, outputs, includes, and aggregations.
"""

from typing import Dict, Any, Optional, List


class MetadataParser:
    """
    Parses variable metadata to extract NRML structures.

    Variable metadata format examples:
    - type: "input:list" - Input parameter that is a list
    - type: "input:object" - Input parameter that is an object
    - type: "include:law_name.output_name" - Include reference
    - type: "count" - Count aggregation
    - collection: "variable_name" - Collection to aggregate over
    - filter: {property: "age", operator: "<=", value: "max_age"} - Filter condition
    """

    @staticmethod
    def is_input(variable: Dict[str, Any]) -> bool:
        """Check if variable is an input declaration"""
        return variable.get('type', '').startswith('input:')

    @staticmethod
    def is_output(variable: Dict[str, Any]) -> bool:
        """Check if variable is an output (currently determined by usage context)"""
        # Outputs are typically aggregations or calculated values
        var_type = variable.get('type', '')
        return var_type in ['count', 'sum', 'avg', 'min', 'max']

    @staticmethod
    def is_include(variable: Dict[str, Any]) -> bool:
        """Check if variable is an include reference"""
        return variable.get('type', '').startswith('include:')

    @staticmethod
    def is_aggregation(variable: Dict[str, Any]) -> bool:
        """Check if variable is an aggregation"""
        var_type = variable.get('type', '')
        return var_type in ['count', 'sum', 'avg', 'min', 'max']

    @staticmethod
    def parse_input(variable: Dict[str, Any]) -> Dict[str, Any]:
        """
        Parse input variable metadata.

        Returns structure for NRML inputs section:
        {
            "type": {"$ref": "#/facts/fact_name"},
            "properties": {"prop_name": "#/facts/fact_name/items/prop_name"}
        }
        """
        var_type = variable.get('type', '')
        item_type = variable.get('itemType', 'object')
        properties = variable.get('properties', [])

        result = {
            "type": {"$ref": f"#/facts/{item_type}"}
        }

        if properties:
            result["properties"] = {
                prop: f"#/facts/{item_type}/items/{prop}"
                for prop in properties
            }

        return result

    @staticmethod
    def parse_include(variable: Dict[str, Any]) -> Dict[str, Any]:
        """
        Parse include variable metadata.

        Returns structure for NRML includes section:
        {
            "law": "law_name",
            "output": "output_name",
            "target": {"$ref": "#/facts/includes/items/item_name"}
        }
        """
        var_type = variable.get('type', '')
        # Format: "include:law_name.output_name"
        include_spec = var_type.replace('include:', '')

        if '.' in include_spec:
            law, output = include_spec.split('.', 1)
        else:
            law = include_spec
            output = variable.get('name', 'output')

        return {
            "law": law,
            "output": output
        }

    @staticmethod
    def parse_aggregation(variable: Dict[str, Any]) -> Dict[str, Any]:
        """
        Parse aggregation variable metadata.

        Returns:
        {
            "function": "count" | "sum" | etc.,
            "collection": "variable_name",
            "property": "property_name" (for sum/avg),
            "filter": {
                "property": "age",
                "operator": "<=",
                "value": "max_age"
            }
        }
        """
        var_type = variable.get('type', '')
        collection = variable.get('collection')
        filter_spec = variable.get('filter', {})
        property_name = filter_spec.get('property') if filter_spec else None

        result = {
            "function": var_type,
            "collection": collection
        }

        if property_name and var_type in ['sum', 'avg']:
            result["property"] = property_name

        if filter_spec:
            result["filter"] = {
                "property": filter_spec.get('property'),
                "operator": filter_spec.get('operator', '=='),
                "value": filter_spec.get('value')
            }

        return result

    @staticmethod
    def get_input_variables(variables: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Get all input variables from variable list"""
        return [v for v in variables if MetadataParser.is_input(v)]

    @staticmethod
    def get_output_variables(variables: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Get all output variables from variable list"""
        return [v for v in variables if MetadataParser.is_output(v)]

    @staticmethod
    def get_include_variables(variables: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Get all include variables from variable list"""
        return [v for v in variables if MetadataParser.is_include(v)]

    @staticmethod
    def get_aggregation_variables(variables: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Get all aggregation variables from variable list"""
        return [v for v in variables if MetadataParser.is_aggregation(v)]
