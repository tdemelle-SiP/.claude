# SiP Development Documentation Standards

This guide establishes documentation standards for the SiP Plugin Suite, ensuring code is self-documenting, maintainable, and accessible to all developers.

## Why Documentation Matters

In the SiP ecosystem, proper documentation is critical because:

1. **Complex Interactions** - Functions often span multiple modules and files
2. **Cross-Module Dependencies** - Code in one module frequently calls functions in another
3. **Data Structure Contracts** - Functions expect specific object structures that aren't obvious
4. **Async Operations** - AJAX flows require clear understanding of request/response cycles
5. **State Management** - Functions depend on global state being set correctly

## Documentation Standards

### JavaScript Documentation (JSDoc)

Every JavaScript function must include JSDoc comments that document the **interface contract**, not the implementation:

```javascript
/**
 * Updates product table highlighting based on template data
 * @param {Object|null} templateData - Template WIP data or null to clear highlighting
 * @param {string} templateData.blueprint_id - Blueprint ID for highlighting
 * @param {string} templateData.source_product_id - Parent product ID
 * @param {Array} templateData.child_products - Array of child product objects
 * @param {string} templateData.child_products[].printify_product_id - Used for row matching
 * @returns {void}
 * @throws {Error} If DataTable not initialized
 */
function updateProductTableHighlights(templateData) {
    // Implementation...
}
```

#### Required Elements

1. **Function Purpose** - One-line description of what the function does
2. **Parameters** - All parameters with:
   - Type (including union types like `Object|null`)
   - Parameter name
   - Description of purpose/usage
   - Object properties documented with dot notation
   - Array element types documented with brackets
3. **Return Value** - What the function returns (use `@returns {void}` for no return)
4. **Exceptions** - Document any errors thrown with `@throws`
5. **Side Effects** - Document any global state changes or DOM modifications

#### Complex Parameter Documentation

For objects with nested properties:

```javascript
/**
 * Sets the creation template WIP data in global scope and localStorage
 * @param {Object|null} data - Template WIP data object or null to clear
 * @param {string} data.template_title - Template display title
 * @param {number|string} data.blueprint_id - Blueprint identifier
 * @param {string} data.source_product_id - Parent product ID
 * @param {Array} data.child_products - Array of child product objects
 * @param {string} data.child_products[].printify_product_id - Product ID
 * @param {string} data.child_products[].title - Product title
 * @param {string|null} wipName - WIP filename with _wip.json suffix
 * @param {string|null} templateFile - Original template filename
 * @returns {void}
 */
```

### PHP Documentation (PHPDoc)

Every PHP function must include PHPDoc comments following the same principles:

```php
/**
 * Handle creation setup actions from AJAX requests
 * Routes creation_setup_action to appropriate handler functions
 * 
 * Expected $_POST parameters:
 * - creation_setup_action: string - The specific action to perform
 * - template_basename: string - Template identifier (for check_and_load_template_wip)
 * 
 * @return void Outputs JSON response via SiP_AJAX_Response
 * @throws Exception If action handler not found
 */
function sip_handle_creation_setup_action() {
    // Implementation...
}
```

#### PHP-Specific Requirements

1. **Global Variable Dependencies** - Document any `$_POST`, `$_GET`, or global variables used
2. **Database Operations** - Document any database tables accessed
3. **File Operations** - Document file paths and operations performed
4. **WordPress Hooks** - Document any hooks fired or filters applied

### Return Value Documentation

Be specific about return structures:

```php
/**
 * @return array Result array containing:
 *   - success: bool - Whether the operation succeeded
 *   - message: string - Error message if failed
 *   - path: string - Full path to created WIP file if successful
 *   - data: array - Parsed JSON data if successful
 */
```

## What NOT to Document

Avoid redundant documentation that adds no value:

### ❌ Bad Documentation (Noise)
```javascript
/**
 * @param {string} name - The name
 * @param {number} id - The ID  
 * @returns {boolean} - Returns true or false
 */
function checkName(name, id) {
    return name.length > 0;
}
```

### ✅ Good Documentation (Value)
```javascript
/**
 * Validates that a product name meets minimum requirements
 * @param {string} name - Product name to validate
 * @param {number} id - Product ID for error reporting
 * @returns {boolean} True if name has at least one character
 */
function checkName(name, id) {
    return name.length > 0;
}
```

## Documentation Patterns

### AJAX Handler Documentation

```javascript
/**
 * Handles form submission for template actions
 * Routes to appropriate action handler based on selected action
 * 
 * @param {Event} e - Form submit event
 * @returns {void}
 * 
 * Actions handled:
 * - check_and_load_template_wip: Loads template into creation table
 * - delete_template: Removes template file
 */
function handleTemplateActionFormSubmit(e) {
    // Implementation...
}
```

### State Management Documentation

```javascript
/**
 * Tracks UI state and persists to localStorage
 * Captures current values of form elements for restoration
 * 
 * @returns {void}
 * 
 * Persisted state structure:
 * {
 *   'sip-printify-manager': {
 *     'creations-table': {
 *       'creation_action': string
 *     }
 *   }
 * }
 */
function trackCreationTableUi() {
    // Implementation...
}
```

