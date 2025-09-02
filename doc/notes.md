# Notes

_Last update: 2025-09-02 by Arvid and Anne_

## Readability

The goal of NRML core is NOT to be human readable (there renders of it that are).
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

Should that be _in_ the NRML definition or on the outside (using, for instance, version control)
Is ValidFrom required? Or optional? Is validTo required or optional? (we think both should be optional, assuming we keep
this in the standard altogether)

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