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
