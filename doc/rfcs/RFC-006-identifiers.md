# RFC-006: UUIDs vs Content-Hash Identifiers

**Status:** Accepted | **Date:** 2025-09-02 | **Authors:** Wouter, Arvid and Anne

## Context

Every entity needs unique identifier. Two approaches: **UUIDs** (random, e.g., `a1b2c3d4-...`) or **content hashes** (hash of content, e.g., `sha256(JSON.stringify(entity))`).

Content hashing is attractive: identical content → same ID (deduplication), verifiable, deterministic.

## Decision

**NRML uses UUIDs, not content hashes.**

## Why

**Semantic identity problem**: Separately defined definitions can have identical structure but different semantics.

```json
// Airline tax age (rounds down)
{
  "name": {"nl": "leeftijd"},
  "type": "integer",
  "unit": "jaar"
}

// Insurance age (rounds up)
{
  "name": {"nl": "leeftijd"},
  "type": "integer",
  "unit": "jaar"
}
```

**Identical content, different meanings.**

**With content hashing**: Both get same ID → collapsed into single entity, erasing semantic difference.

**With UUIDs**: Remain distinct even if structure identical. Sharing is explicit via `$ref`:

```json
{
  "taxRule": {"$ref": "#/facts/a1b2c3d4-.../properties/leeftijd"},
  "insuranceRule": {"$ref": "#/facts/a1b2c3d4-.../properties/leeftijd"}
}
```

**Benefits:**
- Semantic independence (identical structures, different meanings)
- Explicit sharing (references express intent)
- No accidental merging
- Stable IDs when content changes (RFC-007)

**Tradeoffs:**
- No automatic deduplication → **mitigate**: Tooling detects duplicates
- IDs not verifiable → **mitigate**: Can use hashing for integrity checks
- UUID collision risk (astronomically unlikely)

## Use Cases for Content Hashing

Content hashing great for: content-addressed storage (Git, IPFS), integrity verification, deduplication.

**Not for semantic identity**, which NRML needs.

## Alternatives Rejected

- **Content hashing**: Collapses semantically distinct entities
- **Hybrid (UUID + hash)**: More complexity, must keep hash updated, deferred as optional extension
- **Name-based UUIDs** (v5): Name collisions, same problem as content hashing

## Related

- RFC-004 (Variable Keys)
- RFC-007 (Immutability - UUIDs stable)
- RFC-005 (Reusability - explicit `$ref`)
- Notes: `doc/notes.md:55-59`
