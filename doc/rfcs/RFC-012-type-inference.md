# RFC-012: Type Inference from Structure

**Status:** Proposed | **Date:** 2025-09-02 | **Authors:** Tim, Arvid and Anne

## Context

NRML items (facts, properties, roles, characteristics, rules, expressions) have different types. Should types be
**explicit** (stored as field) or **inferred** (derived from structure)?

Currently NRML infers types:

- Fact: appears in `facts` object
- Characteristic: has `"type": "characteristic"` in version
- Expression: has `operator` field
- Rule: has `target` and `conditions` fields

## Problem

**Complex inference logic**: Determining type requires checking multiple conditions in specific order.

**Ambiguity**: What if item matches multiple patterns?

**Extensibility**: Adding new types requires updating inference logic everywhere.

**Validation challenges**: Can't validate "all facts must have X" when which items are facts is inferred.

## Decision

**Status: Under consideration**

Three options being evaluated:

### Option A: Add Explicit Type Field

Every item has `"type"` at top level.

- **Pro**: Clear, easy validation, self-documenting, extensible
- **Con**: Redundant (location already implies type), more verbose

### Option B: Keep Inference, Document Clearly

Formalize inference rules and document them.

- **Pro**: Less verbose, structural constraints enforce types
- **Con**: Complex logic, order-dependent, hard to extend

### Option C: Hybrid

Explicit type for ambiguous cases, inferred for obvious ones.

- **Pro**: Balance between verbosity and clarity
- **Con**: Inconsistent rules—when to be explicit?

## Current Inference Example

```python
def infer_type(item, context):
    if 'operator' in item:
        return 'expression'
    elif 'target' in item and 'conditions' in item:
        return 'rule'
    elif item.get('versions', [{}])[0].get('type') == 'characteristic':
        return 'characteristic'
    elif item in nrml['facts']:
        return 'fact'
    # Order matters!
```

## Open Questions

1. Is redundancy (type + location) acceptable for clarity?
2. How to migrate existing files if we add explicit types?
3. Is strong validation more important than conciseness?
4. How to ensure all tools infer types identically?

## Alternatives Rejected

- **Tags instead of types** `["fact", "versioned", "named"]`: Overkill for simple type system
- **Schema variants**: Separate schema per type creates fragmentation

## Related

- RFC-004 (Variable Keys): Structure of NRML objects
- RFC-011 (Expression Target): Type inference for expressions with targets
- Notes: `doc/notes.md:123-131`
