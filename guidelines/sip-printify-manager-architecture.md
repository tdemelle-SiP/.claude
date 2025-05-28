# SiP Printify Manager Architecture

This document describes the architecture, data flows, and key systems within the SiP Printify Manager plugin.

## Overview

The SiP Printify Manager implements a sophisticated product management system that integrates with the Printify API to manage print-on-demand products. The system includes template-based product creation, parent-child product relationships, and complex data synchronization between local storage and the Printify platform.

## Core System Components

### 1. Database Layer
- **Product Table**: `sip_printify_products` stores basic product data (id, title, status, type, blueprint_id, image_url, full_data)
- **Type Field**: Used for basic categorization ('single', 'template') but not for parent-child relationships
- **Full Data Storage**: Complete Printify API responses stored as JSON for data persistence

### 2. Template System
- **Template JSON Files**: Stored in `/wp-content/uploads/sip-printify-manager/templates/`
- **WIP System**: Working copies in `/templates/wip/` for active editing
- **Child Product Tracking**: Templates maintain arrays of child products with their Printify IDs

### 3. Parent-Child Product Relationship System

The plugin implements a sophisticated parent-child product relationship system that displays hierarchical data in DataTables.

#### System Architecture

The parent-child relationship system uses a hybrid approach:

1. **Database Layer**: Stores basic product data (id, title, status, type, etc.)
2. **Template Layer**: JSON files store detailed parent-child relationships with `source_product_id` and `child_products` arrays
3. **JavaScript Processing Layer**: Dynamically determines relationships by cross-referencing database products with template data
4. **Display Layer**: DataTable shows hierarchical relationships with collapsible/expandable parent-child groupings

#### Data Flow and Processing

##### 1. Template Creation Flow
```
Existing Product → Create Template → Set product.type = 'template' in DB → Save template JSON with source_product_id
```

##### 2. Child Product Creation Flow
```
Template → WIP Copy → Child Products Created → Upload to Printify → printify_product_id stored in template
```

##### 3. Display Processing Flow
```
PHP: Load products from DB + templates from JSON → Localize to JavaScript
JavaScript: processProductTypes() → Assign Parent/Child types → Display hierarchy
```

##### 4. Upload and Synchronization Flow
```
Upload Child Products → Save WIP to Main Template → Update window.masterTemplateData → Reload Products → Correct Parent/Child identification
```

##### 5. Manual Refresh/Sync Flow
```
Fetch from Printify API → Save to DB (overwrites type to 'single') → JavaScript reprocesses relationships using existing masterTemplateData
```

#### Key Data Structures

##### Template JSON Structure
```json
{
  "template_title": "Product Name Template",
  "source_product_id": "12345",
  "child_products": [
    {
      "child_product_id": "template-name_child_product_0001", 
      "child_product_title": "Custom Product Name",
      "printify_product_id": "67890",
      "status": "Uploaded - Published"
    }
  ]
}
```

##### JavaScript Data Structure (window.masterTemplateData)
```javascript
{
  templates: [
    {
      template_title: "Product Name Template",  // ⚠️ Must match PHP field name
      source_product_id: "12345",
      child_products: [
        {
          printify_product_id: "67890",
          child_product_id: "template-name_child_product_0001",
          child_product_title: "Custom Product Name"
        }
      ]
    }
  ]
}
```

#### Relationship Processing Logic

The `processProductTypes()` function in `product-actions.js` determines parent-child relationships:

```javascript
function processProductTypes(products) {
    // Build lookup maps from template data
    const templateSourceIds = {};
    const childProductMap = {};
    const childCountMap = {};
    
    window.masterTemplateData.templates.forEach(template => {
        // Map source product IDs (these become Parents)
        if (template.source_product_id) {
            templateSourceIds[template.source_product_id] = true;
        }
        
        // Map child product IDs 
        if (template.child_products && Array.isArray(template.child_products)) {
            template.child_products.forEach(childProduct => {
                if (childProduct.printify_product_id) {
                    childProductMap[childProduct.printify_product_id] = {
                        templateTitle: template.template_title,
                        childProductId: childProduct.child_product_id,
                        childProductTitle: childProduct.child_product_title
                    };
                    
                    // Count children for each parent
                    if (template.source_product_id) {
                        childCountMap[template.source_product_id] = (childCountMap[template.source_product_id] || 0) + 1;
                    }
                }
            });
        }
    });
    
    // Assign types to products
    products.forEach(product => {
        if (templateSourceIds[product.product_id]) {
            product.type = "Parent";
            product.childCount = childCountMap[product.product_id] || 0;
        } else if (childProductMap[product.product_id]) {
            product.type = "Child";
            // Find parent product ID from template data
            const templateWithChild = window.masterTemplateData.templates.find(t => 
                t.child_products && t.child_products.some(c => c.printify_product_id === product.product_id)
            );
            if (templateWithChild && templateWithChild.source_product_id) {
                product.parent_product_id = templateWithChild.source_product_id;
            }
        }
        // Otherwise remains "single" (default)
    });
}
```

