

-------------------------------------------Notes to be incorporated-------------------------------------------------

the scheme for modularizing the code is based on the idea that code should be associated with the interface where its called.

For this reason, the create template function is in the products files not the template files because the create template action is executed in the product table.  The template actions that are executed on the created template files are then handled in the template files because they are executed from the template table.  Similarly, the Product Creation Table initialization is handled in the template files not the creation files because the create_new_products action is executed from the templates table.  The actions that are then executed within the Product Creation Table are handled in the creation files.

I was thinking this same principle would apply in the case of the template json editor so that the initialization and creation of the json editor would be handled in the creation files because the edit json button is in the Product Creation Table interface, but then, once opened, the interaction with the json editor would take place in the templateEditor files.  That would mean that the save_json_editor_changes and the close_json_editor changes would be handled in the templateEditor files, not the creation files.

For now, I want to focus on the saving loading and closing just in the Product Creation Table and worry about the actions in the json editor later.
------------------------------------------------template file management---------------------------------------------

# Template Management System Documentation

## Overview
The system manages three main interfaces that interact with template files:
1. Template Table - Lists and manages template files
2. Product Creation Table - Uses templates to create new products 
3. Template JSON Editor - Edits template structure and content

## File Structure

### Directories
- Base template directory: `/wp-content/uploads/sip-printify-manager/templates/`
- Working files directory: `/wp-content/uploads/sip-printify-manager/templates/wip/`

### File Types
1. **Permanent Templates** (`.json`)
   - Stored in base template directory
   - Format: `template-name.json`
   - Source of truth for template structure

2. **Work In Progress (WIP) Files** (`_wip.json`)
   - Stored in WIP directory
   - Format: `template-name_wip.json`
   - Temporary working copies

## Workflow Processes

### Template Creation
1. User creates template from existing product
2. System saves permanent template to base directory
3. No WIP file created until template is loaded for editing

### Product Creation Table
1. When template is selected:
   - Creates `template-name_wip.json` in WIP directory
   - Copies content from permanent template
   - Loads WIP content into Product Creation Table

2. During editing:
   - All changes save to WIP file
   - Original template remains unchanged
   - WIP file will persist as long as the open file isn't closed.
   - User can save changes to the source template at any time using the save button in the creation table
   - The opportunity to save the WIP file permanently to the main template file will always be offered during Product Creation Table close sequence

3. On close:
   - If changes saved: WIP copied to permanent template
   - WIP file deleted regardless of save choice 

### Template JSON Editor
1. Editor opened:
   - Uses existing WIP file

2. During editing:
 - the state of the file is maintained in the editor_states.json
 - TO DO
    -remove save button, saving is not an option from the json editor
    -add search functionality to the top of each editor window using codemirror search extension
    -add json linter to the json editor and html linter to the description editor
    -add template name to the editor header

3. On close:
 - upon closing, the user is faced with the a dialogue box with the following options: push and close, discard and close, cancel.  Push and close will save the changes to the wip file and close the dialogue box and the json editor, discard and close will close the dialogue box and the editor without saving to the wip file.  cancel will return the user to the editor.

## Page Load Behavior

1. System checks WIP directory on page load
2. If WIP file exists:
   - Loads content into Product Creation Table
   - checks json editor status (if page was reloaded with editor open) and loads last editor state if so
   - Enables all relevant functionality in the table and editor

3. If no WIP file:
   - Shows empty Product Creation Table
   - Waits for template selection

## Key Functions

### PHP Functions
```php
sip_create_wip_directory()
- Creates WIP directory if needed
- Returns path to WIP directory

sip_get_current_template()
- Checks for existing WIP files
- Returns most recent WIP file content if found

sip_save_wip_file_to_main()
- Saves changes to WIP file
- Maintains working state

sip_close_creation_table()
- Optionally saves WIP to permanent template
- Cleans up WIP file
```

### JavaScript Functions
```javascript
handleSaveWipToMain()
- Saves current state to WIP file
- Updates UI to show saved state

closeCreationTable()
- Prompts for save if changes exist
- Triggers cleanup of WIP file
- Updates UI state

handleJsonEditorSave()
- Saves JSON editor content to WIP
- Updates preview if enabled

handleJsonEditorClose()
- Prompts for save if needed
- Triggers WIP cleanup
- Resets editor state
```

## Error Handling

1. File System
- Checks directory permissions
- Creates missing directories
- Validates file operations

2. Content Validation
- Validates JSON structure
- Maintains backup of WIP file
- Recovers from failed saves

3. State Management
- Tracks unsaved changes
- Prevents data loss on close
- Handles concurrent editing

