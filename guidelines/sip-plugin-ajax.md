# Implementing AJAX Functionality

This guide explains how to implement AJAX functionality in SiP plugins using the centralized architecture. All AJAX requests flow through the core handler for consistency and security.

## AJAX Architecture Overview

The SiP Plugin Suite uses a three-tier AJAX architecture:

1. **Central Router** (`sip-plugins-core/ajax-handler.php`) - Routes all AJAX requests
2. **Plugin Shell** (`includes/{plugin}-ajax-shell.php`) - Routes plugin-specific actions  
3. **Action Handlers** (`includes/{feature}-functions.php`) - Handle specific operations

### Core Principles

1. **Centralized Architecture**: All AJAX requests go through a single, centralized router in SiP Plugins Core.

2. **Plugin Shells**: Each SiP plugin implements its own AJAX "shell" that:
   - Registers with the central router  
   - Routes action types to specific handlers
   - Maintains consistent request/response patterns

3. **Action Handlers**: Each plugin shell routes to specific action handlers that:
   - Handle one type of action (e.g., product actions, template actions)
   - Further route to specific operations based on sub-actions
   - Always use the `SiP_AJAX_Response` class for responses

4. **Response Consistency**: The central router ensures all responses follow a standard format:
   ```json
   {
       "success": true,
       "plugin": "sip-printify-manager",
       "action_type": "product_action", 
       "action": "upload_product",
       "message": "Product uploaded successfully",
       "data": {
           "product_id": 12345,
           "title": "New Product"
       }
   }
   ```

5. **Error Handling**: Errors are caught and formatted at multiple levels:
   - Central router level (plugin not found, missing parameters)
   - Plugin shell level (invalid action type)
   - Handler level (operation-specific errors)

### Request Flow

```
Browser -> WordPress -> Central Router -> Plugin Shell -> Action Handler
                                                     <-> Response
```

### Plugin Shell Architecture

```
Central Router (sip-plugins-core/includes/ajax-handler.php)
  └── Plugin Shell (sip-printify-manager/includes/printify-ajax-shell.php)
      ├── Product Action Handler (product-functions.php)
      ├── Template Action Handler (template-functions.php)  
      └── Image Action Handler (image-functions.php)
```

The shell pattern allows each plugin to:
- Maintain its own action namespace
- Handle plugin-specific routing logic
- Integrate seamlessly with the central router
- Keep action handlers organized by functionality

### Standardized Response Format

All AJAX responses use this consistent format:

```json
{
    "success": true,
    "plugin": "sip-printify-manager",
    "action_type": "product_action", 
    "action": "upload_product",
    "message": "Product uploaded successfully",
    "data": {
        "product_id": 12345,
        "title": "New Product"
    }
}
```

Key fields:
- `success`: Boolean indicating success or failure
- `plugin`: Plugin identifier (e.g., 'sip-printify-manager')
- `action_type`: Type of action (e.g., 'product_action')
- `action`: Specific action (e.g., 'upload_product')
- `message`: Optional message text
- `data`: Response data payload

## Step 1: Register Your AJAX Handler Shell

Create `includes/{plugin-prefix}-ajax-shell.php`:

```php
<?php
if (!defined('ABSPATH')) exit;

// Register with central SiP AJAX handler
function sip_your_plugin_register_ajax_handler() {
    add_action('sip_plugin_handle_action', 'sip_your_plugin_route_action');
}
add_action('init', 'sip_your_plugin_register_ajax_handler');

// Route actions to specific handlers
function sip_your_plugin_route_action($action_type) {
    switch ($action_type) {
        case 'product_action':
            sip_handle_product_action();
            break;
            
        case 'settings_action':
            sip_handle_settings_action();
            break;
            
        default:
            SiP_AJAX_Response::error(
                'sip-your-plugin-name',
                'Invalid action type: ' . $action_type,
                'invalid_action'
            );
            break;
    }
}
```

### AJAX Shell Naming Pattern
Each plugin uses its own prefix for the AJAX shell:
- `printify-ajax-shell.php` for SiP Printify Manager
- `woocommerce-monitor-ajax-shell.php` for SiP WooCommerce Monitor
- `development-tools-ajax-shell.php` for SiP Development Tools

## Step 2: Create Action Handlers

Create specific handlers in `includes/{feature}-functions.php`:

```php
<?php
if (!defined('ABSPATH')) exit; // Exit if accessed directly

function sip_handle_product_action() {
    $specific_action = isset($_POST['product_action']) 
        ? sanitize_text_field($_POST['product_action']) 
        : '';
    
    switch ($specific_action) {
        case 'create':
            sip_create_product();
            break;
            
        case 'update':
            sip_update_product();
            break;
            
        case 'delete':
            sip_delete_product();
            break;
            
        case 'get_data':
            sip_get_product_data();
            break;
            
        default:
            SiP_AJAX_Response::error(
                'sip-your-plugin-name',
                'Unknown product action: ' . $specific_action,
                'unknown_action'
            );
            break;
    }
}

function sip_create_product() {
    // Validate required parameters
    if (!isset($_POST['product_name'])) {
        SiP_AJAX_Response::error(
            'sip-your-plugin-name',
            'product_action',
            'create',
            'Missing required parameter: product_name'
        );
        return;
    }
    
    $product_name = sanitize_text_field($_POST['product_name']);
    
    // Perform the operation
    $product_id = wp_insert_post([
        'post_title' => $product_name,
        'post_type' => 'product',
        'post_status' => 'publish'
    ]);
    
    if (is_wp_error($product_id)) {
        SiP_AJAX_Response::error(
            'sip-your-plugin-name',
            'product_action',
            'create',
            $product_id->get_error_message()
        );
        return;
    }
    
    // Return success response
    SiP_AJAX_Response::success(
        'sip-your-plugin-name',
        'product_action',
        'create',
        ['product_id' => $product_id],
        'Product created successfully'
    );
}
```

## Step 3: Create JavaScript Module

Create `assets/js/modules/product-actions.js`:

```javascript
var SiP = SiP || {};
SiP.YourPlugin = SiP.YourPlugin || {};

console.log('▶ product-actions.js Loading...');

SiP.YourPlugin.productActions = (function($, ajax, utilities, state) {
    'use strict';
    
    // Initialize module
    function init() {
        console.log('         🟡 product-actions.js:init()');
        attachEventListeners();
    }
    
    // Attach event listeners
    function attachEventListeners() {
        $(document).on('click', '.create-product-btn', handleCreateProduct);
        $(document).on('click', '.update-product-btn', handleUpdateProduct);
        $(document).on('click', '.delete-product-btn', handleDeleteProduct);
    }
    
    // Handle create product
    function handleCreateProduct(e) {
        e.preventDefault();
        
        const $button = $(this);
        const productName = $('#product-name').val();
        
        if (!productName) {
            utilities.toast.show('Please enter a product name', 3000);
            return;
        }
        
        // Show spinner
        const spinnerId = utilities.spinner.show($button);
        
        // Create form data
        const formData = utilities.createFormData(
            'sip-your-plugin-name',
            'product_action',
            'create'
        );
        formData.append('product_name', productName);
        
        // Send request
        return ajax.handleAjaxAction(
            'sip-your-plugin-name',
            'product_action',
            formData
        )
        .then(function(response) {
            utilities.toast.show('Product created successfully', 3000);
            // Refresh data or update UI
            if (window.productsTable) {
                window.productsTable.ajax.reload();
            }
            return response;
        })
        .catch(function(error) {
            utilities.toast.show('Error: ' + error.message, 5000);
            throw error;
        })
        .finally(function() {
            utilities.spinner.hide(spinnerId);
        });
    }
    
    // Handle response routing
    function handleSuccessResponse(response) {
        if (!response.success || response.plugin !== 'sip-your-plugin-name') {
            return response;
        }
        
        switch(response.action) {
            case 'create':
                console.log('Product created:', response.data.product_id);
                break;
                
            case 'update':
                console.log('Product updated:', response.data);
                break;
                
            case 'delete':
                console.log('Product deleted:', response.data);
                break;
                
            case 'get_data':
                updateUIWithData(response.data);
                break;
                
            default:
                console.warn('Unhandled action:', response.action);
        }
        
        return response;
    }
    
    // Update UI with data
    function updateUIWithData(data) {
        // Update your UI elements with the received data
        if (data.products) {
            renderProductList(data.products);
        }
    }
    
    // Public API
    return {
        init: init,
        handleSuccessResponse: handleSuccessResponse
    };
    
})(jQuery, SiP.Core.ajax, SiP.Core.utilities, SiP.Core.state);

// Register success handler
SiP.Core.ajax.registerSuccessHandler(
    'sip-your-plugin-name',
    'product_action',
    SiP.YourPlugin.productActions.handleSuccessResponse
);
```

## Step 4: Standard Response Formats

### Success Response

```php
SiP_AJAX_Response::success(
    'sip-your-plugin-name',    // Plugin identifier
    'action_type',             // Action type (e.g., 'product_action')
    'specific_action',         // Specific action (e.g., 'create')
    $data,                     // Response data (array or object)
    'Success message'          // Optional message
);
```

### Error Response

```php
SiP_AJAX_Response::error(
    'sip-your-plugin-name',    // Plugin identifier
    'Error message',           // Error message
    'error_type'               // Error type (e.g., 'invalid_input')
);
```

