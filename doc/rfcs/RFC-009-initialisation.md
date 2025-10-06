# RFC-009: Initialization Without Processing Order

**Status:** Proposed
**Date:** 2025-09-02
**Authors:** Arvid and Anne

## Context

Datalog (the theoretical foundation of NRML) is inherently **order-independent**. Facts can be stated in any order, and rules can be evaluated in any order, as long as the evaluation is consistent (fixed-point semantics).

However, some systems need **initialization**:
- Set default values before rules run
- Initialize accumulators or counters
- Establish baseline state

The question: How do we handle initialization in an order-independent language?

## Problem Statement

Consider this scenario:
```json
{
  "facts": {
    "counter-uuid": {
      "name": "counter",
      "value": 0  // Initial value
    }
  },
  "rules": [
    {
      "target": {"$ref": "#/facts/counter-uuid"},
      "expression": {
        "type": "arithmetic",
        "operator": "plus",
        "operands": [
          {"$ref": "#/facts/counter-uuid"},
          {"value": 1}
        ]
      }
    }
  ]
}
```

**Question**: Is the counter:
- 0 (initial value)?
- 1 (after rule fires once)?
- Infinite (rule fires indefinitely)?

This depends on **when initialization happens** vs. **when rules fire**.

## Decision

**Status: Under consideration**

NRML needs an initialization mechanism, but the exact design is not yet finalized.

## Options Under Consideration

### Option 1: Explicit Initialization Phase

**Approach**: Separate initialization facts from rules
```json
{
  "initialization": {
    "counter-uuid": {"value": 0}
  },
  "rules": [
    // Rules run after initialization
  ]
}
```

**Semantics**:
1. Initialize all facts in `initialization` phase
2. Evaluate rules until fixed point
3. Initialization happens exactly once

**Pros**: Clear separation, explicit semantics
**Cons**: Breaks order-independence, requires two-phase evaluation

### Option 2: Default Values

**Approach**: Facts have default values that apply when no rule has set them
```json
{
  "facts": {
    "counter-uuid": {
      "name": "counter",
      "defaultValue": 0,
      "versions": [
        {
          "value": null  // Will use defaultValue if no rule assigns it
        }
      ]
    }
  }
}
```

**Semantics**: Default value is used only if fact has no assigned value

**Pros**: Order-independent, fits Datalog model
**Cons**: Need to distinguish "no value" from "value is 0"

### Option 3: Stratification

**Approach**: Group rules into strata (layers) that execute in order
```json
{
  "rules": [
    {
      "stratum": 0,  // Initialization stratum
      "target": {"$ref": "#/facts/counter-uuid"},
      "expression": {"value": 0}
    },
    {
      "stratum": 1,  // Computation stratum
      "target": {"$ref": "#/facts/counter-uuid"},
      "expression": {/* increment */}
    }
  ]
}
```

**Semantics**:
1. Evaluate stratum 0 to fixed point
2. Then evaluate stratum 1 to fixed point
3. Etc.

**Pros**: Fits Datalog stratification theory, allows controlled ordering
**Cons**: Breaks full order-independence, adds complexity

### Option 4: Monotonic Initialization

**Approach**: Use a special "initial value" that rules can check
```json
{
  "rules": [
    {
      "target": {"$ref": "#/facts/counter-uuid"},
      "conditions": [
        {"type": "uninitialized", "fact": {"$ref": "#/facts/counter-uuid"}}
      ],
      "expression": {"value": 0}
    }
  ]
}
```

**Semantics**: Rules can check if a fact is uninitialized and set it

**Pros**: Fully declarative, order-independent
**Cons**: Requires "uninitialized" as a value/state

## Current Practice

Currently, NRML uses initialization rules like:
```json
{
  "target": [{"$ref": "#/facts/property-uuid"}],
  "conditions": [],
  "expression": {"value": 0}
}
```

**Issues**:
- Unclear when this fires relative to other rules
- Could fire multiple times if not careful
- Depends on engine evaluation order

## Theoretical Background

### Datalog Stratification

Datalog with negation uses **stratification** to ensure well-defined semantics:
- Rules are grouped into strata
- Each stratum is evaluated to fixed point before next stratum
- Ensures monotonicity even with negation

NRML could adopt similar approach for initialization.

### Closed World Assumption

Datalog uses **Closed World Assumption** (CWA):
- If a fact is not provable, it's false
- This provides a natural "default" (false)

NRML could use CWA for default values:
- If a fact has no value, it's "undefined" or "null"
- Rules can check for this and provide defaults

## Open Questions

1. **Do we need explicit initialization?**
   - Maybe default values are sufficient
   - Maybe rules should always be idempotent

2. **How to handle side effects?**
   - If initialization has side effects (e.g., API calls), when do they happen?

3. **Can we maintain order-independence?**
   - Is stratification acceptable (partial order dependence)?
   - Or must we be fully order-independent?

4. **What about determinism?**
   - If multiple rules could initialize the same fact, which wins?
   - Do we need conflict resolution?

## Consequences

### Option 1 (Explicit Initialization Phase)

**Pros**: Simple, clear semantics
**Cons**: Breaks order-independence

### Option 2 (Default Values)

**Pros**: Order-independent, clean
**Cons**: Need to handle "no value" state

### Option 3 (Stratification)

**Pros**: Theoretically sound, flexible
**Cons**: More complex, partial ordering

### Option 4 (Monotonic Initialization)

**Pros**: Fully declarative
**Cons**: Requires special "uninitialized" state

## Next Steps

1. Analyze existing NRML files to understand initialization patterns
2. Prototype each option with real examples
3. Evaluate impact on engine complexity
4. Decide based on practical needs vs. theoretical purity
5. Update this RFC when decision is made

## Alternatives Considered

### Require Explicit Values

**Approach**: No initialization—all facts must have explicit values
**Cons**: Verbose, repetitive, doesn't handle computed defaults

### Procedural Initialization

**Approach**: Run a script before NRML evaluation
**Cons**: Not part of NRML, breaks declarative model

## Related RFCs

- RFC-003 (Versioning): Default values might interact with versions
- RFC-013 (Data Binding): Initialization might come from external data

## References

- Notes on initialization: `doc/notes.md:71-73`
- [Datalog Stratification](https://en.wikipedia.org/wiki/Datalog#Stratification)
