"""
NRML Registry Module

Manages in-memory dictionary of NRML facts and items during conversion.
"""

import uuid
from typing import Dict, List, Optional, Any
from datetime import date


class NRMLRegistry:
    """
    In-memory registry of NRML facts and items.

    Maintains relationships between:
    - Variable names → Item UUIDs
    - Fact names → Fact UUIDs
    - Full NRML structure
    """

    def __init__(self):
        self.facts: Dict[str, Dict[str, Any]] = {}
        self.variable_to_item: Dict[str, tuple] = {}  # var_name → (fact_uuid, item_uuid)
        self.reference_key_to_path: Dict[str, str] = {}  # reference_key → full path

    def create_fact(self, name: str, language: str = "nl") -> str:
        """
        Create a new fact.

        Args:
            name: Fact name
            language: Language code (default: nl)

        Returns:
            Fact UUID
        """
        fact_uuid = str(uuid.uuid4())
        self.facts[fact_uuid] = {
            "name": {language: name},
            "items": {}
        }
        return fact_uuid

    def get_or_create_fact(self, name: str, language: str = "nl") -> str:
        """
        Get existing fact by name or create new one.

        Args:
            name: Fact name
            language: Language code

        Returns:
            Fact UUID
        """
        # Search for existing fact
        for fact_uuid, fact in self.facts.items():
            if fact.get("name", {}).get(language) == name:
                return fact_uuid

        # Create new fact
        return self.create_fact(name, language)

    def create_item(
        self,
        fact_uuid: str,
        reference_key: str,
        name: str = "",
        language: str = "nl"
    ) -> str:
        """
        Create a new item in a fact.

        Args:
            fact_uuid: Parent fact UUID
            reference_key: Item reference key
            name: Item name (optional)
            language: Language code

        Returns:
            Item UUID
        """
        if fact_uuid not in self.facts:
            raise ValueError(f"Fact {fact_uuid} not found")

        item_uuid = str(uuid.uuid4())
        item = {
            "name": {language: name},
            "reference-key": reference_key,
            "versions": []
        }

        self.facts[fact_uuid]["items"][item_uuid] = item

        # Register mappings
        self.variable_to_item[reference_key] = (fact_uuid, item_uuid)
        self.reference_key_to_path[reference_key] = f"#/facts/{fact_uuid}/items/{item_uuid}"

        return item_uuid

    def add_version_to_item(
        self,
        fact_uuid: str,
        item_uuid: str,
        version: Dict[str, Any]
    ):
        """
        Add a version entry to an item.

        Args:
            fact_uuid: Fact UUID
            item_uuid: Item UUID
            version: Version dictionary (type definition, value initialization, etc.)
        """
        if fact_uuid not in self.facts:
            raise ValueError(f"Fact {fact_uuid} not found")

        if item_uuid not in self.facts[fact_uuid]["items"]:
            raise ValueError(f"Item {item_uuid} not found in fact {fact_uuid}")

        self.facts[fact_uuid]["items"][item_uuid]["versions"].append(version)

    def get_item_path(self, reference_key: str) -> Optional[str]:
        """
        Get full path for an item by reference key.

        Args:
            reference_key: Item reference key (variable name)

        Returns:
            Full path (#/facts/{uuid}/items/{uuid}) or None
        """
        return self.reference_key_to_path.get(reference_key)

    def get_item_uuids(self, reference_key: str) -> Optional[tuple]:
        """
        Get fact and item UUIDs for a variable.

        Args:
            reference_key: Variable name / reference key

        Returns:
            Tuple of (fact_uuid, item_uuid) or None
        """
        return self.variable_to_item.get(reference_key)

    def to_nrml(
        self,
        schema_url: str = "https://example.com/nrml-facts-schema.json",
        inputs: Optional[Dict[str, Any]] = None,
        outputs: Optional[Dict[str, Any]] = None,
        includes: Optional[List[Dict[str, Any]]] = None
    ) -> Dict[str, Any]:
        """
        Convert registry to complete NRML JSON structure.

        Args:
            schema_url: JSON schema URL
            inputs: Optional inputs section
            outputs: Optional outputs section
            includes: Optional includes section

        Returns:
            Complete NRML dictionary
        """
        # Create a deep copy of facts but exclude 'reference-key' from items
        # (reference-key is for internal use only, not part of NRML schema)
        clean_facts = {}
        for fact_uuid, fact in self.facts.items():
            clean_facts[fact_uuid] = {
                "name": fact["name"],
                "items": {}
            }

            # Copy optional fact fields
            if "definite_article" in fact:
                clean_facts[fact_uuid]["definite_article"] = fact["definite_article"]
            if "animated" in fact:
                clean_facts[fact_uuid]["animated"] = fact["animated"]
            if "relation" in fact:
                clean_facts[fact_uuid]["relation"] = fact["relation"]

            # Copy items without reference-key
            for item_uuid, item in fact["items"].items():
                clean_item = {
                    "name": item["name"],
                    "versions": item["versions"]
                }

                # Copy optional item fields
                if "article" in item:
                    clean_item["article"] = item["article"]
                if "plural" in item:
                    clean_item["plural"] = item["plural"]

                clean_facts[fact_uuid]["items"][item_uuid] = clean_item

        result = {
            "$schema": schema_url,
            "version": "1.0",
            "language": "nl"
        }

        # Add optional sections
        if inputs:
            result["inputs"] = inputs
        if outputs:
            result["outputs"] = outputs
        if includes:
            result["includes"] = includes

        # Always include facts
        result["facts"] = clean_facts

        return result

    def get_statistics(self) -> Dict[str, int]:
        """
        Get statistics about the registry.

        Returns:
            Dictionary with counts
        """
        total_items = sum(len(fact["items"]) for fact in self.facts.values())
        total_versions = sum(
            len(item["versions"])
            for fact in self.facts.values()
            for item in fact["items"].values()
        )

        return {
            "facts": len(self.facts),
            "items": total_items,
            "versions": total_versions,
            "variables": len(self.variable_to_item)
        }

    def __repr__(self) -> str:
        stats = self.get_statistics()
        return f"NRMLRegistry(facts={stats['facts']}, items={stats['items']}, versions={stats['versions']})"
