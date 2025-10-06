# RFC-010: Unified Operator Syntax

**Status:** Accepted | **Date:** 2025-09-02 | **Authors:** Arvid and Anne

## Context

NRML expressions historically used inconsistent structures: `{operator, left, right}` for binary ops, `{operator, operands: [...]}` for n-ary, `{operator, from, to}` for ranges, etc. This created parser complexity, difficult schema validation, and brittle transformations.

## Decision

**All operators use a single unified syntax: `{operator, operands: [...]}`**

```json
{
  "type": "arithmetic",
  "operator": "plus",
  "operands": [
    {"$ref": "#/facts/..."},
    {"value": 5}
  ]
}
```

Works for all cases: binary (`plus`), unary (`negate`), n-ary (`sum`), comparison (`lessThan`), logical (`and`).

## Why

**Benefits:**
- **Simpler parsing**: Single code path for all operators
- **Easy validation**: One schema pattern enforces all operators
- **Consistent transformations**: XSLT templates work uniformly
- **Extensible**: New operators need implementation only, not syntax changes
- **Clear semantics**: Operator + operands is function application

**Tradeoffs:**
- More verbose than `{left, right}` (acceptable—JSON is inherently verbose)
- Less semantic field names (mitigated with schema `description` fields)

**Alternatives rejected:**
- **Multiple syntaxes**: Parser complexity outweighs readability gains
- **Prefix notation** `(op a b)`: Not idiomatic JSON
- **Infix strings** `"A + B"`: Requires parser, not structured (see RFC-001)

**Historical evolution:**
Early NRML had 4 different styles (`{left, right}`, `{a, b}`, `{from, to}`, `{xs: [...]}`) which were unified into current form.

**Schema-enforced arity:**
Operators like `lessThan` require exactly 2 operands via JSON Schema conditional validation, while `sum` accepts variable-length arrays.

**Operand types:**
Literals (`{"value": 5}`), references (`{"$ref": "..."}`), nested expressions, or parameters.

## Example

Nested arithmetic `A - (B × C)`:
```json
{
  "type": "arithmetic",
  "operator": "minus",
  "operands": [
    {"$ref": "#/facts/A"},
    {
      "type": "arithmetic",
      "operator": "multiply",
      "operands": [{"$ref": "#/facts/B"}, {"$ref": "#/facts/C"}]
    }
  ]
}
```

## Related

- RFC-001 (Readability): NRML prioritizes structure over readability
- RFC-008 (Transformations): Uniform syntax simplifies XSLT
- Notes: `doc/notes.md:83-112`
