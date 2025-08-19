# NRML Standards Analysis: Positioning in the Legal and Rule Standards Landscape

## Executive Summary

NRML (Normalized Rule Model Language) is a JSON-based format for describing business rules, object models, and their relationships. This analysis examines how NRML relates to existing standards in the legal and rule specification domain, identifying unique features, overlaps, and lessons learned from other initiatives.

## 1. Nederlandse Overheidsstandaarden (Dutch Government Standards)

### 1.0 regels.overheid.nl Methoden

**Overview**: Het Nederlandse platform voor standaardisering van regelbeheer documenteert verschillende methoden voor regelspecificatie.

**Belangrijkste methoden**:

#### FLINT (Formal Language for the Interpretation of Normative Texts)

- **Doel**: Expliciete taal voor het vastleggen van interpretaties van juridische bronnen
- **Aanpak**: Protocol voor het uitvoeren van normatieve taken
- **Focus**: Interpretatie en uitvoerbaarheid van juridische teksten
- **Uniek**: Scheiding tussen brontekst en interpretatie

#### RuleSpeak®

- **Doel**: Richtlijnen voor bedrijfsvriendelijke en precieze regelformulering
- **Aanpak**: Geen programmeertaal maar formuleringsprincipes
- **Focus**: Business-friendly communicatie van regels
- **Standaard**: OMG SBVR (Semantics of Business Vocabulary and Business Rules)

#### Avola

- **Doel**: Platform voor beslisbomen en regelmanagement
- **Aanpak**: Visuele modellering van beslissingslogica
- **Focus**: Low-code/no-code voor business users
- **Nederlands**: Ontwikkeld door Nederlands bedrijf

#### Blawx

- **Doel**: User-friendly expert system voor juridische redeneringen
- **Aanpak**: Visuele programmering (Blockly-gebaseerd zoals ALEF-Blockly!)
- **Focus**: Toegankelijkheid voor niet-programmeurs
- **Open Source**: MIT licentie

#### Semantisch HTML-vocabulaire

- **Doel**: RDF-gebaseerde representatie van regelinformatie
- **Aanpak**: HTML documenten met semantische annotaties
- **Focus**: Machine-leesbare publicatie van regels
- **Standaard**: Linked Data principes

#### USoft

- **Doel**: Model-driven development platform
- **Aanpak**: Declaratieve regelspecificatie
- **Focus**: Enterprise applicaties
- **Commercieel**: Propriëtaire oplossing

#### DataLex

- **Doel**: Legal knowledge-based systems
- **Aanpak**: Rule-based reasoning engine
- **Focus**: Juridische expertsystemen
- **Australisch**: AustLII initiatief

**Vergelijking met NRML**:

- **FLINT's interpretatie-laag**: NRML zou een FLINT-interpretatie kunnen serialiseren
- **RuleSpeak principes**: NRML zou RuleSpeak richtlijnen kunnen volgen voor leesbaarheid
- **Blawx visualisatie**: Beiden gebruiken Blockly - potentie voor integratie
- **Semantisch vocabulaire**: NRML mist RDF/Linked Data features
- **Avola's beslisbomen**: NRML's rule groups zouden decision trees kunnen ondersteunen

**Lessen voor NRML**:

1. FLINT's expliciete interpretatie-model toevoegen
2. RDF/JSON-LD support voor semantische interoperabiliteit
3. Beslisboom visualisatie mogelijkheden
4. Integratie met Blawx voor visuele authoring

### 1.1 BWB (Basis Wetten Bestand) XML Schema

**Overview**: The Dutch government's main XML-based system for storing and distributing legislation.

**Key Features**:

- XML-based format with three main schemas: Toestand (State), WTI (Legal Technical Information), and Manifest
- Approximately 45,000 regulations with over 100,000 states
- Foundation for wetten.overheid.nl
- Uses UTF-8 Unicode encoding

**Comparison with NRML**:

