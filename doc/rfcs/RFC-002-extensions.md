# RFC-002: Extension Mechanism for Domain-Specific Requirements

**Status:** Proposed
**Date:** 2025-09-02
**Authors:** Arvid and Anne

## Context

Different domains and use cases require different metadata. For example:
- Regelspraak/Gegevenspraak require language-specific metadata (Dutch translations, article forms, etc.)
- Regulatory frameworks may require additional validation
- Different deployment contexts may need domain-specific fields

The question is: Should language-related metadata (and other domain-specific requirements) be in NRML core, or should we have an extension mechanism?

## Decision

**Status: Still under consideration**

NRML should support extensions, but the mechanism is not yet finalized.

## Options Under Consideration

We have identified two main approaches:

### Option A: Separate Extension Files

Extensions as separate JSON files that can be merged with core NRML:

```json
// core.nrml.json
{
  "0fe3c5a2-a33a-4a98-9abc-a98929783499": {
    "versions": [...]
  }
}

// nl-regelspraak-extension.json
{
  "0fe3c5a2-a33a-4a98-9abc-a98929783499": {
    "article": "de",
    "plural": "vluchten",
    "translations": {...}
  }
}
```

**Merge logic**: Deep merge by UUID, extension fields overlay on core

### Option B: Separate Schema Extensions

Extensions as additional JSON Schema that extends core schema:

```json
// core-schema.json
{
  "type": "object",
  "properties": {
    "name": {"type": "string"}
  }
}

// regelspraak-schema.json
{
  "allOf": [
    {"$ref": "core-schema.json"},
    {
      "properties": {
        "article": {"type": "string"},
        "plural": {"type": "string"}
      },
      "required": ["article", "plural"]
    }
  ]
}
```

**Validation**: Core validates against core schema; extended versions validate against extended schema

## Rationale

Both approaches enable:

1. **Core Minimalism**: NRML core stays focused on essential semantics
2. **Domain Flexibility**: Different domains can add required metadata
3. **Reusability**: Core NRML can be used across contexts
4. **Optional Requirements**: Extensions can make certain fields required that are optional in core

### Option A Advantages

- **Runtime merging**: Can combine core + extensions dynamically
- **Simpler conceptually**: Just overlay more data
- **Multiple extensions**: Can layer multiple extensions

### Option B Advantages

- **Stronger validation**: JSON Schema enforces extension requirements
- **Clear contracts**: Schema explicitly declares what's valid
- **Composition**: Standard JSON Schema `allOf` mechanism
- **Tool support**: Standard schema validation tools work

## Open Questions

1. Can both approaches coexist? (Schema for validation + separate files for data)
2. How do extensions compose? (If two extensions add same field?)
3. Should extensions be namespaced? (e.g., `nl:article` vs `article`)
4. How do tools discover available extensions?
5. Should core NRML files reference which extensions they comply with?

## Consequences

### Positive (General)

- Keeps core NRML clean and minimal
- Different domains can coexist without conflict
- Extensions can evolve independently
- Same core NRML can support multiple renderings

### Negative (General)

- More complex tooling (need to handle extensions)
- Potential for fragmentation if extensions are incompatible
- Need clear conventions for extension naming and namespacing

## Next Steps

1. Prototype both approaches with real Regelspraak/Gegevenspraak use cases
2. Evaluate composability: Can we merge multiple extensions?
3. Define extension discovery/registration mechanism
4. Document extension authoring guidelines
5. Update this RFC when decision is finalized

## Alternatives Considered

### Put Everything in Core

**Pros**: Simpler, single schema, no extension complexity
**Cons**: Core becomes bloated with domain-specific concerns, not reusable across contexts

### Custom Extension System

**Pros**: Optimized for NRML's specific needs
**Cons**: Reinventing the wheel, no standard tooling

## References

- Notes on extensions: `doc/notes.md:12-25`