## Best Practices

1. Always use WIP files for editing
2. Clean up WIP files after use
3. Validate content before saving
4. Maintain consistent file naming
5. Check permissions before operations

## Security Considerations

1. File Operations
- Use WordPress file system functions
- Sanitize file names
- Validate file paths

2. Content Security
- Sanitize user input
- Escape output
- Validate JSON structure

3. Access Control
- Check user capabilities
- Verify nonces
- Validate actions

------------------------------------------------js file standards----------------------------------------------------
// moduleTemplate.js

/**
 * Standard JavaScript Module Template
 * 
 * Structure:
 * 1. Namespace declaration
 * 2. Module definition (IIFE)
 * 3. Private variables/state
 * 4. Initialization functions
 * 5. Event handlers
 * 6. AJAX success handlers
 * 7. Utility functions
 * 8. Public interface
 * 9. AJAX registration
 */

var SiP = SiP || {};
window.SiP = window.SiP || {};
SiP.PrintifyManager = SiP.PrintifyManager || {};

sip.moduleTemplate = (function($, ajax, utilities) {
    // Private variables - kept to minimum, clearly named
    let selectedId = null;
    let isDirty = false;

    /**
     * Initialize the module
     * @param {Object} [config] Optional configuration object
     */
    function init(config) {
        // Always call attachEventListeners in init
        attachEventListeners();
        
        // Handle any initialization logic
        if (config) {
            initializeWithConfig(config);
        }
    }

    /**
     * Attach all event listeners for the module
     */
    function attachEventListeners() {
        // Group related events together
        // Use jQuery delegation for dynamic elements
        $('#module-form').on('submit', handleFormSubmit);
        
        // Use consistent event binding pattern
        $('#module-table')
            .on('click', '.editable', handleEdit)
            .on('click', '.delete-button', handleDelete);
    }

    /**
     * Handle form submission
     * @param {Event} e The submit event
     */
    function handleFormSubmit(e) {
        e.preventDefault();
        e.stopPropagation();

        // Standard FormData handling pattern
        const formData = new FormData(e.target);
        formData.append('action', 'sip_handle_ajax_request');
        formData.append('action_type', 'module_action');
        formData.append('module_action', formData.get('action_type'));
        formData.append('nonce', sipAjax.nonce);

        SiP.Core.ajax.handleAjaxAction('module_action', formData);
    }

    /**
     * Handle AJAX success responses
     * @param {Object} response The AJAX response object
     */
    function handleSuccessResponse(response) {
        if (response.success) {
            // Use switch for different action types
            switch(response.data.action) {
                case 'get_data':
                    handleGetDataSuccess(response.data);
                    break;
                case 'update_data':
                    handleUpdateDataSuccess(response.data);
                    break;
                default:
                    console.warn('Unhandled action type:', response.data.action);
            }
        } else {
            console.error('Error in AJAX response:', response.data);
            utilities.showToast('Error: ' + response.data, 5000);
        }
    }

    /**
     * Handle successful data retrieval
     * @param {Object} data The response data
     */
    function handleGetDataSuccess(data) {
        if (data.html) {
            $('#module-container').html(data.html);
        }
        SiP.PrintifyManager.utilities.ui.spinner.hide();
    }

    /**
     * Handle successful data update
     * @param {Object} data The response data
     */
    function handleUpdateDataSuccess(data) {
        isDirty = false;
        utilities.showToast('Update successful', 3000);
    }

    /**
     * Utility function for common operations
     * @param {string} value The value to process
     * @returns {string} The processed value
     */
    function utilityFunction(value) {
        return value.trim().toLowerCase();
    }

    // Public interface
    // Only expose what's necessary for external use
    return {
        init: init, // Required for initialization from main.js
        handleSuccessResponse: handleSuccessResponse, // Required for AJAX handling
        utilityFunction: utilityFunction // Only if needed by other modules
    };

})(jQuery, SiP.Core.ajax, SiP.PrintifyManager.utilities);

// Register AJAX success handler
SiP.Core.ajax.registerSuccessHandler('sip-printify-manager', 'module_action', sip.moduleTemplate.handleSuccessResponse);

-----------------------------------------------------------------------------------------------------------

# SiP Printify Manager - File Structure and Guidelines

## 1.1 PHP Files

### Main plugin file: `sip-printify-manager.php`
**Purpose:** Main entry point for the plugin. Initializes the plugin and sets up WordPress hooks.

**Guidelines:**
- Define plugin metadata (name, version, description, etc.)
- Include necessary files
- Define the main plugin class
- Set up activation, deactivation, and uninstall hooks
- Enqueue scripts and styles
- Initialize the plugin

