# RFC-007: Immutability Constraints

**Status:** Accepted | **Date:** 2025-09-02 | **Authors:** Wouter, Arvid and Anne

## Context

Legal and regulatory rules must be auditable and reproducible. If we say "this rule applied on 2019-06-15," we must
retrieve exactly what that rule was, not what it has since become.

## Decision

**All required fields of a version are immutable.**

Once created, required fields cannot change. Any change to required fields creates a **new version** with **new UUID**.

**Allowed**: Add new version

```json
{
  "versions": [
    {
      "id": "v1-uuid",
      "validFrom": "2018-01-01",
      "value": {
        "amount": 5.50,
        "unit": "€"
      }
    },
    {
      "id": "v2-uuid",
      "validFrom": "2020-01-01",
      "value": {
        "amount": 6.00,
        "unit": "€"
      }
    }
  ]
}
```

**Not allowed**: Modify existing version's required fields

## Why

**Benefits:**

- **Auditability**: Historical state always retrievable
- **Reference stability**: `{"$ref": "#/facts/..."}` has well-defined meaning
- **Reproducibility**: Same rule + same date = same result (legal requirement)
- **Append-only history**: Clear audit trail of changes
- **Alignment with legal sources**: Published laws are immutable (see RFC-005 Juriconnect)

**What is immutable:**

- Core semantics: `type`, `operator`, `conditions`
- Values: `value`, `defaultValue`
- Structure: `properties`, `roles`, `parameters`
- Validity periods: `validFrom`, `validTo`

**What is mutable:**

- Documentation: `description`, `notes`
- Extensions: Language-specific metadata (if in separate files)
- Presentation: `displayOrder`, `grouping`

**Entity vs Version UUIDs:**

- Entity UUID stable across all versions: `a1b2c3d4-... = "belastingtarief" concept`
- Version UUID unique per version: `v1-uuid = "belastingtarief as of 2018"`
- References use entity UUID; engine resolves to appropriate version by date

## Consequences

**Tradeoffs:**

- File size grows (mitigated: archive old versions, compression)
- Can't fix errors in published versions (mitigated: new version with `supersededBy` link)
- Schema evolution challenging (mitigated: migration tools)

## Implementation

**Validation**: Engines must check if version UUID exists and verify required fields match exactly.

**Git integration**: Immutability is logical (NRML semantics), not physical (git allows rewrites). Validation tools
should check commits don't violate immutability.

## Open Questions

1. **Corrections**: Should there be "amendment" mechanism for errors?
2. **Schema migrations**: How to handle NRML format upgrades?
3. **Deletion**: Can versions be deleted (GDPR vs. audit requirements)?

## Alternatives Rejected

- **Full mutability**: No auditability
- **Copy-on-write** (new UUID for any change): UUID explosion
- **Event sourcing**: Complex, could be engine implementation strategy

## Related

- RFC-003 (Versioning): How versions work
- RFC-006 (Identifiers): UUIDs vs content hashes
- RFC-005 (Reusability): Juriconnect references to immutable legal sources
- Notes: `doc/notes.md:61-64`
