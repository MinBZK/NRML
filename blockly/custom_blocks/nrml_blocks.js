/**
 * Custom Blockly blocks for NRML (Normalized Rule Model Language)
 * These blocks enable visual programming of NRML rules using Blockly
 */

// ============================================================================
// BLOCK 1: aggregation_count
// Represents NRML aggregation functions (count, sum, etc.)
// ============================================================================

Blockly.Blocks['aggregation_count'] = {
  init: function() {
    this.appendValueInput("COLLECTION")
        .setCheck(["Array", "List"])
        .appendField("count items in");

    this.appendValueInput("CONDITION")
        .setCheck("Boolean")
        .appendField("where");

    this.setOutput(true, "Number");
    this.setColour(230);
    this.setTooltip("Count items in a collection that match a condition");
    this.setHelpUrl("");

    // Store NRML-specific metadata
    this.extraState = {
      aggregationType: "count",
      nrmlRef: null,
      expressionChain: [],
      default: null
    };
  },

  /**
   * Serialize extra state (NRML references) to XML
   */
  mutationToDom: function() {
    const container = Blockly.utils.xml.createElement('mutation');
    if (this.extraState) {
      container.setAttribute('aggregationType', this.extraState.aggregationType || 'count');
      if (this.extraState.nrmlRef) {
        container.setAttribute('nrmlRef', this.extraState.nrmlRef);
      }
      if (this.extraState.expressionChain && this.extraState.expressionChain.length > 0) {
        container.setAttribute('expressionChain', JSON.stringify(this.extraState.expressionChain));
      }
      if (this.extraState.default !== null && this.extraState.default !== undefined) {
        container.setAttribute('default', JSON.stringify(this.extraState.default));
      }
    }
    return container;
  },

  /**
   * Deserialize extra state from XML
   */
  domToMutation: function(xmlElement) {
    this.extraState = this.extraState || {};
    this.extraState.aggregationType = xmlElement.getAttribute('aggregationType') || 'count';
    this.extraState.nrmlRef = xmlElement.getAttribute('nrmlRef') || null;

    const expressionChainStr = xmlElement.getAttribute('expressionChain');
    if (expressionChainStr) {
      this.extraState.expressionChain = JSON.parse(expressionChainStr);
    }

    const defaultStr = xmlElement.getAttribute('default');
    if (defaultStr) {
      this.extraState.default = JSON.parse(defaultStr);
    }

    // Update block label based on aggregation type
    this.updateBlockLabel();
  },

  /**
   * Update block label based on aggregation type
   */
  updateBlockLabel: function() {
    if (this.extraState && this.extraState.aggregationType) {
      const field = this.getField('AGGREGATION_TYPE');
      if (field) {
        field.setValue(this.extraState.aggregationType);
      }
    }
  },

  /**
   * Save extra state to JSON
   */
  saveExtraState: function() {
    return this.extraState;
  },

  /**
   * Load extra state from JSON
   */
  loadExtraState: function(state) {
    this.extraState = state || {};
    this.updateBlockLabel();
  }
};

// Aggregation sum variant
Blockly.Blocks['aggregation_sum'] = {
  init: function() {
    this.appendValueInput("COLLECTION")
        .setCheck(["Array", "List"])
        .appendField("sum");

    this.appendValueInput("PROPERTY")
        .appendField("of property");

    this.appendValueInput("CONDITION")
        .setCheck("Boolean")
        .appendField("where");

    this.setOutput(true, "Number");
    this.setColour(230);
    this.setTooltip("Sum a property across items in a collection that match a condition");
    this.setHelpUrl("");

    this.extraState = {
      aggregationType: "sum",
      nrmlRef: null,
      expressionChain: [],
      default: null
    };
  },

  mutationToDom: Blockly.Blocks['aggregation_count'].mutationToDom,
  domToMutation: Blockly.Blocks['aggregation_count'].domToMutation,
  saveExtraState: Blockly.Blocks['aggregation_count'].saveExtraState,
  loadExtraState: Blockly.Blocks['aggregation_count'].loadExtraState
};

// ============================================================================
// BLOCK 2: property_access
// Represents NRML multi-hop reference chains (role → property)
// ============================================================================

