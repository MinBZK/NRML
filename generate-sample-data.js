#!/usr/bin/env node

/**
 * Generate Sample Data Instances from NRML Schema
 * 
 * Takes NRML schema definitions and generates realistic sample data instances
 * that can be used for testing with Souffle Datalog execution.
 */

const fs = require('fs');

function generateSampleData(nrmlFile, outputFile, numInstances = 5) {
    console.log('🎲 NRML Sample Data Generator');
    console.log('==============================');
    
    const nrml = JSON.parse(fs.readFileSync(nrmlFile, 'utf8'));
    const sampleData = {
        facts: {},
        instances: []
    };
    
    // Copy schema facts (structure definitions)
    sampleData.facts = JSON.parse(JSON.stringify(nrml.facts));
    
    console.log(`📋 Generating ${numInstances} sample instances...`);
    
    // Generate sample instances
    for (let i = 1; i <= numInstances; i++) {
        const instance = generatePersonInstance(i, nrml.facts);
        sampleData.instances.push(instance);
        console.log(`  👤 Generated: ${instance.name} (age ${instance.age})`);
    }
    
    // Add generated data as facts to the NRML structure
    addInstancesAsFacts(sampleData, nrml.facts);
    
    fs.writeFileSync(outputFile, JSON.stringify(sampleData, null, 2));
    console.log(`✅ Sample data written to: ${outputFile}`);
    console.log(`📊 Generated ${sampleData.instances.length} instances`);
    
    return sampleData;
}

function generatePersonInstance(id, facts) {
    // Generate realistic sample data
    const names = ['John', 'Maria', 'Ahmed', 'Lisa', 'Carlos', 'Yuki', 'Sophie', 'David'];
    const ages = [17, 25, 45, 67, 72, 28, 33, 19]; // Mix of ages to test senior rules
    const destinations = [300, 600, 1200, 450, 2800, 150, 900, 1800]; // Mix of distances
    
    const name = names[(id - 1) % names.length];
    const age = ages[(id - 1) % ages.length];
    const distance = destinations[(id - 1) % destinations.length];
    
    return {
        id: `person_${id}`,
        name: name,
        age: age,
        distance: distance,
        birthDate: new Date(new Date().getFullYear() - age, 5, 15).toISOString().split('T')[0],
        isSenior: age >= 65,
        isLongDistance: distance > 500
    };
}

function addInstancesAsFacts(sampleData, originalFacts) {
    // Find the natuurlijk persoon fact UUID
    let personFactId = null;
    let flightFactId = null;
    
    for (const [factId, fact] of Object.entries(originalFacts)) {
        if (fact.name && fact.name.nl === 'natuurlijk persoon') {
            personFactId = factId;
        }
        if (fact.name && fact.name.nl && fact.name.nl.includes('vlucht')) {
            flightFactId = factId;
        }
    }
    
    console.log(`🔗 Adding instances to fact: ${personFactId}`);
    
    // Add instances as properties with defaultValue
    if (personFactId && sampleData.facts[personFactId]) {
        const personFact = sampleData.facts[personFactId];
        
        // Ensure properties structure exists
        if (!personFact.properties) {
            personFact.properties = {};
        }
        
        // Add sample instances as properties
        sampleData.instances.forEach((instance, index) => {
            const instanceId = `instance_${index + 1}`;
            
            // Add age property
            personFact.properties[`${instanceId}_age`] = {
                name: { nl: `leeftijd van ${instance.name}`, en: `age of ${instance.name}` },
                versions: [{
                    validFrom: "2018",
                    type: "number",
                    defaultValue: instance.age,
                    unit: "jr"
                }]
            };
            
            // Add name property  
            personFact.properties[`${instanceId}_name`] = {
                name: { nl: `naam van ${instance.name}`, en: `name of ${instance.name}` },
                versions: [{
                    validFrom: "2018", 
                    type: "string",
                    defaultValue: instance.name
                }]
            };
            
            // Add distance property
            personFact.properties[`${instanceId}_distance`] = {
                name: { nl: `afstand tot bestemming van ${instance.name}`, en: `distance to destination of ${instance.name}` },
                versions: [{
                    validFrom: "2018",
                    type: "number", 
                    defaultValue: instance.distance,
                    unit: "km"
                }]
            };
        });
    }
    
    // Also add system parameters
    if (!sampleData.facts['system-params']) {
        sampleData.facts['system-params'] = {
            name: { nl: "systeem parameters", en: "system parameters" },
            properties: {
                "senior_age_threshold": {
                    name: { nl: "leeftijd grens voor senioren", en: "senior age threshold" },
                    versions: [{
                        validFrom: "2018",
                        type: "number",
                        defaultValue: 65,
                        unit: "jr"
                    }]
                },
                "base_tax_rate": {
                    name: { nl: "basis belasting tarief", en: "base tax rate" },
                    versions: [{
                        validFrom: "2018", 
                        type: "number",
                        defaultValue: 100,
                        unit: "EUR"
                    }]
                },
                "senior_discount_percent": {
                    name: { nl: "senior korting percentage", en: "senior discount percentage" },
                    versions: [{
                        validFrom: "2018",
                        type: "number", 
                        defaultValue: 50,
                        unit: "%"
                    }]
                }
            }
        };
    }
}

// CLI interface
if (require.main === module) {
    const args = process.argv.slice(2);
    const nrmlFile = args[0] || 'example-simple.nrml.json';
    const outputFile = args[1] || 'sample-data.nrml.json';
    const numInstances = parseInt(args[2]) || 5;
    
    if (!fs.existsSync(nrmlFile)) {
        console.error(`❌ Input file not found: ${nrmlFile}`);
        process.exit(1);
    }
    
    try {
        generateSampleData(nrmlFile, outputFile, numInstances);
    } catch (error) {
        console.error(`❌ Error generating sample data:`, error.message);
        process.exit(1);
    }
}

module.exports = { generateSampleData };