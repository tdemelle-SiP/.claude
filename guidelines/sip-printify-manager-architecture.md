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
- Child product rows: Status-based colors using internal values
  - `wip`: `var(--work-in-progress)` (#dcf3ff)
  - `unpublished`: `var(--uploaded-unpublished)` (#bfdfc5)
  - `published`: `var(--uploaded-published)` (#7bfd83)

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

**Note**: The CSS previously included styles for `main-template-row` and `status-header-row` classes. These have been identified as obsolete and removed (January 2025). The creation table uses only the four row types listed above.

### Special Features

#### Status Filtering
- Operates on child products, not variants
- Uses CSS classes (`.filter-hidden`) instead of DataTables search API
- Hidden rows are automatically deselected

#### Selection Behavior
- Summary row checkboxes control their variant rows
- Header checkbox uses DataTables' standard `headerCheckbox: true` with custom event handling
- Filter-hidden rows are automatically deselected via `select.dt` event handler
- Template variant rows are never selectable (no checkboxes shown)

#### Image Assignment & Checkbox Logic
The image cell checkboxes serve two distinct purposes based on row type:

**Template Rows (Template Summary & Template Variants):**
- Have checkboxes that ARE selected by header checkbox clicks
- Purpose: Target locations for "Add to New Product" action from image table
- Creates new child products by replacing template images at selected positions
- Fully implemented functionality for bulk product creation

**Child Product Rows (Summary & Variants):**
- Have checkboxes that are NOT selected by header checkbox clicks
- Purpose: Target locations for replacing existing images (future functionality)
- Will allow selective image replacement in existing products
- Not yet fully implemented

**Header Checkbox Behavior:**
- Clicking header checkbox selects/deselects ONLY template variant row checkboxes
- Template summary checkboxes update automatically based on their variant states
- Header state (checked/indeterminate/unchecked) reflects ONLY template checkbox states
- Child product checkboxes can be individually selected but don't affect header state
- Enables bulk selection for new product creation while preserving individual control for image replacement

**Summary Row Checkbox Behavior:**
Both template and child product summary rows follow the same pattern:
- Summary checkbox reflects the state of its variant rows (checked/unchecked/indeterminate)
- Clicking summary checkbox selects/deselects all its variant checkboxes in that column
- Updates are bidirectional: variant changes update summary, summary changes update variants
- Template summary changes trigger header checkbox updates
- Child product summary changes do NOT affect header state

**Implementation Pattern:**
- `updateTemplateSummaryImageCheckboxStates()` - Updates template summary based on variants
- `updateChildProductImageCheckboxStates()` - Updates child summaries based on variants
- Both functions follow identical logic for consistency
- Called whenever variant checkboxes change or header checkbox is clicked

### Exceptions to Standard SiP Patterns

The Creation Table deviates from standard patterns due to its hybrid architecture:

#### 1. Header Checkbox State Management
**Standard Pattern**: DataTables manages header checkbox state automatically

**Creation Table Enhancement**: Adds custom `updateHeaderCheckboxState()` to handle:
- Visual state updates that account for filter-hidden rows
- Counting both DataTables rows AND custom injected summary rows
- Excluding template variant rows from selection counts

**Filter Integration**: Uses `select.dt` event handler to immediately deselect any filter-hidden rows when header checkbox is clicked, working WITH DataTables rather than replacing its functionality

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

#### 6. Image Cell HTML Structure Variations
**Standard Pattern**: Consistent HTML structure across all row types

**Creation Table Exception**: Different structures for different row types:
- **Template Summary Row**: Image checkboxes have `data-image-index` directly on checkbox element
- **Child Product Summary Row**: Image cells use `div.image-cell[data-image-index]` containing checkbox
- **Variant Rows**: Image cells use `div.image-cell[data-image-index]` containing checkbox
- Selectors must account for these structural differences when targeting checkboxes

### Implementation
- Main file: `creation-table-setup-actions.js`
- Header checkbox: `updateHeaderCheckboxState()`
- Row generation: `generateCreationTableHTML()`

### CSS Organization (Updated January 2025)

The creation table CSS in `tables.css` follows a hierarchical structure:

1. **Column Width Variables** - All column widths defined as CSS variables for maintainability
2. **Layout & Structure** - Table and header positioning
3. **Row Styles (Hierarchical)**:
   - General row styles (all rows)
   - Table header row styles (thead, th)
   - General summary row styles (currently empty)
   - Specific template summary row styles
   - Specific child product summary row styles
   - General variant row styles
   - Specific template variant row styles
   - Specific child product variant row styles
4. **Cell Styles** - General td and cell-specific styles
5. **Print Area & Image Cells** - Complex checkbox and image assignment UI
6. **Column Width Implementations** - Apply the width variables

All styles include clear comments explaining their purpose without requiring selector parsing.

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
    path: 'template_name_wip.json',  // The WIP filename
    data: { /* template data */ }
}
```

Backend:
```php
$creation_template_wip = sip_load_creation_template_wip_for_table();
// Returns:
// [
//     'path' => 'template_name_wip.json',       // The WIP filename (used by frontend)
//     'full_path' => '/full/path/to/file.json', // Complete path for file operations
//     'data' => [ /* template data */ ]         // The template content
// ]

// File operations use the full_path field:
file_put_contents($creation_template_wip['full_path'], json_encode($data));
copy($creation_template_wip['full_path'], $destination);
```

## Common Patterns and Standards

### Template Data Handling

#### Core Principle: Process Once at the Source
Template identifiers are processed once when loaded, then passed consistently without manipulation.

#### Naming Conventions
- Regular templates: `{basename}.json` in `/templates/`
- WIP templates: `{basename}_wip.json` in `/templates/wip/`

### File Path Standards

The WIP data structure provides two fields:

- **`path`**: Contains the WIP filename (e.g., `template_name_wip.json`) - used by frontend JavaScript
- **`full_path`**: Contains the complete file path - used for all PHP file operations

No path construction is needed anywhere in the code. The data structure provides everything required.

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

## Product Status Management

### Overview
The SiP Printify Manager uses a centralized status management system to ensure consistency across all tables and components. All status handling is managed through the `SiP_Product_Status` class (PHP) and `SiP.PrintifyManager.utilities.productStatus` object (JavaScript).

### Status Values

The system defines five canonical product statuses:

1. **Work in Progress** (`wip`) - Product created locally but not uploaded to Printify
2. **Uploaded - Unpublished** (`unpublished`) - Product uploaded to Printify but not published to shop
3. **Publish in Progress** (`publish_in_progress`) - Publish API called, awaiting completion
4. **Uploaded - Published** (`published`) - Product published and available in shop
5. **Template** (`template`) - Used for template rows and template-associated images

### Implementation

#### PHP (Backend)
```php
// Located in includes/utility-functions.php
class SiP_Product_Status {
    const WIP = 'wip';
    const UNPUBLISHED = 'unpublished';
    const PUBLISH_IN_PROGRESS = 'publish_in_progress';
    const PUBLISHED = 'published';
    const TEMPLATE = 'template';
    
    // Get display name for UI
    public static function get_display_name($status)
    
    // Get CSS class
    public static function get_css_class($status)
    
    // Normalize any status value
    public static function normalize($status)
    
    // Get status from Printify API data
    public static function get_status_from_api_product($product, $current_status)
}
```

#### JavaScript (Frontend)
```javascript
// Located in assets/js/core/utilities.js
SiP.PrintifyManager.utilities.productStatus = {
    // Constants
    WIP: 'wip',
    UNPUBLISHED: 'unpublished',
    PUBLISH_IN_PROGRESS: 'publish_in_progress',
    PUBLISHED: 'published',
    TEMPLATE: 'template',
    
    // Methods
    getDisplayName(status),
    getCssClass(status),
    normalize(status),
    getColorVariable(status)
}
```

### Usage Examples

#### Setting Status in PHP
```php
// For new products
$product['status'] = SiP_Product_Status::WIP;

// From API data
$status = SiP_Product_Status::get_status_from_api_product($api_product, $current_status);

// Normalizing unknown status
$normalized = SiP_Product_Status::normalize($raw_status);
```

#### Using Status in JavaScript
```javascript
// Get display name
var displayName = SiP.PrintifyManager.utilities.productStatus.getDisplayName(status);

// Normalize status from DOM
var status = $row.find('.col-status').text().trim();
var normalized = SiP.PrintifyManager.utilities.productStatus.normalize(status);

// Apply CSS class
var cssClass = SiP.PrintifyManager.utilities.productStatus.getCssClass(status);
$element.addClass(cssClass);
```

### CSS Classes

Status-based CSS classes follow the pattern `status-{internal-value}`:
- `.status-wip`
- `.status-unpublished`
- `.status-publish_in_progress`
- `.status-published`
- `.status-template`

These classes are defined in `assets/css/modules/tables.css` and map to color variables.

### Status Filter Dropdowns

Filter dropdowns use the internal status values:
- `''` (empty) - All statuses
- `'wip'` - Work in Progress
- `'unpublished'` - Uploaded - Unpublished
- `'publish_in_progress'` - Publish in Progress
- `'published'` - Uploaded - Published

### Important Notes

1. **No Backward Compatibility**: The system does not handle legacy status values. All code must use the new status constants.

2. **Normalization at Entry Points**: Status values should be normalized when reading from external sources (database, API, DOM).

3. **Display Names for UI Only**: Internal values are used everywhere except when displaying to users.

4. **Consistent Color Mapping**: Each status maps to a specific CSS color variable defined in `variables.css`.

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