- **Format**: BWB uses XML while NRML uses JSON
- **Scope**: BWB focuses on document structure and versioning, NRML on executable rules
- **Overlap**: Both handle versioning (BWB through states, NRML through rule versions)
- **Lesson**: NRML could benefit from BWB's robust versioning and state management approach

### 1.2 MetaLex/CEN Standard

**Overview**: Open XML interchange format for legal and legislative resources, implemented in the Netherlands.

**Key Features**:

- Lowest common denominator for interoperability
- Schema extension mechanism for jurisdiction-specific needs
- All Dutch legislation available as CEN MetaLex and Linked Open Data
- Clear separation between structure and semantics

**Comparison with NRML**:

- **Philosophy**: Both aim for interoperability and machine-readability
- **Extensibility**: MetaLex's extension mechanism vs NRML's domain definitions
- **Implementation**: MetaLex focuses on document interchange, NRML on rule execution
- **Lesson**: NRML could adopt MetaLex's extension mechanism for jurisdiction-specific adaptations

### 1.3 Juriconnect

**Overview**: The Dutch standard for identification of and reference to laws and regulations.

**Key Features**:

- Standardized and persistent referencing system
- Used for references from case law, policy decisions, and implementation content
- Integrated with wetten.overheid.nl
- Permanent link generation for regulation components

**Comparison with NRML**:

- **Purpose**: Juriconnect focuses on identification, NRML on rule execution
- **Integration**: NRML could use Juriconnect identifiers for legal references
- **Standardization**: Both aim for consistent, machine-readable approaches
- **Lesson**: NRML should integrate Juriconnect identifiers for Dutch legal references

### 1.4 ALEF/RegelSpraak (Belastingdienst)

**Overview**: Controlled Natural Language (CNL) for Dutch tax rules with automatic code generation.

**Key Features**:

- Limited Dutch language designed for tax rule specification
- Readable by both lawyers and computers
- Automatic software generation from specifications
- Successfully deployed for income tax calculations

**Comparison with NRML**:

- **Approach**: RegelSpraak uses CNL, NRML uses structured JSON
- **Audience**: RegelSpraak targets non-technical users, NRML requires more technical knowledge
- **Generation**: Both support automatic implementation generation
- **Uniqueness**: RegelSpraak is unique globally as an operational CNL

**Lesson**: NRML could benefit from a CNL layer for non-technical users while maintaining JSON as the underlying format

### 1.5 MinBZK poc-machine-law

**Overview**: Proof of concept for executing machine-readable Dutch legislation specifications.

**Key Features**:

- Executable code, not just documentation
- Built-in execution engine
- Formal verification capabilities
- Multiple implementation engines (Go, Python)

**Comparison with NRML**:

- **Philosophy**: Both aim for executable specifications
- **Verification**: poc-machine-law emphasizes formal verification
- **Integration**: Both designed for direct system implementation
- **Lesson**: NRML could incorporate formal verification features

## 2. Europese Wetgevingsstandaarden (European Legislative Standards)

### 2.1 Akoma Ntoso

**Overview**: OASIS standard XML vocabulary for parliamentary, legislative, and judicial documents.

**Key Features**:

- 310+ element names covering legal document scenarios
- FRBR-based document conceptualization
- Global adoption (UK, Italy, Germany, US, Brazil)
- Version 1.0 standardized in 2018

**Comparison with NRML**:

- **Scope**: Akoma Ntoso focuses on document structure, NRML on rule logic
- **Maturity**: Akoma Ntoso is a mature OASIS standard
- **Adoption**: Akoma Ntoso has wider international adoption
- **Lesson**: NRML could align with Akoma Ntoso for document referencing

### 2.2 ELI (European Legislation Identifier)

**Overview**: System for making legislation available online in standardized format across EU.

**Key Features**:

- HTTP URI-based identifiers
- RDF/JSON-LD metadata embedding
- Cross-border interoperability
- Netherlands has not yet implemented (as of 2023)

**Comparison with NRML**:

- **Purpose**: ELI focuses on identification and discovery, NRML on execution
- **Standards**: Both use JSON-LD compatible approaches
- **Integration**: NRML could use ELI identifiers for legal references
- **Lesson**: NRML should consider ELI compatibility for European interoperability

### 2.3 Formex

**Overview**: EU's XML format for Official Journal publications.

**Key Features**:

- XML-based (migrated from SGML)
- ~260 tags (reduced from 1200 in v3)
- Unicode UTF-8 encoding
- Machine-readable format for EU publications

**Comparison with NRML**:

- **Domain**: Formex for publication, NRML for rules
- **Complexity**: Both aimed at simplification (Formex reduced tags significantly)
- **Format**: XML vs JSON distinction
- **Lesson**: NRML's simpler JSON approach aligns with Formex's simplification goals

## 3. Uitvoerbare Regelstandaarden (Executable Rule Standards)

### 3.1 OpenFisca (France)

**Overview**: Platform transforming legislative code into executable software.

**Key Features**:

- Python-based with JSON Web API
- Domain-specific language for formulas
- Public API with Swagger documentation
- Successfully implements French tax and benefit system

**Comparison with NRML**:

- **API**: Both offer JSON-based APIs
- **Language**: OpenFisca uses Python DSL, NRML uses JSON
- **Maturity**: OpenFisca is production-ready
- **Lesson**: NRML could learn from OpenFisca's API design and documentation approach

### 3.2 Catala

**Overview**: Programming language specifically designed for legislative text implementation.

**Key Features**:

- Default logic as first-class feature
- Literate programming approach
- Formal verification with F\*
- Found bugs in official French implementations

**Comparison with NRML**:

- **Approach**: Catala uses literate programming, NRML uses data-driven
- **Verification**: Catala has stronger formal verification
- **Innovation**: Both are innovative in their domains
- **Lesson**: NRML could incorporate default logic concepts

### 3.3 DatalogCert

**Overview**: Formally verified Datalog implementation framework.

**Key Features**:

- Coq formalization
- Mechanically certified
- Focus on query evaluation
- Suitable for authorization and policy

**Comparison with NRML**:

- **Verification**: DatalogCert emphasizes formal verification
- **Declarative**: Both use declarative approaches
- **Domain**: DatalogCert more general, NRML specific to business rules
- **Lesson**: NRML could explore Datalog for rule inference

### 3.4 Oracle Policy Automation (OPA)

**Overview**: Commercial rule automation platform.

**Key Features**:

- Natural language rule authoring in Word/Excel
- JSON/XML APIs for integration
- Production deployment capabilities
- Management console and analytics

**Comparison with NRML**:

- **Authoring**: OPA uses Office tools, NRML uses JSON
- **Commercial**: OPA is proprietary, NRML appears open
- **Integration**: Both support JSON APIs
- **Lesson**: NRML could provide better authoring tools

## 4. Semantische Standaarden (Semantic Standards)

### 4.1 ODRL (Open Digital Rights Language)

**Overview**: W3C standard for policy expression.

**Key Features**:

- JSON-LD serialization support
- Flexible policy model
- Extensible vocabulary
- Rights and obligations expression

**Comparison with NRML**:

- **Standards**: Both use JSON-based formats
- **Extensibility**: Both support extensions
- **Domain**: ODRL for rights, NRML for business rules
- **Lesson**: NRML could adopt ODRL's policy expression patterns

### 4.2 POWDER

**Overview**: W3C protocol for web resource description.

**Key Features**:

- RDF/OWL based
- Group resource descriptions
- Trust and certification properties
- Replaced PICS standard

**Comparison with NRML**:

- **Scope**: POWDER for resource metadata, NRML for rules
- **Semantics**: Both have formal semantics
- **Trust**: POWDER includes trust mechanisms
- **Lesson**: NRML could incorporate trust and provenance features

### 4.3 LKIF (Legal Knowledge Interchange Format)

**Overview**: OWL ontology for legal concepts and reasoning.

**Key Features**:

- Modular ontology design
- Support for legal reasoning peculiarities
- Rules with exceptions and meta-level information
- European ESTRELLA project outcome