Blockly.Blocks['property_access'] = {
  init: function() {
    this.appendDummyInput()
        .appendField("property")
        .appendField(new Blockly.FieldTextInput("property_name"), "PROPERTY");

    this.appendValueInput("OBJECT")
        .setCheck(null)
        .appendField("of");

    this.setOutput(true, null);
    this.setColour(160);
    this.setTooltip("Access a property through an NRML reference chain");
    this.setHelpUrl("");

    // Store NRML-specific metadata
    this.extraState = {
      nrmlRef: null,
      referenceChain: [],
      propertyType: null,
      unit: null
    };
  },

  mutationToDom: function() {
    const container = Blockly.utils.xml.createElement('mutation');
    if (this.extraState) {
      if (this.extraState.nrmlRef) {
        container.setAttribute('nrmlRef', this.extraState.nrmlRef);
      }
      if (this.extraState.referenceChain && this.extraState.referenceChain.length > 0) {
        container.setAttribute('referenceChain', JSON.stringify(this.extraState.referenceChain));
      }
      if (this.extraState.propertyType) {
        container.setAttribute('propertyType', this.extraState.propertyType);
      }
      if (this.extraState.unit) {
        container.setAttribute('unit', this.extraState.unit);
      }
    }
    return container;
  },

  domToMutation: function(xmlElement) {
    this.extraState = this.extraState || {};
    this.extraState.nrmlRef = xmlElement.getAttribute('nrmlRef') || null;
    this.extraState.propertyType = xmlElement.getAttribute('propertyType') || null;
    this.extraState.unit = xmlElement.getAttribute('unit') || null;

    const referenceChainStr = xmlElement.getAttribute('referenceChain');
    if (referenceChainStr) {
      this.extraState.referenceChain = JSON.parse(referenceChainStr);
    }
  },

  saveExtraState: function() {
    return this.extraState;
  },

  loadExtraState: function(state) {
    this.extraState = state || {};
  }
};

// Simplified property access without "of" input (for direct property access)
Blockly.Blocks['property_access_direct'] = {
  init: function() {
    this.appendDummyInput()
        .appendField(new Blockly.FieldTextInput("property_name"), "PROPERTY");

    this.setOutput(true, null);
    this.setColour(160);
    this.setTooltip("Direct property access via NRML reference");
    this.setHelpUrl("");

    this.extraState = {
      nrmlRef: null,
      referenceChain: [],
      propertyType: null,
      unit: null
    };
  },

  mutationToDom: Blockly.Blocks['property_access'].mutationToDom,
  domToMutation: Blockly.Blocks['property_access'].domToMutation,
  saveExtraState: Blockly.Blocks['property_access'].saveExtraState,
  loadExtraState: Blockly.Blocks['property_access'].loadExtraState
};

// ============================================================================
// BLOCK 3: conditional_value
// Represents NRML conditional assignments (value with condition)
// ============================================================================

Blockly.Blocks['conditional_value'] = {
  init: function() {
    this.appendValueInput("VALUE")
        .appendField("value");

    this.appendValueInput("CONDITION")
        .setCheck("Boolean")
        .appendField("if");

    this.setOutput(true, null);
    this.setColour(210);
    this.setTooltip("Returns a value only if the condition is true");
    this.setHelpUrl("");

    // Store NRML-specific metadata
    this.extraState = {
      nrmlRef: null,
      nrmlType: "conditional_assignment",
      valueType: null
    };
  },

  mutationToDom: function() {
    const container = Blockly.utils.xml.createElement('mutation');
    if (this.extraState) {
      if (this.extraState.nrmlRef) {
        container.setAttribute('nrmlRef', this.extraState.nrmlRef);
      }
      if (this.extraState.nrmlType) {
        container.setAttribute('nrmlType', this.extraState.nrmlType);
      }
      if (this.extraState.valueType) {
        container.setAttribute('valueType', this.extraState.valueType);
      }
    }
    return container;
  },

  domToMutation: function(xmlElement) {
    this.extraState = this.extraState || {};
    this.extraState.nrmlRef = xmlElement.getAttribute('nrmlRef') || null;
    this.extraState.nrmlType = xmlElement.getAttribute('nrmlType') || 'conditional_assignment';
    this.extraState.valueType = xmlElement.getAttribute('valueType') || null;
  },

  saveExtraState: function() {
    return this.extraState;
  },

  loadExtraState: function(state) {
    this.extraState = state || {};
  }
};

