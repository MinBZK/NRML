# RFC-013: Data Binding Mechanism

**Status:** Proposed | **Date:** 2025-09-02 | **Authors:** Tim, Arvid and Anne

## Context

NRML represents pure logic, but real systems need external data: database queries, API calls, legacy systems, user input. How to bind NRML facts to external sources without polluting the core rule model?

## Decision

**Separate binding definitions map NRML facts to external data sources.**

**NRML Core** (pure logic):
```json
{
  "facts": {
    "persoon-uuid": {
      "properties": {
        "leeftijd-uuid": {
          "name": "leeftijd",
          "type": "integer"
        }
      }
    }
  }
}
```

**Binding File** (implementation-specific):
```json
{
  "leeftijd-uuid": {
    "external-requirement": {
      "id": "urn:toeslagen:leeftijd:jr",
      "arguments": {
        "bsn": {"$ref": "#/facts/persoon-uuid/properties/bsn"}
      }
    }
  }
}
```

**Engine Usage**:
```python
engine = NRMLEngine("rules.nrml.json", "prod-binding.json")

def fetch_age(bsn):
    return db.query("SELECT age FROM persons WHERE bsn = ?", bsn)

engine.infer(data_binding={"urn:toeslagen:leeftijd:jr": fetch_age})
```

## Why

**Benefits:**
- **Separation**: Logic separate from data access (no connection strings in NRML)
- **Testability**: Easy mocking (test binding vs prod binding)
- **Security**: Credentials outside of NRML files
- **Flexibility**: Same NRML, different data sources
- **Reusability**: Bindings can be environment-specific

**Tradeoffs:**
- Additional binding layer complexity
- Must keep NRML and bindings synchronized
- Need clear binding contract documentation

**Mitigations**: Validation ensures all external requirements have bindings; type checking verifies argument compatibility.

## Binding Types

**Database**: `urn:db:postgres:query` with SQL query and parameters
**REST API**: `urn:api:rest:get` with URL template
**Function**: `urn:function:calculate_age` for in-memory computation
**User input**: `urn:input:prompt` for interactive queries

Multiple environments use different bindings:
- Test: `urn:mock:leeftijd` → always returns 25
- Prod: `urn:toeslagen:leeftijd:jr` → actual database query

## Open Questions

1. **Caching**: Should engine cache external data? For how long?
2. **Error handling**: Fail evaluation or use defaults when source unavailable?
3. **Versioning**: How to version binding definitions?
4. **Side effects**: How to handle bindings that write data?
5. **Transactions**: Should bindings be transactional?

## Alternatives Rejected

- **Embed sources in NRML**: Violates separation, security issues
- **Custom syntax per source**: Too many special cases
- **No binding mechanism**: Unusable for production (all data must be static)

## Related

- RFC-002 (Extensions): Bindings as extension mechanism
- RFC-005 (Reusability): Enable cross-environment reuse
- RFC-009 (Initialization): External data for initialization
- Notes: `doc/notes.md:132-167`
