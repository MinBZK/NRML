/**
 * TypeScript definitions for NRML Blockly custom blocks
 * Provides type safety when using the custom block API
 */

/// <reference types="blockly" />

declare namespace NRMLBlockly {

  // ============================================================================
  // NRML Reference Types
  // ============================================================================

  /**
   * NRML reference object pointing to a fact, role, or property
   */
  interface NRMLReference {
    $ref: string;
  }

  /**
   * NRML reference chain (array of references for multi-hop navigation)
   */
  type NRMLReferenceChain = NRMLReference[];

  /**
   * NRML value with optional unit
   */
  interface NRMLValue {
    value: number | string | boolean;
    unit?: string;
  }

  // ============================================================================
  // Extra State Interfaces
  // ============================================================================

  /**
   * Base extra state for all NRML blocks
   */
  interface BaseExtraState {
    nrmlRef?: string;
    nrmlType?: string;
  }

  /**
   * Extra state for aggregation blocks
   */
  interface AggregationExtraState extends BaseExtraState {
    aggregationType: 'count' | 'sum' | 'average' | 'min' | 'max';
    expressionChain: NRMLReferenceChain;
    default?: NRMLValue;
  }

  /**
   * Extra state for property access blocks
   */
  interface PropertyAccessExtraState extends BaseExtraState {
    referenceChain: NRMLReferenceChain;
    propertyType?: 'numeric' | 'boolean' | 'string' | 'date' | 'characteristic';
    unit?: string;
  }

  /**
   * Extra state for conditional value blocks
   */
  interface ConditionalValueExtraState extends BaseExtraState {
    valueType?: string;
  }

  /**
   * Extra state for arithmetic blocks (extends standard blocks)
   */
  interface ArithmeticExtraState extends BaseExtraState {
    nrmlOperator?: 'add' | 'subtract' | 'multiply' | 'divide';
  }

  // ============================================================================
  // Block Interfaces
  // ============================================================================

  /**
   * Aggregation count block
   */
  interface AggregationCountBlock extends Blockly.Block {
    type: 'aggregation_count';
    extraState: AggregationExtraState;
  }

  /**
   * Aggregation sum block
   */
  interface AggregationSumBlock extends Blockly.Block {
    type: 'aggregation_sum';
    extraState: AggregationExtraState;
  }

  /**
   * Property access block
   */
  interface PropertyAccessBlock extends Blockly.Block {
    type: 'property_access';
    extraState: PropertyAccessExtraState;
  }

  /**
   * Direct property access block (no context object)
   */
  interface PropertyAccessDirectBlock extends Blockly.Block {
    type: 'property_access_direct';
    extraState: PropertyAccessExtraState;
  }

  /**
   * Conditional value block
   */
  interface ConditionalValueBlock extends Blockly.Block {
    type: 'conditional_value';
    extraState: ConditionalValueExtraState;
  }

  /**
   * Union type for all custom NRML blocks
   */
  type CustomBlock =
    | AggregationCountBlock
    | AggregationSumBlock
    | PropertyAccessBlock
    | PropertyAccessDirectBlock
    | ConditionalValueBlock;

  // ============================================================================
  // NRML Data Types
  // ============================================================================

  /**
   * NRML metadata
   */
  interface NRMLMetadata {
    version: string;
    language: string;
    created?: string;
    description?: string;
    legal_basis?: string;
  }

  /**
   * NRML fact definition
   */
  interface NRMLFact {
    name: {
      nl: string;
      en: string;
    };
    definite_article?: {
      nl: string;
      en: string;
    };
    animated?: boolean;
    items?: {
      [itemId: string]: NRMLItem;
    };
  }

  /**
   * NRML item (property, role, or characteristic)
   */
  interface NRMLItem {
    name: {
      nl: string;
      en: string;
    };
    article?: {
      nl: string;
      en: string;
    };
    plural?: {
      nl: string;
      en: string;
    };
    versions: NRMLVersion[];
  }

  /**
   * NRML version (time-based variant of an item)
   */
  interface NRMLVersion {
    validFrom: string;
    validTo?: string;
    type?: string;
    subtype?: string;
    unit?: string;
    precision?: number;
    target?: NRMLReferenceChain;
    value?: NRMLValue;
    expression?: NRMLExpression;
    condition?: NRMLCondition;
    arguments?: any[];
  }

  /**
   * NRML expression (calculation, aggregation, etc.)
   */
  interface NRMLExpression {
    type: 'aggregation' | 'arithmetic' | 'reference';
    function?: string;
    operator?: string;
    expression?: NRMLReferenceChain;
    arguments?: any[];
    condition?: NRMLCondition;
    default?: NRMLValue;
  }

  /**
   * NRML condition (comparison, logical operation, etc.)
   */
  interface NRMLCondition {
    type: 'comparison' | 'allOf' | 'anyOf' | 'not' | 'exists' | 'notExists';
    operator?: string;
    arguments?: any[];
    conditions?: NRMLCondition[];
    condition?: NRMLCondition;
    characteristic?: NRMLReferenceChain;
  }

