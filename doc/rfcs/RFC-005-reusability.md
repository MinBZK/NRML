# RFC-005: Cross-File Reusability with JSON References

**Status:** Accepted | **Date:** 2025-09-02 | **Authors:** Wouter, Arvid, Tim and Anne

## Context

Rule systems share common definitions across regulations and domains (tax, benefits, licensing). Organizations need to maintain canonical definitions in one place and reference them.

## Decision

**Use standard JSON Reference (`$ref`) with URLs for cross-file linking.**

Supports:
- **Intra-file**: `{"$ref": "#/facts/uuid"}`
- **HTTPS**: `{"$ref": "https://nrml.gov.nl/person.json#/facts/uuid"}`
- **Relative paths**: `{"$ref": "file://../common/defs.json#/facts/uuid"}`
- **Juriconnect**: `{"$ref": "juriconnect://bwb:BWBR0005416/artikel/6/inhoud/lid/2#/facts/uuid"}`

## Why

**Benefits:**
- **Standard**: JSON Reference widely understood (JSON Schema, OpenAPI, AsyncAPI)
- **Uniform syntax**: Same `$ref` for local and remote references
- **Precise targeting**: JSON Pointer drills down to specific elements
- **Tool compatibility**: Existing libraries in all languages, IDE navigation support

## Juriconnect Integration

[Juriconnect](https://standaarden.overheid.nl/juriconnect) is Dutch standard for referencing laws/regulations. NRML extends it to resolve to NRML-encoded rule definitions.

**Resolution**:
1. **Parse**: `juriconnect://bwb:BWBR0005416/artikel/6/inhoud/lid/2`
   - Collection: `bwb` (Basis Wetten Bestand)
   - Identifier: `BWBR0005416`
   - Path: `/artikel/6/inhoud/lid/2`

2. **Resolve**: Map to `https://nrml.overheid.nl/bwb/BWBR0005416/artikel/6/inhoud/lid/2.nrml.json`

3. **Navigate**: Apply JSON Pointer `#/facts/leeftijd-uuid`

**Versioning**: Include effective date in URI:
```json
{"$ref": "juriconnect://bwb:BWBR0005416:2024-01-01/artikel/6/inhoud/lid/2#/facts/..."}
```

Aligns with NRML versioning (RFC-003).

**Registry**: Central government service (`nrml.overheid.nl`), cached resolvers, offline bundles.

**Benefits**: Canonical source, version alignment, immutability (RFC-007), interoperability.

## Implementation

**Resolution**:
1. Parse `$ref` to extract URL and fragment
2. Fetch referenced document (with caching)
3. Apply JSON Pointer
4. Validate target matches expected type
5. Substitute or lazy-load

**Security**: Allowlist trusted domains, sandboxed resolution, content validation.

## Consequences

**Tradeoffs:**
- Network dependency for HTTPS (mitigated: caching, bundling)
- Resolution complexity for multiple schemes
- Versioning coordination across files (mitigated: version pinning)

## Open Questions

1. **Versioning**: URL versioning (`/v1/`), content negotiation, or fragment selector?
2. **Canonicalization**: Is `./file.json` same as `file.json`?
3. **Offline support**: Bundling strategy?
4. **Juriconnect registry**: Who maintains Juriconnect → NRML mapping?
5. **Law versioning**: Use Juriconnect dates, NRML versions, or hybrid?
6. **Bidirectional**: Should legal texts reference NRML implementations?

## Alternatives Rejected

- **Custom import system**: Reinventing the wheel
- **Inline everything**: Massive duplication
- **Package manager**: Overkill for simple references

## Related

- RFC-003 (Versioning): Juriconnect dates align with NRML versions
- RFC-007 (Immutability): Published laws are immutable
- [JSON Reference](https://tools.ietf.org/html/draft-pbryan-zyp-json-ref-03)
- [JSON Pointer RFC 6901](https://tools.ietf.org/html/rfc6901)
- Notes: `doc/notes.md:45-53`