**Example structure:**

```php
<?php
/*
Plugin Name: SiP Printify Manager
Version: X.X
Description: ...
*/

if (!defined('ABSPATH')) exit;

require_once plugin_dir_path(__FILE__) . 'includes/class-sip-printify-manager.php';

function run_sip_printify_manager() {
    $plugin = new SiP_Printify_Manager();
    $plugin->run();
}

run_sip_printify_manager();
```

### Specialized functionality files:

#### `shop-functions.php`
**Purpose:** Handles shop-related functionalities and Printify API interactions.

**Guidelines:**
- Include functions for API authentication
- Implement shop data retrieval and management
- Handle shop-specific AJAX actions

**Example structure:**

```php
<?php
function sip_handle_shop_action() {
    // Handle shop-related AJAX actions
}

function sip_get_shop_details($token) {
    // Retrieve shop details from Printify API
}

function sip_new_shop() {
    // Save and encrypt the API token
}
```

#### `product-functions.php`
**Purpose:** Manages product-related operations.

**Guidelines:**
- Implement functions for product creation, updating, and deletion
- Handle product data retrieval and formatting
- Manage product-specific AJAX actions

**Example structure:**

```php
<?php
function sip_handle_product_action() {
    // Handle product-related AJAX actions
}

function sip_get_products($shop_id) {
    // Retrieve products from Printify API
}

function sip_publish_new_product($product_data) {
    // Create a new product on Printify
}
```

#### `image-functions.php`
**Purpose:** Handles image upload, management, and processing.

**Guidelines:**
- Implement image upload functionality
- Handle image resizing and optimization
- Manage image-related AJAX actions

**Example structure:**

```php
<?php
function sip_handle_image_action() {
    // Handle image-related AJAX actions
}

function sip_upload_image($file) {
    // Handle image upload and processing
}

function sip_get_images($shop_id) {
    // Retrieve images from Printify API
}
```

#### `template-functions.php`
**Purpose:** Manages template creation and usage.

**Guidelines:**
- Implement functions for template creation and editing
- Handle template data storage and retrieval
- Manage template-specific AJAX actions

**Example structure:**

```php
<?php
function sip_handle_template_action() {
    // Handle template-related AJAX actions
}

function sip_create_template($product_data) {
    // Create a new template from product data
}

function sip_get_templates() {
    // Retrieve saved templates
}
```

#### `creation-functions.php`
**Purpose:** Handles bulk product creation functionality.

**Guidelines:**
- Implement functions for bulk product creation
- Handle CSV import/export functionality
- Manage creation-specific AJAX actions

**Example structure:**

```php
<?php
function sip_handle_creation_action() {
    // Handle creation-related AJAX actions
}

function sip_bulk_publish_new_product($template_id, $product_data) {
    // Create multiple products based on a template
}

function sip_import_csv($file) {
    // Import product data from CSV
}
```

#### `utilities.php`
**Purpose:** Contains utility functions used across the plugin.

**Guidelines:**
- Implement reusable helper functions
- Avoid placing business logic here

**Example structure:**

```php
<?php
function sip_sanitize_input($input) {
    // Sanitize user input
}

function sip_format_price($price) {
    // Format price for display
}

function sip_log_error($message) {
    // Log error messages
}
```

### Admin page view: `views/dashboard-html.php`
**Purpose:** Renders the main admin interface for the plugin.

**Guidelines:**
- Focus on HTML structure and minimal PHP for data display
- Avoid including complex logic; use functions from other files

**Example structure:**

```php
<?php
// Check user capabilities
if (!current_user_can('manage_options')) {
    return;
}

// Get necessary data
$shop_details = sip_get_shop_details();
$products = sip_get_products();
$templates = sip_get_templates();
?>

<div class="wrap">
    <h1><?php echo esc_html(get_admin_page_title()); ?></h1>
    
    <!-- Shop details section -->
    <div id="shop-details">
        <!-- Display shop details -->
    </div>
    
    <!-- Products section -->
    <div id="products-section">
        <!-- Display products table -->
    </div>
    
    <!-- Templates section -->
    <div id="templates-section">
        <!-- Display templates table -->
    </div>
    
    <!-- Product creation section -->
    <div id="product-creation">
        <!-- Display product creation form -->
    </div>
</div>
```

## 1.2 JavaScript Files

### Core files:

#### `utilities.js`
**Purpose:** Provides utility functions for client-side operations.

**Guidelines:**
- Implement reusable helper functions
- Use the module pattern to avoid polluting the global namespace

**Example structure:**

