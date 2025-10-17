/**
 * Example TypeScript usage of NRML Blockly custom blocks
 * Demonstrates type-safe usage of the custom block API
 */

/// <reference path="nrml_blocks.d.ts" />

import * as Blockly from 'blockly';
import * as NRMLBlockly from './nrml_blocks';

// ============================================================================
// Example 1: Creating Custom Blocks Programmatically
// ============================================================================

function createKinderbijslagBlocks(workspace: Blockly.Workspace): void {
  // Create variable for children collection
  workspace.createVariable('kinderen', null, 'var-kinderen');

  // Create aggregation count block for counting younger children
  const countBlock = NRMLBlockly.createAggregationCountBlock(workspace, {
    nrmlRef: '#/facts/28b83711-2080-469f-be02-ae8f963affb9/items/1100dac1-6d75-498a-b5db-6b4faacf77b0',
    expressionChain: [
      {
        $ref: '#/facts/43d7495f-da13-4bbf-a485-676cbfe7cedc/items/47b9bf9b-e998-421a-8725-3e2335c9c234'
      }
    ],
    default: { value: 0 }
  });

  // Create property access block for age
  const propertyBlock = NRMLBlockly.createPropertyAccessBlock(workspace, {
    propertyName: 'leeftijd',
    nrmlRef: '#/facts/01290a59-b6d1-4caa-9d51-f53e632ac36f/items/0fe3c5a2-a33a-4a98-9abc-a98929783499',
    referenceChain: [
      {
        $ref: '#/facts/43d7495f-da13-4bbf-a485-676cbfe7cedc/items/47b9bf9b-e998-421a-8725-3e2335c9c234'
      },
      {
        $ref: '#/facts/01290a59-b6d1-4caa-9d51-f53e632ac36f/items/0fe3c5a2-a33a-4a98-9abc-a98929783499'
      }
    ],
    propertyType: 'numeric',
    unit: 'jaar'
  });

  // Create comparison block
  const compareBlock = workspace.newBlock('logic_compare') as Blockly.Block;
  compareBlock.setFieldValue('LTE', 'OP');

  // Create number block
  const numBlock = workspace.newBlock('math_number') as Blockly.Block;
  numBlock.setFieldValue(10, 'NUM');

  // Connect blocks to form: count(kinderen where leeftijd <= 10)
  if (compareBlock.getInput('A') && propertyBlock.outputConnection) {
    compareBlock.getInput('A')!.connection!.connect(propertyBlock.outputConnection);
  }
  if (compareBlock.getInput('B') && numBlock.outputConnection) {
    compareBlock.getInput('B')!.connection!.connect(numBlock.outputConnection);
  }
  if (countBlock.getInput('CONDITION') && compareBlock.outputConnection) {
    countBlock.getInput('CONDITION')!.connection!.connect(compareBlock.outputConnection);
  }

  // Position and render
  countBlock.moveBy(100, 100);
  countBlock.initSvg();
  countBlock.render();

  console.log('✅ Kinderbijslag blocks created successfully');
}

// ============================================================================
// Example 2: Converting NRML to Blockly
// ============================================================================

async function loadNRMLFile(filePath: string, workspace: Blockly.Workspace): Promise<void> {
  try {
    // Load NRML JSON file
    const response = await fetch(filePath);
    const nrml: NRMLBlockly.NRMLDocument = await response.json();

    console.log(`📥 Loading NRML: ${nrml.metadata.description}`);
    console.log(`   Language: ${nrml.language}`);
    console.log(`   Facts: ${Object.keys(nrml.facts).length}`);

    // Clear workspace
    workspace.clear();

    // Convert NRML to Blockly blocks
    NRMLBlockly.nrmlToBlockly(nrml, workspace);

    console.log('✅ NRML loaded into Blockly workspace');

    // Validate all references
    const validation = NRMLBlockly.validateNRMLReferences(workspace, nrml);
    if (!validation.valid) {
      console.warn('⚠️ Validation warnings:', validation.errors);
    }

  } catch (error) {
    console.error('❌ Failed to load NRML:', error);
    throw error;
  }
}

