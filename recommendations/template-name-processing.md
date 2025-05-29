# Template Name Processing Standardization

## Current State

Template names are processed inconsistently across the codebase:

1. **Storage**: Templates are stored as `{name}.json` files
2. **Display**: Templates show their title (from JSON) or filename without extension
3. **Processing**: `.json` is stripped in multiple places:
   - JavaScript (template-actions.js:229)
   - PHP (creation-table-setup-functions.php:197)

## Recommendation

### Principle: Process Once at the Source

**Standard**: Template identifiers should be stored and passed as base names (without extensions) throughout the application.

### Implementation:

1. **Data Structure**: 
   - Add a `basename` field to template data structure
   - Keep `filename` for full filename reference if needed
   
2. **Processing Location**:
   - Process filename → basename in `sip_load_templates_for_table()` (template-functions.php)
   - Pass basename in AJAX requests
   - Use basename directly in PHP without additional processing

3. **Benefits**:
   - Single source of truth for name processing
   - Clear distinction between display name (title) and system identifier (basename)
   - No redundant string manipulation

### Code Changes Needed:

1. **template-functions.php** (line ~222):
   ```php
   'basename' => basename($template_wip_file, '.json'),
   'filename' => basename($template_wip_file),
   ```

2. **template-actions.js** (line ~224):
   ```javascript
   const templateBasename = selectedRows[0].basename || selectedRows[0].filename.replace('.json', '');
   ```

3. **creation-table-setup-functions.php** (line ~197):
   ```php
   // Remove redundant processing
   $template_base = $creation_template_wip_name; // Already processed
   ```

This establishes a clear pattern: filenames are processed once when loaded, and base names are used for all operations.