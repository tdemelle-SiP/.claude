# SIP Printify Manager Architecture Documentation

## Overview

The SIP Printify Manager consists of four main tables that work together to manage product creation:
- **Product Table** - Displays shop products with parent-child relationships
- **Template Table** - Manages templates for product creation
- **Image Table** - Handles image assets for products
- **Product Creation Table** - Complex interface for creating and managing product variants

## Core Architectural Principles

### Data Processing Separation
**Extension = Data Fetcher, WordPress = Data Processor**

The browser extension acts as a "dumb pipe" that only captures and relays raw data:
- Extension intercepts API responses and captures data
- Extension sends raw, unprocessed data to WordPress
- WordPress handles all data processing, validation, and transformation
- WordPress saves both raw data (for debugging) and processed data

This separation provides:
- **Easier debugging** - Raw API responses can be inspected on WordPress side
- **Faster iteration** - Processing logic can be changed without reloading extension
- **Clear responsibilities** - Extension focuses on access, WordPress on business logic
- **Data preservation** - Both raw and processed versions are available

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

#### Blueprint Mockups
Blueprint rows can display mockup buttons that allow users to:
- View existing mockups in a draggable/resizable modal gallery
- Gallery displays mockup thumbnails at 100px height in a grid layout
- Click thumbnails to open full-size images in PhotoSwipe lightbox
- Fetch mockups from Printify via the browser extension (requires extension v4.3.0+)

**Template Preview Row:**
- Location: Dashboard beneath shop name header
- Display: Horizontal scrollable row of 128x128 template preview images
- Content: 
  - Blueprint name above image
  - First mockup image from template's parent product
  - Child product count below image
  - 128px x 3px status meter showing work progress proportions
- Interaction: Click to load template into creation table
- Styling: 20px spacing between items, centered layout

**Mockup Storage:**
- Location: `/wp-content/uploads/sip-printify-manager/mockups/{blueprint_id}/`
- Files: Individual `.jpg` images and `metadata.json`
- Detection: Only blueprints with actual image files are considered to have mockups
- Cleanup: Incomplete folders (metadata without images) are automatically cleaned
- Optimization: Blueprint names are stored in metadata.json (v1.3.0+) to avoid database lookups during display
- Caching: Blueprint data uses request-level caching via `sip_get_cached_blueprints()`

**Mockup Button States:**
- No button: Blueprint has no mockup images
- Gallery icon: Mockup images available for viewing
- Button appears in 4th TD cell of blueprint summary rows

**Mockup Implementation:**
- Module: `mockup-actions.js`
- Detection: `sip_get_existing_blueprint_mockups()` checks for `.jpg` files
- Button creation: `createMockupButtonHtml()` - icon-only button
- Fetch dialog: `showMockupFetchDialog()` - batch processing with progress
- Gallery display: `displayMockupGallery()` - hybrid thumbnail grid + PhotoSwipe
- Cleanup utility: `cleanupIncompleteMockups()` - removes incomplete downloads
- Extension integration: Requires `mockupFetching` capability
- Frontend optimization: Blueprint names pass through from DOM data, avoiding redundant database lookups
- Functions updated for efficiency:
  - `fetchMockupsForBlueprint(blueprintId, blueprintName, dialog)` - accepts name parameter
  - `getProductForBlueprint(blueprintId, blueprintName)` - uses passed name when available

**Template Preview Implementation:**
- Module: `template-actions.js`
- Data function: `sip_get_template_preview_data()` - uses `sip_load_templates()` to get complete template data with parent product images
- Render function: `renderTemplatePreviewRow()` - builds preview items dynamically
- Click handler: `handleTemplatePreviewClick()` - loads template into creation table
- Status meter: `createStatusMeter()` - visual representation of child product statuses using the status field from each child product

#### Implementation
- Main file: `product-actions.js`
- Highlighting function: `updateProductTableHighlights()`
- Initialization: `initializeProductDataTable()`
- Mockup module: `mockup-actions.js`

## Template Table

### Purpose
Manages templates that define product structures for creation.

### Architecture
- Standard DataTables implementation
- Single-level table (no grouping)
- Client-side data processing

### Data Structure
Templates are loaded using `sip_load_templates()` which returns complete template data including all child products:
```javascript
{
    'basename': 'template_name',        // Identifier without extension
    'filename': 'template_name.json',   // Full filename
    'title': 'Display Title',           // User-friendly name
    'template_title': 'Display Title',  // Legacy field
    'source_product_id': '...',         // Parent product ID
    'child_products': [                 // ALL child products
        {
            'child_product_id': '...',
            'child_product_title': '...',
            'printify_product_id': '...', // May be empty for WIP
            'status': 'wip|unpublished|published'
        }
    ]
}
```

### Template Data Loading
**Single Source Function**: `sip_load_templates()`
- Loads complete template JSON files without filtering
- Returns all child products regardless of status
- Used by template table, template preview row, and all other template data needs
- Child product filtering for product table highlighting happens client-side in JavaScript

### Template Data Forms and Flow

The template system uses different data structures for different purposes:

#### 1. Full Template Data (`masterTemplateData.templates`)
- **Source**: `sip_load_templates()` PHP function
- **Contains**: Complete template data including all child products
- **Used for**: DataTable display, accessing child products for operations
- **Available via**: `window.masterTemplateData.templates`
- **Structure**: Array of template objects with full data

#### 2. Template Row Data (`rowData`)
- **Source**: DataTable row selection
- **Contains**: Single template's data from DataTable
- **Used for**: Identifying which template was clicked/selected
- **Available in**: Event handlers only
- **Structure**: Same as full template but scoped to one template

#### 3. Minimal Template Data (`templateData` parameter)
- **Source**: Extracted from rowData in event handlers
- **Contains**: Usually just `basename` and `title`
- **Used for**: Passing template identity to functions
- **Structure**: `{ basename: "name", title: "Title" }`

#### 4. Template Preview Row Data (`templatePreviewRowData`)
- **Source**: `sip_get_template_preview_row_data()` PHP function
- **Contains**: Summary data for visual preview display ONLY
- **Used for**: Rendering the template preview row above dashboard
- **Available via**: `window.sipPrintifyManagerData.templatePreviewRowData`
- **Structure**: 
  ```javascript
  {
      template_basename: "name",
      template_title: "Title",
      preview_image: "url",
      blueprint_name: "Blueprint",
      child_product_stats: {
          total: 10,
          wip: 3,
          unpublished: 5,
          published: 2
      }
  }
  ```
- **Important**: Does NOT contain child_products array

#### Data Flow Best Practices
1. Always use `masterTemplateData.templates` as the source of truth for full template data
2. Use minimal templateData parameters for function calls (just basename/title)
3. Look up full data when needed using basename as the key
4. Never use templatePreviewRowData for anything except the preview row display

### Template Mockup Selection

Templates store mockup preferences using Printify's native images array format:

#### Data Structure
Templates use Printify's images array for mockup selection:
```javascript
{
    'basename': 'template_name',
    'filename': 'template_name.json',
    'title': 'Display Title',
    'template_title': 'Display Title',
    'source_product_id': '...',
    'blueprint_id': '...',
    'images': [  // Printify's native format
        {
            'src': 'https://images.printify.com/mockup/{blueprint_id}/{variant_id}/{design_id}/filename.jpg?camera_label=front',
            'variant_ids': [12100, 12101, 12102], // Size variants for this color only
            'position': 'other',
            'is_default': true,  // Only one per product
            'is_selected_for_publishing': true,
            'order': null
        }
        // One entry per color/mockup combination
    ],
    'child_products': [...]
}
```