// ============================================================================
// Example 3: Converting Blockly to NRML
// ============================================================================

function saveWorkspaceAsNRML(workspace: Blockly.Workspace, outputPath: string): void {
  try {
    // Convert workspace to NRML
    const nrml = NRMLBlockly.blocklyToNRML(workspace);

    // Pretty print JSON
    const json = JSON.stringify(nrml, null, 2);

    console.log('📤 Converted workspace to NRML:');
    console.log(`   Facts: ${Object.keys(nrml.facts).length}`);
    console.log(`   Size: ${json.length} characters`);

    // In browser: download as file
    if (typeof window !== 'undefined') {
      const blob = new Blob([json], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = outputPath;
      a.click();
      URL.revokeObjectURL(url);
      console.log(`✅ Downloaded as ${outputPath}`);
    }

    // In Node.js: write to file
    if (typeof require !== 'undefined') {
      const fs = require('fs');
      fs.writeFileSync(outputPath, json, 'utf-8');
      console.log(`✅ Saved to ${outputPath}`);
    }

  } catch (error) {
    console.error('❌ Failed to convert to NRML:', error);
    throw error;
  }
}

// ============================================================================
// Example 4: Analyzing Block References
// ============================================================================

function analyzeWorkspaceReferences(workspace: Blockly.Workspace, nrml: NRMLBlockly.NRMLDocument): void {
  console.log('🔍 Analyzing workspace references...\n');

  // Extract all NRML references
  const references = NRMLBlockly.extractNRMLReferences(workspace);

  console.log(`Found ${references.length} NRML references:\n`);

  references.forEach((ref) => {
    const resolved = NRMLBlockly.resolveNRMLReference(ref, nrml, 'nl');
    console.log(`  ${ref}`);
    console.log(`  → ${resolved || '⚠️ UNRESOLVED'}\n`);
  });

  // Check for custom blocks
  const customBlocks = workspace.getAllBlocks(false).filter((block) => {
    return ['aggregation_count', 'aggregation_sum', 'property_access', 'conditional_value'].includes(block.type);
  });

  console.log(`\n📊 Custom block usage:`);
  console.log(`  aggregation_count: ${customBlocks.filter(b => b.type === 'aggregation_count').length}`);
  console.log(`  aggregation_sum: ${customBlocks.filter(b => b.type === 'aggregation_sum').length}`);
  console.log(`  property_access: ${customBlocks.filter(b => b.type === 'property_access').length}`);
  console.log(`  conditional_value: ${customBlocks.filter(b => b.type === 'conditional_value').length}`);
}

// ============================================================================
// Example 5: Round-Trip Test
// ============================================================================

async function testRoundTrip(nrmlFilePath: string, workspace: Blockly.Workspace): Promise<boolean> {
  console.log('🔄 Testing round-trip conversion...\n');

  // Load original NRML
  const response = await fetch(nrmlFilePath);
  const originalNRML: NRMLBlockly.NRMLDocument = await response.json();

  console.log('1️⃣ Loaded original NRML');

  // Convert to Blockly
  NRMLBlockly.nrmlToBlockly(originalNRML, workspace);
  console.log('2️⃣ Converted to Blockly blocks');

  // Convert back to NRML
  const reconstructedNRML = NRMLBlockly.blocklyToNRML(workspace);
  console.log('3️⃣ Converted back to NRML');

  // Compare
  const originalJSON = JSON.stringify(originalNRML, null, 2);
  const reconstructedJSON = JSON.stringify(reconstructedNRML, null, 2);

  if (originalJSON === reconstructedJSON) {
    console.log('✅ Round-trip successful! NRMLs are identical.');
    return true;
  } else {
    console.log('⚠️ Round-trip produced differences:');

    // Find differences
    const originalLines = originalJSON.split('\n');
    const reconstructedLines = reconstructedJSON.split('\n');

    for (let i = 0; i < Math.max(originalLines.length, reconstructedLines.length); i++) {
      if (originalLines[i] !== reconstructedLines[i]) {
        console.log(`  Line ${i + 1}:`);
        console.log(`    Original:      ${originalLines[i]}`);
        console.log(`    Reconstructed: ${reconstructedLines[i]}`);
        if (i > 10) {
          console.log('  ... (more differences)');
          break;
        }
      }
    }

    return false;
  }
}

// ============================================================================
// Example 6: Working with Extra State
// ============================================================================

function inspectBlockExtraState(block: Blockly.Block): void {
  console.log(`\n🔍 Inspecting block: ${block.type} (${block.id})`);

  // Check if block has extra state
  if ('extraState' in block) {
    const extraState = (block as any).extraState;

    console.log('  Extra State:');
    console.log(`    nrmlRef: ${extraState.nrmlRef || 'none'}`);

    if (extraState.aggregationType) {
      console.log(`    aggregationType: ${extraState.aggregationType}`);
      console.log(`    expressionChain: ${JSON.stringify(extraState.expressionChain)}`);
      console.log(`    default: ${JSON.stringify(extraState.default)}`);
    }

    if (extraState.referenceChain) {
      console.log(`    referenceChain: ${JSON.stringify(extraState.referenceChain)}`);
      console.log(`    propertyType: ${extraState.propertyType || 'none'}`);
      console.log(`    unit: ${extraState.unit || 'none'}`);
    }

    if (extraState.nrmlOperator) {
      console.log(`    nrmlOperator: ${extraState.nrmlOperator}`);
    }
  } else {
    console.log('  No extra state (standard Blockly block)');
  }
}

// ============================================================================
// Main Demo Function
// ============================================================================

async function runDemo(): Promise<void> {
  console.log('🚀 NRML Blockly Custom Blocks Demo\n');
  console.log('=' .repeat(60) + '\n');

  // Create workspace (in browser or headless)
  const workspace = new Blockly.Workspace();

  try {
    // Example 1: Create blocks programmatically
    console.log('📝 Example 1: Creating blocks programmatically\n');
    createKinderbijslagBlocks(workspace);
    console.log('\n');

    // Example 2: Load NRML file
    console.log('=' .repeat(60) + '\n');
    console.log('📝 Example 2: Loading NRML file\n');
    await loadNRMLFile('../../rules/kinderbijslag.nrml.json', workspace);
    console.log('\n');

    // Example 3: Analyze references
    console.log('=' .repeat(60) + '\n');
    console.log('📝 Example 3: Analyzing references\n');
    const response = await fetch('../../rules/kinderbijslag.nrml.json');
    const nrml = await response.json();
    analyzeWorkspaceReferences(workspace, nrml);
    console.log('\n');

    // Example 4: Inspect block details
    console.log('=' .repeat(60) + '\n');
    console.log('📝 Example 4: Inspecting blocks\n');
    const allBlocks = workspace.getAllBlocks(false);
    allBlocks.slice(0, 3).forEach(inspectBlockExtraState);
    console.log('\n');

    // Example 5: Test round-trip
    console.log('=' .repeat(60) + '\n');
    console.log('📝 Example 5: Round-trip test\n');
    await testRoundTrip('../../rules/kinderbijslag.nrml.json', workspace);
    console.log('\n');

    // Example 6: Save as NRML
    console.log('=' .repeat(60) + '\n');
    console.log('📝 Example 6: Saving as NRML\n');
    saveWorkspaceAsNRML(workspace, 'output_kinderbijslag.nrml.json');
    console.log('\n');

    console.log('=' .repeat(60));
    console.log('✅ All examples completed successfully!');

  } catch (error) {
    console.error('❌ Demo failed:', error);
    throw error;
  }
}

// Run demo if this file is executed directly
if (typeof require !== 'undefined' && require.main === module) {
  runDemo().catch(console.error);
}

// Export for use in other modules
export {
  createKinderbijslagBlocks,
  loadNRMLFile,
  saveWorkspaceAsNRML,
  analyzeWorkspaceReferences,
  testRoundTrip,
  inspectBlockExtraState,
  runDemo
};
