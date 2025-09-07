# NRML Enhancement Proposal: Juridische Expressiviteit

## Samenvatting

Na het transformeren van de **Penitentiaire beginselenwet** naar NRML zijn enkele belangrijke beperkingen aan het licht gekomen die de expressiviteit van complexe juridische logica beperken. Dit voorstel behandelt concrete uitbreidingen om NRML geschikter te maken voor realistische wetgeving.

## Huidige Beperkingen

### 1. **Beperkte Logische Operatoren**
**Probleem**: Alleen enkelvoudige `comparison` condities mogelijk
**Gemist**: `allOf`, `anyOf`, `not` voor complexe juridische voorwaarden

**Voorbeeld uit Pbw**:
```yaml
# Originele wet: Persoon is gedetineerd ALS (opgenomen in inrichting EN status = INGESLOTEN/TIJDELIJK_AFWEZIG)
```

**Huidige NRML beperking**:
```json
"condition": {
  "type": "comparison", // Kan alleen 1 conditie checken
  "operator": "equals"  // Geen meerdere waarden mogelijk
}
```

### 2. **Ontbrekende Set Operatoren**
**Probleem**: Geen `in`, `contains`, `subset` operatoren
**Gemist**: Lidmaatschap van enumeraties, lijsten, sets

**Penitentiaire beginselenwet voorbeeld**:
```json
// GEWENST: inrichting_type IN ["PENITENTIAIRE_INRICHTING", "HUIS_VAN_BEWARING", "INRICHTING_STELSELMATIGE_DADERS"]
// GEDWONGEN: 3 aparte regels met elk 1 waarde
```

### 3. **Beperkte Rol-Relatie Expressie** 
**Probleem**: Geen directe many-to-many relatie ondersteuning
**Gemist**: "Persoon X opgenomen in Inrichting Y" relaties

## Voorgestelde Uitbreidingen

### 1. **Uitgebreide Condition Types**

```json
{
  "condition": {
    "type": "allOf",
    "conditions": [
      {
        "type": "comparison",
        "left": [{"$ref": "#/facts/.../items/detention-status"}],
        "operator": "in",
        "right": {"values": ["INGESLOTEN", "TIJDELIJK_AFWEZIG"]}
      },
      {
        "type": "exists",
        "characteristic": [
          {"$ref": "#/facts/.../roles/person"},
          {"$ref": "#/facts/.../roles/facility"}
        ]
      }
    ]
  }
}
```

**Nieuwe condition types**:
- `allOf`: Alle sub-condities waar
- `anyOf`: Minstens één sub-conditie waar  
- `not`: Negatie van sub-conditie
- `exists`: Controleer bestaan van relatie/karakteristiek
- `notExists`: Controleer afwezigheid

### 2. **Uitgebreide Comparison Operators**

```json
{
  "operator": "in",           // Lidmaatschap van set
  "operator": "notIn",        // Niet lid van set  
  "operator": "contains",     // Bevat element
  "operator": "containsAll",  // Bevat alle elementen
  "operator": "containsAny",  // Bevat minstens één element
  "operator": "subset",       // Is deelverzameling van
  "operator": "overlaps"      // Heeft gemeenschappelijke elementen
}
```

### 3. **Relatie-gebaseerde Facts**

```json
{
  "facts": {
    "detention-relationship": {
      "name": {"nl": "detentie relatie"},
      "_source": "relationship",
      "cardinality": "many-to-many",
      "roles": {
        "detainee": {
          "name": {"nl": "gedetineerde"},
          "target": {"$ref": "#/facts/natural-person"},
          "required": true
        },
        "facility": {
          "name": {"nl": "inrichting"}, 
          "target": {"$ref": "#/facts/detention-facility"},
          "required": true
        }
      },
      "properties": {
        "admission-date": {
          "name": {"nl": "opnamedatum"},
          "type": "date"
        },
        "status": {
          "name": {"nl": "status"},
          "type": "enumeration",
          "values": ["INGESLOTEN", "TIJDELIJK_AFWEZIG"]
        }
      }
    }
  }
}
```

### 4. **Temporal Logic Ondersteuning**

```json
{
  "condition": {
    "type": "temporal",
    "temporalType": "during",
    "timeReference": "evaluation-date",
    "condition": {
      "type": "comparison",
      "left": [{"$ref": "#/facts/.../properties/detention-status"}],
      "operator": "equals",
      "right": {"value": "INGESLOTEN"}
    }
  }
}
```

**Temporal types**:
- `during`: Gedurende periode waar
- `before`: Voor tijdstip waar
- `after`: Na tijdstip waar
- `between`: Tussen tijdstippen waar

