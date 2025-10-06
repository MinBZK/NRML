# RFC-004: Variable Keys vs Fixed Keys

**Status:** Accepted
**Date:** 2025-09-02
**Authors:** Arvid and Anne

## Context

JSON objects can be structured in two fundamentally different ways:

**Fixed keys** (predictable structure):

```json
{
  "facts": [
    {
      "id": "a1b2",
      "name": "vlucht"
    },
    {
      "id": "c3d4",
      "name": "passagier"
    }
  ]
}
```

**Variable keys** (UUIDs as keys):

```json
{
  "facts": {
    "a1b2c3d4-...": {
      "name": "vlucht"
    },
    "e5f6g7h8-...": {
      "name": "passagier"
    }
  }
}
```

The question: Should NRML allow variable keys (UUIDs as keys) or enforce fixed, predictable keys?

## Decision

**NRML allows variable keys (UUIDs as object keys).**

Facts, properties, roles, and other NRML entities use their UUIDs as object keys, not array indices or fixed field
names.

## Rationale

### Why Variable Keys?

1. **Direct Lookup**: O(1) access to entities by UUID
   ```json
   facts["a1b2c3d4-..."]  // Direct hash lookup
   ```
   vs.
   ```json
   facts.find(f => f.id === "a1b2c3d4-...")  // O(n) search
   ```

2. **Natural Referencing**: `$ref` syntax maps directly to structure
   ```json
   {"$ref": "#/facts/a1b2c3d4-ee86-4c31-a3c3-22f90fa4e21a"}
   ```
   This is a JSON Pointer that works with standard tools.

3. **Merge Semantics**: Adding/updating facts is straightforward
   ```json
   // Merge two NRML files
   {...coreFacts, ...extensionFacts}  // Objects merge cleanly
   ```

4. **No Duplicate IDs**: Object keys enforce uniqueness automatically
    - Duplicate UUID keys = JSON parse error
    - Array approach requires manual uniqueness validation

5. **Sparse Updates**: Can update single fact without full array
   ```json
   {"facts": {"a1b2-...": {"name": "updated"}}}  // Partial update
   ```

### Parser Considerations

**Counterargument**: "Many parsers find fixed keys easier."

**Response**: Modern JSON parsers handle variable keys efficiently:

- JavaScript: Native object access
- Python: `dict` access is fundamental
- Java/C#: `Map<String, T>` or `Dictionary<string, T>`
- Schema validation: JSON Schema supports `patternProperties` for UUID keys

```json
{
  "facts": {
    "type": "object",
    "patternProperties": {
      "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$": {
        "$ref": "#/definitions/fact"
      }
    }
  }
}
```

## Consequences

### Positive

- **Efficient lookup**: Direct hash access by UUID
- **Natural JSON Pointers**: `$ref` works with standard tools
- **Automatic uniqueness**: No duplicate UUIDs
- **Easy merging**: Object spread/merge semantics
- **Partial updates**: Can modify single entities

### Negative

- **Iteration order**: Object key order may not be guaranteed (though ES2015+ preserves insertion order)
- **Schema complexity**: Need `patternProperties` instead of simple `properties`
- **Human navigation**: Can't predict keys without knowing UUIDs (but see RFC-001 on readability)

### Mitigations

- **Order independence**: NRML semantics don't depend on iteration order
- **Tooling**: Editors can present entities in sorted or semantic order
- **Schema tooling**: JSON Schema validation tools fully support `patternProperties`

## Alternatives Considered

### Array with ID Fields

**Structure**:

```json
{
  "facts": [
    {
      "id": "a1b2-...",
      "name": "vlucht"
    },
    {
      "id": "c3d4-...",
      "name": "passagier"
    }
  ]
}
```

**Pros**:

- Predictable structure (always an array)
- Easier to iterate
- Order can be meaningful

**Cons**:

- O(n) lookup by ID
- Must maintain ID uniqueness separately
- JSON Pointers use array indices: `#/facts/0` (breaks if order changes)
- Merging requires de-duplication logic

**Rejected because**: Lookup efficiency and reference stability are critical

### Hybrid Approach

**Structure**:

```json
{
  "facts": {
    "byId": {
      "a1b2-...": {
        ...
      },
      "c3d4-...": {
        ...
      }
    },
    "all": [
      ...
    ]
  }
}
```

**Pros**:

- Fast lookup + easy iteration

**Cons**:

- Redundancy (same data twice)
- Must keep `byId` and `all` in sync
- Larger file size
- More complex validation

**Rejected because**: Adds complexity without sufficient benefit

## References

- Notes on variable keys: `doc/notes.md:40-43`
- Related: RFC-001 (Readability - UUIDs are acceptable)
