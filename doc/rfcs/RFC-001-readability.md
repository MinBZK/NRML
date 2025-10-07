# RFC-001: Readability Goals and Format Choice

**Status:** Accepted | **Date:** 2025-09-02 | **Authors:** Wouter, Arvid and Anne

## Context

Tension between human readability and machine processability. Different serialization formats (JSON, YAML, XML, custom DSLs) offer different tradeoffs.

## Decision

**The goal of NRML core is NOT to be human readable.**

- NRML core uses **strict JSON**
- Accept UUID identifiers (not human-friendly)
- Human readability via **transformations** (Regelspraak, Gegevenspraak)
- Prioritize precision, parsability, no ambiguity

## Why

**Separation of concerns:**
- Core optimizes for unambiguous semantics, programmatic manipulation, JSON Schema validation, efficient processing
- Human-friendly views via domain-specific renderers, specialized editors, multiple presentation formats
- UUIDs ensure global uniqueness, unambiguous references, no naming conflicts

**JSON over YAML:**
```yaml
# YAML footguns:
country: NO    # Boolean false in some parsers!
country: "NO"  # String "NO"
version: 1.0   # Number
version: "1.0" # String
```

JSON has no implicit type coercion, simpler specification, better JSON Schema tooling, predictability.

**Benefits:**
- Unambiguous parsing
- Precise validation via JSON Schema
- Simple tooling (every language has robust JSON support)
- Clear separation (core vs presentation)

**Tradeoffs:**
- Raw JSON verbose
- Not human-friendly
- Manual editing error-prone
- **Mitigations**: Editors resolve UUIDs to names, renderers for review, JSON Schema validation

## Alternatives Rejected

- **YAML**: Footguns (Norway problem), ambiguous parsing
- **Custom DSL**: Need custom parser, tooling from scratch
- **XML**: Even more verbose, less ergonomic
- **JSON5/JSONC**: Not standard, limited tool support

## Related

- [Norway Problem](https://hitchdev.com/strictyaml/why/implicit-typing-removed/)
- Notes: `doc/notes.md:5-10`
