# RFC-005: Cross-File Reusability with JSON References

**Status:** Proposed
**Date:** 2025-09-02
**Authors:** Wouter, Arvid, Tim and Anne

## Context

Real-world rule systems often share common definitions:

- Multiple regulations may reference the same definition of "natuurlijk persoon"
- Different domains (tax, benefits, licensing) may share address definitions
- Organizations want to maintain canonical definitions in one place

NRML needs a mechanism to link across files so definitions can be reused and domains can interoperate.

## Decision

**Use JSON Reference (`$ref`) with URLs for cross-file linking.**

NRML adopts standard JSON Reference (RFC 6901 JSON Pointer + JSON Reference draft) for both:

- **Intra-file references**: `{"$ref": "#/facts/a1b2-..."}`
- **Cross-file references**: `{"$ref": "https://example.com/nrml/persoon.json#/facts/a1b2-..."}`

## Rationale

### Why JSON Reference?

1. **Standard Mechanism**: JSON Reference is established and widely understood
    - Used by JSON Schema, OpenAPI, AsyncAPI
    - Supported by many libraries and tools
    - Clear specification (no need to invent custom syntax)

2. **Uniform Syntax**: Same `$ref` syntax for local and remote references
   ```json
   {
     "localRef": {"$ref": "#/facts/uuid-1"},
     "remoteRef": {"$ref": "https://nrml.gov.nl/definitions/person.json#/facts/uuid-2"}
   }
   ```

3. **Fragment Support**: JSON Pointer allows precise targeting
   ```json
   {"$ref": "https://example.com/tax.json#/facts/abc-123/properties/def-456"}
   ```

4. **Tooling Ecosystem**: Existing tools can resolve references
    - Dereferencing libraries in all major languages
    - Schema validators understand `$ref`
    - IDEs can follow references for navigation

### URL Schemes

Support multiple URL schemes for different use cases:

- **HTTPS**: Canonical definitions hosted on web
  ```json
  {"$ref": "https://nrml.gov.nl/core/v1/person.json#/facts/..."}
  ```

- **Relative paths**: References within same repository
  ```json
  {"$ref": "file://../common/definitions.json#/facts/..."}
  ```

- **Juriconnect**: Reference to Dutch legal sources (laws, regulations)
  ```json
  {"$ref": "juriconnect://bwb:BWBR0005416/artikel/6/inhoud/lid/2#/facts/leeftijd-uuid"}
  ```
  Resolves to NRML definitions published at canonical legal source locations

### Juriconnect Resolution

