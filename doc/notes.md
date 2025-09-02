# Notes

_Last update: 2025-09-02 by Arvid and Anne_

## Readability

The goal of NRML core is NOT to be human readable (there renders of it that are).
For instance, we are ok with UUIDs that are not easy to navigate by humans.

Strict JSON over YAML (because we don't want to shoot ourselves in the foot).

## Extensions

Should language related metadata, as required by regelspraak/gegevenspraak, be in the core?
Or should we have an extension on the core that allows for requiring this metadata?

## Versioning

Should that be _in_ the NRML definition or on the outside (using, for instance, version control)
Is ValidFrom required? Or optional? Is validTo required or optional? (we think both should be optional, assuming we keep
this in the standard altogether)

## Variable keys

Should keys be allowed to be variable (should we have UUIDs as keys), or do we want a fixed and predictable number of
keys (which for many parsers is easier)?

# Reusability

We need a way to link across NRML definitions (in other files) so that definitions/domains/... can be reused/work
together.
We think jsonpoints can work:

```json
 "$ref": "https://example.com/schemas/address.json#/definitions/address"
 ```