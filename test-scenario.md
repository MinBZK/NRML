# Test Scenario's voor Penitentiaire Beginselenwet

## Huidige Regel Logica
```
De detentie status van een natuurlijk persoon moet berekend worden 
  • GEDETINEERD_TIJDELIJK_AFWEZIG als de type verlof van de tenuitvoerlegging is ALGEMEEN_VERLOF, REGIMESGEBONDEN_VERLOF, INCIDENTEEL_VERLOF of STRAFONDERBREKING
  • anders GEDETINEERD_INGESLOTEN als de type verlof van de tenuitvoerlegging gelijk is aan GEEN_VERLOF
  • anders NIET_GEDETINEERD
indien er aan alle volgende voorwaarden wordt voldaan :
  • de type straf of maatregel van de tenuitvoerlegging is VRIJHEIDSSTRAF of VRIJHEIDSBENEMENDE_MAATREGEL
  • de type inrichting van de penitentiaire inrichting is PENITENTIAIRE_INRICHTING of HUIS_VAN_BEWARING
  • de type verlof van de tenuitvoerlegging is ALGEMEEN_VERLOF, REGIMESGEBONDEN_VERLOF, INCIDENTEEL_VERLOF, STRAFONDERBREKING of GEEN_VERLOF.
```

## Test Personen

### Persoon A - Normale Gedetineerde
- **Type straf**: VRIJHEIDSSTRAF ✅
- **Type inrichting**: PENITENTIAIRE_INRICHTING ✅ 
- **Type verlof**: GEEN_VERLOF ✅
- **Resultaat**: GEDETINEERD_INGESLOTEN ✅

### Persoon B - Gedetineerde met Verlof
- **Type straf**: VRIJHEIDSSTRAF ✅
- **Type inrichting**: HUIS_VAN_BEWARING ✅
- **Type verlof**: ALGEMEEN_VERLOF ✅
- **Resultaat**: GEDETINEERD_TIJDELIJK_AFWEZIG ✅

### Persoon C - Taakstraf (PROBLEEM!)
- **Type straf**: TAAKSTRAF ❌ (niet in lijst)
- **Type inrichting**: N/A
- **Type verlof**: N/A
- **Resultaat**: REGEL VUURT NIET AF! ❌
- **Verwacht**: NIET_GEDETINEERD

### Persoon D - Geldboete (PROBLEEM!)
- **Type straf**: GELDBOETE ❌ (niet in lijst)
- **Type inrichting**: N/A
- **Type verlof**: N/A
- **Resultaat**: REGEL VUURT NIET AF! ❌
- **Verwacht**: NIET_GEDETINEERD

### Persoon E - Psychiatrische Kliniek (PROBLEEM!)
- **Type straf**: VRIJHEIDSBENEMENDE_MAATREGEL ✅
- **Type inrichting**: PSYCHIATRISCHE_KLINIEK ❌ (niet in lijst)
- **Type verlof**: GEEN_VERLOF
- **Resultaat**: REGEL VUURT NIET AF! ❌
- **Verwacht**: Waarschijnlijk NIET_GEDETINEERD (of aparte status?)

## Het Probleem

De huidige regel bepaalt alleen een detentie status voor mensen die:
1. VRIJHEIDSSTRAF of VRIJHEIDSBENEMENDE_MAATREGEL hebben
2. IN een PENITENTIAIRE_INRICHTING of HUIS_VAN_BEWARING zitten
3. Een bekende verlof status hebben

**Maar wat gebeurt er met alle anderen?** Hun detentie status blijft onbepaald!

## Mogelijke Oplossing

De regel zou ALTIJD een status moeten bepalen:

```
De detentie status van een natuurlijk persoon is:
  • NIET_GEDETINEERD als de type straf NIET VRIJHEIDSSTRAF of VRIJHEIDSBENEMENDE_MAATREGEL is
  • NIET_GEDETINEERD als de type inrichting NIET PENITENTIAIRE_INRICHTING of HUIS_VAN_BEWARING is  
  • GEDETINEERD_TIJDELIJK_AFWEZIG als type verlof is ALGEMEEN_VERLOF, REGIMESGEBONDEN_VERLOF, INCIDENTEEL_VERLOF of STRAFONDERBREKING
  • GEDETINEERD_INGESLOTEN anders (bij GEEN_VERLOF)
```

Dit zou alle scenario's afdekken zonder "indien" voorwaarden.