### 5. **Kwantificatie Ondersteuning**

```json
{
  "condition": {
    "type": "quantified",
    "quantifier": "forAll",
    "variable": "detention_record",
    "domain": [{"$ref": "#/facts/detention-relationship"}],
    "condition": {
      "type": "comparison",
      "left": [{"$ref": "detention_record/properties/status"}],
      "operator": "in", 
      "right": {"values": ["INGESLOTEN", "TIJDELIJK_AFWEZIG"]}
    }
  }
}
```

**Quantifiers**:
- `forAll`: Voor alle elementen geldt
- `exists`: Er bestaat minstens één element waarvoor geldt
- `count`: Tel elementen waarvoor geldt
- `unique`: Er is precies één element waarvoor geldt

## Verbeterde Penitentiaire Beginselenwet

Met deze uitbreidingen zou de wet veel natuurlijker worden:

```json
{
  "detention-determination-rule": {
    "name": {"nl": "Detentiestatus bepaling artikel 2 Pbw"},
    "target": [{"$ref": "#/facts/natural-person/items/is-detained"}],
    "condition": {
      "type": "allOf",
      "conditions": [
        {
          "type": "exists",
          "relationship": [
            {"$ref": "#/facts/detention-relationship"},
            {"roles": ["detainee", "facility"]}
          ]
        },
        {
          "type": "comparison",
          "left": [{"$ref": "#/facts/detention-facility/items/facility-type"}],
          "operator": "in",
          "right": {
            "values": [
              "PENITENTIAIRE_INRICHTING", 
              "HUIS_VAN_BEWARING", 
              "INRICHTING_STELSELMATIGE_DADERS"
            ]
          }
        },
        {
          "type": "comparison", 
          "left": [{"$ref": "#/facts/detention-relationship/properties/status"}],
          "operator": "in",
          "right": {"values": ["INGESLOTEN", "TIJDELIJK_AFWEZIG"]}
        }
      ]
    },
    "value": {"value": true}
  }
}
```

## Schema Wijzigingen

### Condition Schema Uitbreiding

```json
{
  "condition": {
    "oneOf": [
      {
        "type": "object",
        "properties": {
          "type": {"enum": ["comparison"]},
          "left": {"type": "array"},
          "operator": {
            "enum": [
              "equals", "notEquals", 
              "lessThan", "lessThanOrEquals",
              "greaterThan", "greaterThanOrEquals",
              "in", "notIn", "contains", "containsAll", 
              "containsAny", "subset", "overlaps"
            ]
          },
          "right": {"type": "object"}
        }
      },
      {
        "type": "object", 
        "properties": {
          "type": {"enum": ["allOf", "anyOf"]},
          "conditions": {
            "type": "array",
            "items": {"$ref": "#/definitions/condition"}
          }
        }
      },
      {
        "type": "object",
        "properties": {
          "type": {"enum": ["not"]},
          "condition": {"$ref": "#/definitions/condition"}
        }
      },
      {
        "type": "object",
        "properties": {
          "type": {"enum": ["exists", "notExists"]},
          "relationship": {"type": "array"},
          "characteristic": {"type": "array"}
        }
      }
    ]
  }
}
```

## Implementatie Prioriteit

### **Fase 1: Kritieke Logische Operatoren** 🔴
- `allOf`, `anyOf`, `not` condition types
- `in`, `notIn` comparison operators
- Backwards compatible schema wijzigingen

### **Fase 2: Relatie Ondersteuning** 🟡  
- Relationship facts met rollen
- `exists`/`notExists` voor relaties
- Many-to-many cardinalities

### **Fase 3: Geavanceerde Features** 🟢
- Temporal logic
- Quantificatie  
- Set operatoren (`contains`, `subset`, etc.)

## Juridische Impact

Deze uitbreidingen zouden NRML geschikt maken voor:

- ✅ **Complexe voorwaarden** uit echte wetgeving
- ✅ **Relatiegerichte wetten** (Familie, Contract, Straf)  
- ✅ **Temporale bepalingen** (geldigheid, termijnen)
- ✅ **Kwantificatie** ("alle", "sommige", "geen")
- ✅ **Set-gebaseerde logica** (categorieën, lijsten)

## Conclusie

De voorgestelde uitbreidingen zouden NRML transformeren van een beperkte regel-engine naar een volwaardige juridische specificatietaal die complexe Nederlandse wetgeving adequaat kan uitdrukken, terwijl backwards compatibiliteit behouden blijft.