# RFC-010: Unified Operator Syntax

**Status:** Accepted
**Date:** 2025-09-02
**Authors:** Arvid and Anne

## Context

Expressions in NRML need to represent various operations: arithmetic, comparisons, logical operations, aggregations, etc. Different operation types historically had different syntactic structures:

- Binary operators: `{operator, left, right}`
- N-ary operators: `{operator, operands: [...]}`
- Range operators: `{operator, from, to}`
- Different names: `{operator, a, b}` vs. `{operator, x, y}`

This inconsistency makes:
- Parser implementation complex (many special cases)
- Schema validation harder (different structures for different operators)
- Transformations brittle (must handle many patterns)

## Decision

**All operators use a single unified syntax: `{operator, operands: [...]}`**

- **One structure**: All operations use the same JSON shape
- **Array of operands**: Even single-operand operations use array
- **No special cases**: No separate fields for `left/right`, `from/to`, `a/b`, etc.

### Unified Structure

```json
{
  "type": "arithmetic",  // or "comparison", "logical", etc.
  "operator": "plus",
  "operands": [
    {"$ref": "#/facts/..."},
    {"value": 5}
  ]
}
```

This works for all operation types:

```json
// Binary: A + B
{"operator": "plus", "operands": [A, B]}

// Unary: -X
{"operator": "negate", "operands": [X]}

// N-ary: sum(A, B, C)
{"operator": "sum", "operands": [A, B, C]}

// Comparison: X < Y
{"operator": "lessThan", "operands": [X, Y]}

// Logical: A AND B AND C
{"operator": "and", "operands": [A, B, C]}
```

## Rationale

### Benefits of Uniformity

1. **Simpler Parsing**: One code path for all operators
   ```python
   def eval_expression(expr):
       operator = expr['operator']
       operands = [eval_operand(op) for op in expr['operands']]
       return OPERATORS[operator](*operands)
   ```

2. **Easier Validation**: Single schema pattern
   ```json
   {
     "type": "object",
     "properties": {
       "operator": {"type": "string"},
       "operands": {
         "type": "array",
         "items": {"$ref": "#/definitions/operand"}
       }
     }
   }
   ```

3. **Consistent Transformations**: XSLT templates handle all operators uniformly
   ```xsl
   <xsl:template match="*[@type='arithmetic']">
     <xsl:apply-templates select="operands[1]"/>
     <xsl:value-of select="operator"/>
     <xsl:apply-templates select="operands[2]"/>
   </xsl:template>
   ```

4. **Extensibility**: New operators just need implementation, not new syntax
   - Add `"median"` operator? Just implement it, syntax is same
   - Add `"coalesce"` for null handling? No schema changes needed

### Multiple Ways to Express Same Thing?

From notes:
> Do we ever need multiple ways to say the same thing: sum(a, b, c) vs a + (b + c)?

**Answer**: No, we standardize on function call syntax for N-ary operations.

- `sum(a, b, c)` = `{"operator": "sum", "operands": [a, b, c]}`
- `a + b + c` is syntactic sugar that desugars to above

This avoids ambiguity and reduces parser complexity.

### Operator Arity Constraints

The schema can enforce arity constraints per operator:

```json
{
  "if": {
    "properties": {"operator": {"const": "lessThan"}}
  },
  "then": {
    "properties": {
      "operands": {
        "type": "array",
        "minItems": 2,
        "maxItems": 2
      }
    }
  }
}
```

This ensures `lessThan` always has exactly 2 operands, while `sum` can have variable length.

## Historical Context

Early NRML had multiple representations:
```json
// Style 1: {operator, left, right}
{"operator": "plus", "left": A, "right": B}

// Style 2: {operator, a, b}
{"operator": "plus", "a": A, "b": B}

// Style 3: {operator, from, to}
{"operator": "range", "from": A, "to": B}

// Style 4: {operator, [xs]}
{"operator": "sum", "xs": [A, B, C]}
```

This was simplified to:
```json
// Unified: {operator, operands: [...]}
{"operator": "plus", "operands": [A, B]}
{"operator": "range", "operands": [A, B]}
{"operator": "sum", "operands": [A, B, C]}
```

## Consequences

### Positive

- **Simpler implementation**: One code path, less branching
- **Easier to extend**: New operators don't require syntax changes
- **Better validation**: Single schema pattern enforces structure
- **Consistent transformations**: XSLT/JSONata rules are uniform
- **Clearer semantics**: Operator + operands is function application

### Negative

- **Verbosity**: `"operands": [A, B]` is longer than `"left": A, "right": B`
- **Less semantic field names**: `operands[0]` is less clear than `from` for range operations

### Mitigations

- **Verbosity is acceptable**: JSON is inherently verbose; consistency matters more
- **Documentation**: Clear docs on operand order for each operator (e.g., `lessThan(operands[0], operands[1])` means operands[0] < operands[1])
- **Schema annotations**: Use JSON Schema `description` to document operand meanings

## Implementation

### Operand Types

Operands can be:
1. **Literal values**: `{"value": 5}`
2. **References**: `{"$ref": "#/facts/..."}`
3. **Nested expressions**: `{"type": "arithmetic", "operator": "plus", ...}`
4. **Parameters**: `{"parameter": "input_value"}`

### Operator Categories

**Arithmetic**: `plus`, `minus`, `multiply`, `divide`, `modulo`, `negate`
**Comparison**: `lessThan`, `greaterThan`, `equals`, `lessThanOrEqual`, etc.
**Logical**: `and`, `or`, `not`
**Aggregation**: `sum`, `count`, `average`, `min`, `max`
**String**: `concat`, `substring`, `length`
**Custom**: Domain-specific operators as needed

## Examples

### Nested Arithmetic

`A - (B × C)`:
```json
{
  "type": "arithmetic",
  "operator": "minus",
  "operands": [
    {"$ref": "#/facts/A"},
    {
      "type": "arithmetic",
      "operator": "multiply",
      "operands": [
        {"$ref": "#/facts/B"},
        {"$ref": "#/facts/C"}
      ]
    }
  ]
}
```

### Complex Condition

`(X > 10) AND (Y < 20)`:
```json
{
  "type": "logical",
  "operator": "and",
  "operands": [
    {
      "type": "comparison",
      "operator": "greaterThan",
      "operands": [
        {"$ref": "#/facts/X"},
        {"value": 10}
      ]
    },
    {
      "type": "comparison",
      "operator": "lessThan",
      "operands": [
        {"$ref": "#/facts/Y"},
        {"value": 20}
      ]
    }
  ]
}
```

## Alternatives Considered

### Keep Multiple Syntaxes

**Approach**: Allow both `{left, right}` and `{operands: [...]}` styles

**Pros**: More readable field names for specific operators
**Cons**: Parser complexity, schema duplication, transformation brittleness

**Rejected because**: Consistency more valuable than minor readability gains

### Prefix Notation

**Approach**: `(operator operand1 operand2)`

**Pros**: Very uniform, familiar from Lisp
**Cons**: Not idiomatic JSON, harder for non-programmers

**Rejected because**: Want JSON-native syntax

### Infix Strings

**Approach**: `"expression": "A + B * C"`

**Pros**: Most readable for humans
**Cons**: Requires parser, ambiguity (precedence, whitespace), not structured

**Rejected because**: NRML core is not human-readable (RFC-001)

## Related RFCs

- RFC-001 (Readability): NRML core prioritizes structure over readability
- RFC-008 (Transformations): Uniform syntax simplifies XSLT templates

## References

- Notes on operator syntax: `doc/notes.md:83-112`
