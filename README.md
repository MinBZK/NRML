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
uv run scripts/validate

# Valideer specifieke bestanden
uv run scripts/validate schema.json mijn-model.nrml.json
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

## XSLT Transformaties

NRML documenten kunnen worden getransformeerd naar verschillende output formaten:

### Beschikbare Transformaties

1. **Gegevensspraak** (`gegevensspraak.xsl`) - Object model specificatie
2. **Regelspraak** (`regelspraak.xsl`) - Business rules in natuurlijke taal

### Quick Start

```bash
# Installeer dependencies (eenmalig)
npm install

# Gegevensspraak transformatie (standaard)
./scripts/transform

# Regelspraak transformatie  
./scripts/transform transformations/regelspraak.xsl toka.nrml.json output.txt

# Custom bestanden met taal
./scripts/transform my.xsl input.json output.txt en

# Help
./scripts/transform --help
```

### Voorbeeld Output

**Input (NRML JSON):**
```json
{
  "objectTypes": {
    "48c6ed9c-0911-43d8-b6ef-47d2b406ea35": {
      "name": {"nl": "vlucht", "en": "flight"},
      "definite_article": {"nl": "de", "en": "the"},
      "properties": {
        "d72ead33-2e0c-450a-ba71-b83940c8e926": {
          "name": {"nl": "belaste reis", "en": "taxable journey"},
          "type": "characteristic"
        }
      }
    }
  }
}
```

**Gegevensspraak Output (Nederlands):**
```
Objecttype de vlucht
de	belaste reis	kenmerk
de	onbelaste reis	kenmerk
de	rondvlucht	kenmerk
is	klimaatneutraal	kenmerk (bijvoeglijk)
```

**Regelspraak Output (Nederlands):**
```
Regel belaste reis 01
geldig vanaf 2018
Een reis is een belaste reis
indien bereikbaar per trein van de reis gelijk is aan waar.
```

### Multilingual Support

Beide transformaties ondersteunen Nederlands (`nl`) en Engels (`en`) via het centralized `translations.xsl` module:

```bash
# Nederlandse output (standaard)
./scripts/transform transformations/regelspraak.xsl toka.nrml.json output-nl.txt nl

# Engelse output  
./scripts/transform transformations/regelspraak.xsl toka.nrml.json output-en.txt en
```

### Architectuur Principes

**Strikte scheiding tussen taal en domein:**
- **Taalconstructies** (lidwoorden, voegwoorden): uit `translations.xsl`
- **Domeintermen** (vlucht, passagier): uit JSON object model
- **Geen hardcoded strings** in XSL transformaties

**Unified Reference Chain System:**
- Alle referenties zijn arrays (zelfs enkele referenties)
- Ondersteuning voor multi-hop chains (role → property)
- Possessive pronouns gebaseerd op rule target context

### Technical Features

- **XSLT 3.0** - Declaratieve templates met pattern matching
- **JSON native** - Directe `json-to-xml()` support  
- **SaxonJS** - XSLT 3.0 processor via Node.js (geen Java nodig)
- **UUID support** - Volledig UUID-based multilingual NRML v2
- **Role references** - Expliciete relationele modellering

## Toekomstige Ontwikkelingen

NRML is een levende standaard die zich ontwikkelt samen met de behoeften van de Nederlandse overheid voor machine-leesbare wetgeving. Bijdragen en feedback zijn welkom via GitHub issues.

Voor een uitgebreide analyse van hoe NRML zich verhoudt tot bestaande standaarden, zie [NRML Standards Analysis](doc/comparison.md).
