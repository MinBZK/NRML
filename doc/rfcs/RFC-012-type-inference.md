# RFC-012: Type Inference from Structure

**Status:** Proposed
**Date:** 2025-09-02
**Authors:** Arvid and Anne

## Context

NRML items (facts, properties, roles, etc.) have different **types**:
- `fact`
- `property`
- `role`
- `characteristic`
- `rule`
- `expression`
- etc.

The question: Should item types be **explicit** (stored as a field) or **inferred** (derived from structure)?

## Current Approach

**NRML currently infers item types from structure, not from explicit type fields.**

A fact is identified as a "fact" because it appears in the `facts` object:
```json
{
  "facts": {
    "uuid-123": {
      "name": "vlucht",
      // No "type": "fact" field
    }
  }
}
```

A characteristic is identified by having `"type": "characteristic"` in its version:
```json
{
  "uuid-456": {
    "name": "onbelaste reis",
    "versions": [
      {
        "type": "characteristic"  // ← Type is here, inside version
      }
    ]
  }
}
```

An expression is identified by having an `operator` field:
```json
{
  "type": "arithmetic",
  "operator": "plus",
  "operands": [...]
}
```

## Problems with Current Approach

### 1. Complex Inference Logic

Determining type requires checking multiple conditions in a **specific order**:

```python
def infer_type(item):
    if 'operator' in item:
        return 'expression'
    elif 'target' in item and 'conditions' in item:
        return 'rule'
    elif item.get('versions', [{}])[0].get('type') == 'characteristic':
        return 'characteristic'
    elif item in nrml['facts']:
        return 'fact'
    elif item in fact['properties']:
        return 'property'
    else:
        return 'unknown'
```

**Issue**: Order matters. If checks are reordered, results could change.

### 2. Ambiguity

What if an item matches multiple patterns?
```json
{
  "operator": "plus",
  "target": {"$ref": "..."},
  "conditions": []
}
```

Is this a rule or an expression? Both patterns match.

### 3. Future Extensibility

If we add new types, inference logic must be updated everywhere:
- Parser
- Validator
- Transformers
- Tools

**Risk**: Different tools could infer types differently, leading to inconsistency.

### 4. Validation Challenges

Can't validate "all facts must have property X" because **which items are facts** is inferred, not explicit.

## Decision

**Status: Under consideration**

Options being evaluated:

### Option A: Add Explicit Type Field

**Approach**: Every item has a `"type"` field at the top level

```json
{
  "facts": {
    "uuid-123": {
      "type": "fact",
      "name": "vlucht",
      ...
    }
  }
}
```

**Pros**:
- Clear and unambiguous
- Easy validation: "If type=fact, require name field"
- Extensible: New types don't break existing logic
- Self-documenting: Type is explicit in data

**Cons**:
- Redundant: `facts` object already implies these are facts
- More verbose
- Must keep type consistent with location

### Option B: Keep Inference, Document Clearly

**Approach**: Formalize inference rules and document them

**Pros**:
- Less verbose
- Structural constraints enforce types
- No redundancy

**Cons**:
- Complex inference logic
- Order-dependent checking
- Hard to extend

### Option C: Hybrid

**Approach**: Explicit type for ambiguous cases, inferred for obvious cases

```json
// Clear from context: inferred
{
  "facts": {
    "uuid": {"name": "vlucht"}  // Obviously a fact
  }
}

// Ambiguous: explicit
{
  "items": {
    "uuid": {
      "type": "characteristic",  // Needs explicit type
      "name": "onbelaste reis"
    }
  }
}
```

**Pros**: Balance between verbosity and clarity
**Cons**: Inconsistent rules, when to be explicit?

## Consequences

### Option A (Explicit Type)

**Positive**:
- Validation is straightforward
- No order-dependent logic
- Types are self-documenting
- Easier to extend

**Negative**:
- More verbose
- Redundancy (type duplicates location)
- Must maintain consistency

**Example validation**:
```json
{
  "if": {"properties": {"type": {"const": "fact"}}},
  "then": {
    "required": ["name", "versions"]
  }
}
```

### Option B (Keep Inference)

**Positive**:
- Concise
- No redundancy
- Structure implies type

**Negative**:
- Complex inference
- Ambiguity risk
- Hard to validate
- Order-dependent

**Example inference**:
```python
# Must check in this order!
if in_facts_object(item): return 'fact'
elif in_properties(item): return 'property'
# etc.
```

## Use Cases

### Parser Implementation

**With explicit type**:
```python
def parse_item(item):
    parser = PARSERS[item['type']]
    return parser(item)
```

**With inference**:
```python
def parse_item(item, context):
    item_type = infer_type(item, context)
    parser = PARSERS[item_type]
    return parser(item)
```

### Validation

**With explicit type**:
```json
{
  "allOf": [
    {"if": {"properties": {"type": {"const": "fact"}}}, "then": {...}},
    {"if": {"properties": {"type": {"const": "property"}}}, "then": {...}}
  ]
}
```

**With inference**:
- Can't easily express in JSON Schema
- Must validate programmatically

## Open Questions

1. **Redundancy acceptable?** Is it okay to have type info duplicated (location + type field)?

2. **Migration cost?** If we add explicit types, how to migrate existing files?

3. **Validation priority?** Is strong validation more important than conciseness?

4. **Tool consistency?** How to ensure all tools infer types identically?

## Alternatives Considered

### Tags Instead of Types

**Approach**: Use tags to classify items
```json
{
  "uuid": {
    "tags": ["fact", "versioned", "named"]
  }
}
```

**Pros**: Flexible, multi-dimensional classification
**Cons**: Overkill for simple type system

### Schema Variants

**Approach**: Different schema files for different item types

**Pros**: Strong validation per type
**Cons**: Fragmentation, hard to compose

## Related RFCs

- RFC-004 (Variable Keys): Structure of NRML objects
- RFC-011 (Expression Target): Type inference for expressions with targets

## References

- Notes on type inference: `doc/notes.md:123-131`