```javascript
var sip = sip  {};

SiP.PrintifyManager.utilities = (function($) {
    function formatPrice(price) {
        // Format price for display
    }

    function showToast(message, duration) {
        // Display a toast notification
    }

    return {
        formatPrice: formatPrice,
        showToast: showToast
    };
})(jQuery);
```

#### `ajax.js`
**Purpose:** Centralizes AJAX request handling.

**Guidelines:**
- Implement a centralized function for making AJAX requests
- Handle common AJAX errors and responses

**Example structure:**

```javascript
var sip = sip  {};

SiP.Core.ajax = (function($) {
    function handleAjaxAction(actionType, formData, successCallback, errorCallback) {
        $.ajax({
            url: sipAjax.ajax_url,
            type: 'POST',
            data: formData,
            processData: false,
            contentType: false,
            success: function(response) {
                if (response.success) {
                    successCallback(response.data);
                } else {
                    errorCallback(response.data);
                }
            },
            error: function(jqXHR, textStatus, errorThrown) {
                errorCallback(errorThrown);
            }
        });
    }

    return {
        handleAjaxAction: handleAjaxAction
    };
})(jQuery);
```

### Module files:

#### `product-actions.js`, `image-actions.js`, `template-actions.js`, `creation-actions.js`
**Purpose:** Handle UI interactions and AJAX calls for specific functionalities.

**Guidelines:**
- Use the module pattern
- Implement event listeners for UI interactions
- Call AJAX functions from `ajax.js`
- Update UI based on AJAX responses

**Example structure (product-actions.js):**

```javascript
var sip = sip  {};

SiP.PrintifyManager.productActions = (function($, ajax, utilities) {
    function init() {
        $('#create-product-btn').on('click', handleCreateProduct);
        $('#reload-products-btn').on('click', handleReloadProducts);
    }

    function handleCreateProduct() {
        // Gather product data and call AJAX function
        var formData = new FormData($('#create-product-form')[0]);
        formData.append('action', 'sip_handle_ajax_request');
        formData.append('action_type', 'product_action');
        formData.append('product_action', 'publish_new_product');

        ajax.handleAjaxAction('product_action', formData, 
            function(response) {
                // Handle success
                utilities.showToast('Product created successfully');
                // Update UI
            },
            function(error) {
                // Handle error
                utilities.showToast('Error creating product: ' + error);
            }
        );
    }

    function handleReloadProducts() {
        // Implementation for reloading products
    }

    return {
        init: init
    };
})(jQuery, SiP.Core.ajax, SiP.PrintifyManager.utilities);
```

### Initialization files:

#### `main.js`
**Purpose:** Entry point for JavaScript execution.

**Guidelines:**
- Set up any global error handlers
- Call the init function when the document is ready

**Example structure:**

```javascript
(function($) {
    $(document).ready(function() {
        sip.init.initializeAllModules();
    });

    // Global error handler
    window.onerror = function(message, source, lineno, colno, error) {
        console.error('Global error:', message, 'at', source, 'line', lineno, ':', error);
        SiP.PrintifyManager.utilities.showToast('An error occurred. Please try again or contact support.');
    };
})(jQuery);
```