### Response Signatures

The `SiP_AJAX_Response` class provides three methods with specific signatures:

```php
// Success response
public static function success($plugin, $action_type, $action, $data = [], $message = '')

// Error response  
public static function error($plugin, $message, $error_type = 'general_error')

// DataTable response
public static function datatable($plugin, $action_type, $action, $items, $total, $filtered, $message = '')
```

### DataTable Response

```php
SiP_AJAX_Response::datatable(
    'sip-your-plugin-name',    // Plugin identifier
    'action_type',             // Action type
    'specific_action',         // Specific action
    $data,                     // Array of data rows
    $total_records,            // Total records in database
    $filtered_records,         // Filtered records count
    'Success message'          // Optional message
);
```

## Step 5: DataTables Integration

For server-side DataTables:

```javascript
$('#products-table').DataTable({
    processing: true,
    serverSide: true,
    ajax: {
        url: sipCoreAjax.ajaxUrl,
        type: 'POST',
        data: function(data) {
            // Add our standard parameters
            data.action = 'sip_handle_ajax_request';
            data.plugin = 'sip-your-plugin-name';
            data.action_type = 'product_action';
            data.product_action = 'get_data';
            data.nonce = sipCoreAjax.nonce;
            return data;
        },
        dataSrc: function(response) {
            if (response.success) {
                return response.data;
            }
            console.error('DataTable error:', response.message);
            return [];
        }
    },
    columns: [
        { data: 'id' },
        { data: 'name' },
        { data: 'status' },
        { 
            data: null,
            render: function(data, type, row) {
                return '<button class="edit-btn" data-id="' + row.id + '">Edit</button>';
            }
        }
    ]
});
```

PHP handler for DataTables:

```php
function sip_get_product_data() {
    // Get DataTables parameters
    $draw = isset($_POST['draw']) ? intval($_POST['draw']) : 1;
    $start = isset($_POST['start']) ? intval($_POST['start']) : 0;
    $length = isset($_POST['length']) ? intval($_POST['length']) : 10;
    $search = isset($_POST['search']['value']) ? $_POST['search']['value'] : '';
    
    // Build query
    $args = [
        'post_type' => 'product',
        'posts_per_page' => $length,
        'offset' => $start,
    ];
    
    if (!empty($search)) {
        $args['s'] = $search;
    }
    
    // Get data
    $query = new WP_Query($args);
    $products = [];
    
    foreach ($query->posts as $post) {
        $products[] = [
            'id' => $post->ID,
            'name' => $post->post_title,
            'status' => $post->post_status,
        ];
    }
    
    // Return DataTables response
    SiP_AJAX_Response::datatable(
        'sip-your-plugin-name',
        'product_action',
        'get_data',
        $products,
        $query->found_posts,    // Total records
        $query->found_posts,    // Filtered records
        'Products retrieved successfully'
    );
}
```

## Error Handling Best Practices

### PHP Side

1. **Always validate input**:
```php
if (!isset($_POST['required_field'])) {
    SiP_AJAX_Response::error(
        'sip-your-plugin-name',
        'Missing required field: required_field',
        'validation_error'
    );
    return;
}
```

2. **Sanitize all input**:
```php
$input = sanitize_text_field($_POST['input_field']);
$id = intval($_POST['id']);
$html = wp_kses_post($_POST['html_content']);
```

3. **Check capabilities**:
```php
if (!current_user_can('manage_options')) {
    SiP_AJAX_Response::error(
        'sip-your-plugin-name',
        'Insufficient permissions',
        'permission_denied'
    );
    return;
}
```

### JavaScript Side

1. **Handle errors gracefully**:
```javascript
ajax.handleAjaxAction(plugin, actionType, formData)
    .then(function(response) {
        // Handle success
    })
    .catch(function(error) {
        utilities.toast.show('Error: ' + error.message, 5000);
        console.error('AJAX Error:', error);
    })
    .finally(function() {
        utilities.spinner.hide(spinnerId);
    });
```

2. **Validate before sending**:
```javascript
if (!productName.trim()) {
    utilities.toast.show('Product name is required', 3000);
    return;
}
```

## Debugging AJAX Requests

### Browser Console

```javascript
// Enable debug logging
SiP.Core.ajax.enableDebugLogging = true;

// This will log all AJAX requests and responses
```

### PHP Error Logging

```php
// In your handler
error_log('AJAX Request: ' . print_r($_POST, true));
error_log('Processing action: ' . $specific_action);
```

### Network Tab

1. Open browser developer tools
2. Go to Network tab
3. Filter by XHR/AJAX requests
4. Look for requests to `admin-ajax.php`
5. Check request payload and response

## Common Patterns

### JavaScript Request Structure