### 4. Data Synchronization System

#### PHP Functions
- **`sip_load_templates_for_table()`**: Loads template data for JavaScript consumption
- **`save_products_to_database()`**: Stores products from Printify API (always sets type='single')
- **`sip_update_template_product_statuses()`**: Syncs product statuses from database back to template JSON files
- **`sip_fetch_shop_products_chunk()`**: Fetches products from Printify API in batches

#### Status Synchronization
After uploading child products or refreshing from Printify:
1. Products saved to database with current Printify status
2. `sip_update_template_product_statuses()` updates template JSON files
3. Template status mappings: `Published` → `Uploaded - Published`, `Unpublished` → `Uploaded - Unpublished`

#### Upload Synchronization Mechanism
The upload process includes automatic synchronization to ensure parent-child relationships are correctly identified:

1. **Individual Uploads**: Each `sip_upload_child_product_to_printify()` call updates both WIP and main template files with new `printify_product_id`
2. **Batch Completion**: After all uploads complete:
   - `handleSaveWipToMain()` ensures final WIP→main template synchronization
   - `updateMasterTemplateDataFromWip()` updates `window.masterTemplateData` directly from WIP data
   - Product reload triggers `processProductTypes()` with current template data
3. **Result**: Newly uploaded child products are correctly identified as "Child" type instead of "Single"

This eliminates timing issues where `window.masterTemplateData` might be outdated when `processProductTypes()` runs.

## Critical Implementation Details

### PHP Template Data Structure (template-functions.php)
```php
// In sip_load_templates_for_table()
$formatted_templates[] = array(
    'filename' => basename($template_wip_file),
    'title' => $master_template_data['template_title'],
    'template_title' => $master_template_data['template_title'], // ⚠️ Required for JavaScript
    'source_product_id' => $master_template_data['source_product_id'],
    'child_products' => $child_product_map  // Array of simplified child product data
);
```

**Critical:** The `template_title` field must be included in the PHP data structure, as JavaScript specifically looks for `template.template_title`, not `template.title`.

### Database Type Field Behavior
- The database `type` field is used for basic categorization ('single' vs 'template')
- **Important**: When products are refreshed from Printify API, `save_products_to_database()` always sets `type = 'single'`
- This is intentional - the actual parent-child relationships are determined dynamically by JavaScript, not by the database `type` field
- The database `type` only persists for template products (products that became templates)

### File Structure
```
/wp-content/uploads/sip-printify-manager/
├── templates/
│   ├── product-name-template.json
│   └── wip/
│       └── product-name-template_wip.json
├── products/
│   └── product-name.json
└── images/
    └── uploaded-images/
```

## Common Issues and Troubleshooting

### Child Products Appear as "Single" Instead of "Child"

**Symptoms**: Child products uploaded to Printify appear as standalone "single" products instead of being grouped under their parent template.

**Root Causes**:
1. **Missing `template_title` field**: JavaScript expects `template.template_title` but PHP only provides `template.title`
2. **Empty template data**: `window.masterTemplateData.templates` is undefined or empty
3. **ID mismatches**: `printify_product_id` in templates doesn't match `product_id` in product data
4. **Template data not loading**: Template files missing or corrupted

**Debugging Steps**:
1. **Check browser console** for: `🟢💻 Processing products for type assignment and parent-child relationships`
2. **Verify template data structure**: `console.log(window.masterTemplateData)`
3. **Check for type assignment logs**: `🟢💻 Set product "..." to Parent/Child type`
4. **Verify template-product ID matches** in PHP logs and JavaScript data
5. **Check template file structure** using `sip_plugin_storage()->get_folder_path('sip-printify-manager', 'templates')`

**Common Fixes**:
- Ensure `template_title` field is included in PHP template data structure
- Verify template JSON files contain valid `child_products` arrays with `printify_product_id` values
- Check that `window.masterTemplateData.templates` is properly populated on page load
- **Note**: As of the latest implementation, `window.masterTemplateData` is automatically updated after upload operations complete, so timing issues between uploads and product reloads have been resolved