[Juriconnect](https://standaarden.overheid.nl/juriconnect) is a Dutch standard for referencing laws and regulations. NRML extends this to resolve to NRML-encoded rule definitions.

**Resolution Mechanism**:

1. **Parse Juriconnect URI**: Extract law identifier and structural path
   ```
   juriconnect://bwb:BWBR0005416/artikel/6/inhoud/lid/2
   ├── scheme: juriconnect
   ├── collection: bwb (Basis Wetten Bestand)
   ├── identifier: BWBR0005416
   └── path: /artikel/6/inhoud/lid/2
   ```

2. **Resolve to NRML repository**: Map to canonical NRML location
   ```
   https://nrml.overheid.nl/bwb/BWBR0005416/artikel/6/inhoud/lid/2.nrml.json
   ```

3. **Apply JSON Pointer**: Navigate to specific fact within NRML document
   ```json
   #/facts/leeftijd-uuid
   ```

**Versioning Considerations**:

Laws change over time (amendments, revocations). Juriconnect URIs should include version information:

```json
{
  "$ref": "juriconnect://bwb:BWBR0005416:2024-01-01/artikel/6/inhoud/lid/2#/facts/..."
}
```

Where `:2024-01-01` indicates the law version effective on that date, aligning with NRML's versioning strategy (RFC-003).

**Registry Authority**:

- **Central registry**: `nrml.overheid.nl` or similar government-maintained service
- **Caching**: Resolvers should cache NRML documents from legal sources
- **Offline bundles**: Tools can pre-fetch and bundle legal NRML for offline use

**Benefits**:

- **Canonical source**: Link directly to authoritative legal definitions
- **Version alignment**: Law versions match NRML versions
- **Immutability**: Published laws are immutable (aligns with RFC-007)
- **Interoperability**: Multiple rule systems can reference same legal sources

## Consequences

### Positive

- **Standard approach**: No custom reference mechanism to learn
- **Tool compatibility**: Works with existing JSON tooling
- **Precise targeting**: JSON Pointer allows drilling down to specific elements
- **Version control**: Can reference specific versions via URLs
  ```json
  {"$ref": "https://nrml.gov.nl/definitions/person/v2.1.json#/facts/..."}
  ```
- **Local development**: Relative paths work for local file references

### Negative

- **Network dependency**: HTTPS references require network access
- **Resolution complexity**: Need resolver that handles multiple schemes
- **Caching**: Should cache remote references for performance
- **Versioning coordination**: Referenced files may change

### Mitigations

- **Caching**: Implement smart caching for remote references
- **Bundling**: Tools can "bundle" all references into single file for distribution
- **Validation**: Check that referenced paths exist and match expected schema
- **Version pinning**: Encourage version-specific URLs (not `latest`)

## Implementation Considerations

### Reference Resolution

Engines should:

1. **Parse** `$ref` to extract URL and fragment
2. **Fetch** referenced document (with caching)
3. **Apply** JSON Pointer to navigate to target
4. **Validate** that target matches expected type
5. **Substitute** reference with resolved value (or keep lazy)

### Circular References

**Challenge**: What if A references B which references A?

**Approaches**:

- Detect cycles during resolution and error
- Allow cycles but use lazy evaluation
- Require references to be acyclic (validation rule)

**Decision**: TBD (implementation-specific for now)

### Security

**Risks**:

- Malicious URLs could trigger requests to attacker-controlled servers
- SSRF (Server-Side Request Forgery) if server-side resolution

**Mitigations**:

- Allowlist trusted domains for remote references
- Sandboxed resolution (no file:// access, restricted network)
- Content validation (ensure fetched content is valid NRML)

## Open Questions

1. **Versioning**: How do we handle references to definitions that evolve?
    - Option A: URL includes version (`/v1/`, `/v2/`)
    - Option B: Content negotiation via headers
    - Option C: Fragment includes version selector

2. **Canonicalization**: How to ensure reference equivalence?
    - Is `./file.json` same as `file.json`?
    - Is `https://example.com/file.json` same as `https://example.com/file.json#/`?

3. **Offline support**: How to work without network?
    - Bundle all references into single file?
    - Local mirror/cache of remote definitions?

4. **Juriconnect resolution**: Who maintains the Juriconnect → NRML mapping?
    - Government registry (`nrml.overheid.nl`)?
    - Decentralized resolution?
    - Community-maintained mappings?

5. **Law versioning**: How to handle law amendments and temporal validity?
    - Use Juriconnect version syntax (`:YYYY-MM-DD`)?
    - Rely on NRML's internal versioning?
    - Hybrid approach (both)?

6. **Bidirectional references**: Should legal texts themselves reference NRML?
    - One-way: NRML → Law (simpler)
    - Bidirectional: Law ↔ NRML (enables law publication systems to link to implementations)

## Alternatives Considered

### Custom Import System

**Approach**: NRML-specific `import` or `include` mechanism

```json
{
  "imports": [
    "common/person.json",
    "common/address.json"
  ],
  "facts": {
    "ref-to-person": {
      "use": "person:natural-person"
    }
  }
}
```

**Pros**: Could optimize for NRML use cases
**Cons**: Reinventing the wheel, no tool support, learning curve

**Rejected because**: JSON Reference is standard and sufficient

### Inline Everything

**Approach**: No cross-file references, duplicate definitions everywhere

**Pros**: No resolution complexity, fully self-contained
**Cons**: Massive duplication, maintenance nightmare, inconsistency risk

**Rejected because**: Untenable for real-world use

### Package Manager

**Approach**: npm-style dependency management for NRML files

**Pros**: Versioning, caching, semantic versioning
**Cons**: Heavy infrastructure, overkill for simple references

**Rejected because**: JSON Reference + URL versioning is simpler and sufficient

## References

- Notes on reusability: `doc/notes.md:45-53`
- [JSON Reference Draft](https://tools.ietf.org/html/draft-pbryan-zyp-json-ref-03)
- [JSON Pointer RFC 6901](https://tools.ietf.org/html/rfc6901)
