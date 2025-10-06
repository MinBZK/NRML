# RFC-000: RFC Process for NRML

**Status:** Accepted
**Date:** 2025-10-06
**Authors:** NRML Team

## Context

The NRML (Normalized Rule Model Language) project needs a structured way to document design decisions, architectural
choices, and implementation patterns. As the project evolves, it's essential to maintain a historical record of why
certain approaches were chosen and what alternatives were considered.

## Decision

We adopt an RFC (Request for Comments) process to document significant decisions in the NRML project. Each RFC will be a
standalone markdown document stored in `docs/rfcs/`.

## RFC Structure

Each RFC follows this template:

```markdown
# RFC-NNN: Title

**Status:** [Proposed | Accepted | Rejected | Superseded]
**Date:** YYYY-MM-DD
**Authors:** Name(s)

## Context

Why is this decision needed? What problem does it solve?

## Decision

What was decided?

## Rationale

Why was this approach chosen?

## Consequences

What are the implications of this decision?

## Alternatives Considered

What other options were evaluated? (if applicable)
```

## RFC Numbering

- **RFC-000**: Reserved for the RFC process itself
- **RFC-001+**: Technical decisions in order of creation
- Numbers are assigned sequentially as RFCs are created
- Once assigned, an RFC number is never reused

## RFC Statuses

- **Proposed**: Under discussion, not yet accepted
- **Accepted**: Approved and implemented/being implemented
- **Rejected**: Considered but not adopted
- **Superseded**: Replaced by a newer RFC (reference the new RFC number)

## Rationale

An RFC process provides:

1. **Historical Context**: Future contributors can understand why decisions were made
2. **Structured Discussion**: Forces clear articulation of problems and solutions
3. **Knowledge Transfer**: Documents tribal knowledge in accessible format
4. **Version Control**: Git tracks evolution of each decision over time
5. **Discoverability**: All design decisions in one predictable location

## Consequences

### Positive

- Clear documentation of architectural decisions
- Easier onboarding for new contributors
- Better justification for current implementations
- Historical record prevents re-litigating settled decisions

### Negative

- Overhead of writing RFCs for design decisions
- Need to maintain and update RFCs as designs evolve

### Neutral

- RFCs complement but don't replace code comments and inline documentation
- Not all decisions need RFCs—use judgment for significance threshold

## Process Guidelines

### When to Write an RFC

Write an RFC for:

- Changes to core NRML syntax or semantics
- Significant architectural decisions
- Design patterns that affect multiple components
- Choices between competing implementation approaches

Don't write an RFC for:

- Bug fixes that don't change semantics
- Routine implementation details
- Temporary workarounds

### RFC Workflow

1. **Draft**: Create RFC with "Proposed" status
2. **Discussion**: Review with team (PR review, meetings, etc.)
3. **Decision**: Update status to "Accepted" or "Rejected"
4. **Implementation**: Reference RFC in related code/documentation
5. **Evolution**: Update RFC if decision changes; mark as "Superseded" if replaced

## Alternatives Considered

### Decision Records in Code Comments

**Pros**: Directly adjacent to implementation
**Cons**: Hard to discover, no structured format, difficult to search

### Wiki-based Documentation

**Pros**: Easy to edit, good for collaborative writing
**Cons**: Separate from code repository, version control unclear

### GitHub Issues/Discussions

**Pros**: Already using GitHub, good for discussions
**Cons**: Not structured for long-term reference, hard to maintain as canonical source

## References

This RFC process is inspired by:

- [Rust RFC Process](https://github.com/rust-lang/rfcs)
- [Python PEP Process](https://www.python.org/dev/peps/)
- [Architecture Decision Records (ADR)](https://adr.github.io/)
