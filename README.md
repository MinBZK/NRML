# NRML - Normalized Rule Model Language

NRML (uitspraak: /ˈnɔrməl/) is een JSON-gebaseerd formaat voor het beschrijven van bedrijfsregels, objectmodellen en hun relaties op een gestructureerde manier.

## Wat maakt NRML uniek?

In tegenstelling tot bestaande XML-gebaseerde standaarden zoals BWB, Akoma Ntoso of MetaLex, kiest NRML bewust voor een **JSON-first** aanpak die aansluiting zoekt bij moderne software development practices. Waar standaarden zoals OpenFisca (Frankrijk) en Oracle Policy Automation zich richten op specifieke domeinen of propriëtaire oplossingen, biedt NRML een **open, developer-vriendelijke** benadering voor het specificeren van bedrijfsregels.

NRML onderscheidt zich door:

- **Executie-gerichte** aanpak (vs. document-georiënteerde juridische standaarden)
- **Brugfunctie** tussen menselijk leesbare specificaties en machine-uitvoerbare code
- **Nederlandse taalondersteuning** met ingebouwde lidwoorden (de/het)
- **Pragmatische simpliciteit** met een lagere drempel dan formele methoden zoals Catala

## Context

NRML is ontwikkeld als onderdeel van een bredere beweging naar machine-leesbare wetgeving en regelgeving:

- **Regelspraak/ALEF** - Een initiatief van de Belastingdienst voor het formaliseren van fiscale wet- en regelgeving
- **[MinBZK Machine Law PoC](https://github.com/MinBZK/poc-machine-law)** - Proof of Concept van het Ministerie van BZK voor machine-interpreteerbare wetgeving
- **[regels.overheid.nl](https://github.com/MinBZK/regels.overheid.nl)** - Standaardisering van regelbeheer voor Nederlandse overheidsdiensten

NRML bouwt voort op deze initiatieven door een gestandaardiseerd JSON-formaat te bieden dat zowel door mensen leesbaar als door machines interpreteerbaar is.

## Structuur

Een NRML document bestaat uit de volgende hoofdcomponenten:

### 1. Metadata

Bevat informatie over het document zoals versie, taal en beschrijving.

### 2. Domains

Type definities die hergebruikt kunnen worden, bijvoorbeeld:

- `Bedrag`: numeriek type met precisie en eenheid (€)
- `Percentage`: percentage type
- Enumeraties voor vaste waardenlijsten

### 3. Object Types

Definities van bedrijfsobjecten met hun eigenschappen:

- **Attributen**: eigenschappen met een datatype
- **Kenmerken**: boolean eigenschappen (bijv. "is belaste reis")
- **Article**: lidwoord (de/het) voor Nederlandse taal

### 4. Fact Types

Relaties tussen objecten:

- **Rollen**: de objecten die deelnemen aan de relatie
- **Cardinaliteit**: één-op-één, één-op-veel, etc.
- **Relatieomschrijving**: menselijk leesbare beschrijving

### 5. Parameters

Configureerbare waarden zoals tarieven en drempels.

### 6. Rule Groups

Bedrijfsregels georganiseerd in logische groepen:

- **Regels**: individuele bedrijfslogica
- **Versies**: regels kunnen verschillende versies hebben met geldigheidsperiodes
- **Expressies**: berekeningen en voorwaarden

## JSON Pointers

NRML gebruikt RFC 6901 JSON Pointers voor interne referenties:

```json
"$ref": "#/objectTypes/vlucht/properties/afstand"
```

Dit verwijst naar de `afstand` property van het `vlucht` object type.

## Voorbeeld

Het `toka.nrml.json` bestand bevat een volledig voorbeeld van het Nederlandse vliegbelastingsysteem met:

- Vluchten, passagiers en belastingberekeningen
- Afstand- en tijdgebaseerde tarieven
- Kortingen en uitzonderingen
- Treinmiles verdeling

## Schema Validatie

Het `schema.json` bestand definieert de formele structuur van NRML documenten en kan gebruikt worden voor validatie.

## Evaluatie en Testen

### 1. Schema Validatie

NRML documenten kunnen gevalideerd worden tegen het JSON Schema voor structurele correctheid.

**Met de ingebouwde validator:**

```bash
# Valideer het standaard bestand
uv run scripts/validate.py

# Valideer specifieke bestanden
uv run scripts/validate.py schema.json mijn-model.nrml.json
```

**Handmatig met Python:**

```python
import json
import jsonschema

with open('schema.json') as f:
    schema = json.load(f)

with open('toka.nrml.json') as f:
    document = json.load(f)

jsonschema.validate(document, schema)
```

De validator controleert:
- UUID-formaat voor alle keys
- Vereiste velden per object type  
- Taalcode formaat (ISO 639-1)
- JSON Schema compliance

### 2. Referentie Integriteit

Controleer of alle JSON Pointer referenties (`$ref`) correct verwijzen naar bestaande elementen.

### 3. Regelconsistentie

- Versies mogen geen overlappende geldigheidsperiodes hebben
- Expressies moeten syntactisch correct zijn
- Object- en attribuutreferenties moeten bestaan

### 4. Volledigheid

- Alle gerefereerde domains moeten gedefinieerd zijn
- Relaties moeten beide zijden correct definiëren
- Parameters gebruikt in regels moeten bestaan

## Toekomstige Ontwikkelingen

NRML is een levende standaard die zich ontwikkelt samen met de behoeften van de Nederlandse overheid voor machine-leesbare wetgeving. Bijdragen en feedback zijn welkom via GitHub issues.

Voor een uitgebreide analyse van hoe NRML zich verhoudt tot bestaande standaarden, zie [NRML Standards Analysis](./NRML_Standards_Analysis.md).
