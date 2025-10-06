# RFC-004: Variable Keys vs Fixed Keys

**Status:** Accepted | **Date:** 2025-09-02 | **Authors:** Arvid and Anne

## Context

JSON objects can use **fixed keys** (predictable) or **variable keys** (UUIDs as keys):

Fixed: `{"facts": [{"id": "a1b2", "name": "vlucht"}]}`
Variable: `{"facts": {"a1b2c3d4-...": {"name": "vlucht"}}}`

## Decision

**NRML uses variable keys (UUIDs as object keys).**

Facts, properties, roles use their UUIDs as keys, not array indices or fixed fields.

## Why

**Benefits:**
- **O(1) lookup**: Direct hash access by UUID vs O(n) array search
- **Natural referencing**: `{"$ref": "#/facts/uuid"}` is standard JSON Pointer
- **Merge semantics**: `{...coreFacts, ...extensionFacts}` merges cleanly
- **Automatic uniqueness**: Duplicate UUID keys = JSON parse error
- **Sparse updates**: Can update single fact without full array

**Parser support**: Modern parsers handle variable keys efficiently (JavaScript objects, Python dicts, Java/C# Maps). JSON Schema supports `patternProperties` for UUID keys.

**Tradeoffs:**
- Iteration order may not be guaranteed (ES2015+ preserves insertion order)
- Schema uses `patternProperties` instead of simple `properties`
- Human navigation requires knowing UUIDs (acceptable per RFC-001)

**Mitigations**: NRML semantics don't depend on iteration order; tooling can present entities in semantic order.

## Alternatives Rejected

- **Array with ID fields**: O(n) lookup, JSON Pointers use fragile array indices
- **Hybrid** (byId + all): Redundancy, synchronization burden

## Related

- RFC-001 (Readability): UUIDs acceptable; core not human-readable
- Notes: `doc/notes.md:40-43`