### Cross-Module Operation Documentation

```javascript
/**
 * Initiates cross-table AJAX operation
 * Template table action triggers creation table data load
 * 
 * @param {string} templateBasename - Template identifier without extension
 * @returns {Promise} Resolves when creation table is loaded
 * 
 * @fires SiP.PrintifyManager.creationTableSetupActions.reloadCreationTable
 * @fires SiP.PrintifyManager.imageActions.updateImageTableStatus
 * @fires SiP.PrintifyManager.productActions.updateProductTableHighlights
 */
```

## Implementation Checklist

When documenting functions:

- [ ] Purpose is clear from first line
- [ ] All parameters documented with types
- [ ] Complex objects have properties documented
- [ ] Return value documented (even if void)
- [ ] Exceptions/errors documented
- [ ] Side effects noted
- [ ] Cross-module dependencies identified
- [ ] Examples provided for complex usage

## Tools and Automation

### JSDoc Generation
Use JSDoc tools to generate HTML documentation:
```bash
jsdoc assets/js/modules/*.js -d docs/js
```

### PHPDoc Generation
Use phpDocumentor for PHP documentation:
```bash
phpdoc -d includes/ -t docs/php
```

### IDE Integration
Modern IDEs use these comments for:
- Autocomplete suggestions
- Type checking
- Parameter hints
- Error detection

## Benefits of Proper Documentation

1. **Reduced Debugging Time** - Clear contracts prevent incorrect usage
2. **Faster Onboarding** - New developers understand interfaces immediately
3. **Better Maintenance** - Changes to interfaces are immediately visible
4. **Improved Collaboration** - Team members understand each other's code
5. **Error Prevention** - Type information prevents common mistakes

## When to Update Documentation

Update documentation when:
- Adding new parameters
- Changing parameter types
- Modifying return values
- Adding error conditions
- Changing function behavior
- Adding side effects

## Documentation Review Checklist

Before committing code:
1. All new functions have complete documentation
2. Modified functions have updated documentation
3. Documentation matches actual implementation
4. Examples work as written
5. No outdated information remains

## Architectural Documentation Standards

Beyond code-level documentation, the SiP Plugin Suite requires architectural documentation that explains system design and deviations from standard patterns.

### Core Documentation Principle

Documentation should consist of:
1. **General Rules and Principles** - Standard patterns that apply broadly across the plugin suite
2. **Documented Exceptions** - Clear identification of where and why code deviates from standards
3. **Rationale** - Explanations for architectural decisions, especially non-standard approaches

### When to Document Architectural Patterns

Create or update architectural documentation when:
- Implementing a pattern that deviates from SiP standards
- Creating a hybrid or non-standard architecture
- Making design decisions that future developers might question
- Building systems with complex interactions between components

### What Makes Good Architectural Documentation

#### 1. Document the "Why" Not the "What"
```markdown
❌ Bad: "The Creation Table uses data-template='true' on rows"
✅ Good: "Template variant rows use data-template='true' because the hybrid architecture requires distinguishing between DataTables-managed and custom-injected rows"
```

#### 2. Identify Standard vs. Exception
```markdown
**Standard Pattern**: DataTables provides `headerCheckbox: true` in the select configuration.

**Creation Table Exception**: Uses custom `updateHeaderCheckboxState()` function because:
- Must count both DataTables rows AND custom injected rows
- Must exclude template variant rows from selection logic
- Standard DataTables header checkbox only knows about its own rows
```

#### 3. Provide Context for Design Decisions
```markdown
### Why This Architecture

This design was chosen because:
- Child products are the primary unit of work (what users upload/publish)
- Variants are secondary details that belong to child products
- Summary rows need special behaviors DataTables can't provide
```

### Implementation Details vs. Architectural Patterns

**Architectural Documentation Should Include:**
- Design patterns and their rationale
- Deviations from standard approaches
- System interactions and dependencies
- Data flow and state management approaches

**Architectural Documentation Should NOT Include:**
- Specific line numbers (they change)
- Exact function names (unless they represent a pattern)
- Implementation details that follow standard patterns
- Bug fixes or minor adjustments

### Example: Documenting the Creation Table

The Creation Table documentation exemplifies good architectural documentation:

1. **Explains the Hybrid Architecture** - Why it exists and what problems it solves
2. **Documents Exceptions** - Lists specific deviations from DataTables standards
3. **Provides Rationale** - Explains why each exception is necessary
4. **Maintains Abstraction** - Focuses on patterns, not implementation details

### Maintenance of Architectural Documentation

Review and update architectural documentation when:
- Discovering undocumented patterns during bug fixes
- Implementing new features that follow non-standard approaches
- Refactoring reveals assumptions that should be documented
- Team members have questions about "why" something works a certain way

By maintaining both code-level and architectural documentation, the SiP Plugin Suite ensures developers understand not just how to use the code, but why it was designed that way.

By following these standards, the SiP Plugin Suite maintains high-quality, self-documenting code that serves as both implementation and reference.