### Template Status Sync Issues

**Symptoms**: Template child product statuses don't match actual Printify product statuses.

**Root Cause**: `sip_update_template_product_statuses()` function not running or failing to update template files.

**Debugging**: Check PHP error logs for template file write permissions and JSON encoding errors.

### Performance Issues with Large Product Sets

**Symptoms**: Slow DataTable rendering or browser freezing with many products.

**Root Cause**: `processProductTypes()` function processing large datasets inefficiently.

**Solutions**: 
- Consider pagination or virtual scrolling for large datasets
- Optimize relationship processing algorithms
- Consider server-side relationship processing for very large datasets

## Development Guidelines

### Adding New Product Types
1. Update database schema if needed
2. Modify `processProductTypes()` function logic
3. Update DataTable configuration for new type display
4. Add appropriate CSS styling for new types

### Modifying Template Structure
1. Update template JSON structure
2. Modify `sip_load_templates_for_table()` to handle new fields
3. Update JavaScript processing logic
4. Consider migration strategy for existing templates

### Product Options Handling

The system handles product options (colors and sizes) with flexibility to accommodate different Printify product naming conventions:

#### Option Name Variations
The `transform_product_data()` function in `product-functions.php` checks for multiple variations of option names:
- **Colors**: Accepts "color", "colors", "colour", "colours" (case-insensitive)
- **Sizes**: Accepts "size", "sizes" (case-insensitive)

This flexible approach ensures compatibility with different product types that may use singular/plural or regional spelling variations.

#### Data Transformation Process
1. **Option Extraction**: The system extracts color and size options from the Printify API response
2. **Variant Filtering**: Only options from enabled variants are included in the final template
3. **Standardized Output**: Options are always output as "options - colors" and "options - sizes" for consistent JavaScript processing

#### Important Assumptions
The system makes certain assumptions about variant option ordering:
- **Option Position**: The code assumes `variant['options'][0]` contains the color ID and `variant['options'][1]` contains the size ID
- This assumption works for most Printify products but may need adjustment for products with different option arrangements

#### Color Swatch Display
In the creation table, color swatches are rendered using:
- The first color value from the `colors` array in each color option
- CSS background styling to display the actual color
- Tooltip showing the color name on hover

### API Integration Changes
1. Update `save_products_to_database()` for new Printify API fields
2. Modify `sip_update_template_product_statuses()` for new status types
3. Update `sip_fetch_shop_products_chunk()` for API changes
4. Test data synchronization thoroughly

## Security Considerations

- Template files contain product data - ensure proper file permissions
- Sanitize all data when creating template files
- Validate template JSON structure before processing
- Secure file upload directory against direct access
- Encrypt sensitive Printify API tokens

## Performance Considerations

- Template loading happens on every page load - consider caching strategies
- Large template files can slow processing - monitor file sizes
- JavaScript relationship processing is client-side - consider server-side processing for scale
- DataTable rendering can be slow with many products - implement pagination if needed

## Creation Table System

### Overview

The creation table is a complex DataTable implementation that manages product templates and their child products during the creation/editing process. It uses row grouping to organize data hierarchically and provides a rich interface for managing product variants.

### Table Architecture

#### Row Types

The creation table displays three distinct types of rows:

1. **Template Summary Row** - Header row for template products
   - Not a DataTable row, injected via `rowGroup.startRender`
   - Contains aggregated template data
   - No checkbox (templates cannot be selected)
   - Always sorts to the top

2. **Child Product Summary Row** - Header row for each child product
   - Not a DataTable row, injected via `rowGroup.startRender`
   - Contains aggregated child product data
   - Has group checkbox for selecting all variants
   - Shows row numbers (sequential, updates with filtering)

3. **Variant Rows** - Actual DataTable rows
   - Represent individual product variants
   - Can be selected individually
   - Hidden by default, toggled via visibility control

#### Column Structure (After Reorganization)