// ============================================================================
// CODE GENERATORS (JavaScript/Python example)
// ============================================================================

// JavaScript code generator for aggregation_count
Blockly.JavaScript['aggregation_count'] = function(block) {
  const collection = Blockly.JavaScript.valueToCode(block, 'COLLECTION', Blockly.JavaScript.ORDER_MEMBER) || '[]';
  const condition = Blockly.JavaScript.valueToCode(block, 'CONDITION', Blockly.JavaScript.ORDER_NONE) || 'true';

  const defaultValue = block.extraState?.default?.value ?? 0;

  const code = `(function() {
    const coll = ${collection};
    if (!coll || coll.length === 0) return ${defaultValue};
    return coll.filter(item => ${condition}).length;
  })()`;

  return [code, Blockly.JavaScript.ORDER_FUNCTION_CALL];
};

// JavaScript code generator for aggregation_sum
Blockly.JavaScript['aggregation_sum'] = function(block) {
  const collection = Blockly.JavaScript.valueToCode(block, 'COLLECTION', Blockly.JavaScript.ORDER_MEMBER) || '[]';
  const property = Blockly.JavaScript.valueToCode(block, 'PROPERTY', Blockly.JavaScript.ORDER_MEMBER) || 'null';
  const condition = Blockly.JavaScript.valueToCode(block, 'CONDITION', Blockly.JavaScript.ORDER_NONE) || 'true';

  const defaultValue = block.extraState?.default?.value ?? 0;

  const code = `(function() {
    const coll = ${collection};
    if (!coll || coll.length === 0) return ${defaultValue};
    return coll.filter(item => ${condition}).reduce((sum, item) => sum + (item[${property}] || 0), 0);
  })()`;

  return [code, Blockly.JavaScript.ORDER_FUNCTION_CALL];
};

// JavaScript code generator for property_access
Blockly.JavaScript['property_access'] = function(block) {
  const propertyName = block.getFieldValue('PROPERTY');
  const object = Blockly.JavaScript.valueToCode(block, 'OBJECT', Blockly.JavaScript.ORDER_MEMBER) || 'null';

  const code = `${object}?.${propertyName}`;
  return [code, Blockly.JavaScript.ORDER_MEMBER];
};

// JavaScript code generator for property_access_direct
Blockly.JavaScript['property_access_direct'] = function(block) {
  const propertyName = block.getFieldValue('PROPERTY');

  // Use the NRML reference chain if available
  if (block.extraState?.referenceChain && block.extraState.referenceChain.length > 0) {
    // This would need to be resolved against the NRML context
    const code = `nrmlContext.resolve('${block.extraState.nrmlRef}')`;
    return [code, Blockly.JavaScript.ORDER_MEMBER];
  }

  const code = propertyName;
  return [code, Blockly.JavaScript.ORDER_ATOMIC];
};

// JavaScript code generator for conditional_value
Blockly.JavaScript['conditional_value'] = function(block) {
  const value = Blockly.JavaScript.valueToCode(block, 'VALUE', Blockly.JavaScript.ORDER_CONDITIONAL) || 'null';
  const condition = Blockly.JavaScript.valueToCode(block, 'CONDITION', Blockly.JavaScript.ORDER_NONE) || 'false';

  const code = `(${condition} ? ${value} : undefined)`;
  return [code, Blockly.JavaScript.ORDER_CONDITIONAL];
};

// ============================================================================
// NRML-SPECIFIC UTILITIES
// ============================================================================

/**
 * Convert Blockly workspace to NRML JSON
 * This would traverse the block tree and reconstruct NRML structure
 */
function blocklyToNRML(workspace) {
  const topBlocks = workspace.getTopBlocks(true);
  const nrml = {
    "$schema": "https://example.com/toka-corrected-schema.json",
    "version": "1.0",
    "language": "nl",
    "metadata": {},
    "facts": {}
  };

  // Process each top-level block
  topBlocks.forEach(block => {
    processBlockToNRML(block, nrml);
  });

  return nrml;
}

