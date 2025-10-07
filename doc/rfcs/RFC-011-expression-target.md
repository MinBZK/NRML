# RFC-011: Expression Target Pattern (Inverted Dependencies)

**Status:** Proposed | **Date:** 2025-09-02 | **Authors:** Tim and Anne

## Context

Typical Datalog: dependencies flow forward (rule references dependencies, produces target).

NRML has inverted pattern: target referenced **from** expression, but target **depends on** expression semantically.

```json
{
  "expression": {
    ...
  },
  "target": {
    "$ref": "#/facts/some-fact"
  }
  // Reference FROM expression TO target
}
```

## Problem

### 1. Inverted Lookups

To find "what rules compute fact X", must search all rules for `target: X` (backward lookup).

### 2. Multiple Writers

Multiple expressions could target same fact → value depends on evaluation order.

### 3. Side Effects

Setting target is side effect of evaluating expression → breaks referential transparency.

## Decision

**Status: Accepted with concerns documented**

Expression-target pattern remains, with constraints:

### Constraints

1. **Single Writer Rule**: Each target has at most one rule (validation error otherwise)
    - Exception: Rules with mutually exclusive conditions (stratification)

2. **Order Independence**: Must work regardless of evaluation order (fixed-point evaluation)

3. **Documentation**: Make inverted dependency explicit in schemas and tools

## Why Keep It?

**Natural expression**: Some computations naturally "set" values:

```
"The total tax is computed as the sum of..."  → target ← expression
```

**Aggregation pattern**: Common in rule systems (similar to SQL UPDATE)

**Backwards compatibility**: Existing NRML uses this extensively

## Mitigations

**Validation**: Enforce single-writer rule at engine level

**Tooling**: Build dependency graph visualizers showing fact → rules that compute it

**Documentation**: Explicit warnings in schema docs about inverted dependencies

## Implementation

**Reverse index required**:

```python
# Must scan all rules to build reverse index
reverse_index = {}
for rule in rules:
    for target in rule.targets:
        if target in reverse_index:
            raise ConflictError(f"Multiple rules target {target}")
        reverse_index[target] = rule
```

## Open Questions

1. **Stratification**: Allow multiple writers if conditions mutually exclusive?
2. **Default values**: What if target has no rule?
3. **Incremental evaluation**: How to efficiently update when inputs change?

## Alternatives Rejected

- **Explicit assignment section**: More verbose, doesn't solve fundamental issues
- **Implicit target**: Harder to reference
- **Pure Datalog (no target field)**: Major breaking change, could be future direction

## Related

- RFC-009 (Initialization): Target pattern interacts with initialization
- RFC-012 (Type Inference): Item types inferred from structure, not from target
- Notes: `doc/notes.md:113-122`
