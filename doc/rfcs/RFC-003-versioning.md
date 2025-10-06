# RFC-003: Versioning Strategy

**Status:** Accepted | **Date:** 2025-09-02 | **Authors:** Wouter, Arvid and Anne

## Context

Legal rules evolve over time (tax rates change, criteria amended, new exceptions). NRML needs strategy for representing changes. Should versioning be in NRML or external (git)? Should `validFrom`/`validTo` be required?

## Decision

**Versioning is embedded in NRML at the fact/definition level.**

1. **Versions part of NRML**: Each fact has `versions` array with `validFrom`/`validTo`
2. **Both fields optional**: Allowing flexibility
3. **All versions kept**: Historical versions remain (immutability, RFC-007)
4. **No git dependency**: End users access historical facts without version control
5. **UUID stability**: References use UUIDs stable across versions

```json
{
  "facts": {
    "a1b2c3d4-...": {
      "name": {"nl": "belastingtarief"},
      "versions": [
        {
          "validFrom": "2018-01-01",
          "validTo": "2019-12-31",
          "value": {"amount": 5.50, "unit": "€"}
        },
        {
          "validFrom": "2020-01-01",
          "value": {"amount": 6.00, "unit": "€"}
        }
      ]
    }
  }
}
```

## Why

**In-NRML versioning benefits:**
- **Efficient references**: `{"$ref": "#/facts/uuid/..."}` works across versions; runtime resolves by date
- **Maintain relationships**: Object identity persists ("belastingtarief" 2018 and 2020 are same concept)
- **User accessibility**: Non-technical users explore historical rules; temporal queries straightforward
- **Explicit semantics**: Engine handles resolution with clear overlap rules

**Optional validFrom/validTo**: Flexibility for timeless facts, incremental adoption, defaults (missing validFrom = "from beginning", missing validTo = "indefinitely")

**Benefits:**
- Temporal queries natively supported
- Complete audit trail in single file
- Stable UUID references
- No external dependencies

**Tradeoffs:**
- File size growth → **mitigate**: Archive old versions
- Engine complexity → **mitigate**: JSON Schema enforces non-overlapping
- Potential conflicts → **mitigate**: Version-aware editors

## Open Questions

1. **Overlapping periods**: Error (enforce non-overlap)? Priority (later wins)? Undefined?
2. **Version identity**: Should versions have own UUIDs?
3. **Cross-version queries**: API design for "all versions of X"?
4. **Juriconnect alignment**: Legal source versions include dates (`juriconnect://bwb:BWBR0005416:2024-01-01/...`). How to align NRML versioning with external legal source versions?

## Alternatives Rejected

- **Git-based versioning**: End users need git knowledge, no semantic versioning, hard temporal queries, ambiguous references
- **Separate files per version**: References break, lose entity identity, hard timeline queries
- **External version metadata**: Two files to sync, same problems, more fragmentation

## Related

- RFC-007 (Immutability)
- RFC-005 (Reusability - Juriconnect versioning)
- Notes: `doc/notes.md:27-39`
