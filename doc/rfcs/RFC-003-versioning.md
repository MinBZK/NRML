# RFC-003: Versioning Strategy

**Status:** Accepted
**Date:** 2025-09-02
**Authors:** Wouter, Arvid and Anne

## Context

Legal rules evolve over time. Tax rates change, eligibility criteria are amended, new exceptions are added. NRML needs a
strategy for representing these changes over time. Key questions:

1. Should versioning be in the NRML definition or external (e.g., git)?
2. Should `validFrom` and `validTo` be required or optional?
3. How do we maintain references across versions?
4. How do end users access historical versions?

## Decision

**Versioning is embedded in NRML at the fact/definition level, not external.**

### Version Management Principles

1. **Versions are part of NRML**: Each fact has a `versions` array with `validFrom`/`validTo` timestamps
2. **Both fields are optional**: `validFrom` and `validTo` are optional, allowing flexibility
3. **All versions are kept**: Historical versions remain in NRML files (immutability, see RFC-007)
4. **No reliance on git**: End users can access historical facts without using version control
5. **UUID-based references**: References use UUIDs, which remain stable across versions

### Example Structure

```json
{
  "facts": {
    "a1b2c3d4-...": {
      "name": {
        "nl": "belastingtarief"
      },
      "versions": [
        {
          "validFrom": "2018-01-01",
          "validTo": "2019-12-31",
          "value": {
            "amount": 5.50,
            "unit": "€"
          }
        },
        {
          "validFrom": "2020-01-01",
          "value": {
            "amount": 6.00,
            "unit": "€"
          }
        }
      ]
    }
  }
}
```

## Rationale

### Why In-NRML Versioning?

1. **Efficient Reference Resolution**: References point to UUIDs, not version-specific copies
    - `{"$ref": "#/facts/a1b2c3d4-.../properties/xyz"}` works across all versions
    - Runtime resolves to the correct version based on effective date
    - No need for version-aware reference syntax

2. **Maintain Relationships**: Object identity persists across versions
    - "Belastingtarief" in 2018 and 2020 are the same concept
    - Only the value changed, the entity remains
    - Allows queries like "what changed about this fact?"

3. **User Accessibility**: End users shouldn't need git
    - Non-technical users can explore historical rules
    - Tools can show timelines without version control knowledge
    - Temporal queries ("what was the rate on 2019-06-15?") are straightforward

4. **Explicit Semantics**: NRML engine handles version resolution
    - Clear semantics for overlapping periods (error or priority rules)
    - Explicit `validFrom`/`validTo` in data, not inferred from commit history
    - Version logic is part of language specification

### Why Optional `validFrom`/`validTo`?

- **Flexibility**: Some facts are timeless or version is managed externally
- **Incremental Adoption**: Can add versioning to specific facts without refactoring everything
- **Defaults**: Missing `validFrom` = "from the beginning"; missing `validTo` = "indefinitely"

## Consequences

### Positive

- **Temporal queries**: "What was true on date X?" is natively supported
- **Audit trails**: Complete history in single file
- **Stable references**: UUIDs don't change when values change
- **No external dependencies**: Don't need git to understand versioning

### Negative

- **File size growth**: Files grow as versions accumulate
- **Complexity**: NRML engines must handle version resolution
- **Potential conflicts**: Overlapping `validFrom`/`validTo` need clear semantics

### Mitigations

- **Archiving**: Very old versions can be moved to archive files if needed
- **Validation**: JSON Schema can enforce non-overlapping validity periods
- **Tooling**: Version-aware editors can help manage complexity

## Open Questions

1. **Overlapping periods**: What if two versions have overlapping validity?
    - Error (enforce non-overlap)?
    - Priority (later version wins)?
    - Undefined (implementation-specific)?

2. **Version identity**: Should versions have their own UUIDs?
    - Pro: Can reference specific versions explicitly
    - Con: More complexity, most references want "current version"

3. **Cross-version queries**: How to query "all versions of fact X"?
    - Engine API design question

4. **External legal source versioning**: How to align with versioned legal sources (Juriconnect)?
    - Juriconnect references include date: `juriconnect://bwb:BWBR0005416:2024-01-01/...`
    - Should NRML version resolution consider external source versions?
    - How to handle when law version doesn't match NRML version?

## Alternatives Considered

### Git-based Versioning

**Approach**: Use git commits to track changes; NRML files have no version metadata

**Pros**:

- Simpler NRML structure
- Leverage existing version control
- Diff tools show changes

**Cons**:

- End users need git knowledge
- No semantic versioning (commit != logical version)
- Hard to query "what was true on date X?"
- References become ambiguous across commits

**Rejected because**: NRML should be self-contained for end users

### Separate Files Per Version

**Approach**: `tax-2018.nrml.json`, `tax-2019.nrml.json`, etc.

**Pros**:

- Each file is simpler
- Easy to archive old versions

**Cons**:

- References across files break when versions change
- Lose entity identity (2018 tax rate vs 2019 tax rate are separate)
- Hard to query timelines

**Rejected because**: Breaks reference stability and entity identity

### External Version Metadata

**Approach**: NRML files + separate `versions.json` mapping

**Pros**:

- Core NRML stays simpler
- Version metadata managed separately

**Cons**:

- Two files to keep in sync
- Still need to solve same problems (resolution, etc.)
- More fragmentation

**Rejected because**: Doesn't simplify meaningfully, adds coordination burden

## References

- Notes on versioning: `doc/notes.md:27-39`
- Related: RFC-007 (Immutability)
- Related: RFC-005 (Reusability - Juriconnect versioning aligns with NRML versioning for legal sources)
