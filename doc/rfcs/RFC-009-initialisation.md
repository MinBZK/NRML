# RFC-009: Initialization Without Processing Order

**Status:** Proposed | **Date:** 2025-09-02 | **Authors:** Wouter and Anne

## Context

Datalog is inherently order-independent (fixed-point semantics), but some systems need initialization: default values,
accumulators, baseline state. How to handle initialization when there's no processing order?

**Problem example**: If a counter starts at 0 and a rule increments it, is the result 0, 1, or infinite? Depends on when
initialization happens vs. when rules fire.

## Decision

**Status: Under consideration**

NRML needs an initialization mechanism, but exact design not yet finalized.

## Options

### 1. Explicit Initialization Phase

Separate `initialization` section evaluated before rules.

- **Pro**: Clear separation, explicit semantics
- **Con**: Breaks order-independence, two-phase evaluation

### 2. Default Values

Facts have `defaultValue` used when no rule assigns a value.

- **Pro**: Order-independent, fits Datalog model
- **Con**: Need to distinguish "no value" from "value is 0"

### 3. Stratification

Group rules into strata (layers) executed in order (stratum 0, then 1, etc.).

- **Pro**: Theoretically sound (Datalog stratification), controlled ordering
- **Con**: Breaks full order-independence, adds complexity

### 4. Monotonic Initialization

Rules can check if fact is "uninitialized" and set it.

- **Pro**: Fully declarative, order-independent
- **Con**: Requires special "uninitialized" state

## Current Practice

NRML uses initialization rules with empty conditions:

```json
{
  "target": [
    {
      "$ref": "#/facts/property-uuid"
    }
  ],
  "conditions": [],
  "expression": {
    "value": 0
  }
}
```

**Issues**: Unclear when this fires, could fire multiple times, depends on engine evaluation order.

## Theoretical Background

**Datalog Stratification**: Rules grouped into strata, each evaluated to fixed point before next stratum. Ensures
monotonicity with negation. NRML could adopt for initialization.

**Closed World Assumption**: If fact not provable, it's false/undefined. Could provide natural defaults.

## Open Questions

1. Do we need explicit initialization, or are default values sufficient?
2. How to handle side effects if initialization calls external services?
3. Can we maintain order-independence, or is stratification acceptable?
4. If multiple rules could initialize same fact, which wins?

## Alternatives Rejected

- **Require explicit values**: Too verbose, doesn't handle computed defaults
- **Procedural initialization script**: Breaks declarative model

## Related

- RFC-003 (Versioning): Default values might interact with versions
- RFC-013 (Data Binding): Initialization might come from external data
- Notes: `doc/notes.md:71-73`
- [Datalog Stratification](https://en.wikipedia.org/wiki/Datalog#Stratification)
