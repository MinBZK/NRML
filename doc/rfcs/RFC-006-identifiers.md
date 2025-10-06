# RFC-006: UUIDs vs Content-Hash Identifiers

**Status:** Accepted
**Date:** 2025-09-02
**Authors:** Arvid and Anne

## Context

Every entity in NRML needs a unique identifier. Two main approaches are common:

1. **UUIDs (Universally Unique Identifiers)**: Random/generated IDs (e.g., `a1b2c3d4-ee86-4c31-a3c3-22f90fa4e21a`)
2. **Content hashes**: Hash of entity content (e.g., `sha256(JSON.stringify(entity))`)

Content hashing is attractive because:
- Identical content → same ID (deduplication)
- Verifiable (can rehash to confirm ID matches content)
- Deterministic (same content always produces same ID)

However, should NRML use content hashes or UUIDs?

## Decision

**NRML uses UUIDs, not content hashes, as identifiers.**

All facts, properties, roles, and other NRML entities are identified by globally unique UUIDs, not by hashes of their content.

## Rationale

### The Semantic Identity Problem

**Key Insight**: Separately defined definitions can have identical structure but different semantics.

Consider two definitions:
```json
// Definition A: "Passenger age for airline tax purposes"
{
  "name": {"nl": "leeftijd"},
  "type": "integer",
  "unit": "jaar"
}

// Definition B: "Passenger age for insurance purposes"
{
  "name": {"nl": "leeftijd"},
  "type": "integer",
  "unit": "jaar"
}
```

These have **identical content** but represent **different concepts**:
- Airline tax age might round down (14 years, 364 days = 14)
- Insurance age might round up (14 years, 1 day = 15)
- They just happen to have the same structure

### If We Used Content Hashing

With content hashing, both would get the same ID:
```
hash(A) = "abc123..."
hash(B) = "abc123..."  // Same!
```

**Problem**: References to A and B would be indistinguishable. They would be collapsed into a single entity, erasing their semantic difference.

### Why UUIDs Preserve Semantics

With UUIDs:
```json
// Airline age
{
  "a1b2c3d4-...": {
    "name": {"nl": "leeftijd (vliegtuigbelasting)"},
    ...
  }
}

// Insurance age
{
  "e5f6g7h8-...": {
    "name": {"nl": "leeftijd (verzekering)"},
    ...
  }
}
```

**Benefit**: Even if content is identical, they remain distinct entities with distinct semantics.

### Explicit Sharing

If two definitions **should** be the same, that's an explicit decision:
```json
// Both rules reference THE SAME definition
{
  "taxRule": {"$ref": "#/facts/a1b2c3d4-.../properties/leeftijd"},
  "insuranceRule": {"$ref": "#/facts/a1b2c3d4-.../properties/leeftijd"}
}
```

This is intentional sharing, not automatic collapse.

## Consequences

### Positive

- **Semantic independence**: Identical structures can have different meanings
- **Explicit sharing**: References express intent to share
- **No accidental merging**: Won't silently collapse distinct concepts
- **Stable IDs**: IDs don't change when content changes (see RFC-007 Immutability)

### Negative

- **No automatic deduplication**: Duplicate content requires manual detection
- **IDs aren't verifiable**: Can't hash to confirm ID matches content
- **UUID collision risk**: Theoretically possible (but astronomically unlikely)

### Mitigations

- **Tooling**: Build tools to detect duplicate content and suggest sharing
- **Conventions**: Encourage reuse of common definitions via `$ref`
- **Validation**: Can still use content hashing to detect unintended duplicates

## Use Cases for Content Hashing

Content hashing is great for:
- **Content-addressed storage** (e.g., Git, IPFS)
- **Integrity verification** (detect tampering)
- **Deduplication** (find identical files)

But not for **semantic identity**, which is what NRML needs.

## Alternatives Considered

### Content Hashing

**Pros**: Automatic deduplication, verifiable IDs, deterministic
**Cons**: Collapses semantically distinct entities with identical structure

**Rejected because**: Semantic identity is not the same as structural identity

### Hybrid Approach

**Approach**: UUIDs + content hash field for verification
```json
{
  "id": "a1b2c3d4-...",
  "contentHash": "sha256:abc123...",
  ...
}
```

**Pros**: Best of both worlds—semantic identity + verification
**Cons**: More complexity, must keep hash updated, file size increase

**Deferred**: Could add as optional extension later if needed

### Name-Based UUIDs

**Approach**: Generate UUIDs from names (UUID v5)
```javascript
uuid = uuidv5("leeftijd", NRML_NAMESPACE)
```

**Pros**: Deterministic, same name → same UUID
**Cons**: Name collisions (different "leeftijd" definitions), requires namespace management

**Rejected because**: Same problem as content hashing (collapses distinct concepts)

## Related Decisions

- **RFC-004 (Variable Keys)**: UUIDs as object keys
- **RFC-007 (Immutability)**: UUIDs remain stable when content changes
- **RFC-005 (Reusability)**: Explicit `$ref` sharing instead of implicit hash-based sharing

## References

- Notes on hash identifiers: `doc/notes.md:55-59`
