# SIP Printify Manager Architecture Documentation

## Dynamic Row Highlighting System

The SIP Printify Manager implements a sophisticated row highlighting system that visually indicates relationships between data across multiple tables when a template is loaded into the product creation table.

### Overview

When a template is loaded into the creation table, the system dynamically highlights related rows across all four main tables (Product, Template, Image, and Creation tables) to show the relationships between:
- The source blueprint
- The source product (parent)
- Child products
- Associated templates
- Related images

### Color System

The highlighting uses CSS variables defined in `variables.css`:

```css
/* Template-based Row Highlighting Colors */
--template-dark: #dfc1a6;      /* Darkest - Blueprint rows */
--template: #e7c8ac;           /* Medium - Parent/template rows */
--template-light: #eaded5;     /* Lightest - Child/variant rows (fallback) */
--work-in-progress: #dcf3ff;   /* Blue - WIP status */
--uploaded-unpublished: #bfdfc5; /* Light green - Uploaded but unpublished */
--uploaded-published: #7bfd83;   /* Green - Published */
```

#### Status-Based Highlighting

Child products in both the Product Table and Creation Table use status-based colors instead of the generic template color:
- **Work in Progress**: `--work-in-progress` (#dcf3ff)
- **Uploaded Unpublished**: `--uploaded-unpublished` (#bfdfc5) 
- **Uploaded Published**: `--uploaded-published` (#7bfd83)
- **Fallback**: `--template-light` (#eaded5) for products without specific status

### Implementation Details

#### 1. CSS Structure (tables.css)

The CSS uses a combination of structural classes (always present) and relational classes (dynamically added):

```css
/* Only highlight when both structural AND relational classes are present */
table.display.dataTable .blueprint-summary-row.template-blueprint {
    box-shadow: inset 0 0 0 9999px var(--template-dark) !important;
    color: #000 !important;
}
```

#### 2. JavaScript Implementation

Each table has its own highlighting function:
- `updateProductTableHighlights()` in `product-actions.js`
- `updateTemplateTableHighlights()` in `template-actions.js`
- `updateImageTableHighlights()` in `image-actions.js`

**Important Note**: Blueprint rows in the product table are created by DataTables' rowGroup feature and are NOT part of the regular rows collection. They must be targeted directly with jQuery selectors.

#### 3. Data Flow

1. Template data source:
   - The highlighting functions receive data from the **template_wip file** (not the template file)
   - Accessed via `window.creationTemplateWipData.data`
   - Contains the current working state of the template loaded in the creation table

2. Template data structure:
   - `blueprint_id`: The blueprint ID (e.g., 6)
   - `source_product_id`: The parent product ID
   - `child_products`: Array of child product data, each containing:
     - `printify_product_id`: The Printify product ID used for matching

3. The highlighting functions:
   - Clear previous highlighting classes
   - Extract IDs from the template_wip data
   - Apply appropriate classes to matching rows

#### 4. Trigger Points

Highlighting is updated when:

1. **Page Load** - If a template is already loaded:
   ```javascript
   // In product-actions.js initializeProductDataTable()
   if (window.creationTemplateWipData && window.creationTemplateWipData.data) {
       debug.log("There is a loaded wip file, calling updateProductTableHighlights():", window.creationTemplateWipData.data.template_title);
       updateProductTableHighlights(window.creationTemplateWipData.data);
   }
   ```

2. **Template Loading**:
   - Via template table: `loadTemplateIntoCreationTable()`
   - Via creation table setup: `setupCreationTableActions()`
   - Both call all three highlighting functions with the template data

3. **Template Closing**:
   - When creation table is closed, pass null to clear highlights:
   ```javascript
   updateProductTableHighlights(null);
   updateTemplateTableHighlights(null);
   updateImageTableHighlights(null);
   ```

4. **Child Product Operations**:
   - Create: `createChildProduct()`
   - Edit: `editChildProduct()`
   - Delete: `deleteChildProduct()`
   - Publish: `publishChildProducts()`
   - Unpublish: `unpublishChildProducts()`
   - Upload: `uploadChildProducts()`

5. **Image Integration**:
   - When images are integrated: `integrateSelectedImages()`

6. **JSON Editor Changes**:
   - After JSON edits: `updateDataAfterJsonEdit()`

### Special Considerations

1. **Blueprint Rows**: 
   - Created by DataTables rowGroup feature in `rowGroup.startRender`
   - NOT part of the regular DataTable rows collection
   - Must be selected using jQuery: `$('.blueprint-summary-row[data-bp_id="6"]')`
   - The `data-bp_id` attribute is set when the row is created

2. **Data Type Conversion**:
   - IDs may be strings or numbers depending on the source
   - Always convert to strings for comparison: `String(id1) === String(id2)`
   - This prevents type mismatches between template data and DOM attributes

3. **Performance**:
   - Highlighting functions are called frequently
   - Use efficient selectors and minimize DOM manipulation
   - Clear all highlights before applying new ones
   - Blueprint rows must be cleared separately from DataTable rows

4. **Implementation Pattern**:
   ```javascript
   function updateProductTableHighlights(templateData) {
       // 1. Clear all highlighting (DataTable rows + blueprint rows)
       table.rows().every(function() {
           $(this.node()).removeClass('template-blueprint template-parent template-child status-work-in-progress status-uploaded-unpublished status-uploaded-published');
       });
       $('.blueprint-summary-row').removeClass('template-blueprint');
       
       // 2. Exit early if no template data
       if (!templateData) return;
       
       // 3. Extract IDs from template data
       const blueprintId = templateData.blueprint_id;
       
       // 4. Apply highlighting
       // Blueprint rows (direct jQuery selection)
       $(`.blueprint-summary-row[data-bp_id="${blueprintId}"]`).addClass('template-blueprint');
       
       // DataTable rows (using DataTables API)
       table.rows().every(function() {
           const rowData = this.data();
           const $row = $(this.node());
           
           // Parent product
           if (sourceProductId && rowData.product_id === sourceProductId && $row.hasClass('parent-product-row')) {
               $row.addClass('template-parent');
           }
           
           // Child products with status-based colors
           if (rowData.product_id && childProductIds.has(rowData.product_id) && $row.hasClass('child-product-row')) {
               $row.addClass('template-child');
               
               // Add status-based class
               if (rowData.status) {
                   const normalizedStatus = rowData.status.toLowerCase()
                       .replace(/\s+/g, '-')
                       .replace('_', '-');
                   $row.addClass(`status-${normalizedStatus}`);
               }
           }
       });
   }
   ```

### Example Template Data

```json
{
    "template_title": "FSGP Abstract 01 Tee Template",
    "source_product_id": "6740c96f6abac8a2d30d6a12",
    "blueprint_id": 6,
    "child_products": [
        {
            "printify_product_id": "6740ca016abac8a2d30d6a13",
            "title": "FSGP Abstract 01 Tee - Blue"
        }
    ]
}
```

### Debugging

Enable debug logging to trace highlighting:
```javascript
debug.log("Product highlighting - Blueprint ID:", blueprintId);
debug.log("Blueprint row not found for bp_id=" + blueprintId);
```

## Template Data Handling

The SIP Printify Manager implements a standardized pattern for handling template data throughout the application.

### Core Principle: Process Once at the Source

Template identifiers are processed once when loaded, then passed consistently throughout the application without further manipulation.

### Template Data Structure

When loading templates, the following fields are provided:

```php
$formatted_templates[] = array(
    'basename' => $template_basename,        // Template identifier without extension
    'filename' => $template_filename,        // Full filename with extension
    'title' => $template_title,             // Display title (from JSON or basename fallback)
    'template_title' => $template_title,    // Legacy field for compatibility
    // ... other fields
);
```

### Naming Conventions

#### Template Files
- **Regular templates**: `{basename}.json` in `/templates/`
- **WIP templates**: `{basename}_wip.json` in `/templates/wip/`

#### Data Flow
1. **Backend**: Process filename → basename once in `sip_load_templates_for_table()`
2. **Frontend**: Use `row.basename` directly from table data
3. **AJAX**: Pass basename in requests, no processing needed

### Implementation Pattern

#### PHP (Backend)
```php
// Process once when loading
$template_basename = basename($template_file, '.json');
$template_filename = basename($template_file);

// Use basename directly elsewhere
$template_path = $templates_dir . $template_basename . '.json';
$wip_path = $wip_dir . $template_basename . '_wip.json';
```

#### JavaScript (Frontend)
```javascript
// Use basename from table data
const templateBasename = selectedRows[0].basename;

// Pass to AJAX without processing
formData.append('template_name', templateBasename);
```

### Anti-Patterns to Avoid

❌ **Don't** process extensions multiple times:
```php
// Bad - processing in multiple places
$name = str_replace('.json', '', $template_id);
$name = basename($template_file, '.json');
```

❌ **Don't** add backward compatibility fallbacks:
```javascript
// Bad - fallback logic hides errors
const name = row.basename || row.filename.replace('.json', '');
```

✅ **Do** expect and require proper data structure:
```javascript
// Good - fail fast if data is incorrect
const templateBasename = selectedRows[0].basename;
```

### Benefits
1. **Single source of truth**: No confusion about where processing happens
2. **Performance**: Fewer string operations
3. **Maintainability**: Clear data flow
4. **Debugging**: Errors surface immediately at the source

### Migration Notes
When updating existing code:
1. Add basename field to data sources
2. Update consumers to use basename
3. Remove all redundant processing
4. Remove backward compatibility code immediately
5. Let errors surface to identify missing updates

## WIP File Lifecycle Management

The SIP Printify Manager uses Work-In-Progress (WIP) files to manage the state of the product creation table.

### Purpose

- A WIP (Work In Progress) file represents the current state of the product creation table
- Only one WIP file exists at a time (single active template)
- Created by copying a template file with `_wip.json` suffix

### Core Principle: Single Entry Point

All WIP file operations flow through `sip_check_and_load_template_wip()` which handles the complete lifecycle.

### WIP File Structure

- **Location**: `/templates/wip/` directory
- **Naming**: `{template_basename}_wip.json`
- **Creation**: Copy of template file with modified suffix
- **Constraint**: Only one WIP file exists at a time

### Lifecycle Stages

1. **Check**: Determine if a WIP file exists
2. **Create**: Copy template to create new WIP if needed  
3. **Load**: Read WIP file contents
4. **Update**: Modify WIP file as user makes changes
5. **Clear**: Delete WIP file when done

### Lifecycle Operations

```php
// Single entry point for all WIP operations
$result = sip_check_and_load_template_wip($template_name);

// Returns:
[
    'success' => true,
    'path' => '/path/to/template_wip.json',
    'data' => [...],  // Parsed JSON data
    'filename' => 'template_wip.json',
    'template_name' => 'template'
]
```

### Operation Flow

1. **Check**: Looks for existing WIP file
2. **Validate**: If template requested, ensures WIP matches
3. **Create**: Copies template to create WIP if needed
4. **Load**: Reads and parses JSON data once
5. **Return**: Provides complete data structure

### AJAX Integration

For AJAX requests, use the wrapper function:
```php
// In AJAX handler
case 'check_and_load_template_wip':
    sip_ajax_check_and_load_template_wip();
    break;
```

### Parameter Naming Convention

The system uses two distinct parameter names to clearly indicate the lifecycle stage:

#### `template_basename` - Pre-WIP Selection
- **Used when**: Selecting a template from the template table to create/load a WIP
- **Contains**: Template basename without any suffixes (e.g., "my_template")
- **Example**: 
```javascript
// In template-actions.js when selecting a template
formData.append('template_basename', templateBasename);
```

#### `wip_basename` - Post-WIP Operations
- **Used when**: Performing operations on an already-loaded WIP file
- **Contains**: Template basename without any suffixes (e.g., "my_template")
- **Example**:
```javascript
// In creation-table-actions.js when working with loaded WIP
formData.append('wip_basename', templateBasename);
```

#### Implementation Pattern

JavaScript always sends just the basename:
```javascript
// Extract basename if you have a full filename
const templateBasename = templateWipFilename ? templateWipFilename.replace('_wip.json', '') : '';
formData.append('wip_basename', templateBasename);
```

PHP handles all file path construction:
```php
// PHP builds the complete path
$wip_path = $wip_dir . $template_basename . '_wip.json';
```

This clear distinction prevents confusion about which lifecycle stage an operation is in and ensures consistent data handling throughout the system.

### Benefits

1. **Single file read**: Data loaded once per operation
2. **Atomic operations**: Check/create/load in one call
3. **Clear ownership**: One function manages lifecycle
4. **Consistent state**: Automatic cleanup of old WIP files

### Anti-Patterns to Avoid

❌ **Don't** check for WIP files in multiple places:
```php
// Bad - multiple checks
if (file_exists($wip_path)) { ... }
// Then checking again in another function
$wip = check_wip_exists();
if ($wip) { ... }
```

✅ **Do** use the single entry point:
```php
// Good - single operation
$result = sip_check_and_load_template_wip();
if ($result['success']) {
    // Use $result['data']
}
```

### WIP Data Access Patterns

#### Frontend (JavaScript)

The WIP data is stored in `window.creationTemplateWipData` with this structure:
```javascript
window.creationTemplateWipData = {
    path: 'template_name_wip.json',  // Just the filename, not full path
    data: { /* template data */ }
}
```

To get the WIP basename for AJAX requests:
```javascript
// Standard pattern for all creation table actions
const templateWipData = SiP.PrintifyManager.creationTableSetupActions.utils.getCreationTemplateWipData();
const wipFilename = templateWipData?.path;
const wipBasename = wipFilename ? wipFilename.replace('_wip.json', '') : '';
formData.append('wip_basename', wipBasename);
```

#### Backend (PHP)

When handling AJAX requests, use `sip_load_creation_template_wip_for_table()`:
```php
$creation_template_wip = sip_load_creation_template_wip_for_table();
if (!$creation_template_wip || empty($creation_template_wip['data'])) {
    // Handle error - no WIP file found
    return;
}

// Access the data directly
$wip_data = $creation_template_wip['data'];

// Save changes back to the file
if (file_put_contents($creation_template_wip['path'], json_encode($wip_data, JSON_PRETTY_PRINT))) {
    // Success
}
```

**Important**: Always use `$creation_template_wip['data']` directly instead of trying to read the file again with `file_get_contents()`.