**Variant ID Grouping:**
- Each mockup entry represents one color/mockup combination
- `variant_ids` contains only the size variants for that specific color
- URL uses the numerically lowest variant ID from the group
- System automatically expands single mockup selection to multiple color entries

#### Why This Architecture
- **Native format**: Uses Printify's exact structure, no transformation needed
- **Single source of truth**: Images array is preserved from source products and maintained throughout
- **Template-level control**: Mockup preferences apply to all products created from template
- **Printify API limitation**: Public API doesn't support mockup management, requires browser extension

### Special Features

#### Template Selection
- Load into Creation Table action
- Creates WIP file from template
- Triggers cross-table highlighting

#### Mockup Selection Interface
Template thumbnails are clickable with instant CSS tooltips:
- **Thumbnail click**: Opens modal dialog showing available blueprint mockups
- **Modal features**: Draggable, resizable with state persistence using SiP.Core.modal
- **Scene-based selection**: 
  - Mockups grouped by scene (Front, Back, Left, Right, etc.)
  - Scene-level checkboxes select/deselect all color variants for that scene
  - Default scene radio button for primary image selection
  - Color swatches below default scene for primary color selection
- **Instant tooltips**: CSS-based tooltips appear immediately on hover
- **Data persistence**: Selected mockups saved in Printify's native format with variant_ids populated
- **PhotoSwipe integration**: Click thumbnails in modal to view full-size images

