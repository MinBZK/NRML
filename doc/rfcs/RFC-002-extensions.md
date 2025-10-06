# RFC-002: Extension Mechanism for Domain-Specific Requirements

**Status:** Proposed | **Date:** 2025-09-02 | **Authors:** Arvid and Anne

## Context

Different domains require different metadata: Regelspraak needs Dutch translations/articles, regulatory frameworks need validation, deployment contexts need domain fields. Should language metadata be in NRML core or via extensions?

## Decision

**Status: Under consideration**

NRML should support extensions, mechanism not yet finalized.

## Options Under Consideration

### Option A: Separate Extension Files

Extensions as separate JSON merged with core:

```json
// core.nrml.json
{"uuid": {"versions": [...]}}

// nl-regelspraak-extension.json
{"uuid": {"article": "de", "plural": "vluchten"}}
```

**Merge logic**: Deep merge by UUID

### Option B: Schema Extensions

JSON Schema extends core schema:

```json
// regelspraak-schema.json
{
  "allOf": [
    {"$ref": "core-schema.json"},
    {"properties": {"article": {"type": "string"}}}
  ]
}
```

## Why

**Benefits (both options):**
- Core minimalism (focused on semantics)
- Domain flexibility (add required metadata)
- Reusability (core works across contexts)
- Optional requirements (extensions make fields required)

**Option A advantages**: Runtime merging, simpler conceptually, multiple extensions
**Option B advantages**: Stronger validation, clear contracts, standard JSON Schema composition

**Tradeoffs**: More complex tooling, potential fragmentation, need clear conventions

## Open Questions

1. Can both approaches coexist?
2. How do extensions compose if two add same field?
3. Should extensions be namespaced (`nl:article` vs `article`)?
4. How do tools discover extensions?
5. Should core files reference which extensions they comply with?

## Next Steps

1. Prototype both with Regelspraak/Gegevenspraak
2. Evaluate composability
3. Define discovery/registration
4. Document authoring guidelines
5. Update RFC when finalized

## Alternatives Rejected

- **Everything in core**: Core bloated, not reusable
- **Custom extension system**: Reinventing wheel, no standard tooling

## Related

- Notes: `doc/notes.md:12-25`