Each AJAX request must include these parameters:
- `action`: Always set to `'sip_handle_ajax_request'` (handled by `createFormData`)
- `plugin`: The plugin identifier (e.g., `'sip-plugin-name'`) (handled by `createFormData`)
- `action_type`: The type of action (e.g., `'functionality_action'`) (handled by `createFormData`)
- `nonce`: The security nonce (handled by `createFormData`)
- Additional parameters specific to the action

The POST array should also include the specific action identifier:
- The key should be the action_type value
- The value should be the specific operation name
- Example: `$_POST['functionality_action'] = 'specific_operation'` (handled by `createFormData`)

### Loading Initial Data

```javascript
// In your module's init function
function loadInitialData() {
    const formData = utilities.createFormData(
        'sip-your-plugin-name',
        'settings_action',
        'get_settings'
    );
    
    return ajax.handleAjaxAction(
        'sip-your-plugin-name',
        'settings_action',
        formData
    )
    .then(function(response) {
        if (response.data.settings) {
            applySettings(response.data.settings);
        }
    });
}
```

### Form Submission

```javascript
$('#settings-form').on('submit', function(e) {
    e.preventDefault();
    
    const $form = $(this);
    const formData = utilities.createFormData(
        'sip-your-plugin-name',
        'settings_action',
        'save_settings'
    );
    
    // Add form fields to FormData
    $form.serializeArray().forEach(function(field) {
        formData.append(field.name, field.value);
    });
    
    // Show spinner on submit button
    const $submitBtn = $form.find('[type="submit"]');
    const spinnerId = utilities.spinner.show($submitBtn);
    
    ajax.handleAjaxAction(
        'sip-your-plugin-name',
        'settings_action',
        formData
    )
    .then(function(response) {
        utilities.toast.show('Settings saved', 3000);
    })
    .catch(function(error) {
        utilities.toast.show('Error: ' + error.message, 5000);
    })
    .finally(function() {
        utilities.spinner.hide(spinnerId);
    });
});
```

### DataTables AJAX Configuration

Always use the standard configuration for server-side DataTables:

```javascript
$('#functionality-table').DataTable({
    processing: true,
    serverSide: true,
    ajax: {
        url: sipCoreAjax.ajaxUrl,
        type: 'POST',
        data: function(data) {
            // Add required parameters
            data.action = 'sip_handle_ajax_request';
            data.plugin = 'sip-plugin-name';
            data.action_type = 'functionality_action';
            data.functionality_action = 'get_table_data';
            data.nonce = sipCoreAjax.nonce;
            return data;
        },
        dataSrc: function(response) {
            return response.data.items;
        }
    },
    columns: [
        {
            data: 'column_name',
            title: 'Column Title',
            render: function(data, type, row) {
                // Formatting logic
                return formatted_data;
            }
        },
        // Other columns
    ]
});
```

## AJAX Checklist

Use this checklist for every AJAX implementation:

### PHP Side
- [ ] Created or updated ajax shell with proper routing
- [ ] Named ajax shell with plugin-specific prefix
- [ ] Registered handler with `sip_plugin_handle_action` hook
- [ ] Implemented action handlers with switch statements
- [ ] Used `SiP_AJAX_Response` for all responses:
  - [ ] `SiP_AJAX_Response::success()` for successful responses
  - [ ] `SiP_AJAX_Response::error()` for error responses
  - [ ] `SiP_AJAX_Response::datatable()` for server-side DataTables
- [ ] Never used WordPress's wp_send_json functions
- [ ] Validated all required parameters
- [ ] Sanitized all input data
- [ ] Checked user capabilities where needed
- [ ] Added meaningful error messages with error types

### JavaScript Side
- [ ] Used `SiP.Core.utilities.createFormData()` for all requests
- [ ] Used `SiP.Core.ajax.handleAjaxAction()` for all requests
- [ ] No direct use of jQuery.ajax or XMLHttpRequest
- [ ] Registered success handler if needed
- [ ] Added proper error handling
- [ ] Managed spinner states
- [ ] Validated data before sending
- [ ] Updated UI after successful operations
- [ ] Followed module pattern structure
- [ ] Followed module organization principle (code with interface)

### Testing
- [ ] Tested success scenarios
- [ ] Tested error scenarios
- [ ] Verified spinner behavior
- [ ] Checked console for errors
- [ ] Tested with slow network

## Next Steps

- [Batch Processing](./batch-processing.md) - For operations on multiple items
- [File Uploads](./file-uploads.md) - For handling file uploads via AJAX
- [DataTables Integration](./datatables-integration.md) - For advanced table features
- [Error Handling](./error-handling.md) - For comprehensive error handling
- [Testing and Debugging](./testing-debugging.md) - For debugging AJAX issues