## General Best Practices:
1. Use consistent naming conventions across all files (e.g., prefix all functions with `sip_` in PHP and use camelCase in JavaScript).
2. Keep functions focused and modular. Each function should do one thing and do it well.
3. Comment complex logic and provide function documentation using PHPDoc for PHP and JSDoc for JavaScript.
4. Adhere to WordPress coding standards for PHP files (https://make.wordpress.org/core/handbook/best-practices/coding-standards/php/).
5. Use ESLint or similar tools to maintain JavaScript code quality and consistency.
6. Implement comprehensive error handling and logging in both PHP and JavaScript.
7. Ensure all user inputs are properly sanitized and validated using WordPress functions like `sanitize_text_field()` and `wp_kses()`.
8. Use nonce verification for all AJAX actions to prevent CSRF attacks.
9. Keep the separation of concerns in mind when adding new functionality. If a new feature doesn't fit into existing files, consider creating a new module.
10. Use WordPress transients for caching frequently accessed data to improve performance.
11. Optimize database queries and use `$wpdb->prepare()` for all database operations involving variables.
12. Implement proper data cleanup on plugin deactivation and provide options for users to export their data.
13. Use WordPress hooks and filters to make the plugin extensible.
14. Keep the UI consistent with WordPress admin design patterns.
15. Ensure all strings are internationalized using WordPress i18n functions.

By following these guidelines and best practices, you'll maintain a clean, efficient, and maintainable codebase for the SiP Printify Manager plugin.

## Creating Product Creation Table Data

Here is how template data should be interpreted to populate image and color cells:

For the purposes of filling in the images tabs, go through the print_area arrays like this:
        "variant_ids": [				    	    |	OPEN
                11952,					    	    |	REMEMBER
                11951,					    	    |	REMEMBER
                11953,					    	    |	REMEMBER
                11950,					    	    |	REMEMBER
                11954					    	    |	REMEMBER

placeholders: [     					    	    |	OPEN
	"position": "front",			   		        |	REMEMBER
	"images": [
            {            	        	            |	OPEN
			"id": "66d5bce57c0b485c83827a0f",	    |	REMEMBER
			"name":	"FSGPurl98989a.svg",		    |	REMEMBER
			"type": "image\/png",			        |	IGNORE 
                        "height": 65,			    |	IGNORE 
                        "width": 800,			    |	IGNORE
                        "x": 0.5,				    |	IGNORE
                        "y": 0.82486495233750334,   |	IGNORE
                        "scale": 0.4556,			|	IGNORE
                        "angle": 0,				    |	IGNORE
                        "src": ""				    |	IGNORE
            },
            {   					                |	INCREMENT THE IMAGE NUMBER AND MOVE TO THE NEXT IMAGE IN THE ARRAY
			"id": "66d4a40ef3e52e3c26057e06",       |	SAME PATTERN FOR ALL IMAGES IN ARRAY
            ...
            }
    ]
    }
],

Go through each of the remembered variant ids.  search the templates variants array by variant id to get option data associated with that variant id. "options": [376, 15],.  the first number represents color (the second number represents size) that can be identified in the templates options array. search options array using first number in the variant options to get color title and hex value:

    "options": [
        {
            "name": "Colors",
            "type": "color",
            "values": [
                {
                    "id": 521,
                    "title": "White",
                    "colors": [
                        "#ffffff"
                    ]
                },

Remember the list of returned color names and hex values (removing duplicates) so you can make swatches from them that correspond to the image sets associated with a print area "position" in each template.

When you get to the end of the first array, you will have the following data
| 						                    Front Design						                    |                           |
	|   image #1		|       image #2		|          image #3			|       image #4		|	        Colors		    |
	_________________________________________________________________________________________________________________________________________
	| image thumbnail	| image thumbnail	    |       image thumbnail		|       image thumbnail	|	swatches that correspond|
	| FSGPurl98989a.svg	| square_empty_black.svg| fsgp_abstract_04_3600.jpg	| FSGPtopper98989a.svg	|	to colors that make up	|
															                                                    variant ids

CYCLE THROUGH ALL THE PLACEHOLDER ENTRIES IN THE TEMPLATE ARRAY
IF YOU FIND NEW IMAGES IN A POSITION CREATE A NEW ROW UNDER THE TEMPLATE ROW AND ADD THEM TO THE APPROPRIATE COLUMN THERE.  PUT THE TITLE + "Design Variant x" incrementing the x for each new row

AT THE END WE HAVE

|			             | 						Front Design						                        |				                |
|        Title		    | image #1		    | image #2		    | image #3			    | image #4		    |	      Colors		        |
__________________________________________________________________________________________________________________________________________________________________
|			            | image thumbnail	| image thumbnail	| image thumbnail		| image thumbnail	|   swatches that correspond	|
|  FSGP Abstract 04 Tee	| FSGPurl98989a.svg	| square_empty_bl...| fsgp_abstract_04_3...	| FSGPtopper9898...	|   to colors that make up	    |
																                                            |             variant ids		|
__________________________________________________________________________________________________________________________________________________________________	
|  FSGP Abstract 04 Tee	| image thumbnail	|			        |				        | image thumbnail	|   swatches that correspond	|
|   Design Variant 01	| FSGPurl151515.svg	|			        |				        | FSGPtopper1515...	|   to colors that make Up      |
  																	                                        |            variant ids        |
__________________________________________________________________________________________________________________________________________________________________	
|  FSGP Abstract 04 Tee	| image thumbnail	|			        |				        | image thumbnail	|   swatches that correspond	|
|   Design Variant 02 	| FSGPurl303030.svg	|			        |				        | FSGPtopper3030...	|   to colors that make up      |
  																	                                        |            variant ids        |

IMAGE THUMBNAILS WILL NEED TO BE DERIVED FROM THE IMAGES IN THE IMAGES TABLE using the image id # WHICH SHOULD CONTAIN ALL IMAGES REFERENCED IN THE CREATE NEW PRODUCTS TABLE





XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
///////////////////////////IMAGES////////////////////////

The portion of the template array that contains the images for the product is structured like this in the template.json file:

print_areas:
	variant_ids:
	placeholders: [
		"position": "front",
		"images": [
				{
				"id": "66d5bce57c0b485c83827a0f",
				"name":	"FSGPurl98989a.svg",
				"type": "image\/png",
							"height": 65,
							"width": 800,
							"x": 0.5,
							"y": 0.82486495233750334,
							"scale": 0.4556,
							"angle": 0,
							"src": ""
				},
				{
				"id": "66d4a40ef3e52e3c26057e06",
				...
				}

The important data fields for our purposes are:
"variant_ids" - the ids of the variant products that use these images in their print areas - these are important for structuring and populating color swatch data in the Product Creation Table as explained later.
"position" - the location on the product where the image is to be printed.  This is essentially the print area.  
"id" - the printify image id and the key that well use later for identifying images in the images table
"name" - the name of the image that will be used to label the image in the product creation table


Here's how this data will drive creation of the image clusters in the Product Creation Table
Each unique "position" value will create its own header in the Product Creations Table.  This header will be titled "(position name) - Design".

Under each position there may be multiple images.  Each image in the array will be represented by a subheader cell in the table titled "image#n" from left to right corresponding to the images in the array from top to bottom.  The "(position name) - Design" main title header will span whatever number of subheaders are needed to present all the images in the position.  If a print area has only one image in it, the header cell contains simply "design - (print area)" and no subheader.

When it comes time to populate the first row of template data under the position design headers, each subheader cell will contain a small 30x30 image thumbnail derived from the url in the "src" key with the image title centered beneath it. The thumbnail should be clickable and open up a lightbox with the image in it.

Here is an example of design headers and subheaders in a case where there are four images in the print area array
						---------------------------------------------------------------------------------
						| 							(position name) - Design							|
						| 		image #1	| 		image #2	| 		image #3	| 		image #4	|
						---------------------------------------------------------------------------------						
						| image thumbnail	| image thumbnail	| image thumbnail	| image thumbnail	|	
						| image name		| image name		| image name		| image name		|
						---------------------------------------------------------------------------------

Each different position in the template will have its own segment like this across the top of the table.

There are commonly cases in which the same position is used in multiple placeholders.  These are handled by adding a new row under the position design headers for each different array of images associated with a placeholder.  In the new row, any unique image or combination of images is listed under the appropriate image # subheader.

/////////////////DETAILED IMAGE AND COLOR POPULATION NOTES//////////////
Here is how template data should be interpreted to populate image and color cells:

For the purposes of filling in the images tabs, go through the print_area array like this:
"variant_ids": [				    	 		   |	OPEN
        11952,					    	 		   |	REMEMBER
        11951,					    	 		   |	REMEMBER
        11953,					    	 		   |	REMEMBER
        11950,					    	 		   |	REMEMBER
        11954					    	 		   |	REMEMBER

placeholders: [     					    	    |	OPEN
	"position": "front",			   		        |	REMEMBER
	"images": [
            {            	        	            |	OPEN
			"id": "66d5bce57c0b485c83827a0f",	    |	REMEMBER
			"name":	"FSGPurl98989a.svg",		    |	REMEMBER
			"type": "image\/png",			        |	IGNORE 
                        "height": 65,			    |	IGNORE 
                        "width": 800,			    |	IGNORE
                        "x": 0.5,				    |	IGNORE
                        "y": 0.82486495233750334,   |	IGNORE
                        "scale": 0.4556,			|	IGNORE
                        "angle": 0,				    |	IGNORE
                        "src": ""				    |	IGNORE
            },
            {   					                |	INCREMENT THE IMAGE NUMBER AND MOVE TO THE NEXT IMAGE IN THE ARRAY
			"id": "66d4a40ef3e52e3c26057e06",       |	SAME PATTERN FOR ALL IMAGES IN ARRAY
            ...
            }
    ]
    }
],

Go through each of the remembered variant ids.  search the templates variants array by variant id to get option data associated with that variant id. "options": [376, 15],.  the first number represents color (the second number represents size) that can be identified in the templates options array. search options array using first number in the variant options to get color title and hex value:

    "options": [
        {
            "name": "Colors",
            "type": "color",
            "values": [
                {
                    "id": 521,
                    "title": "White",
                    "colors": [
                        "#ffffff"
                    ]
                },

Remember the list of returned color names and hex values (removing duplicates) so you can make swatches from them that correspond to the image sets associated with a print area "position" in each template.

When you get to the end of the first array, you will have the following data
| 						                    Front Design						                    |                           |
	|   image #1		|       image #2		|          image #3			|       image #4		|	        Colors		    |
	_________________________________________________________________________________________________________________________________________
	| image thumbnail	| image thumbnail	    |       image thumbnail		|       image thumbnail	|	swatches that correspond|
	| FSGPurl98989a.svg	| square_empty_black.svg| fsgp_abstract_04_3600.jpg	| FSGPtopper98989a.svg	|	to colors that make up	|
															                                                    variant ids

CYCLE THROUGH ALL THE PLACEHOLDER ENTRIES IN THE TEMPLATE ARRAY
IF YOU FIND NEW IMAGES IN A POSITION CREATE A NEW ROW UNDER THE TEMPLATE ROW AND ADD THEM TO THE APPROPRIATE COLUMN THERE.  PUT THE TITLE + "Design Variant x" incrementing the x for each new row

AT THE END WE HAVE

|			             | 						Front Design						                        |				                |
|        Title		    | image #1		    | image #2		    | image #3			    | image #4		    |	      Colors		        |
__________________________________________________________________________________________________________________________________________________________________
|			            | image thumbnail	| image thumbnail	| image thumbnail		| image thumbnail	|   swatches that correspond	|
|  FSGP Abstract 04 Tee	| FSGPurl98989a.svg	| square_empty_bl...| fsgp_abstract_04_3...	| FSGPtopper9898...	|   to colors that make up	    |
																                                            |             variant ids		|
__________________________________________________________________________________________________________________________________________________________________	
|  FSGP Abstract 04 Tee	| image thumbnail	|			        |				        | image thumbnail	|   swatches that correspond	|
|   Design Variant 01	| FSGPurl151515.svg	|			        |				        | FSGPtopper1515...	|   to colors that make Up      |
  																	                                        |            variant ids        |
__________________________________________________________________________________________________________________________________________________________________	
|  FSGP Abstract 04 Tee	| image thumbnail	|			        |				        | image thumbnail	|   swatches that correspond	|
|   Design Variant 02 	| FSGPurl303030.svg	|			        |				        | FSGPtopper3030...	|   to colors that make up      |
  																	                                        |            variant ids        |

IMAGE THUMBNAILS WILL NEED TO BE DERIVED FROM THE IMAGES IN THE IMAGES TABLE using the image id # WHICH SHOULD CONTAIN ALL IMAGES REFERENCED IN THE CREATE NEW PRODUCTS TABLE

XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
each table subheader cell that represents an image in the template has a number of features.
	*image thumbnail - 
		a small 30x30 image thumbnail derived from the url in the "src" key  The thumbnail should be clickable and open up a lightbox with the image in it.
	*image name - 
		the name of the image is displayed in small text beneath the thumbnail.  If it is the default image from the template, the text is in 70% grey.  If the image has been replaced by the user, the text is 100% black.
    *selection toggle - 
		a small square checkbox in the upper left corner that will designate the column as a target for image addition.  
        When a column is selected, the user can then select a number of images in the image table, choose 'add images to new products' from the pulldown, click 'execute' and the images will populate unedited image cells one per row in the selected column.  If there ara no numbered new product rows for the images to populate, they will be automatically created with the other cells in the new rows initialized with the main template data.  In this way the user can select a large number of products and quickly create indiviudal products from each.

XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

//////////////////////MAIN TEMPLATE DATA ROW//////////////////////
The second row of the table will populate with the main template values associated with the template keys.
	This row has custom css that distinguishes it from other rows.
	This row is not numbered.
	This cells in this row are editable and will be saved when the save button is clicked.
	there is no checkbox next to this row; this row is not selectable for product Creation
	Edits to the main template data cells will populate the corresponding cells in any new product rows created thereafter. (existing product rows created from the previous template data will not be updated)


    title				| The title in the table is assembled in part from the template title and in part from the front image name.  The code should look up the front image name in the template, find its string in the title string (or the placeholder "[title]") and replace it with the image name of whatever image is in the front image cell whether thats pulled in from the template or the user enters or drags a new image into the image thumb or front image name cells of the table - the name should then be editable.  There should be a reset icon on the far right side of the name cell that will revert it to the template name with the current front image.

    
    colors				| For all the ids in the colors array create a series of swatches in the "colors" table cell associated with that product.  The swatches are filled with the their associated colors hexadecimal value with rollover text that shows the associated colors title.

    sizes				| For all the ids in the sizes array create a series of strings in the "sizes" table cell associated with that product.  For each size show "title" values separated by commas

    description			| The description should populate from the template description.  The cell should only show the first 20 or 30 characters of the description followed by ellipsis.  There should be a document edit button on the far right side of the cell that brings up a text editor overlay using the same implementation used in the description editor already implemented in the code.  Next to the document edit button should be a reset icon that will revert it to the description in the source template.

    tags				| The tags cell should be populated from the template and the cell should be editable.  There should be a reset button on the far right of the cell that reverts the contents of the cell back to the tags in the source template.

    price			| not quite sure how to implement this yet.  Perhaps to start it could just show the range of lowest to highest price shown in the template.

    print areas			| appear in the template in the context of the design locations	

    position	| the solution for the "front" position has been included above.  Each additional position in the template should be structured in the same way and the associated headers, columns and data should be appended to the table in the order in which they appear in the template

    images		| images data is integrated as described above

	If another template is selected in the template list and the Create New Product action is executed, it should replace the currently open template.  If there are unsaved changes, the user should be prompted to save them.



Here is an example of design headers and subheaders in a case where there are four images in the print area array
						| 							Design - (print area)								|
						| image thumbnail	| image thumbnail	| image thumbnail	| image thumbnail	|	
						| image name		| image name		| image name		| image name		|


////////////////////NEW PRODUCT ROWS///////////////////////////
Subsequent rows below the main template data are where new products are made, one product per row. 

	Initially new product rows are blank.  there is custom css to style the blank state.
		there is a + sign, the add product button, in the # column of the first blank product row.  When clicked the row is initialized.

	Blank product rows can be initialized in a number of ways.
		clicking the add product button next to the row - 
			There is an add product button next to each empty row.  These can be shift clicked.

		importing a csv -
			When a csv file is imported, the table is populated with new rows.  The csv file should be structured in the same way as the template json file.

		adding images to the product table -
			each new row will be numbered and populated with the main template data (in grey text) so that new products can be made by switching out the relevant cells with new images or text (turning the text black) as needed.

	When a blank product row is "initialized"
	 	a unique sequential number replaces the + sign in the first column on the left side.  This number is not associated with the product in any way except to distinguish it from other new product rows.
		the cells in the new product row populate with the data from the main template data row in 70% grey text.  When customized, the text will appear 100% black.
		each cell will have a revert icon that will revert the cell to the main template data turning the text back to grey.  The revert icon will be a small circular arrow that will appear in the upper right corner of the cell when the cell is hovered over.
		each image cell in the table will also have a small square selection toggle in the upper left corner.  
        	These can be used to designate multiple cells to send a single image to.  When a user selects cells as targets and uses the 'add image to new products' button, the selected image populates all the selected cells.
	
////////////////////////EDITING THE TEMPLATE/////////////////////


The user can then move on to edit each cell using tools made available by the plugin including adding images, tags, updating titles and descriptions.

PRODUCT CREATION
when the user has completed the population of a new product row or rows to create new products, the rows can be selected and the publish new product button can be clicked.  This will trigger the assembly of the product rows into json files that will be submitted to printify through its api so printify can create new products from them and deliver them to the users woocommerce store for sale.

Once the user has created new products and saved their template, each time the template is subsequently loaded, there will be new types of rows below the main template data row.  These rows will be color coded as follows:
	-rows containing products that have been published to printify have a light green background (these are no longer editable)
	-rows that contain saved products that have not been published to printify have a light yellow background (these are editable)
	-rows that contain products made in the current session have a white background.
Rows containing already made products can be toggled off so that the user can just review new products


//////////////////////LATER DEV/////////////////////
-----------------------------------

FOR LATER DEVELOPMENT: template sync button 
		This should be an advanced control in the settings tab or in the advanced controls tab of the sip printify manager plugin.  it scans the images list for images that have tags that share the source product, then it scans the products list for products that have the same blueprint as the template with images that correspond to the tags in the images list.  It then updates the create product table with the products that have been identified.


--------------------------------

when we select an image cell in a header and it selects the unedited rows in the child products in its column, the behavior should be that when a series of images is chosen in the image table and the Add to New Products button is clicked, each image should populate all the corresponding image cells in all the variant rows in a selected Child Products column.  Then the next image should populate all the corresponding image cells in all the variant rows in the next selected Child Products column. And so on. So all the variants of the selected child image in a particular child products image column will be populated with the same image instead of just the first variant.
With this as the default behavior, we don't need to include more than one placeholders array in the copies json in the template_wip.json file.  We can include only one and, it can be assumed that all the corresponding images in all the variant placeholder arrays use the image if it is in the single placeholders images array in the copies array.
We will implement additional functionality at a later time so that if the user would like, they can then select individual cells and click the Add To New Product button and the selected image will populate the selected cell.  In that case, the json representation in the copies array will need to grow to represent the location of the edited image positions.