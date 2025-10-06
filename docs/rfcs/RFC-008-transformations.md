# RFC-008: Formal Transformations with XSLT

**Status:** Accepted
**Date:** 2025-09-02
**Authors:** Arvid and Anne

## Context

NRML is a machine-oriented format (RFC-001). To be useful for human stakeholders, it must be transformed into readable representations:
- **Regelspraak**: Natural language rule text (Dutch)
- **Gegevenspraak**: Data dictionary/specification
- **Documentation**: User guides, decision tables, etc.

Different transformation approaches exist (custom code, template engines, transformation languages). Which should NRML prefer?

## Decision

**Transformations from NRML to other representations should use formal transformation languages, with XSLT preferred.**

- **Formal transformations** (XSLT, JSONata, etc.) are preferred over imperative code
- **XSLT** is the primary transformation language for the NRML project
- Custom code is acceptable for prototyping but should be replaced with formal transformations

## Rationale

### Why Formal Transformation Languages?

1. **Declarative**: Describes **what** to transform, not **how**
   ```xsl
   <xsl:template match="fact[@type='rule']">
     <xsl:apply-templates select="condition"/>
     <xsl:text> dan </xsl:text>
     <xsl:apply-templates select="conclusion"/>
   </xsl:template>
   ```
   vs. imperative code:
   ```python
   def transform_rule(rule):
       result = ""
       result += transform_condition(rule['condition'])
       result += " dan "
       result += transform_conclusion(rule['conclusion'])
       return result
   ```

2. **Verifiable**: Formal semantics enable reasoning about transformations
   - Can prove properties (e.g., "all rules are rendered")
   - Can validate correctness formally
   - Academic research on transformation correctness applies

3. **Reusable**: Templates compose and can be overridden
   ```xsl
   <!-- Base template -->
   <xsl:template match="fact">
     <xsl:value-of select="name"/>
   </xsl:template>

   <!-- Override for specific case -->
   <xsl:template match="fact[@type='special']" priority="1">
     <strong><xsl:value-of select="name"/></strong>
   </xsl:template>
   ```

4. **Standardized**: XSLT is a W3C standard
   - Stable specification (XSLT 1.0 from 1999, still widely used)
   - Multiple implementations (Saxon, Xalan, libxslt)
   - Extensive documentation and tooling

### Why XSLT Specifically?

1. **XML ↔ JSON**: XSLT 3.0 supports JSON natively
   ```xsl
   <xsl:variable name="nrml" select="json-to-xml(unparsed-text('rules.nrml.json'))"/>
   ```

2. **Mature Ecosystem**: 25+ years of development
   - Fast processors (Saxon-EE)
   - Debugging tools
   - Extensive libraries

3. **Complex Transformations**: XSLT handles sophisticated logic
   - Recursive templates
   - Multi-pass transformations
   - Cross-references and lookups

4. **Multiple Output Formats**: Single transformation can output text, HTML, XML, JSON
   ```xsl
   <xsl:output method="text"/>  <!-- Natural language -->
   <xsl:output method="html"/>  <!-- Documentation -->
   <xsl:output method="xml"/>   <!-- Structured format -->
   ```

### Regelspraak Example

Current NRML transformation pipeline:
```
NRML JSON → (json-to-xml) → XML → (XSLT) → Dutch text
```

This is working well for the Regelspraak renderer:
- Complex grammar rules expressed in XSLT templates
- Proper Dutch article selection ("de" vs "het")
- Reference chain resolution (multi-hop paths)
- Pluralization and conjugation

## Consequences

### Positive

- **Declarative**: Easier to understand intent
- **Formal semantics**: Can reason about correctness
- **Composability**: Templates can be combined and overridden
- **Portability**: Standard XSLT runs anywhere
- **Debugging**: XSLT debuggers show transformation steps

### Negative

- **Learning curve**: XSLT syntax is unfamiliar to many developers
- **Verbosity**: XSLT can be verbose compared to template languages
- **Limited libraries**: Fewer utility libraries than in Python/JavaScript
- **Performance**: Can be slower than optimized imperative code (though Saxon is fast)

### Mitigations

- **Documentation**: Provide XSLT guides specific to NRML transformations
- **Templates**: Offer starter templates for common transformations
- **Testing**: Unit test XSLT templates with example inputs
- **Tooling**: Use modern XSLT processors (Saxon-HE/EE) for better performance

## Implementation

### Current Transformations

**Regelspraak** (`transformations/regelspraak.xsl`):
- Transforms NRML → Dutch natural language
- Handles grammar, articles, plurals
- Resolves reference chains
- ~800+ lines of XSLT

**Gegevenspraak** (planned):
- Transform NRML → Data dictionary
- Generate field descriptions
- Create validation rules

### Development Workflow

```bash
# Transform NRML to Regelspraak
./scripts/transform transformations/regelspraak.xsl toka.nrml.json output.txt

# Compare with expected output
diff output.txt toka.regelspraak.groundtruth.txt
```

### Testing Strategy

1. **Unit tests**: Individual templates with mock data
2. **Integration tests**: Full NRML → output validation
3. **Ground truth**: Compare against known-good outputs
4. **Regression tests**: Ensure changes don't break existing transformations

## Alternatives Considered

### Template Languages (Jinja2, Mustache)

**Approach**: Use text template languages
```jinja
{% for rule in rules %}
  Als {{ rule.condition }} dan {{ rule.conclusion }}
{% endfor %}
```

**Pros**: Familiar syntax, easy to learn, fast
**Cons**: Not formal, hard to verify, limited composition

**Rejected because**: Lack of formal semantics, harder to verify correctness

### Custom Imperative Code

**Approach**: Write Python/JavaScript transformation code
```python
def transform_nrml(nrml):
    output = []
    for rule in nrml['rules']:
        output.append(f"Als {rule['condition']} dan {rule['conclusion']}")
    return '\n'.join(output)
```

**Pros**: Maximum flexibility, familiar to developers, easy debugging
**Cons**: Not declarative, hard to verify, no composability

**Rejected because**: Want formal, verifiable transformations

### JSONata

**Approach**: JSON transformation language
```jsonata
rules.{
  "text": "Als " & condition & " dan " & conclusion
}
```

**Pros**: JSON-native, concise, declarative
**Cons**: Less mature than XSLT, smaller ecosystem, limited text generation

**Considered but deferred**: May revisit for JSON-to-JSON transformations

### ANTLR/Parser Generators

**Approach**: Define grammar and generate code
**Pros**: Strong typing, fast
**Cons**: Overkill for transformations, not declarative

**Rejected because**: Transformations are not parsing

## Open Questions

1. **Performance**: Is XSLT fast enough for large NRML files?
   - Current answer: Yes, Saxon handles toka.nrml.json quickly
   - May need optimization for very large rule bases

2. **Debugging**: How to make XSLT easier to debug?
   - Option: XSLT debuggers (Oxygen XML Editor)
   - Option: Better error messages
   - Option: Unit test individual templates

3. **Modularity**: How to organize large XSLT stylesheets?
   - Current: Single stylesheet per output format
   - Option: Split into modules (`grammar.xsl`, `references.xsl`, etc.)

## Related RFCs

- **RFC-001 (Readability)**: NRML core is not human-readable; transformations provide that
- **RFC-002 (Extensions)**: Transformations may need extension metadata

## References

- Notes on transformations: `doc/notes.md:66-69`
- Current implementation: `transformations/regelspraak.xsl`
- [XSLT 3.0 Specification](https://www.w3.org/TR/xslt-30/)
- [Saxon Processor](https://www.saxonica.com/welcome/welcome.xml)
