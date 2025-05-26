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