| Index | Column Name | Purpose | Class Name | Notes |
|-------|------------|---------|------------|-------|
| 0 | Row Number | Sequential numbering | `row-number-column` | Only shows for child products |
| 1 | Checkbox | Selection control | `select-column` | Uses DataTable.render.select() |
| 2 | Visibility | Expand/collapse toggle | `visibility-column` | Shows ▶/▼ icons |
| 3 | Title | Product/variant name | `title-column` | Main identifier |
| 4 | Row Type | Type identifier | `row-type-column` | Used for sorting |
| 5 | Status | Product status | `status-column` | Work in Progress, Uploaded, etc. |
| 6 | Print Area | Image thumbnails | `print-area-column` | Multiple image cells |
| 7 | Colors | Color swatches | `colors-column` | Visual color options |
| 8 | Sizes | Size options | `sizes-column` | Comma-separated list |
| 9 | Tags | Product tags | `tags-column` | Metadata |
| 10 | Description | Product description | `description-column` | Truncated text |
| 11 | Price | Price range | `price-column` | Min-max pricing |

### Key Files and Responsibilities

#### PHP Files

- **`creation-table-functions.php`**
  - Main PHP handler for the creation table
  - Generates initial HTML structure
  - Handles AJAX actions for child product operations
  - Manages WIP (Work In Progress) file operations
  - Integrates with Printify API for uploads

- **`creation-table-setup-functions.php`**
  - Handles WIP file creation and loading
  - Template initialization
  - Cross-table operations (template to creation table)
  - File system operations for temporary edits

#### JavaScript Files

- **`creation-table-setup-actions.js`**
  - DataTable initialization and configuration
  - Row rendering and grouping logic
  - Cell building functions
  - State management functions
  - Event listener attachment

- **`creation-table-actions.js`**
  - User interaction handlers
  - AJAX action triggers
  - Image selection management
  - Save/close dialog handling
  - Form submission processing
  - Success response handlers

### Technical Implementation Details

#### DataTable Configuration

```javascript
creationTable = new DataTable("#creation-table", {
    serverSide: false,
    processing: false,
    order: [[5, "asc"], [3, "asc"]], // Order by row_type then title
    orderFixed: [4, "asc"], // Fixed ordering on row_type column
    
    rowGroup: {
        dataSrc: function(row) {
            return row.is_template ? "template" : row.child_product_id;
        },
        startRender: function(rows, group) {
            // Renders summary rows
        }
    },
    
    select: {
        style: "multi",
        selector: "td.select-column",
        headerCheckbox: true
    }
});
```

#### Row Grouping Logic

- Groups are determined by `is_template` flag or `child_product_id`
- Template variants group under "template"
- Child product variants group under their `child_product_id`
- Summary rows are injected HTML, not DataTable rows
- Variant rows are actual DataTable rows that can be hidden/shown

#### State Management

**Global State**:
```javascript
window.creationTemplateWipData = {
    path: 'template_name_wip.json',
    data: { /* template data */ }
}
```

**Local Storage Structure**:
```javascript
{
    "sip-core": {
        "sip-printify-manager": {
            "creations-table": {
                "loaded-wip": "template_title",
                "wipFilename": "template_name_wip.json",
                "templateFile": "template_name.json",
                "isDirty": true/false
            }
        }
    }
}
```

### WIP (Work In Progress) System

1. When a template is loaded, a WIP copy is created
2. All edits happen on the WIP file
3. Save operation copies WIP back to main file
4. Close without saving discards WIP changes
5. Dirty state tracking prevents accidental data loss

### Key Functions

#### JavaScript Functions

- **`updateChildProductRowNumbers()`**
  - Dynamically numbers visible child product summary rows
  - Updates on table draw, filter, and sort
  - Sequential numbering starting from 1
  - Only shows for child products, not templates

- **`buildTemplateVariantCells(templateWipData)`**
  - Processes raw template data into variant row objects
  - Groups variants by unique image sets
  - Returns array of variant objects with HTML cells

- **`buildChildProductVariantCells(templateWipData, childProduct)`**
  - Similar to template variant builder
  - Overlays child product data on template structure
  - Handles image replacements and option overrides

- **`buildTemplateSummaryCells()`**
  - Aggregates template data for summary row
  - Builds image cells with header checkboxes
  - Calculates price ranges and option sets

- **`buildChildProductSummaryCells()`**
  - Aggregates child product data for summary rows
  - Inherits from template where child data missing
  - Updates status-specific styling

### Common Issues and Solutions

#### Issue: Template rows not sorting to top
**Solution**: Ensure `orderFixed` is set on the row_type column (now column 4)

#### Issue: Row numbers not updating
**Solution**: Call `updateChildProductRowNumbers()` in `drawCallback`

#### Issue: Checkboxes in wrong column
**Solution**: Update `columnDefs` targets when adding new columns

#### Issue: Summary rows misaligned
**Solution**: Ensure summary row HTML has same number of `<td>` elements as columns array