/**
 * Process a single block and add it to NRML structure
 */
function processBlockToNRML(block, nrml) {
  const blockType = block.type;

  switch(blockType) {
    case 'variables_set':
      return processVariableAssignment(block, nrml);
    case 'aggregation_count':
    case 'aggregation_sum':
      return processAggregation(block, nrml);
    case 'property_access':
    case 'property_access_direct':
      return processPropertyAccess(block, nrml);
    case 'conditional_value':
      return processConditionalValue(block, nrml);
    default:
      // Handle standard Blockly blocks
      return processStandardBlock(block, nrml);
  }
}

/**
 * Process aggregation block to NRML
 */
function processAggregation(block, nrml) {
  const aggregationType = block.extraState?.aggregationType || 'count';
  const expressionChain = block.extraState?.expressionChain || [];
  const defaultValue = block.extraState?.default;

  const nrmlExpression = {
    type: "aggregation",
    function: aggregationType,
    expression: expressionChain
  };

  // Add condition if present
  const conditionBlock = block.getInputTargetBlock('CONDITION');
  if (conditionBlock) {
    nrmlExpression.condition = processBlockToNRML(conditionBlock, nrml);
  }

  // Add default if present
  if (defaultValue !== null && defaultValue !== undefined) {
    nrmlExpression.default = defaultValue;
  }

  return nrmlExpression;
}

/**
 * Process property access block to NRML reference chain
 */
function processPropertyAccess(block, nrml) {
  const referenceChain = block.extraState?.referenceChain || [];

  // Return the reference chain (array of $ref objects)
  return referenceChain;
}

/**
 * Process conditional value block to NRML
 */
function processConditionalValue(block, nrml) {
  const valueBlock = block.getInputTargetBlock('VALUE');
  const conditionBlock = block.getInputTargetBlock('CONDITION');

  const nrmlConditional = {
    value: valueBlock ? processBlockToNRML(valueBlock, nrml) : null,
    condition: conditionBlock ? processBlockToNRML(conditionBlock, nrml) : null
  };

  return nrmlConditional;
}

/**
 * Convert NRML JSON to Blockly workspace
 * This would parse NRML and create corresponding blocks
 */
function nrmlToBlockly(nrml, workspace) {
  workspace.clear();

  // Process facts and create blocks
  if (nrml.facts) {
    Object.entries(nrml.facts).forEach(([factId, fact]) => {
      if (fact.items) {
        Object.entries(fact.items).forEach(([itemId, item]) => {
          if (item.versions) {
            item.versions.forEach(version => {
              if (version.expression) {
                createBlockFromNRML(version, workspace, factId, itemId);
              }
            });
          }
        });
      }
    });
  }

  return workspace;
}

/**
 * Create a Blockly block from NRML version data
 */
function createBlockFromNRML(version, workspace, factId, itemId) {
  const expression = version.expression;

  if (expression.type === 'aggregation') {
    const block = workspace.newBlock('aggregation_' + expression.function);
    block.extraState = {
      aggregationType: expression.function,
      nrmlRef: `#/facts/${factId}/items/${itemId}`,
      expressionChain: expression.expression || [],
      default: expression.default || null
    };
    block.initSvg();
    block.render();
    return block;
  }

  if (expression.type === 'arithmetic') {
    const operatorMap = {
      'add': 'ADD',
      'subtract': 'MINUS',
      'multiply': 'MULTIPLY',
      'divide': 'DIVIDE'
    };

    const block = workspace.newBlock('math_arithmetic');
    block.setFieldValue(operatorMap[expression.operator] || 'ADD', 'OP');
    block.extraState = {
      nrmlType: 'arithmetic',
      nrmlOperator: expression.operator,
      nrmlRef: `#/facts/${factId}/items/${itemId}`
    };
    block.initSvg();
    block.render();
    return block;
  }

  // Handle other expression types...
  return null;
}

// ============================================================================
// EXPORT
// ============================================================================

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    blocklyToNRML,
    nrmlToBlockly,
    processBlockToNRML,
    createBlockFromNRML
  };
}
