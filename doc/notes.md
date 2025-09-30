# Notes

_Last update: 2025-09-02 by Arvid and Anne_

## Readability

The goal of NRML core is NOT to be human readable (there are renders of it that are).
For instance, we are ok with UUIDs that are not easy to navigate by humans.

Strict JSON over YAML (because we don't want to shoot ourselves in the foot).

## Extensions

Should language related metadata, as required by regelspraak/gegevenspraak, be in the core?
Or should we have an extension on the core that allows for requiring this metadata?

Options/choices we have:

- We could have a separate JSON file with for instance translations that maps uuids to objects (that can then be
  merged).

- We could have a separate schema file that will be merged with core schema. This schema could then for instance require
  certain fields that were not required in core.

Both could result in the same view on NRML.

## Versioning

Should that be _in_ the NRML definition or on the outside (using, for instance, version control).
Is ValidFrom required? Or optional? Is validTo required or optional? (we think both should be optional, assuming we keep
this in the standard altogether).

We should keep all versions around (relates to immutability, see below), so that we can always freely refer to any
version. The end user should _NOT_ need to use version control (git) to see earlier versions of a fact.

Because reference can be absolutely linked to version UUIDs, versioning at this level is efficient (doesn't runtime
resolves). Another reason to keep versions at this level is that we want to keep relations between the versions: if an
attribute changes over time, we still want the object of the attribute to remain the same.

## Variable keys

Should keys be allowed to be variable (should we have UUIDs as keys), or do we want a fixed and predictable number of
keys (which for many parsers is easier)?

## Reusability

We need a way to link across NRML definitions (in other files) so that definitions/domains/... can be reused/work
together.
We think jsonpoints can work:

```json
 "$ref": "https://example.com/schemas/address.json#/definitions/address"
```

## Hash as identifiers?

We consider instead UUIDs to use a hash of the content as an identifier. However, separately defined definitions, even
with the exact same fields can have different semantics and should not be collapsed.
Therefor, we should NOT use hashes as identifiers (and instead we should use globally unique UUIDs)

## Immutability

All required fields of a _version_ are immutable. So, any change to a required field in a version results in a _new_
version (with a new UUID).

## Transformations

Transformations from NRML to other representations (such as Regelspraak) can be done with any tool, but formal
transformations, such as those that can be expressed in XSLT, are preferred.

## Initialisation

We may need a construct to initialize something, there's no order in which facts are processed.

## Article

we should call them "definite article"

## Nested arithmetic

We may need to deal still with using correct brackets for nested arithmetic.

## Multiple ways of expressing the same thing

Do we ever need multiple ways to say the same thing: sum(a, b, c) vs a + (b + c)?
What's part of NRML-core? What's an extension?
Isn't the sum syntactic suger?


We had multiple representations of expressions:
- `{operator, left, right}`
- `{operator, a, b}`
- `{operator, from, to}`
- `{operator, [xs]}`

The new idea is:
- `{operators, [args]}`
  a.k.a. one way to do functions.

To make it strict, the schema can enforce that certain operators have exactly 2 args, `less than` for example, where `sum` can take a list of arbitrary length.

```json
{
  "type": "array",
  "contains": {
    "type": "number"
  },
  "minContains": 2,
  "maxContains": 2
}
```

## Expression target

Most items have a reference to their dependencies, but in the case of an expression target this is inverted. 
The target of an expression has a dependency on the expression, but it is referenced from the expression to the target. 

The result is that 
- Lookups are inverted for this specific relation
- Multiple expressions could set the same target, causing a different execution order to yield different results 
- Processing the expression sets the value of a different fact as a 'side effect'

## Item type is inferred

Item types are not stored as a property but inferred by the structure of the item. 
This is possible, but the logic is complex and depends on a specific ordering of the checks when deciding the type. 
There might be a future situation where different types can not be distinguished by their structure or the order 
in which they need to be evaluated changes leading to significant refactoring.

Adding the type would also allow an additional validation that the item confirms to the requirements of the type. 

## Binding data to facts

We need a way to bind data to facts. We think we might need a separate binding definition, that is implementation 
specific and might look something like this.

`binding.js`:
```js
{
  "0fe3c5a2-a33a-4a98-9abc-a98929783499": {
    "external-requirement": {
      "id": "urn:toeslagen:leeftijd:jr",
      "arguments": {
        "bsn": {
          "$ref": "#/facts...."
        }
      }
    }
  }
}
```

Which could then be used as follows:

`inference.py`
```python
engine = NRMLEngine("kinderbijslag.nrml.json", "prod-binding.json")


def leeftijd(bsn):
    return 10


engine.infer(
    data_binding={"urn:toeslagen:leeftijd:jr": leeftijd}
)
```