**Implementation:**
- Module: `template-actions.js` - handles UI and AJAX calls
- Table column: Third column with 80px width, icon-only buttons
- Button classes: `.sip-pm-mockup-icon-button` with `.has-selection` modifier
- Modal Dialog: Uses `SiP.Core.modal.create()` with draggable/resizable features
- Backend: `sip_get_template_mockup_data()` - retrieves mockup data and `sip_save_template_mockup_selection()` - saves to template JSON
- CSS: Modal base styles from SiP Core, mockup grid styles and color swatches in plugin's `modals.css`
- Thumbnails: Mockups display at 80px height in compact grid layout
- Scene grouping: `groupMockupsByScene()` organizes mockups by camera label
- Color extraction: `extractColorOptions()` gets unique colors from mockups
- Extension sync: Uses scene names via URL parameters for mockup updates (see [Scene-Based Selection Implementation](./sip-printify-manager-extension-widget-v3.md#78-scene-based-selection-implementation-details))

#### Dynamic Row Highlighting
When a template is loaded:
- Selected template row: `var(--template)` (#e7c8ac)

#### Implementation
- Main file: `template-actions.js`
- Highlighting function: `updateTemplateTableHighlights()`
- Action handler: `handleTemplateActionFormSubmit()`
- Mockup selection: `handleMockupSelectionAction()`

## Product Publishing System

### Overview
The product publishing system allows users to publish unpublished products to their Printify shop. Since the Printify Public API doesn't support publishing, this functionality uses the browser extension to make internal API calls.

### Architecture

#### Publishing Workflow
1. **User initiates publishing**: From product table or after mockup updates
2. **Progress dialog appears**: Shows batch publishing interface
3. **Extension communication**: WordPress sends publish requests to extension
4. **Internal API calls**: Extension makes Printify internal API calls
5. **Status updates**: Real-time progress reported back to WordPress
6. **Database updates**: Product status changed to `published` after success

#### Why This Architecture
- **API limitation**: Printify Public API has no publish endpoint
- **Browser access required**: Internal API requires authenticated browser session
- **Batch efficiency**: Publishing multiple products in single operation
- **Progress visibility**: Users see real-time status during long operations

### Implementation Components

#### Frontend
- **Module**: `product-actions.js` - adds publish actions to product table
- **Progress Dialog**: Uses `SiP.Core.progressDialog` for batch operations
- **Status Management**: Updates product status to `publish_in_progress` then `published`

#### Backend
- **AJAX Handler**: `sip_handle_product_publish()` in `product-functions.php`
- **Status Updates**: Uses `SiP_Product_Status` class constants
- **Extension Message**: Sends `SIP_PUBLISH_PRODUCTS` command

#### Extension
- **Handler**: `publish-products-handler.js` - navigates to Printify and makes API calls
- **API Endpoint**: Uses internal `/api/v1/shops/{shopId}/products/{productId}/publish.json`
- **Error Handling**: Reports failures back to WordPress for retry options

### User Interface

#### Product Table Integration
- Unpublished products show "Publish" action button
- Bulk selection allows publishing multiple products
- Visual status updates during publishing process

#### Progress Dialog Features
- Shows count of products being published
- Real-time progress updates per product
- Error reporting with retry options
- Summary report after completion
- Log export for troubleshooting

## Mockup Update Process

### Overview
When users configure mockup selections for templates, these selections must be applied to all unpublished child products before publishing. This two-step process ensures products display only the selected mockups.

### Architecture

#### Update Workflow
1. **Template mockup selection saved**: User configures mockups for template
2. **Update products dialog**: Progress dialog for applying changes
3. **Extension loads product pages**: Opens each product's mockup configuration
4. **Internal API calls**: Removes unwanted mockups, keeps selected ones
5. **Confirmation**: Reports success/failure for each product

#### Why This Architecture
- **No direct API**: Printify doesn't expose mockup management in public API
- **Product-level changes**: Each product must be updated individually
- **Visual feedback**: Complex operation needs progress tracking
- **Error recovery**: Failed updates can be retried

### Implementation Components

#### Frontend
- **Triggers**: 
  - Automatically after saving template mockup selection (for unpublished/published products)
  - Automatically after successful WIP product uploads (if template has mockup selections)
- **Dialog**: `showMockupUpdateProgress()` in `template-actions.js`
- **Batch Processing**: Uses `SiP.Core.progressDialog.processBatch()`
- **Data Source**: Uses existing `child_products` from template data (no extra AJAX needed)

#### Backend
- **Template Data**: Mockup selection saved to template JSON via `sip_save_template_mockup_selection()`
- **Product List**: Filters `child_products` for status `wip` or `unpublished`
- **No batch AJAX handler needed**: Frontend uses existing template data

#### Extension Integration
- **Message Type**: `SIP_UPDATE_PRODUCT_MOCKUPS`
- **Navigation**: Loads product mockup page in Printify
- **API Calls**: Makes internal API calls to update mockup configuration
- **Tab Reuse**: Efficient tab management for multiple products

### Progress Dialog Structure

```javascript
SiP.Core.progressDialog.processBatch({
    items: childProducts,
    batchSize: 1,
    dialogOptions: {
        title: 'Update Product Mockups',
        item: 'product',
        initialMessage: `Updating mockups for ${childProducts.length} unpublished {item}s...`,
        progressMessage: 'Processing {stepCount} of {count} {item}s',
        secondaryProgressMessage: 'Updating mockups for "{name}"...',
        completionMessage: '{successCount} {item}s updated successfully!',
        secondaryCompletionMessage: 'Click "Publish Products" below to publish the updated products',
        waitForUserOnStart: false,
        waitForUserOnComplete: true,
        completionButtons: [{
            text: 'Publish Products',
            class: 'ui-button-primary',
            handler: function(dialog) {
                dialog.close();
                publishUpdatedProducts(childProducts);
            }
        }]
    },
    steps: {
        weights: {
            navigate: 20,    // Navigate to product mockup page
            update: 60,      // Update mockups via internal API
            verify: 20       // Verify changes were applied
        },
        batchCount: childProducts.length
    },
    processItemFn: function(product, dialog) {
        return updateProductMockupsViaExtension(product, selectedMockups, blueprintId, dialog);
    }
});
```

### Upload Integration

When uploading WIP products that have mockup selections in their template:

1. **Upload Completion Detection**: The `onAllComplete` callback in `creation-table-actions.js` checks for:
   - Successfully uploaded products (`uploadedProductIds` array)
   - Template has mockup selections (`templateData.images` array)
   - Products now have `unpublished` status

2. **Automatic Trigger**: After a 1-second delay (to let upload dialog close), the system:
   - Filters child products to find those just uploaded
   - Triggers `showMockupUpdateProgress()` with the filtered list
   - Shows progress dialog for mockup updates

3. **Why This Architecture**:
   - **User convenience**: No manual step needed after uploads
   - **Efficient workflow**: Mockups applied immediately when products are ready
   - **Clear separation**: Upload completes fully before mockup updates begin
   - **Visual continuity**: Brief delay prevents dialog overlap

### Comprehensive Mockup Update Dialog

When template mockup selections are saved, a comprehensive dialog presents a summary before processing:

#### Dialog Features
1. **Product Status Summary**: Shows counts of products by status (WIP, unpublished, published)
2. **Upload Option**: Checkbox to upload WIP products before updating mockups (checked by default)
3. **Processing Sequence**:
   - Upload WIP products to Printify (if selected)
   - Clean up local mockup data for published products
   - Update mockups for all products via browser extension
4. **Completion Summary**: Shows results with "Download Updated Mockups" button

#### Implementation Details
- **Function**: `showComprehensiveMockupUpdateDialog()` in `template-actions.js`
- **WIP Upload**: Reuses `upload_child_product_to_printify` AJAX endpoint
- **Cleanup**: Uses `cleanup_published_product_mockups` for local file removal
- **Sequential Processing**: Tasks processed one at a time for clear progress tracking

#### Why This Architecture
- **User Control**: Shows what will happen before starting
- **Efficiency**: Combines multiple operations in one workflow
- **Flexibility**: Optional WIP upload based on user needs
- **Clear Feedback**: Detailed progress and completion summary

### Error Handling
- Individual product failures don't stop batch
- Failed products listed in summary
- Retry option for failed updates
- Detailed logs for debugging

## Browser Extension Mockup Update System

### Overview
The browser extension enables mockup management capabilities that aren't available through Printify's public API. This system allows automated updating of product mockups based on template selections.

### Architecture

#### Why This Architecture
- **API Limitation**: Printify's public API has no endpoints for mockup management
- **Browser Access**: Only the browser with an authenticated session can access internal Printify APIs
- **Automation**: Manual mockup updates for hundreds of products would be impractical
- **Consistency**: Ensures all products from a template have identical mockup selections

#### Communication Flow
1. **WordPress initiates**: Sends `SIP_UPDATE_PRODUCT_MOCKUPS` message with selected scenes and primary image settings
   - Includes unique `requestId` generated via `SiP.Core.utilities.generateRequestId()` for response correlation
2. **Extension navigates**: Opens product's mockup library page in Printify with scene parameters in URL
3. **Scene-based selection**: Content script reads URL parameters and:
   - Navigates carousel to ALL available scenes
   - Selects mockups for scenes in the selection list
   - Deselects mockups for scenes NOT in the selection list
   - Ensures exact synchronization with WordPress selection
4. **Internal API calls**: Uses Printify's internal endpoints to save changes
5. **Status reporting**: Reports success/failure back to WordPress with preserved `requestId`

### Implementation Components

#### WordPress Side
- **Trigger Function**: `showMockupUpdateProgress()` in `template-actions.js`
- **Mockup Selection UI**: `showMockupSelectionModal()` presents scene-based selection
- **Message Format** (standardized as of v1.4.0):
  ```javascript
  {
      context: 'wordpress',
      action: 'SIP_UPDATE_PRODUCT_MOCKUPS',
      source: 'sip-printify-manager',
      requestId: 'update_mockups_123_1737547890123_x7k9m2p',  // Generated via SiP.Core.utilities.generateRequestId()
      data: {
          productId: '68534afa6ad639c0cd011c55',
          shopId: '17823150',
          blueprintId: '6',
          selectedScenes: ['Front', 'Back', 'Left'],  // Scenes to select
          primaryScene: 'Front',                       // Default image scene
          primaryColor: '#FF0000',                     // Default image color
          productInfo: {
              productName: 'Product Name',
              productId: '68534afa6ad639c0cd011c55'
          }
      }
  }
  ```

#### Extension Handler
- **Location**: `handler-scripts/mockup-update-handler.js`
- **Responsibilities**:
  - Receive scene-based selection data from WordPress
  - Construct URL with parameters:
    - `sip-action=update`
    - `scenes=Front,Back,Left` (selected scenes)
    - `primary-scene=Front` (default image scene)
    - `primary-color=%23FF0000` (URL-encoded color)
  - Navigate to mockup library URL with parameters
  - Monitor operation completion
  - Report detailed progress to WordPress
  - Handle errors with specific messaging

#### Content Script
- **Location**: `action-scripts/mockup-library-actions.js`
- **Responsibilities**:
  - Detect URL parameters (`sip-action=update&scenes=...`)
  - Extract all available scenes from carousel: `extractAvailableScenes()`
  - Execute scene synchronization: `synchronizeMockupsByScenes()`
    - Navigate to EVERY scene using carousel buttons
    - Select all mockups if scene is in selection list
    - Deselect all mockups if scene is NOT in selection list
  - Click save button after all scenes processed
  - Use action logger for operation tracking
  - Note: chrome.runtime is blocked on Printify, uses URL parameters instead

#### Mockup Library Page Structure
- **URL Pattern**: `https://printify.com/app/mockup-library/shops/{shopId}/products/{productId}`
- **Data Available**:
  - `groups`: Color variants with their mockup options
  - `selected_mockups`: Currently selected mockups
- **Update Mechanism**:
  - Toggle mockup checkboxes via click events
  - Designate default mockup with radio buttons
  - Save button click or auto-save triggers API call

### Mockup Selection Data Format

#### Template Storage (images array)
```javascript
{
    "images": [
        {
            "src": "https://images.printify.com/mockup/...",
            "variant_ids": [12100, 12101, 12102], // Size variants for one color
            "position": "other",
            "is_default": true,
            "is_selected_for_publishing": true,
            "order": null
        }
    ]
}
```

#### Extension Update Format
```javascript
{
    "selected_mockups": [
        {
            "id": "68534afa6ad639c0cd011c55_12100_102005_front-2",
            "type": "GENERATED",
            "group_key": "521",
            "label": "Front, White",
            "custom_background": true,
            "src": "https://images.printify.com/mockup/..."
        }
    ]
}
```

### Error Handling Strategy
- **Navigation failures**: Retry with new tab
- **Page load timeout**: Report specific timeout error
- **Selection mismatch**: Log which mockups couldn't be found
- **Save failures**: Capture API error response
- **Connection loss**: Store progress for manual recovery

### Development Testing Approach

#### Test Mode Features
1. **Dry run mode**: Log actions without making changes
2. **Single product test**: Update one product before batch
3. **Detailed logging**: Capture all API calls and responses
4. **Visual indicators**: Highlight updated elements in DOM

## Async Message Correlation System

### Overview
The SiP Printify Manager uses request IDs to correlate responses with their originating requests when communicating with the browser extension. This is critical for operations that may run concurrently or take significant time to complete.

### Implementation

#### Request ID Generation
All async operations use the standardized request ID generator from SiP Core:

```javascript
// Generate unique request ID
const requestId = SiP.Core.utilities.generateRequestId('mockup_' + blueprintId);
// Result: 'mockup_123_1737547890123_x7k9m2p'
```

#### Message Flow with Request ID
1. **WordPress sends request** with generated `requestId`
2. **Extension processes** the request asynchronously
3. **Router preserves** the `requestId` automatically in responses
4. **WordPress matches** response to request via `requestId`

#### Example: Concurrent Mockup Fetches
```javascript
// Fetching mockups for multiple blueprints
blueprints.forEach(blueprint => {
    const requestId = SiP.Core.utilities.generateRequestId('mockup_' + blueprint.id);
    
    // Send request
    window.postMessage({
        context: 'wordpress',
        action: 'SIP_FETCH_MOCKUPS',
        source: 'sip-printify-manager',
        requestId: requestId,
        data: { blueprint_id: blueprint.id }
    }, '*');
    
    // Set up response listener
    const responseHandler = (event) => {
        if (event.data && 
            event.data.action === 'SIP_MOCKUP_DATA' &&
            event.data.requestId === requestId) {
            // This response matches our request
            processMockupData(event.data);
            window.removeEventListener('message', responseHandler);
        }
    };
    window.addEventListener('message', responseHandler);
});
```

### Why This Architecture
- **Concurrent Operations**: Multiple mockup fetches can run simultaneously without response confusion
- **Timeout Handling**: Each request can have its own timeout without affecting others
- **Debugging**: Request IDs in logs make it easy to trace request/response pairs
- **Reliability**: Prevents processing stale responses from previous operations

#### Debug Information to Capture
- Current mockup selections before update
- Mapping of variant IDs to mockup IDs
- API request/response payloads
- DOM state changes
- Timing information for optimization

## Image Table

### Purpose
Manages image assets that can be integrated into products.

### Architecture
- Standard DataTables implementation
- Filterable by location and status
- Supports drag-and-drop upload

### Special Features

#### Image Upload System (Updated January 2025)

The image upload system now uses efficient batch processing:

**Frontend Upload Process:**
1. **File Validation**: Pre-upload checks for duplicates, file types, and size limits
2. **Batch Processing**: Files uploaded in batches of 5 using `processBatchFn`
3. **Progress Feedback**: Real-time status for each file with visual indicators
4. **Performance Tracking**: Detailed timing metrics for optimization

**Backend Processing:**
- `sip_add_local_images_batch()`: Processes multiple files in one request
- Single database update after all files processed
- Automatic thumbnail generation (256x256)
- Unique filename handling with counters

**Key Files:**
- Frontend: `image-actions.js` - `processApprovedFiles()` function
- Backend: `image-functions.php` - `sip_add_local_images_batch()` function

#### Image Integration
- Select images for product print areas
- Drag-and-drop upload interface
- PhotoSwipe lightbox integration
- Pre-upload validation dialog with detailed reporting

#### Dynamic Row Highlighting
When a template is loaded, referenced images are highlighted:
- Template-associated: `var(--template)` (#e7c8ac)
- Status-based colors using internal values:
  - `wip`: `var(--work-in-progress)` (#dcf3ff)
  - `unpublished`: `var(--uploaded-unpublished)` (#bfdfc5)
  - `published`: `var(--uploaded-published)` (#7bfd83)

#### Upload Validation Features

**Pre-Upload Analysis:**
- Duplicate detection (existing files and within batch)
- File type validation (JPEG, PNG, GIF, WebP, SVG)
- File size limits (10MB max)
- Large image warnings (dimensions > 1024px)

**Validation Dialog:**
- Summary of files to upload, duplicates, and invalid files
- Option to proceed with valid files only
- "Save Log" feature for detailed upload reports
- "View Log" button after completion for troubleshooting

**Log Features:**
- Detailed upload log with timestamps
- Performance metrics and throughput statistics
- Export to text file for support purposes
- CodeMirror viewer for in-app log viewing

#### Implementation
- Main file: `image-actions.js`
- Highlighting function: `updateImageTableStatus()`
- Upload handlers: `handleImageDrop()`, `handleImageAdd()`
- Batch processor: `processApprovedFiles()`
- Validation: `analyzeFilesForUpload()`

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

#### Template Title Display
- The creation table header includes a subtitle element (`#selected-template-subtitle`) that displays the currently loaded template's title
- Template title is stored in `window.creationTemplateWipData.data.template_title`
- The subtitle is updated in two places:
  - `handleTemplateLoadSuccess()` - When a template is initially loaded
  - `reloadCreationTable()` - When the creation table is refreshed
- The template title comes from the `template_title` field in the template JSON file

#### Pagination (Added January 2025)
- The creation table now supports pagination for better performance with large templates
- Page size options: 25, 50, 100, or All child products
- Default page size: 50 child products
- User's page size selection is saved to localStorage as part of UI state management
- Navigation controls appear when pagination is active and multiple pages exist
  - First page icon (dashicons-controls-skipback)
  - Previous page icon (dashicons-arrow-left-alt2)
  - Page X of Y display
  - Next page icon (dashicons-arrow-right-alt2)
  - Last page icon (dashicons-controls-skipforward)
- Only the current page of child products and their variants are loaded into DataTables
- Summary rows are generated only for the visible child products
- This significantly improves performance when working with templates containing hundreds of child products

**Pagination Implementation Details:**
- Uses localStorage key: `sip-core > sip-printify-manager > creations-table > pageSize`
- Custom implementation bypasses DataTables' built-in pagination because:
  - DataTables pagination operates on individual rows, not grouped child products
  - The creation table's hybrid architecture requires filtering at the child product level
  - Summary rows are injected via rowGroup and aren't part of the DataTable data
- Pagination controls are manually inserted above the table and managed separately
- The DataTables info widget is disabled to prevent confusion about row counts
- Page navigation maintains all selection states and visibility preferences

#### Status Filtering and Data State Management (Updated January 2025)

**Filtering System:**
- Operates on child products, not variants
- Filter is applied to the source data BEFORE pagination
- When filter changes, the table reloads with filtered dataset
- Maintains all available status options in dropdown regardless of current filter
- Resets to page 1 when filter changes

**Data State Tracking:**
The creation table tracks and displays four distinct data states:
1. **Total Products** - All child products in the loaded template
2. **Filtered Products** - Products matching the current status filter
3. **Products on Page** - Based on pagination settings (25, 50, 100, or all)
4. **Selected Products** - Those with checkboxes checked

**Display Format:**
- Without filter: "Showing 1-50 of 536 child products"
- With filter: "Showing 1-50 of 180 filtered products from 536 total child products"
- With selections: Appends ". 15 child products selected"

**Row Numbering:**
- Numbers are applied only to visible rows
- Renumbered from 1 after filtering
- Continues across pages (e.g., page 2 with size 50 shows 51-100)

**Implementation Details:**
- Filter-hidden rows are automatically deselected
- Uses `isTableReloading` flag to prevent infinite reload loops
- Filter dropdown populated from source data, not DOM rows

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

#### 7. Custom Pagination Implementation
**Standard Pattern**: DataTables built-in pagination with standard controls

**Creation Table Exception**: Custom pagination implementation because:
- DataTables pagination only works with rows in its data model
- Child product summary rows are injected via rowGroup and not part of the data
- Pagination must operate at the child product level, not the variant row level
- Controls are manually inserted and managed outside DataTables
- The info widget is disabled (`info: false`) to prevent confusion
- localStorage uses `creations-table` key to match UI Components documentation pattern

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

## Shop-Level Data Management

### Purpose
Certain data is constant across all products in a shop and should be stored at the shop level rather than duplicated in each product.

### Shop-Level Data Storage Pattern
```javascript
// PHP: Store once when shop connects or products are fetched
update_option('sip_printify_shop_id', $shop_id);
update_option('sip_printify_shop_name', $shop_name);
update_option('sip_printify_user_id', $user_id);  // Extracted from first product

// JavaScript: Access globally via wp_localize_script
window.sipPrintifyManagerData = {
    shopId: '17823150',
    shopName: 'My Shop',
    userId: '14758458',
    // ... other data
};
```

### Implementation Details
- **Shop ID & Name**: Retrieved from `/v1/shops.json` API endpoint
- **User ID**: Extracted from first product during initial fetch (products contain `user_id` at root level)
- **Storage**: WordPress options table via `update_option()`
- **Access**: Made globally available to JavaScript via `wp_localize_script()`

### Why This Architecture
- **Data ownership**: User owns shop, shop contains products - hierarchical relationship
- **No redundancy**: Store once at appropriate level, not in every product
- **Performance**: No JSON parsing or database queries for frequently needed data
- **Consistency**: Single source of truth for shop-level constants

### Shop Authorization Flow

The shop authorization process works as follows:

1. **Token Submission**: User enters Printify API token
2. **Shop Details Fetched**: PHP calls `/v1/shops.json` to get shop info
3. **Details Stored**: PHP saves to WordPress options and returns in AJAX response
4. **UI Update**: JavaScript updates shop name display immediately

The shop details are properly saved in WordPress options during authorization, making them available on subsequent page loads via `wp_localize_script`.

### Example Usage
```javascript
// Mockup fetching needs user_id to construct API URL
var shopId = window.sipPrintifyManagerData.shopId;
var userId = window.sipPrintifyManagerData.userId;

// Construct URL: /users/{userId}/shops/{shopId}/products/{productId}/generated-mockups-map
```

## Global Data Access Pattern

### Purpose
Make plugin configuration and frequently-needed data available to JavaScript without requiring AJAX calls.

### Implementation
Data is made available via `wp_localize_script()` in the main plugin file:

```php
wp_localize_script('sip-main', 'sipPrintifyManagerData', array(
    'hasToken' => !empty($token),
    'shopName' => $shop_name,
    'shopId' => $shop_id,
    'userId' => get_option('sip_printify_user_id'),
    'templates' => $templates,
    'images' => $processed_images,
    'products' => $products_summary['products'] ?? [],
    'creationTemplateWip' => $creation_template_wip,
    'extensionApiKey' => get_option('sip_extension_api_key')
));
```

### Available Data
- **hasToken**: Boolean indicating if Printify API token is configured
- **shopName**: Display name of the connected Printify shop
- **shopId**: Printify shop identifier
- **userId**: Printify user identifier (extracted from first product)
- **templates**: Array of available product templates
- **images**: Array of available images with metadata
- **products**: Initial product data for table population
- **creationTemplateWip**: Current work-in-progress template data
- **extensionApiKey**: API key for browser extension authentication

### Why This Architecture
- **Performance**: No AJAX calls needed for frequently-used data
- **Availability**: Data ready immediately on page load
- **Consistency**: Single source of truth for configuration
- **Security**: Server-side filtering of sensitive data before exposure

### Template Data Refresh Pattern

#### Purpose
Prevent stale product IDs and template data when operations modify the underlying data but don't trigger a page reload.

#### Problem Addressed
Two related issues can cause stale product IDs:

1. **Client-side staleness**: When users save WIP data back to main templates, the `window.masterTemplateData` object becomes stale
2. **Server-side data loss**: When saving WIP to main, updated product IDs from uploads could be overwritten with old IDs from the WIP file

#### Implementation
The system uses two complementary approaches:

##### 1. Client-side Refresh
The template system implements a refresh mechanism via `refreshTemplateDataFromServer()`:

```javascript
function refreshTemplateDataFromServer() {
    const formData = SiP.Core.utilities.createFormData('sip-printify-manager', 'template_action', 'load_templates');
    
    return SiP.Core.ajax.handleAjaxAction('sip-printify-manager', 'template_action', formData)
        .then(function(response) {
            if (response.success && response.data) {
                // Update global data
                window.masterTemplateData = { templates: response.data.templates || [] };
                
                // Reload template table
                reloadTemplateTable(response.data);
                
                return response.data;
            }
        });
}
```

##### 2. Server-side Product ID Preservation
The `sip_save_wip_to_main_template_file()` function merges updated product IDs before saving:

```php
// Before saving WIP to main, preserve any updated product IDs
if (file_exists($permanent_path)) {
    $existing_main_data = json_decode(file_get_contents($permanent_path), true);
    
    // Create map of updated product IDs
    $existing_product_map = [];
    foreach ($existing_main_data['child_products'] as $child) {
        if (!empty($child['printify_product_id'])) {
            $existing_product_map[$child['child_product_id']] = $child['printify_product_id'];
        }
    }
    
    // Merge updated IDs into WIP data before saving
    foreach ($wip_data['child_products'] as &$wip_child) {
        if (isset($existing_product_map[$wip_child['child_product_id']]) && 
            $wip_child['status'] !== 'wip') {
            $wip_child['printify_product_id'] = $existing_product_map[$wip_child['child_product_id']];
        }
    }
}
```

#### Refresh Triggers
Data refresh is triggered after operations that modify template data:
- **Save WIP to Main**: After `creation-table-actions.js` saves work in progress
- **Template Deletion**: After removing a template
- **Bulk Operations**: After batch updates that modify multiple templates

#### Usage Example
```javascript
// In creation-table-actions.js after saving WIP to main
handleSuccessResponse: function(response) {
    if (response.action === 'save_wip_to_main') {
        // Refresh template data to get updated product IDs
        if (SiP.PrintifyManager.templateActions && 
            typeof SiP.PrintifyManager.templateActions.refreshTemplateDataFromServer === 'function') {
            SiP.PrintifyManager.templateActions.refreshTemplateDataFromServer();
        }
    }
}
```

#### Why This Architecture
- **Data Integrity**: Two-layer protection ensures product IDs are never lost
- **No Page Reload**: Updates data seamlessly without disrupting user workflow  
- **Selective Updates**: Only refreshes when data changes, not on every operation
- **Product ID Preservation**: Server-side merge prevents data loss during WIP saves
- **Non-destructive**: Only updates non-WIP products, preserving work in progress

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

#### Cross-Table Filter Interactions
**Important**: When resetting filters in any table, use table-specific selectors to avoid unintended effects:

```javascript
// ✅ CORRECT: Target filters within specific table wrapper
$('#product-table_wrapper .sip-filter').val('');

// ❌ WRONG: Affects all tables' filters
$('.sip-filter').val('');
```

This prevents cascading effects where one table's operations trigger reloads in other tables.

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
Status normalization is now handled by the centralized status management system:
```javascript
// Use the utility function instead of manual string manipulation
const normalizedStatus = SiP.PrintifyManager.utilities.productStatus.normalize(status);
```

## Product Status Management

### Overview
The SiP Printify Manager uses a centralized status management system to ensure consistency across all tables and components. All status handling is managed through the `SiP_Product_Status` class (PHP) and `SiP.PrintifyManager.utilities.productStatus` object (JavaScript).

**CRITICAL**: Any code not following these patterns must be updated. There is NO backward compatibility for old status formats.

### The Five Canonical Status Values

The system defines exactly five product statuses. These are the ONLY valid internal status values:

| Internal Value | Display Name | Description |
|----------------|--------------|-------------|
| `wip` | Work in Progress | Product created locally but not uploaded to Printify |
| `unpublished` | Uploaded - Unpublished | Product uploaded to Printify but not published to shop |
| `publish_in_progress` | Publish in Progress | Publish API called, awaiting completion |
| `published` | Uploaded - Published | Product published and available in shop |
| `template` | Template | Used for template rows and template-associated images |

### CORRECT Patterns (MUST Use)

#### PHP Status Handling

```php
// ✅ CORRECT: Setting status using constants
$product['status'] = SiP_Product_Status::WIP;
$product['status'] = SiP_Product_Status::UNPUBLISHED;
$product['status'] = SiP_Product_Status::PUBLISH_IN_PROGRESS;
$product['status'] = SiP_Product_Status::PUBLISHED;
$product['status'] = SiP_Product_Status::TEMPLATE;

// ✅ CORRECT: Getting display name for UI
$display_name = SiP_Product_Status::get_display_name($status);
echo "<td class='status'>{$display_name}</td>";

// ✅ CORRECT: Getting CSS class
$css_class = SiP_Product_Status::get_css_class($status);
echo "<tr class='{$css_class}'>";

// ✅ CORRECT: Normalizing status from any source
$normalized = SiP_Product_Status::normalize($raw_status);
if ($normalized === SiP_Product_Status::WIP) {
    // Handle work in progress
}

// ✅ CORRECT: Getting status from Printify API
$status = SiP_Product_Status::get_status_from_api_product($api_product, $current_status);
```

#### JavaScript Status Handling

```javascript
// ✅ CORRECT: Using status constants
var status = SiP.PrintifyManager.utilities.productStatus.WIP;
var status = SiP.PrintifyManager.utilities.productStatus.UNPUBLISHED;
var status = SiP.PrintifyManager.utilities.productStatus.PUBLISH_IN_PROGRESS;
var status = SiP.PrintifyManager.utilities.productStatus.PUBLISHED;
var status = SiP.PrintifyManager.utilities.productStatus.TEMPLATE;

// ✅ CORRECT: Getting display name for UI
var displayName = SiP.PrintifyManager.utilities.productStatus.getDisplayName(status);
$element.text(displayName);

// ✅ CORRECT: Getting CSS class
var cssClass = SiP.PrintifyManager.utilities.productStatus.getCssClass(status);
$element.addClass(cssClass);

// ✅ CORRECT: Normalizing status from any source
var normalized = SiP.PrintifyManager.utilities.productStatus.normalize(rawStatus);
if (normalized === SiP.PrintifyManager.utilities.productStatus.WIP) {
    // Handle work in progress
}

// ✅ CORRECT: Status filtering with data attributes
$row.attr('data-status', normalizedStatus);
var filterStatus = $row.data('status');
if (filterStatus === selectedFilter) {
    $row.show();
}
```

#### CSS Class Usage

```css
/* ✅ CORRECT: Using standardized status classes */
.status-wip { background-color: var(--work-in-progress); }
.status-unpublished { background-color: var(--uploaded-unpublished); }
.status-publish_in_progress { background-color: var(--publish-progress-color); }
.status-published { background-color: var(--uploaded-published); }
.status-template { background-color: var(--template); }
```

### INCORRECT Patterns (MUST Replace)

#### PHP - Patterns to Remove

```php
// ❌ WRONG: Hardcoded display names
$product['status'] = 'Work in Progress';
$product['status'] = 'Work In Progress';  // Different casing
$product['status'] = 'Uploaded - Unpublished';
$product['status'] = 'Uploaded - Published';

// ❌ WRONG: Direct string comparison with display names
if ($status == 'Work in Progress') {
if ($status === 'Uploaded - Unpublished') {

// ❌ WRONG: Hardcoded status strings
$status = 'wip';  // Should use constant
$status = 'unpublished';  // Should use constant

// ❌ WRONG: Manual status mapping
switch($status) {
    case 'Work in Progress':
        $internal = 'wip';
        break;
    case 'Uploaded - Unpublished':
        $internal = 'unpublished';
        break;
}

// ❌ WRONG: Using wrong CSS classes
$class = 'status-work-in-progress';  // Should be status-wip
$class = 'status-uploaded-unpublished';  // Should be status-unpublished
```

#### JavaScript - Patterns to Remove

```javascript
// ❌ WRONG: Hardcoded display names
product.status = 'Work in Progress';
product.status = 'Uploaded - Unpublished';
product.status = 'Uploaded - Published';

// ❌ WRONG: Direct string comparison with display names
if (status === 'Work in Progress') {
if (status === 'Uploaded - Unpublished') {

// ❌ WRONG: Manual status mapping
switch(status) {
    case 'Work in Progress':
        shortStatus = 'wip';
        break;
    case 'Uploaded - Unpublished':
        shortStatus = 'unpublished';
        break;
}

// ❌ WRONG: Using SiP.Core.utilities.normalizeForClass for statuses
var statusClass = SiP.Core.utilities.normalizeForClass(status, 'status-');
// This creates 'status-work-in-progress' instead of 'status-wip'

// ❌ WRONG: Filtering by text content instead of data attributes
var statusText = $row.find('.col-status').text().trim();
if (statusText === 'Work in Progress') {

// ❌ WRONG: Using wrong CSS classes
$element.addClass('status-work-in-progress');
$element.addClass('status-uploaded-unpublished');
```

### Migration Checklist

When updating code to the new status system, check for:

1. **PHP Files** (`*.php`):
   - [ ] Replace all hardcoded status strings with `SiP_Product_Status::` constants
   - [ ] Replace all display name comparisons with normalized comparisons
   - [ ] Use `get_display_name()` for any UI output
   - [ ] Use `get_css_class()` for any HTML class generation
   - [ ] Remove any manual status mapping switch/if statements

2. **JavaScript Files** (`*.js`):
   - [ ] Replace all hardcoded status strings with `SiP.PrintifyManager.utilities.productStatus.` constants
   - [ ] Replace display name comparisons with normalized comparisons
   - [ ] Use `getDisplayName()` for any UI text
   - [ ] Use `getCssClass()` for any DOM class manipulation
   - [ ] Replace `normalizeForClass()` with proper status utilities
   - [ ] Use data attributes for filtering, not text content

3. **CSS Files** (`*.css`):
   - [ ] Ensure only using the five standardized status classes
   - [ ] Remove any legacy status classes like `status-work-in-progress`
   - [ ] Check that status classes map to correct CSS variables

4. **Database/Storage**:
   - [ ] Store only internal values (`wip`, `unpublished`, etc.)
   - [ ] Never store display names
   - [ ] Normalize on retrieval if legacy data exists

5. **AJAX Responses**:
   - [ ] Return internal status values in data
   - [ ] Let frontend handle display name conversion

### Common Pitfalls

1. **Text Content Filtering**: Never filter by `.text()` content. Always use data attributes.
2. **Mixed Formats**: Don't mix internal values and display names in the same context.
3. **Case Sensitivity**: Internal values are always lowercase. Display names have specific casing.
4. **CSS Class Generation**: Never construct status CSS classes manually. Always use the utility functions.
5. **Backward Compatibility**: There is none. Update all code to use the new system.

### Key Implementation Files

When auditing for status compliance, focus on these files:

#### PHP Files
- `includes/utility-functions.php` - Contains `SiP_Product_Status` class (source of truth)
- `includes/product-functions.php` - Product save/update operations
- `includes/creation-table-functions.php` - Creation table operations
- `includes/template-functions.php` - Template operations
- `includes/*-ajax-shell.php` - AJAX handlers returning status data

#### JavaScript Files
- `assets/js/core/utilities.js` - Contains `productStatus` object (source of truth)
- `assets/js/modules/product-actions.js` - Product table operations
- `assets/js/modules/creation-table-setup-actions.js` - Creation table rendering
- `assets/js/modules/creation-table-actions.js` - Creation table interactions
- `assets/js/modules/template-actions.js` - Template operations
- `assets/js/modules/image-actions.js` - Image highlighting based on status

#### Search Patterns for Non-Compliance

Use these regex patterns to find code that needs updating:

```bash
# Find hardcoded display names
grep -r "Work [Ii]n Progress\|Uploaded - \(Un\)\?[Pp]ublished" --include="*.php" --include="*.js"

# Find wrong CSS classes
grep -r "status-work-in-progress\|status-uploaded-\(un\)\?published" --include="*.css" --include="*.js" --include="*.php"

# Find manual status mappings
grep -r "case ['\"]\(Work\|Uploaded\)" --include="*.js" --include="*.php"

# Find text-based filtering
grep -r "\.text().*\(Work\|Progress\|Uploaded\|Published\)" --include="*.js"

# Find normalizeForClass usage with status
grep -r "normalizeForClass.*status" --include="*.js"
```

### Implementation Examples by Scenario

#### Scenario 1: Creating a New Product
```php
// PHP
$new_product = array(
    'title' => $title,
    'status' => SiP_Product_Status::WIP,  // ✅ CORRECT
    // NOT: 'status' => 'Work in Progress'  // ❌ WRONG
);
```

#### Scenario 2: Displaying Status in a Table
```php
// PHP
$status_display = SiP_Product_Status::get_display_name($product['status']);
$status_class = SiP_Product_Status::get_css_class($product['status']);
echo "<td class='col-status {$status_class}'>{$status_display}</td>";
```

```javascript
// JavaScript
var displayName = SiP.PrintifyManager.utilities.productStatus.getDisplayName(rowData.status);
var cssClass = SiP.PrintifyManager.utilities.productStatus.getCssClass(rowData.status);
$row.find('.col-status').text(displayName).addClass(cssClass);
```

#### Scenario 3: Filtering by Status
```javascript
// JavaScript - Creation table row generation
return `<tr class="child-product-summary-row ${statusClass}" 
            data-child_product_id="${rowData.child_product_id}" 
            data-status="${normalizedStatus}">`;  // ✅ CORRECT: data attribute

// JavaScript - Filter implementation
$('.child-product-summary-row').each(function() {
    var normalizedStatus = $(this).data('status');  // ✅ CORRECT: read from data
    // NOT: var status = $(this).find('.col-status').text();  // ❌ WRONG
    if (normalizedStatus === filterValue) {
        $(this).show();
    }
});
```

#### Scenario 4: Status Change Operations
```php
// PHP - Publishing a product
function sip_publish_product($product_id) {
    // Set to publish in progress
    update_product_status($product_id, SiP_Product_Status::PUBLISH_IN_PROGRESS);
    
    // After API call succeeds
    update_product_status($product_id, SiP_Product_Status::PUBLISHED);
}
```

#### Scenario 5: Handling Legacy Data
```php
// PHP - When retrieving from database
$product = get_product_from_db($id);
$product['status'] = SiP_Product_Status::normalize($product['status']);
```

```javascript
// JavaScript - When receiving AJAX data
ajax.handleAjaxAction().then(function(response) {
    var normalizedStatus = SiP.PrintifyManager.utilities.productStatus.normalize(response.data.status);
    // Use normalizedStatus for all operations
});
```

## Mockup Management System

### Overview
The mockup management system allows users to view product mockups for each blueprint. Mockups are fetched from Printify using the browser extension and stored locally for quick access via PhotoSwipe galleries.

### Architecture

#### Frontend Components
- **mockup-actions.js**: Main module that handles mockup buttons, fetching, and display
- **browser-extension-manager.js**: Triggers jQuery events when extension state changes
- **PhotoSwipe integration**: Uses SiP Core's PhotoSwipe utility for gallery display

#### Backend Components
- **class-sip-mockup-ajax.php**: Handles AJAX requests for mockup operations
- **Mockup storage**: Local file system storage in `/mockups/` directory
- **Database tracking**: Post meta tracks which blueprints have mockups

#### Browser Extension Components
- **mockup-fetch-handler.js**: Navigates to Printify mockup pages and captures data
- **Content script injection**: Intercepts `generated-mockups-map` API responses
- **Tab reuse**: Sequential fetches reuse the same Printify tab for efficiency

### Mockup Workflow

#### Automated Fetch-on-Load System
The mockup system follows a strict automated workflow with NO manual fetching from blueprint rows:

1. **Blueprint Row Creation**: When blueprint rows are created, the system checks which blueprints have mockups
2. **Missing Mockups Detection**: If blueprints without mockups are found:
   - NO buttons appear on the blueprint rows
   - Progress dialog automatically appears asking "There are X blueprints without mockups. Would you like to fetch mockups now?"
3. **Batch Fetching**: If user confirms:
   - ALL missing mockups are fetched as a batch operation through the progress dialog
   - Extension handles the fetching invisibly in the background
   - Progress updates shown in the dialog
4. **Post-Fetch State**: After successful fetching:
   - Mockup data and images are stored locally
   - Blueprint rows now display gallery buttons
   - Clicking these buttons opens PhotoSwipe lightbox with the stored mockups

#### Fetch Process Details
1. **Progress Dialog**: Shows batch processing dialog with user confirmation
2. **Product Lookup**: Finds a product using the blueprint (required for Printify URL)
3. **Extension Request**: Sends `SIP_FETCH_MOCKUPS` message to extension
4. **Tab Navigation**: Extension navigates to mockup library page (invisible to user)
5. **DOM Data Extraction**: Extracts mockup data from loaded images in the page
6. **Data Processing**: Extracts one color variant for blueprint-agnostic mockups
7. **Local Storage**: Downloads and stores mockup images locally
8. **UI Update**: Blueprint rows that now have mockups show gallery buttons

### Mockup Data Structure

```php
// Stored as post meta for each blueprint
$mockup_data = array(
    'blueprint_id' => '123',
    'product_id' => '456',  // Product used to fetch mockups
    'generated_at' => '2025-01-21T10:00:00Z',
    'mockup_types' => array(
        array(
            'id' => 'front',
            'label' => 'Front',
            'mockup_type_id' => '789',
            'image_url' => 'https://printify.com/...',
            'local_url' => '/wp-content/uploads/sip-printify/mockups/...'
        ),
        // Additional mockup types...
    )
);
```

### Event-Driven Communication

The mockup system uses jQuery events for loose coupling between modules:

```javascript
// Extension ready event
$(document).on('extensionDetected', function(e, data) {
    // Re-check for mockup availability
});

// Extension installed event  
$(document).on('extensionInstalled', function(e, data) {
    if (data.firstInstall) {
        // Check for missing mockups
    }
});

// Blueprint rows created event
$(document).on('blueprintRowsCreated', function(e, data) {
    // Add mockup buttons to rows
});
```

### User Experience

#### Button States
Blueprint rows follow a simple two-state system:
- **No button**: No mockups available (triggers automated fetch dialog on page load)
- **Gallery icon button**: Mockups have been fetched and stored - clicking opens PhotoSwipe gallery

Note: There are NO download buttons on individual blueprint rows. All fetching is handled through the batch progress dialog system.

#### Gallery Display
- Uses PhotoSwipe for responsive image viewing
- Shows all mockup types (front, back, etc.) for the blueprint
- Fallback to simple modal if PhotoSwipe unavailable

#### Automated Fetch Dialog
When blueprints without mockups are detected on page load:
- Modal dialog appears automatically
- Shows count of blueprints needing mockups
- User can accept to fetch all or cancel
- Progress updates shown during batch operation
- Dialog closes automatically when complete

### Extension Requirements
- Minimum version: 4.3.0 (for `mockupFetching` capability)
- Must be installed and connected
- Requires active Printify session for API access

### Event-Driven Communication
The mockup system uses jQuery events for inter-module communication:
- **`extensionDetected`**: Triggered by browser-extension-manager when extension announces readiness
- **`extensionInstalled`**: Triggered when extension is first installed
- **`blueprintRowsCreated`**: Triggered when product table creates blueprint rows

This pattern allows modules to react to state changes without tight coupling.

## JSON Creation Process and Field Inheritance

### Overview
The product creation process assembles JSON data for the Printify API by combining template data with child product overrides. This system allows for flexible product creation while maintaining template defaults.

### The assemble_product_json() Function

Located in `creation-table-functions.php`, this function is the heart of the JSON creation process:

```php
function assemble_product_json($child_product, $creation_template_wip_data) {
    $product_json = [
        'title' => $child_product['child_product_title'] ?? $creation_template_wip_data['template_title'],
        'description' => (!empty($child_product['description'])) ? $child_product['description'] : ($creation_template_wip_data['description'] ?? ''),
        'tags' => (!empty($child_product['tags'])) ? 
            (is_array($child_product['tags']) ? $child_product['tags'] : [$child_product['tags']]) : 
            ($creation_template_wip_data['tags'] ?? []),
        'blueprint_id' => $creation_template_wip_data['blueprint_id'],
        'print_provider_id' => $creation_template_wip_data['print_provider_id'],
        'variants' => [],
        'print_areas' => [],
        'is_printify_express_eligible' => false,
        'is_printify_express_enabled' => false
    ];
    // ... variant and print area processing
}
```

### Field Inheritance Patterns

#### Critical Distinction: Empty Strings vs Null Values

The system treats empty strings (`""`) and null values differently:
- **Empty string (`""`)**: Treated as "intentionally blank" - a deliberate choice to have no value
- **Null or unset**: Treated as "use default" - inherit from template

#### The Description/Tags Fix

**Problem**: Child products often have empty strings for description and tags, which were being sent to Printify as blank values instead of using template defaults.

**Root Cause**: The null coalescing operator (`??`) only checks for null/unset values, not empty strings:
```php
// WRONG: Empty strings bypass the template default
'description' => $child_product['description'] ?? $creation_template_wip_data['description'] ?? ''
```

**Solution**: Use `!empty()` checks to treat empty strings as "use template default":
```php
// CORRECT: Empty strings trigger template default usage
'description' => (!empty($child_product['description'])) 
    ? $child_product['description'] 
    : ($creation_template_wip_data['description'] ?? '')
```

### Field-by-Field Inheritance Rules

| Field | Inheritance Pattern | Notes |
|-------|-------------------|-------|
| `title` | Child overrides template | Uses `??` operator - null triggers template default |
| `description` | Child overrides if not empty | Uses `!empty()` - empty string triggers template default |
| `tags` | Child overrides if not empty | Uses `!empty()` - ensures array format |
| `blueprint_id` | Always from template | Blueprint defines product type |
| `print_provider_id` | Always from template | Provider is template-level |
| `variants` | Always from template | Size/color options from template |
| `print_areas` | Template base, child image overrides | Complex merge of template structure with child images |

### Print Area Merging Logic

Print areas follow a sophisticated merge pattern:
1. Start with template's complete print area structure
2. Deep copy to avoid modifying template data
3. For each child product print area:
   - Match by position (front, back, etc.)
   - Replace template images with child images at specific indices
   - Preserve template structure and metadata
4. Validate and clean resulting structure

### API Test Injection System

For testing Printify API behavior, the system includes a test injection mechanism located in `sip_upload_child_product_to_printify()` around line 1177.

**Purpose**: Test which JSON fields Printify accepts/ignores during product creation
**Location**: Injected directly before API call for maximum reliability
**Control**: `$enable_test_injection` flag (set to `false` in production)

**Complete Testing Guide**: See [SiP Printify Manager Testing](./sip-printify-manager-testing.md) for detailed testing procedures, setup instructions, and troubleshooting.

### Debug Output Files

When API testing is enabled, the system generates debug files in `/templates/wip/` for analysis. These files should be reviewed and deleted after extracting insights, as they contain verbose test data.

**Note**: Test results and findings should be documented in this architecture guide rather than preserved as files.

### Key Learnings from API Testing

Through extensive testing, we've confirmed:
1. **Description and Tags**: Accepted and stored by Printify when sent during creation
2. **Images Field**: Completely ignored during creation - Printify generates its own mockups
3. **Mockup Control**: Not possible via creation API - requires post-creation management
4. **Printify Express**: Must be explicitly disabled with both flags set to `false`

## Data Structures

### Child Product Object Structure

Child products from templates use this structure:

```javascript
{
    child_product_id: '12345',           // Local WordPress post ID
    child_product_title: 'FSGP Abstract 01 Tee - Red/M',
    printify_product_id: '68534afa6ad639c0cd011c55',  // Printify's ID (only present after upload)
    status: 'wip' | 'unpublished' | 'published',
    blueprint_id: '6',
    // ... other fields
}
```

**Key Fields**:
- `child_product_id`: Local identifier for WordPress
- `printify_product_id`: Printify's identifier (required for Printify operations)
- Products without `printify_product_id` are WIP and cannot be updated on Printify

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

4. **Mockup Performance**
   - Images are downloaded once and cached locally
   - Thumbnails could be generated for faster loading (future enhancement)
   - Batch fetching reduces API calls and user wait time

## Dashboard UI Features

### Dynamic Table Header Counts

Each main table header displays a dynamic count that updates in real-time as tables are filtered:

#### Display Format
- **Products Table**: Shows parent product count only (excludes child variants)
- **Images Table**: Shows total count of all images (local + Printify)
- **Templates Table**: Shows count of template files

#### Implementation Details

**HTML Structure:**
Each table header uses a flexbox layout with three parts:
```html
<h2>
    <span class="table-count" id="products-count">42</span>
    <div class="table-title-container">
        Products
        <!-- Search field appends here -->
    </div>
    <span class="table-count-spacer"></span>
</h2>
```

**CSS Layout:**
```css
.products-section-header h2,
.template-section-header h2,
.image-section-header h2 {
    display: flex;
    justify-content: space-between;
}

.table-count {
    min-width: 60px;
    text-align: left;
    flex-shrink: 0;
}

.table-title-container {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-grow: 1;
    gap: 10px;
}
```

**Dynamic Updates:**
Count updates are integrated with DataTables events:
- Products: `updateProductCount()` in `product-actions.js`
- Templates: `updateTemplateCount()` in `template-actions.js`
- Images: `updateImageCount()` in `image-actions.js`

The counts update automatically when:
- Tables are filtered via search
- Column filters are applied
- Data is reloaded via AJAX

**Key Architecture Decisions:**
1. **Single Source of Truth**: Counts come directly from DataTables API
2. **No Defensive Coding**: Direct DOM updates without null checks
3. **Flexbox Layout**: Ensures proper alignment and centering
4. **Search Field Integration**: Search fields append to `.table-title-container` to maintain center alignment