**Comparison with NRML**:

- **Reasoning**: LKIF supports complex legal reasoning
- **Modularity**: Both use modular approaches
- **Standards**: LKIF uses OWL, NRML uses JSON
- **Lesson**: NRML could adopt LKIF's approach to exceptions and meta-rules

## Analysis: What Makes NRML Unique?

### 1. **JSON-First Approach**

- While most legal standards use XML, NRML's JSON format is more developer-friendly
- Aligns with modern API practices and web development

### 2. **Integrated Test Scenarios**

- Built-in support for Gherkin-style test scenarios
- Direct connection between rules and their tests

### 3. **Business Rule Focus**

- Specifically designed for business rules rather than legal documents
- Practical implementation focus vs theoretical representation

### 4. **Dutch Context Integration**

- Article support (de/het) for Dutch language
- Builds on Dutch initiatives while remaining language-agnostic

### 5. **Simplicity**

- Simpler than comprehensive standards like Akoma Ntoso or LKIF
- Lower barrier to entry than formal methods like Catala

## Overlaps with Existing Standards

1. **Rule Versioning**: Similar to BWB's state management
2. **JSON Schema**: Like OpenFisca's API approach
3. **Metadata Structure**: Comparable to ODRL's policy model
4. **Object Modeling**: Similar to LKIF's ontology approach
5. **Parameter Management**: Like OPA's configuration approach

## Lessons from Existing Standards

### 1. **From Document Standards (BWB, MetaLex, Akoma Ntoso)**

- Robust versioning and change tracking
- Clear separation of structure and content
- Standardized identifiers for cross-referencing

### 2. **From Executable Standards (OpenFisca, Catala, ALEF)**

- Importance of non-technical user interfaces
- Need for formal verification
- Value of production-ready implementations

### 3. **From Semantic Standards (ODRL, LKIF, POWDER)**

- Extensibility mechanisms
- Formal semantics definition
- Trust and provenance tracking

### 4. **From Dutch Initiatives**

- Success of controlled natural languages
- Importance of government backing
- Value of open source approach

## Positioning NRML in the Landscape

NRML occupies a unique position as:

1. **A Bridge Format**: Between human-readable specifications and machine-executable code
2. **Developer-Friendly**: JSON format appeals to modern developers
3. **Domain-Specific**: Focused on business rules rather than general legal documents
4. **Pragmatic**: Emphasizes practical implementation over theoretical completeness
5. **Complementary to FLINT**: Where FLINT captures interpretations, NRML executes them
6. **Blockly-Compatible**: Like Blawx, leverages visual programming for accessibility

## Recommendations for NRML Evolution

### 1. **Short-term Enhancements**

- Add formal verification capabilities (learning from Catala/DatalogCert)
- Implement CNL layer for non-technical users (inspired by RegelSpraak)
- Adopt ELI identifiers for legal references
- Include provenance and trust mechanisms (from POWDER)
- Add FLINT interpretation references
- Support RDF/JSON-LD for semantic web compatibility
- Integrate with Blawx for visual rule authoring

### 2. **Medium-term Development**

- Develop visual authoring tools (like ALEF-Blockly integration)
- Create transformation tools to/from other standards
- Implement formal semantics specification
- Build production-ready reference implementation

### 3. **Long-term Vision**

- Seek standardization through appropriate body
- Develop ecosystem of tools and implementations
- Create certification/validation framework
- Build community of practice

## Conclusion

NRML represents a pragmatic approach to rule specification that builds on lessons from existing standards while maintaining its own identity. Its JSON-first approach and focus on business rules distinguish it from document-oriented legal standards. To succeed, NRML should:

1. Leverage strengths from existing standards
2. Maintain its simplicity and developer focus
3. Build bridges to established standards
4. Develop a robust ecosystem of tools

The landscape analysis shows that while many standards exist, there's room for NRML's particular approach, especially in bridging the gap between legal specifications and practical implementation in modern software systems.
