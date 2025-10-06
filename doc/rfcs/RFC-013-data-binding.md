# RFC-013: Data Binding Mechanism

**Status:** Proposed
**Date:** 2025-09-02
**Authors:** Arvid and Anne

## Context

NRML represents rules and logic, but real-world systems need to connect to **external data sources**:
- Database queries (fetch customer age from database)
- API calls (get current weather, exchange rates)
- External systems (legacy mainframe, third-party services)
- User input (form data, interactive queries)

The question: How does NRML bind to external data without polluting the core rule model?

## Problem Statement

Consider a rule that uses a person's age:
```json
{
  "conditions": [
    {
      "type": "comparison",
      "operator": "greaterThan",
      "operands": [
        {"$ref": "#/facts/persoon-uuid/properties/leeftijd"},
        {"value": 18}
      ]
    }
  ]
}
```

**Question**: Where does `leeftijd` (age) come from?

Options:
1. **Static data** in NRML file: `"leeftijd": 25`
2. **External lookup**: `SELECT age FROM persons WHERE bsn = ?`
3. **API call**: `GET /api/persons/{bsn}/age`
4. **User input**: Ask the user

## Decision

**Status: Under consideration**

NRML should support **separate binding definitions** that map NRML facts to external data sources.

## Proposed Approach

### Separation of Concerns

**NRML Core**: Pure logic, no data source details
```json
// kinderbijslag.nrml.json
{
  "facts": {
    "persoon-uuid": {
      "properties": {
        "leeftijd-uuid": {
          "name": "leeftijd",
          "type": "integer",
          "unit": "jaar"
        }
      }
    }
  }
}
```

**Binding File**: Implementation-specific mapping
```json
// prod-binding.json
{
  "0fe3c5a2-a33a-4a98-9abc-a98929783499": {
    "external-requirement": {
      "id": "urn:toeslagen:leeftijd:jr",
      "arguments": {
        "bsn": {"$ref": "#/facts/persoon-uuid/properties/bsn"}
      }
    }
  }
}
```

**Implementation**: Maps logical requirements to actual functions
```python
engine = NRMLEngine("kinderbijslag.nrml.json", "prod-binding.json")

def leeftijd(bsn):
    # Actual implementation: database, API, etc.
    return db.query("SELECT age FROM persons WHERE bsn = ?", bsn)

engine.infer(
    data_binding={"urn:toeslagen:leeftijd:jr": leeftijd}
)
```

### Why This Approach?

1. **NRML stays pure**: No database connection strings, API URLs, etc. in rule files
2. **Multiple bindings**: Same NRML can use different bindings (test vs. prod)
3. **Implementation independence**: Binding specifies **what** data is needed, not **how** to get it
4. **Security**: Sensitive credentials not in NRML files

## Binding File Structure

### External Requirement

```json
{
  "fact-uuid": {
    "external-requirement": {
      "id": "urn:provider:service:method",
      "arguments": {
        "arg1": {"$ref": "..."},
        "arg2": {"value": "constant"}
      }
    }
  }
}
```

**Semantics**: To compute `fact-uuid`, call external service identified by `id` with given arguments.

### Binding Types

**Database Query**:
```json
{
  "id": "urn:db:postgres:query",
  "arguments": {
    "query": "SELECT age FROM persons WHERE bsn = :bsn",
    "params": {"bsn": {"$ref": "#/facts/.../bsn"}}
  }
}
```

**REST API**:
```json
{
  "id": "urn:api:rest:get",
  "arguments": {
    "url": "https://api.example.com/persons/{bsn}/age",
    "params": {"bsn": {"$ref": "#/facts/.../bsn"}}
  }
}
```

**Function Call** (in-memory):
```json
{
  "id": "urn:function:calculate_age",
  "arguments": {
    "birthdate": {"$ref": "#/facts/.../geboortedatum"}
  }
}
```

**User Input**:
```json
{
  "id": "urn:input:prompt",
  "arguments": {
    "prompt": "Wat is uw leeftijd?",
    "type": "integer"
  }
}
```

## Implementation

### Engine Integration

```python
class NRMLEngine:
    def __init__(self, nrml_file, binding_file=None):
        self.nrml = load_json(nrml_file)
        self.bindings = load_json(binding_file) if binding_file else {}

    def infer(self, data_binding=None):
        # Resolve external requirements using data_binding
        for fact_id, binding in self.bindings.items():
            if 'external-requirement' in binding:
                req = binding['external-requirement']
                func = data_binding[req['id']]
                args = self.resolve_arguments(req['arguments'])
                result = func(**args)
                self.set_fact_value(fact_id, result)

        # Continue with normal inference
        ...
```

### Multiple Environments

**Test binding**:
```json
// test-binding.json
{
  "persoon-uuid": {
    "external-requirement": {
      "id": "urn:mock:leeftijd",
      "arguments": {}
    }
  }
}
```

```python
# Test implementation
def mock_leeftijd(bsn):
    return 25  # Always return 25 for testing

engine.infer(data_binding={"urn:mock:leeftijd": mock_leeftijd})
```

**Production binding**:
```python
def prod_leeftijd(bsn):
    return db.query("SELECT age FROM persons WHERE bsn = ?", bsn)

engine.infer(data_binding={"urn:toeslagen:leeftijd:jr": prod_leeftijd})
```

## Consequences

### Positive

- **Separation**: Logic separate from data access
- **Testability**: Easy to mock external data
- **Flexibility**: Different bindings for different environments
- **Security**: No credentials in NRML files
- **Reusability**: Same NRML with different data sources

### Negative

- **Complexity**: Additional binding layer
- **Coordination**: Must keep NRML and bindings in sync
- **Documentation**: Need to document binding contract

### Mitigations

- **Validation**: Check that all external requirements have bindings
- **Type checking**: Verify argument types match
- **Documentation**: Clear binding specification

## Open Questions

1. **Caching**: Should engine cache external data? For how long?

2. **Error handling**: What if external data source is unavailable?
   - Fail evaluation?
   - Use default/fallback value?
   - Retry logic?

3. **Versioning**: How to version binding definitions?

4. **Discovery**: How does engine discover what bindings are needed?

5. **Side effects**: What if binding has side effects (write to DB)?

6. **Transactions**: Should bindings be transactional?

## Alternatives Considered

### Embed Data Sources in NRML

**Approach**: Include connection info in NRML
```json
{
  "leeftijd": {
    "source": {
      "type": "database",
      "connection": "postgres://...",
      "query": "SELECT age FROM persons WHERE bsn = ?"
    }
  }
}
```

**Pros**: Self-contained
**Cons**: Mixes logic with implementation, security issues, not reusable

**Rejected**: Violates separation of concerns

### Custom Extensions per Source

**Approach**: Different NRML syntax for each source type

**Pros**: Type-safe, specific validation
**Cons**: Proliferation of special cases, hard to extend

**Rejected**: Too many special cases

### No Binding Mechanism

**Approach**: All data must be in NRML files

**Pros**: Simplest
**Cons**: Not practical for real systems, huge NRML files

**Rejected**: Unusable for production systems

## Related RFCs

- RFC-002 (Extensions): Bindings could be considered an extension mechanism
- RFC-005 (Reusability): Bindings enable reuse across environments
- RFC-009 (Initialization): External data might be used for initialization

## References

- Notes on data binding: `doc/notes.md:132-167`
