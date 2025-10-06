# RFC-011: Expression Target Pattern (Inverted Dependencies)

**Status:** Proposed
**Date:** 2025-09-02
**Authors:** Arvid and Anne

## Context

In typical Datalog-style systems, **dependencies flow forward**:
```
Rule: Y :- X.
Dependency: Rule depends on X, produces Y
```

The rule **references** its dependencies (`X`) and **produces** its target (`Y`). References point from the rule to the dependencies.

However, NRML has a pattern where the **target** is referenced **from the expression**:

```json
{
  "expression": {
    "type": "arithmetic",
    "operator": "plus",
    "operands": [...]
  },
  "target": {"$ref": "#/facts/some-fact"}
}
```

This creates an **inverted dependency**:
- The **expression** has a reference to the **target**
- The **target** depends on the **expression** (semantically)
- But the **reference** points from expression → target (syntactically)

## Problem Statement

This inversion causes several issues:

### 1. Inverted Lookups

To determine what affects a fact, you must search backward:
```
Question: "What rules compute the value of fact X?"
Answer: Search all rules for target: {"$ref": "#/facts/X"}
```

vs. forward dependency (normal Datalog):
```
Question: "What does rule R depend on?"
Answer: Look at R's conditions and expressions
```

### 2. Multiple Writers

Multiple expressions could target the same fact:
```json
// Rule 1
{
  "target": {"$ref": "#/facts/counter"},
  "expression": {"value": 0}
}

// Rule 2
{
  "target": {"$ref": "#/facts/counter"},
  "expression": {"value": 10}
}
```

**Question**: What's the value of `counter`? Depends on **evaluation order**.

### 3. Side Effects

Setting a target is a **side effect** of evaluating the expression:
- Expression evaluates to a value
- As a side effect, assigns value to a different fact

This breaks **referential transparency** (expression value depends on where it's used).

## Current Usage in NRML

Despite these issues, the target pattern is used extensively:

```json
{
  "target": [
    {"$ref": "#/facts/vlucht-uuid/properties/totaal-belasting"}
  ],
  "expression": {
    "type": "aggregation",
    "operator": "sum",
    "operands": [...]
  }
}
```

This says: "Compute the sum and assign it to `totaal-belasting`."

## Decision

**Status: Accepted with concerns documented**

The expression-target pattern remains in NRML, but with these constraints:

### Constraints

1. **Single Writer Rule**: Each target can have at most one rule that assigns to it
   - Multiple rules assigning to same target = validation error
   - Exception: Rules with mutually exclusive conditions (stratification)

2. **Execution Order Independence**: Rules must be order-independent
   - Target assignment happens during fixed-point evaluation
   - No observable differences based on evaluation order

3. **Documentation**: Make inverted dependency explicit
   - Schema documentation must note this pattern
   - Tooling should visualize dependency graphs accurately

## Rationale

### Why Keep This Pattern?

1. **Natural Expression**: Some computations naturally "set" a value
   ```
   "The total tax is computed as the sum of..."
   ```
   This reads as: target ← expression

2. **Aggregation Pattern**: Common in rule systems
   ```sql
   UPDATE facts SET total = (SELECT SUM(amount) FROM items);
   ```
   SQL does this too (target on left, expression on right)

3. **Backwards Compatibility**: Existing NRML files use this extensively

### Why Not Remove It?

**Alternative**: Make target implicit in expression
```json
{
  "fact": {"$ref": "#/facts/totaal-belasting"},
  "value": {
    "type": "aggregation",
    "operator": "sum",
    ...
  }
}
```

But this is just reordering the same fields. Doesn't solve fundamental issues.

## Consequences

### Positive

- **Expressive**: Natural for assignment-style rules
- **Familiar**: Similar to SQL UPDATE, imperative assignment
- **Compatible**: Works with existing NRML files

### Negative

- **Inverted lookups**: Need reverse index to find rules affecting a fact
- **Conflict potential**: Multiple rules could target same fact (need validation)
- **Side effects**: Expression evaluation has effects beyond its value

### Mitigations

1. **Validation**: Enforce single-writer rule at schema/engine level
   ```json
   // Engine validation
   if (targetFactHasMultipleRules(fact)) {
     throw new Error(`Multiple rules assign to ${fact}`);
   }
   ```

2. **Tooling**: Build dependency graph visualizers
   - Show fact → rules that compute it
   - Detect circular dependencies
   - Highlight conflicts

3. **Documentation**: Explicit warnings in schema docs
   ```
   WARNING: target creates inverted dependency. Ensure only one rule
   per target or use mutually exclusive conditions.
   ```

## Implementation Considerations

### Dependency Analysis

Engines must build **reverse index**:
```python
# Forward index (easy)
rule.dependencies = [ref for ref in rule.expression.references()]

# Reverse index (requires scan)
reverse_index = {}
for rule in rules:
    for target in rule.targets:
        reverse_index.setdefault(target, []).append(rule)
```

### Conflict Detection

```python
def detect_conflicts(rules):
    targets = {}
    for rule in rules:
        for target in rule.targets:
            if target in targets:
                if not mutually_exclusive(rule, targets[target]):
                    raise ConflictError(f"Multiple rules target {target}")
            targets[target] = rule
```

### Evaluation Order

**Key insight**: Fixed-point evaluation makes order irrelevant _if_ rules are confluent.

Target pattern doesn't break confluence as long as single-writer rule is enforced.

## Open Questions

1. **Stratification**: Should we allow multiple writers if conditions are mutually exclusive?
   ```json
   // Rule 1: if condition A, set X = 10
   // Rule 2: if condition B, set X = 20
   // Valid if A and B are mutually exclusive
   ```

2. **Default Values**: What if target has no rule? Use default? Error?

3. **Incremental Evaluation**: How to efficiently update when inputs change?

## Alternatives Considered

### Explicit Assignment

**Approach**: Separate assignment from expression
```json
{
  "assignments": [
    {
      "fact": {"$ref": "#/facts/totaal"},
      "expression": {...}
    }
  ]
}
```

**Pros**: Makes assignment explicit
**Cons**: More verbose, doesn't solve fundamental issues

**Rejected**: Doesn't provide enough benefit

### Implicit Target

**Approach**: Expression defines its own location
```json
{
  "totaal": {
    "type": "aggregation",
    "operator": "sum",
    ...
  }
}
```

**Pros**: Simpler structure
**Cons**: Harder to reference, unclear ownership

**Rejected**: Loses explicit target reference

### Pure Datalog (No Target Field)

**Approach**: Remove target, use pure Datalog rules
```
totaal(Flight, Sum) :-
  sum(Tax, flight_passenger_tax(Flight, _, Tax), Sum).
```

**Pros**: Standard Datalog, no inversion
**Cons**: Less familiar syntax, major breaking change

**Deferred**: Could be future direction, but requires rethinking NRML structure

## Related RFCs

- RFC-009 (Initialization): Target pattern interacts with initialization
- RFC-012 (Type Inference): Item types inferred from structure, not from target

## References

- Notes on expression target: `doc/notes.md:113-122`
