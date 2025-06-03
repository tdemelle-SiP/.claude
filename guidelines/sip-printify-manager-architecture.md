# SIP Printify Manager Architecture Documentation

## Overview

The SIP Printify Manager consists of four main tables that work together to manage product creation:
- **Product Table** - Displays shop products with parent-child relationships
- **Template Table** - Manages templates for product creation
- **Image Table** - Handles image assets for products
- **Product Creation Table** - Complex interface for creating and managing product variants

## Product Table

### Purpose
Displays all products from the Printify shop, organized by blueprint with parent-child relationships visible through expandable rows.

### Architecture
- Built on DataTables with rowGroup extension
- Implements parent-child row toggling
- Blueprint grouping via rowGroup feature

### Row Types
1. **Blueprint Summary Rows** - Group headers created by rowGroup
2. **Parent Product Rows** - Main products
3. **Child Product Rows** - Variants of parent products
4. **Single Product Rows** - Products without parent-child relationships

### Special Features

#### Blueprint Row Groups
Blueprint rows are created by DataTables' rowGroup feature and are NOT part of the regular rows collection:
- Must be targeted directly with jQuery selectors
- Use `data-bp_id` attribute for identification
- Example: `$('.blueprint-summary-row[data-bp_id="6"]')`

#### Dynamic Row Highlighting
When a template is loaded, related rows are highlighted:
- Blueprint rows: `var(--template-dark)` (#dfc1a6)
- Parent product rows: `var(--template)` (#e7c8ac)
- Child product rows: Status-based colors
  - Work in Progress: `var(--work-in-progress)` (#dcf3ff)
  - Uploaded Unpublished: `var(--uploaded-unpublished)` (#bfdfc5)
  - Uploaded Published: `var(--uploaded-published)` (#7bfd83)

#### Implementation
- Main file: `product-actions.js`
- Highlighting function: `updateProductTableHighlights()`
- Initialization: `initializeProductDataTable()`

## Template Table

### Purpose
Manages templates that define product structures for creation.

### Architecture
- Standard DataTables implementation
- Single-level table (no grouping)
- Server-side data loading

### Data Structure
Templates use a standardized data structure:
```javascript
{
    'basename': 'template_name',        // Identifier without extension
    'filename': 'template_name.json',   // Full filename
    'title': 'Display Title',           // User-friendly name
    'template_title': 'Display Title'   // Legacy field
}
```

### Special Features

#### Template Selection
- Load into Creation Table action
- Creates WIP file from template
- Triggers cross-table highlighting

#### Dynamic Row Highlighting
When a template is loaded:
- Selected template row: `var(--template)` (#e7c8ac)

#### Implementation
- Main file: `template-actions.js`
- Highlighting function: `updateTemplateTableHighlights()`
- Action handler: `handleTemplateActionFormSubmit()`

## Image Table

### Purpose
Manages image assets that can be integrated into products.

### Architecture
- Standard DataTables implementation
- Filterable by location and status
- Supports drag-and-drop upload

### Special Features

#### Image Integration
- Select images for product print areas
- Drag-and-drop upload interface
- PhotoSwipe lightbox integration

#### Dynamic Row Highlighting
When a template is loaded, referenced images are highlighted:
- Template-associated: `var(--template)` (#e7c8ac)
- Work in Progress: `var(--work-in-progress)` (#dcf3ff)
- Uploaded Unpublished: `var(--uploaded-unpublished)` (#bfdfc5)
- Uploaded Published: `var(--uploaded-published)` (#7bfd83)

#### Implementation
- Main file: `image-actions.js`
- Highlighting function: `updateImageTableHighlights()`
- Upload handler: `handleImageDrop()`, `handleImageAdd()`

## Product Creation Table

### Purpose
Complex interface for creating products from templates, managing variants, and assigning images to print areas.

### Hybrid Architecture

The creation table implements a unique hybrid approach combining DataTables with custom row management:

#### Two-Layer Design

1. **Custom Layer (Primary)**: Manages child product summary rows
   - Represent actual products that get uploaded/published
   - Exist outside DataTables' data model (injected via rowGroup)
   - Handle group selection, status display, and action triggers

2. **DataTables Layer (Secondary)**: Manages variant rows
   - Show size/color combinations for each child product
   - Participate in DataTables' selection and data model
   - Provide detailed view but aren't the primary business objects

#### Why This Architecture

This design was chosen because:
- Child products are the primary unit of work (what users upload/publish)
- Variants are secondary details that belong to child products
- Summary rows need special behaviors DataTables can't provide:
  - Custom checkboxes that select/deselect all variants
  - Group expand/collapse functionality
  - Status-based filtering at the child product level
  - Positional requirements (staying above their variants)

### Row Types

1. **Template Summary Row** - Displays loaded template information
2. **Template Variant Rows** - Template's size/color combinations (read-only)
3. **Child Product Summary Rows** - Actual products being created
4. **Child Product Variant Rows** - Size/color combinations for each child

### Special Features

#### Status Filtering
- Operates on child products, not variants
- Uses CSS classes (`.filter-hidden`) instead of DataTables search API
- Hidden rows are automatically deselected

#### Selection Behavior
- Summary row checkboxes control their variant rows
- Header checkbox is custom-implemented (DataTables' headerCheckbox disabled)
- Template variant rows are never selectable (no checkboxes shown)

#### Image Assignment
- Complex checkbox hierarchy for print area selection
- Column-based selection for image positions
- Indeterminate states for partial selection

### Exceptions to Standard SiP Patterns

The Creation Table deviates from standard patterns due to its hybrid architecture:

#### 1. Custom Header Checkbox Implementation
**Standard Pattern**: DataTables provides `headerCheckbox: true`

**Creation Table Exception**: Uses custom `updateHeaderCheckboxState()` because:
- Must count both DataTables rows AND custom injected rows
- Must exclude template variant rows from selection
- Standard header checkbox only knows about DataTables rows

#### 2. Row Type Identification via Data Attributes
**Standard Pattern**: CSS classes following BEM methodology

**Creation Table Exception**: Uses data attributes:
- Template variant rows: `data-template="true"`
- Child product summary rows: Custom injection outside DataTables

#### 3. Custom Checkbox Classes
**Standard Pattern**: DataTables uses `.dt-checkboxes`

**Creation Table Exception**: Uses custom classes:
- Child product summary checkboxes: `.child-product-group-select`
- Template variant rows: Hide checkboxes entirely via CSS

#### 4. CSS-Based Filtering
**Standard Pattern**: DataTables search API

**Creation Table Exception**: CSS class `.filter-hidden` because:
- Must hide entire child product groups as a unit
- DataTables search only knows about variant rows

#### 5. Split Selection State Management
**Standard Pattern**: DataTables manages all selection state

**Creation Table Exception**: Selection state is split:
- DataTables manages variant row selection
- Custom code manages summary row checkbox states
- Custom code synchronizes between the two

### Implementation
- Main file: `creation-table-setup-actions.js`
- Header checkbox: `updateHeaderCheckboxState()`
- Row generation: `generateCreationTableHTML()`

## Cross-Table Systems

### Dynamic Row Highlighting System

When a template is loaded into the creation table, all four tables update to show relationships:

#### Data Flow
1. Template data source: `window.creationTemplateWipData.data`
2. Each table has its own highlighting function
3. Functions clear previous highlights then apply new ones
4. Highlighting updates on multiple trigger points

#### Trigger Points
- **Page Load**: If template already loaded
- **Template Loading**: Via template table or creation table
- **Template Closing**: Pass null to clear highlights
- **Child Product Operations**: Create, edit, delete, publish, upload
- **Image Integration**: When images are assigned
- **JSON Editor Changes**: After template edits

#### Implementation Pattern
```javascript
function updateProductTableHighlights(templateData) {
    // 1. Clear all highlighting
    table.rows().every(function() {
        $(this.node()).removeClass('template-blueprint template-parent template-child status-*');
    });
    $('.blueprint-summary-row').removeClass('template-blueprint');
    
    // 2. Exit if no template data
    if (!templateData) return;
    
    // 3. Extract IDs from template data
    const blueprintId = templateData.blueprint_id;
    
    // 4. Apply highlighting
    // ... specific to each table
}
```

### WIP File Lifecycle Management

Work-In-Progress files manage the state of the product creation table:

#### Core Principle: Single Entry Point
All WIP operations flow through `sip_check_and_load_template_wip()`

#### WIP File Structure
- **Location**: `/templates/wip/` directory
- **Naming**: `{template_basename}_wip.json`
- **Constraint**: Only one WIP file exists at a time

#### Parameter Naming Convention
- `template_basename`: When selecting from template table
- `wip_basename`: When operating on loaded WIP file

#### Data Access Patterns

Frontend:
```javascript
window.creationTemplateWipData = {
    path: 'template_name_wip.json',
    data: { /* template data */ }
}
```

Backend:
```php
$creation_template_wip = sip_load_creation_template_wip_for_table();
$wip_data = $creation_template_wip['data'];
```

## Common Patterns and Standards

### Template Data Handling

#### Core Principle: Process Once at the Source
Template identifiers are processed once when loaded, then passed consistently without manipulation.

#### Naming Conventions
- Regular templates: `{basename}.json` in `/templates/`
- WIP templates: `{basename}_wip.json` in `/templates/wip/`

### File Path Construction

#### Directory Paths
SiP storage returns paths WITHOUT trailing slashes:
```php
$wip_dir = sip_plugin_storage()->get_folder_path('sip-printify-manager', 'templates/wip');
// Returns: /wp-content/uploads/sip-printify-manager/templates/wip
```

#### Path Construction
Always add slash between directory and filename:
```php
// CORRECT
$wip_path = $wip_dir . '/' . $basename . '_wip.json';

// WRONG
$wip_path = $wip_dir . $basename . '_wip.json';
```

### Data Type Handling

#### ID Comparison
IDs may be strings or numbers - always normalize:
```javascript
String(id1) === String(id2)
```

#### Status Normalization
Use consistent status string formatting:
```javascript
const normalizedStatus = status.toLowerCase()
    .replace(/\s+/g, '-')
    .replace('_', '-');
```

## Performance Considerations

1. **Highlighting Functions**
   - Called frequently - optimize selectors
   - Clear all highlights before applying new ones
   - Blueprint rows cleared separately from DataTable rows

2. **DOM Manipulation**
   - Minimize reflows and repaints
   - Batch DOM updates where possible
   - Use efficient selectors

3. **Data Processing**
   - Process template data once at source
   - Avoid redundant string operations
   - Cache frequently accessed data