# RFC-008: Formal Transformations with XSLT

**Status:** Accepted | **Date:** 2025-09-02 | **Authors:** Wouter and Anne

## Context

NRML is machine-oriented (RFC-001). To be useful for humans, it must transform to readable representations:
Regelspraak (Dutch rule text), Gegevenspraak (data dictionary), documentation.

## Decision

**Transformations from NRML should use formal transformation languages, with XSLT preferred.**

- **Formal** (XSLT, JSONata) preferred over imperative code
- **XSLT** is primary language for NRML project
- Custom code acceptable for prototyping, should be replaced with formal transformations

## Why

**Benefits:**

- **Declarative**: Describes **what** to transform, not **how**
- **Verifiable**: Formal semantics enable correctness reasoning
- **Reusable**: Templates compose and can be overridden
- **Standardized**: XSLT is W3C standard (25+ years, stable implementations)

**XSLT specifically:**

- **JSON support**: XSLT 3.0 handles JSON natively via `json-to-xml()`
- **Mature ecosystem**: Fast processors (Saxon), debugging tools, extensive libraries
- **Complex transformations**: Recursive templates, multi-pass, cross-references
- **Multiple outputs**: Text, HTML, XML, JSON from single transformation

**Current pipeline:**

```
NRML JSON → json-to-xml → XSLT → Dutch text (Regelspraak)
```

Works well: complex grammar, article selection ("de"/"het"), reference chains, pluralization.

**Tradeoffs:**

- Learning curve (XSLT unfamiliar to many)
- Verbosity compared to template languages
- Limited libraries vs Python/JavaScript
- Performance (mitigated: Saxon is fast)

**Mitigations**: Documentation, starter templates, testing, modern processors (Saxon-HE/EE).

## Implementation

**Current**: `transformations/regelspraak.xsl` (~800+ lines) transforms NRML → Dutch
**Planned**: Gegevenspraak transformation for data dictionary

**Development**:

```bash
./scripts/transform transformations/regelspraak.xsl toka.nrml.json output.txt
diff output.txt toka.regelspraak.groundtruth.txt
```

**Testing**: Unit tests (individual templates), integration tests (full NRML), ground truth comparison, regression
tests.

## Alternatives Rejected

- **Template languages** (Jinja2, Mustache): Not formal, hard to verify
- **Custom imperative code**: Not declarative, hard to verify, no composability
- **JSONata**: Less mature, smaller ecosystem (may revisit for JSON-to-JSON)
- **ANTLR/Parser generators**: Overkill, not declarative

## Open Questions

1. **Performance**: Fast enough for large NRML files? (Currently: yes)
2. **Debugging**: How to improve? (XSLT debuggers, better errors, unit tests)
3. **Modularity**: How to organize large stylesheets? (Consider splitting into modules)

## Related

- RFC-001 (Readability): NRML core not human-readable; transformations provide that
- RFC-002 (Extensions): Transformations may need extension metadata
- Notes: `doc/notes.md:66-69`
- [XSLT 3.0](https://www.w3.org/TR/xslt-30/), [Saxon](https://www.saxonica.com/)
