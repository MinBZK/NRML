# RFC-007: Immutability Constraints

**Status:** Accepted
**Date:** 2025-09-02
**Authors:** Arvid and Anne

## Context

Legal and regulatory rules must be auditable and reproducible. If we say "this rule applied on 2019-06-15," we must be
able to retrieve exactly what that rule was, not what it has since become. This requires immutability constraints on how
NRML entities can change over time.

Related to RFC-003 (Versioning) and RFC-006 (Identifiers).

## Decision

**All required fields of a version are immutable.**

Once a version of an entity is created, its required fields cannot be changed. Any change to a required field results in
a **new version** with a **new UUID**.

### What This Means

```json
{
  "facts": {
    "a1b2c3d4-...": {
      "name": {
        "nl": "belastingtarief"
      },
      "versions": [
        {
          "id": "v1-uuid",
          "validFrom": "2018-01-01",
          "validTo": "2019-12-31",
          "value": {
            "amount": 5.50,
            "unit": "€"
          }
          // These fields are IMMUTABLE
        }
      ]
    }
  }
}
```

**Allowed**: Add a new version

```json
{
  "versions": [
    // Old version unchanged
    {
      "id": "v1-uuid",
      "validFrom": "2018-01-01",
      ...
    },
    // New version added
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

**Not allowed**: Modify existing version

```json
{
  "versions": [
    // WRONG: Changing v1's value
    {
      "id": "v1-uuid",
      "validFrom": "2018-01-01",
      "value": {
        "amount": 5.75,
        "unit": "€"
      }
    }
  ]
}
```

## Rationale

### Why Immutability?

1. **Auditability**: Must be able to reconstruct historical state
    - "What was the tax rate on 2019-06-15?" should always return the same answer
    - Changes to historical data undermine trust

2. **Reference Stability**: References point to specific semantic versions
    - `{"$ref": "#/facts/a1b2-..."}` has well-defined meaning
    - If content could mutate, references become ambiguous

3. **Reproducibility**: Running the same rule on the same date should always yield same result
    - Legal requirement for many regulatory systems
    - Essential for testing and verification

4. **Append-Only History**: Changes are additions, not mutations
    - Clear audit trail of what changed and when
    - Can track evolution of rules over time

5. **Alignment with Legal Sources**: Published laws and regulations are immutable
    - Once a law is published, it cannot be changed retroactively
    - Amendments create new versions, old versions remain valid for their period
    - NRML immutability mirrors legal immutability (see RFC-005 Juriconnect references)

### What Is Immutable?

**Immutable (required fields)**:

- Core semantics: `type`, `operator`, `conditions`
- Values: `value`, `defaultValue`
- Structure: `properties`, `roles`, `parameters`
- Validity periods: `validFrom`, `validTo`

**Mutable (optional metadata)**:

- Documentation: `description`, `notes`
- Extensions: Language-specific metadata (if in separate extension files)
- Presentation: `displayOrder`, `grouping`

### Version vs Entity

**Entity UUID**: Stable across all versions

```
a1b2c3d4-...  = "belastingtarief" concept
```

**Version UUID**: Unique per version (if we add version UUIDs—see RFC-003 open questions)

```
v1-uuid = "belastingtarief as of 2018"
v2-uuid = "belastingtarief as of 2020"
```

References use **entity UUID** and engine resolves to appropriate version based on context (effective date).

## Consequences

### Positive

- **Trust**: Historical data is trustworthy
- **Reproducibility**: Same input + same date = same output, always
- **Clear history**: Can see exactly what changed and when
- **Simplified reasoning**: No "action at a distance" from mutations

### Negative

- **Storage growth**: Can't delete old versions
- **Correction difficulty**: Can't fix errors in published versions
- **Schema evolution**: Hard to migrate if version schema changes

### Mitigations

#### Storage Growth

- **Archiving**: Move very old versions to separate archive files
- **Compression**: Historical versions compress well (similar content)

#### Corrections

If a version has an error:

1. **Minor error** (typo in description): Correct if it's mutable metadata
2. **Semantic error** (wrong value): Create new version, mark old as deprecated
   ```json
   {
     "versions": [
       {
         "id": "v1-uuid",
         "validFrom": "2018-01-01",
         "value": {"amount": 5.50, "unit": "€"},
         "deprecated": true,
         "supersededBy": "v2-uuid"
       },
       {
         "id": "v2-uuid",
         "validFrom": "2018-01-01",  // Same date
         "value": {"amount": 5.00, "unit": "€"}  // Corrected
       }
     ]
   }
   ```

#### Schema Evolution

- **Backward compatible changes**: Add optional fields
- **Breaking changes**: New major version of NRML format
- **Migration tools**: Can transform old NRML to new format

## Implementation

### Validation

JSON Schema can enforce immutability at **create time** but not at **update time** (schema doesn't see previous state).

**Solution**: NRML engines must validate:

1. Check if version UUID already exists
2. If exists, verify all required fields match exactly
3. If different, reject the change

### Git Integration

Immutability in NRML is **logical** (semantic constraint), not **physical** (git prevents rewrites).

- Git commits can modify NRML files (physical mutability)
- NRML semantics require version immutability (logical immutability)
- Validation tools should check that git commits don't violate immutability

## Open Questions

1. **Corrections**: Should there be an "amendment" mechanism for errors?
    - Current answer: Use new version with `supersededBy` link

2. **Schema migrations**: How to handle NRML format upgrades?
    - Option: Migration tool transforms old → new format
    - Option: Engines support multiple format versions

3. **Deletion**: Can versions ever be deleted (e.g., for legal compliance like GDPR)?
    - Tension: Right to be forgotten vs. regulatory audit requirements

## Alternatives Considered

### Full Mutability

**Approach**: Allow changing any field at any time

**Pros**: Flexible, easy to fix mistakes
**Cons**: No auditability, no reproducibility, references become ambiguous

**Rejected because**: Regulatory compliance requires immutability

### Copy-on-Write

**Approach**: Any change creates a new UUID (even for optional fields)

**Pros**: Maximum immutability
**Cons**: Explosion of UUIDs, hard to track "same entity", breaks references on minor changes

**Rejected because**: Too rigid; optional metadata should be mutable

### Event Sourcing

**Approach**: Store only events (create, update, delete) and compute state

**Pros**: Perfect audit trail, can replay history
**Cons**: Complex implementation, requires event replay to query

**Deferred**: Could be an implementation strategy for NRML engines, but not required by format

## Related RFCs

- **RFC-003 (Versioning)**: How versions work
- **RFC-006 (Identifiers)**: UUIDs vs content hashes
- **RFC-004 (Variable Keys)**: UUID-based lookup
- **RFC-005 (Reusability)**: Juriconnect references to immutable legal sources

## References

- Notes on immutability: `doc/notes.md:61-64`