  /**
   * Complete NRML document structure
   */
  interface NRMLDocument {
    $schema?: string;
    version: string;
    language: string;
    metadata: NRMLMetadata;
    facts: {
      [factId: string]: NRMLFact;
    };
  }

  // ============================================================================
  // Blockly Variable Metadata
  // ============================================================================

  /**
   * Extended variable metadata for NRML
   */
  interface NRMLVariable {
    id: string;
    name: string;
    type: string;
    unit?: string;
    precision?: number;
    nrmlRef?: string;
    itemType?: string;
    properties?: NRMLPropertyMetadata[];
  }

  /**
   * Property metadata for NRML variables
   */
  interface NRMLPropertyMetadata {
    name: string;
    type: string;
    unit?: string;
    precision?: number;
    nrmlRef?: string;
  }

  // ============================================================================
  // Conversion Functions
  // ============================================================================

  /**
   * Convert a Blockly workspace to NRML JSON
   * @param workspace The Blockly workspace to convert
   * @returns NRML document
   */
  function blocklyToNRML(workspace: Blockly.Workspace): NRMLDocument;

  /**
   * Convert NRML JSON to Blockly workspace
   * @param nrml The NRML document to convert
   * @param workspace The target Blockly workspace
   * @returns The populated workspace
   */
  function nrmlToBlockly(nrml: NRMLDocument, workspace: Blockly.Workspace): Blockly.Workspace;

  /**
   * Process a single block to NRML structure
   * @param block The block to process
   * @param nrml The NRML document being built
   * @returns NRML expression or condition
   */
  function processBlockToNRML(
    block: Blockly.Block,
    nrml: NRMLDocument
  ): NRMLExpression | NRMLCondition | NRMLReferenceChain | null;

  /**
   * Create a Blockly block from NRML version data
   * @param version The NRML version to convert
   * @param workspace The target workspace
   * @param factId The fact UUID
   * @param itemId The item UUID
   * @returns The created block
   */
  function createBlockFromNRML(
    version: NRMLVersion,
    workspace: Blockly.Workspace,
    factId: string,
    itemId: string
  ): Blockly.Block | null;

  // ============================================================================
  // Helper Functions
  // ============================================================================

  /**
   * Resolve an NRML reference to its human-readable name
   * @param ref The NRML reference path
   * @param nrml The NRML document
   * @param language The language code (default: 'nl')
   * @returns The resolved name
   */
  function resolveNRMLReference(
    ref: string,
    nrml: NRMLDocument,
    language?: string
  ): string | null;

  /**
   * Resolve a reference chain to a human-readable path
   * @param chain The reference chain
   * @param nrml The NRML document
   * @param language The language code (default: 'nl')
   * @returns The resolved path string
   */
  function resolveNRMLChain(
    chain: NRMLReferenceChain,
    nrml: NRMLDocument,
    language?: string
  ): string;

  /**
   * Extract all NRML references from a workspace
   * @param workspace The workspace to analyze
   * @returns Array of unique NRML reference paths
   */
  function extractNRMLReferences(workspace: Blockly.Workspace): string[];

  /**
   * Validate that all NRML references in workspace are valid
   * @param workspace The workspace to validate
   * @param nrml The NRML document to validate against
   * @returns Validation result with errors
   */
  function validateNRMLReferences(
    workspace: Blockly.Workspace,
    nrml: NRMLDocument
  ): {
    valid: boolean;
    errors: Array<{
      blockId: string;
      reference: string;
      message: string;
    }>;
  };

  // ============================================================================
  // Block Builder Functions
  // ============================================================================

  /**
   * Create an aggregation count block programmatically
   */
  function createAggregationCountBlock(
    workspace: Blockly.Workspace,
    options: {
      nrmlRef: string;
      expressionChain: NRMLReferenceChain;
      default?: NRMLValue;
    }
  ): AggregationCountBlock;

  /**
   * Create an aggregation sum block programmatically
   */
  function createAggregationSumBlock(
    workspace: Blockly.Workspace,
    options: {
      nrmlRef: string;
      expressionChain: NRMLReferenceChain;
      default?: NRMLValue;
    }
  ): AggregationSumBlock;

  /**
   * Create a property access block programmatically
   */
  function createPropertyAccessBlock(
    workspace: Blockly.Workspace,
    options: {
      propertyName: string;
      nrmlRef: string;
      referenceChain: NRMLReferenceChain;
      propertyType?: string;
      unit?: string;
    }
  ): PropertyAccessBlock;

  /**
   * Create a conditional value block programmatically
   */
  function createConditionalValueBlock(
    workspace: Blockly.Workspace,
    options: {
      nrmlRef: string;
      valueType?: string;
    }
  ): ConditionalValueBlock;
}

// Export for module usage
export = NRMLBlockly;
export as namespace NRMLBlockly;
