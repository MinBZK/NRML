# RFC-001: Readability Goals and Format Choice

**Status:** Accepted
**Date:** 2025-09-02
**Authors:** Wouter, Arvid and Anne

## Context

When designing a rule language format, there's a tension between human readability and machine processability. Different
serialization formats (JSON, YAML, XML, custom DSLs) offer different tradeoffs. NRML core needs to establish its
position on this spectrum.

## Decision

**The goal of NRML core is NOT to be human readable.**

- NRML core uses **strict JSON** as its serialization format
- We accept UUID identifiers that are not easy for humans to navigate
- Human readability is achieved through **renderers/transformations** of NRML (e.g., Regelspraak, Gegevenspraak)
- The core format prioritizes precision, parsability, and avoiding ambiguity

## Rationale

### Why Not Human Readable Core?

1. **Separation of Concerns**: Core representation should optimize for:
    - Unambiguous semantics
    - Easy programmatic manipulation
    - Precise validation via JSON Schema
    - Efficient processing by engines

2. **Rendering Layer**: Human-friendly views are better served by:
    - Domain-specific renderers (Regelspraak for Dutch rule text)
    - Specialized editors with UUIDs resolved to names
    - Multiple presentation formats for different audiences

3. **UUIDs Are Acceptable**: While UUIDs are not human-friendly:
    - They ensure global uniqueness
    - They enable unambiguous references
    - They prevent naming conflicts
    - Tooling can resolve them to names when needed

### Why JSON Over YAML?

We choose **strict JSON** over YAML because:

1. **YAML Footguns**: YAML has notorious parsing issues:
   ```yaml
   # These are all different in YAML:
   country: NO    # Boolean false in some parsers!
   country: "NO"  # String "NO"
   version: 1.0   # Number
   version: "1.0" # String
   ```

2. **No Implicit Type Coercion**: JSON's explicit typing prevents:
    - Accidental boolean conversion (Norway problem)
    - Unexpected number/string coercion
    - Locale-dependent parsing

3. **Simpler Specification**: JSON has one canonical spec; YAML has multiple versions with subtle differences

4. **Better Tooling**: JSON Schema validation is more mature and widely supported

5. **Predictability**: JSON's stricter syntax means fewer surprises

## Consequences

### Positive

- **Unambiguous parsing**: No YAML-style gotchas
- **Precise validation**: JSON Schema provides strong guarantees
- **Simple tooling**: Every language has robust JSON support
- **Clear separation**: Core format vs presentation layer
- **UUID safety**: No naming conflicts across NRML files

### Negative

- **Raw JSON is verbose**: More characters than YAML or DSLs
- **Not human-friendly**: UUIDs require tooling to understand
- **Manual editing is hard**: Direct JSON editing is error-prone

### Mitigations

- **Editors/tooling**: Build tools that present UUIDs as resolved names
- **Renderers**: Provide Regelspraak/Gegevenspraak transformations for review
- **Validation**: JSON Schema catches errors that YAML might silently accept

## Alternatives Considered

### YAML

**Pros**: More concise, less punctuation, human-friendly
**Cons**: Footguns (Norway problem), ambiguous parsing, version fragmentation

### Custom DSL

**Pros**: Optimal syntax for domain, maximum readability
**Cons**: Need custom parser, tooling ecosystem from scratch, harder validation

### XML

**Pros**: Mature validation (XSD), good transformation support (XSLT)
**Cons**: Even more verbose than JSON, less ergonomic for modern tools

### JSON5/JSONC

**Pros**: Comments, trailing commas, less strict than JSON
**Cons**: Not standard, limited tool support, loses JSON's simplicity

## References

- [Norway Problem in YAML](https://hitchdev.com/strictyaml/why/implicit-typing-removed/)
- Notes on readability: `doc/notes.md:5-10`
