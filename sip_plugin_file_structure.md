# File Structure

## Overview

This document outlines the patterns, utilities, and naming conventions that should be followed when implementing SiP (Stuff is Parts) plugins. Following these guidelines ensures consistency across plugins and leverages all centralized functionality provided by the sip-plugins-core plugin.

## Table of Contents

1. [Plugin Structure](#plugin-structure)
2. [PHP Implementation Standards](#php-implementation-standards)
3. [JavaScript Implementation Standards](#javascript-implementation-standards)
4. [AJAX Communication Standards](#ajax-communication-standards)
5. [User Interface Standards](#user-interface-standards)
6. [Plugin Integration Checklist](#plugin-integration-checklist)

## Plugin Structure

The full file hierarchy of the sip plugin suite plugins is documented in the [Sip Plugin Suite Hierarchy](./sip_plugin_suite_hierarchy.md) Document.

## Core Plugin Structure

The SiP Plugins Core acts as a foundation and framework for all Stuff is Parts plugins. Its architecture follows these key principles:

### 1. Centralized Plugin Management

- Provides a unified admin dashboard under "SiP Plugins" menu
- Manages plugin dependencies and cross-plugin relationships
- Handles activation/deactivation of dependent plugins

### 2. Component Architecture

- **Core Libraries**:
  - `ajax.js`: Standardized AJAX request/response handling
  - `utilities.js`: Common utility functions used across plugins
  - `state.js`: Client-side state management
  
- **UI Components**:
  - Standardized headers via `sip_render_standard_header()`
  - Common CSS/styling system
  - Progress dialog system

### 3. Update System

- Custom plugin updater connecting to Stuff is Parts server
- Centralized version checking via `init_plugin_updater()`
- Plugin self-registration pattern for update checks

## Inter-Plugin Communication

- Plugins register themselves with core via `SiP_Plugin_Framework::init_plugin()`
- Each plugin maintains its own admin page but shares common UI patterns
- JavaScript modules can communicate through core-provided state system

## Directory Structure

Each SiP plugin should follow this standard directory structure:

```
sip-plugin-name/
├── sip-plugin-name.php          # Main plugin file
├── includes/                    # PHP includes
│   ├── plugin-ajax-shell.php    # AJAX handler shell
│   └── *-functions.php          # Functionality-specific PHP files
├── assets/                      # Frontend assets
│   ├── css/                     # Stylesheets
│   ├── js/                      # JavaScript files
│   │   ├── core/                # Core JS utilities
│   │   └── modules/             # Functionality-specific JS modules
│   └── images/                  # Images and icons
└── vendor/                      # Third-party dependencies (if any)
```

## Plugin Integration Pattern

Other SiP plugins follow this integration pattern:

1. Include the framework: `require_once WP_PLUGIN_DIR . '/sip-plugins-core/sip-plugin-framework.php'`
2. Initialize via: `SiP_Plugin_Framework::init_plugin($name, __FILE__, $class_name)`
3. Implement a static `render_dashboard()` method in their main class

### File Naming Conventions

- **Main plugin file**: `sip-plugin-name.php`
- **PHP function files**: `{functionality}-functions.php` (e.g., `shop-functions.php`, `image-functions.php`)
- **AJAX handler shell**: `plugin-ajax-shell.php`
- **JavaScript module files**: `{functionality}-actions.js` (e.g., `image-actions.js`, `shop-actions.js`)
- **JavaScript utility files**: `utilities.js`

## PHP Implementation Standards

### Main Plugin File

The main plugin file (e.g., `sip-plugin-name.php`) should:

1. Include the SiP Plugin Framework first:
```php
require_once WP_PLUGIN_DIR . '/sip-plugins-core/sip-plugin-framework.php';
```

2. Include the AJAX shell next:
```php
require_once plugin_dir_path(__FILE__) . 'includes/plugin-ajax-shell.php';
```

3. Include all functionality-specific files:
```php
$includes = [
    'shop-functions.php',
    'product-functions.php',
    'image-functions.php',
    // other functionality modules
];

foreach ($includes as $file) {
    require_once plugin_dir_path(__FILE__) . 'includes/' . $file;
}
```

4. Define a main plugin class that initializes the plugin:
```php
class SiP_Plugin_Name {
    private static $instance = null;
    
    private function __construct() {
        // Hook registrations
        add_action('admin_enqueue_scripts', array($this, 'enqueue_admin_scripts'));
        // Other hooks and actions
    }
    
    // Singleton pattern implementation
    public static function get_instance() {
        if (null === self::$instance) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    // Plugin initialization methods
    // Asset enqueuing methods
    // Other core plugin methods
}

// Initialize the plugin
SiP_Plugin_Name::get_instance();
```

### AJAX Handler Shell

The AJAX handler shell (`includes/plugin-ajax-shell.php`) should:

1. Register with the central SiP AJAX handler:
```php
function sip_plugin_register_ajax_handler() {
    add_action('sip_plugin_handle_action', 'sip_plugin_route_action');
}
add_action('init', 'sip_plugin_register_ajax_handler');
```

2. Route actions to specific handlers:
```php
function sip_plugin_route_action($action_type) {
    switch ($action_type) {
        case 'functionality_action':
            sip_handle_functionality_action();
            break;
        // Other action types
        default:
            SiP_AJAX_Response::error(
                'sip-plugin-name',
                'Invalid action type: ' . $action_type,
                'invalid_action'
            );
            break;
    }
}
```

### Functionality-Specific PHP Files

Each functionality-specific PHP file should:

1. Start with a check to prevent direct access:
```php
if (!defined('ABSPATH')) exit; // Exit if accessed directly
```

2. Define an action handler function:
```php
function sip_handle_functionality_action() {
    $specific_action = isset($_POST['functionality_action']) ? sanitize_text_field($_POST['functionality_action']) : '';
    
    switch ($specific_action) {
        case 'specific_operation':
            sip_specific_operation();
            break;
        // Other specific actions
        default:
            SiP_AJAX_Response::error(
                'sip-plugin-name',
                'functionality_action',
                'unknown',
                'Unknown functionality action: ' . $specific_action
            );
            break;
    }
}
```

3. Define operation-specific functions:
```php
function sip_specific_operation() {
    // Parameter validation
    if (!isset($_POST['required_parameter'])) {
        SiP_AJAX_Response::error(
            'sip-plugin-name',
            'functionality_action',
            'specific_operation',
            'Missing required parameter'
        );
        return;
    }
    
    // Business logic
    $result = perform_operation();
    
    // Response
    if ($result) {
        SiP_AJAX_Response::success(
            'sip-plugin-name',
            'functionality_action',
            'specific_operation',
            ['result_data' => $result],
            'Operation completed successfully'
        );
    } else {
        SiP_AJAX_Response::error(
            'sip-plugin-name',
            'functionality_action',
            'specific_operation',
            'Operation failed'
        );
    }
}
```

### AJAX Response Standards

Always use the `SiP_AJAX_Response` class for sending responses:

1. For success responses:
```php
SiP_AJAX_Response::success(
    'sip-plugin-name',           // Plugin identifier
    'functionality_action',      // Action type
    'specific_operation',        // Specific action
    ['result_data' => $data],    // Data to return
    'Success message'            // Message
);
```

2. For error responses:
```php
SiP_AJAX_Response::error(
    'sip-plugin-name',           // Plugin identifier
    'functionality_action',      // Action type
    'specific_operation',        // Specific action
    'Error message'              // Error message
);
```

3. For DataTables responses:
```php
SiP_AJAX_Response::datatable(
    'sip-plugin-name',           // Plugin identifier
    'functionality_action',      // Action type
    'get_table_data',            // Specific action
    $items,                      // Array of items
    $total,                      // Total record count
    $filtered,                   // Filtered record count
    'Data retrieved successfully' // Message
);
```

4. NEVER use WordPress's built-in functions:
   - ❌ `wp_send_json()`
   - ❌ `wp_send_json_success()`
   - ❌ `wp_send_json_error()`

## JavaScript Implementation Standards

### Module Structure

Each JavaScript module should follow this structure:

```javascript
var SiP = SiP || {};
window.SiP = window.SiP || {};
SiP.PluginName = SiP.PluginName || {};

console.log('▶ functionality-actions.js Loading...');

SiP.PluginName.functionalityActions = (function($, ajax, utilities) {
    
    // Private variables and functions
    
    function init() {
        console.log('         🟡 functionality-actions.js:init():attachEventListeners()');
        attachEventListeners();
    }
    
    function attachEventListeners() {
        // Event binding code
    }
    
    // Action handlers
    
    function handleSpecificAction(data) {
        const formData = SiP.Core.utilities.createFormData('sip-plugin-name', 'functionality_action', 'specific_action');
        
        // Add action-specific data
        formData.append('param1', data.param1);
        
        // Send the request
        return SiP.Core.ajax.handleAjaxAction('sip-plugin-name', 'functionality_action', formData)
            .then(function(response) {
                // Handle success response
                return response;
            })
            .catch(function(error) {
                // Handle error
                SiP.Core.utilities.toast.show('Error: ' + error.message, 5000);
                throw error;
            });
    }
    
    // Response handlers
    
    function handleSuccessResponse(response) {
        if (!response.success) {
            return response;
        }
        
        switch(response.action) {
            case 'specific_action':
                // Handle specific action response
                break;
            // Handle other actions
            default:
                console.warn('Unhandled action type:', response.action);
        }
        
        return response;
    }
    
    // Public API
    return {
        init: init,
        handleSpecificAction: handleSpecificAction,
        handleSuccessResponse: handleSuccessResponse
        // Other public methods
    };
    
})(jQuery, SiP.Core.ajax, SiP.Core.utilities);

// Register success handler
SiP.Core.ajax.registerSuccessHandler('sip-plugin-name', 'functionality_action', SiP.PluginName.functionalityActions.handleSuccessResponse);
```

### AJAX Request Standards

1. Always use `SiP.Core.utilities.createFormData()` to create FormData objects:
```javascript
const formData = SiP.Core.utilities.createFormData('sip-plugin-name', 'functionality_action', 'specific_action');
```

2. Always use `SiP.Core.ajax.handleAjaxAction()` to send AJAX requests:
```javascript
SiP.Core.ajax.handleAjaxAction('sip-plugin-name', 'functionality_action', formData)
    .then(function(response) {
        // Handle success
    })
    .catch(function(error) {
        // Handle error
    });
```

3. Always register a success handler for your action type:
```javascript
SiP.Core.ajax.registerSuccessHandler('sip-plugin-name', 'functionality_action', SiP.PluginName.functionalityActions.handleSuccessResponse);
```

### UI Utilities

1. For showing spinners:
```javascript
// Show spinner
SiP.Core.utilities.spinner.show();

// Hide spinner (usually handled automatically by handleAjaxAction)
SiP.Core.utilities.spinner.hide();
```

2. For showing notifications:
```javascript
// Show toast message
SiP.Core.utilities.toast.show('Message text', 3000); // 3000ms duration
```

3. For dialog boxes:
```javascript
const dialog = $('<div>Dialog content</div>').dialog({
    modal: true,
    width: 400,
    dialogClass: 'sip-dialog',
    // Other options
});
```

4. For progress dialogs (batch operations):
```javascript
SiP.Core.progressDialog.processBatch({
    items: itemsArray,
    batchSize: 5,
    
    // Dialog configuration
    dialogOptions: {
        title: 'Processing Items',
        initialMessage: 'Starting batch process...',
        waitForUserOnComplete: true
    },
    
    // Process function
    processItemFn: async (item, dialog) => {
        // Process the item
        return { success: true };
    },
    
    // Completion handler
    onAllComplete: function(successCount, failureCount, errors) {
        // Handle completion
    }
});
```

## AJAX Communication Standards

### AJAX Request Structure

1. Each AJAX request must include these parameters:
   - `action`: Always set to `'sip_handle_ajax_request'` (handled by `createFormData`)
   - `plugin`: The plugin identifier (e.g., `'sip-plugin-name'`) (handled by `createFormData`)
   - `action_type`: The type of action (e.g., `'functionality_action'`) (handled by `createFormData`)
   - `nonce`: The security nonce (handled by `createFormData`)
   - Additional parameters specific to the action

2. The POST array should also include the specific action identifier:
   - The key should be the action_type value
   - The value should be the specific operation name
   - Example: `$_POST['functionality_action'] = 'specific_operation'` (handled by `createFormData`)

### AJAX Response Structure

AJAX responses will have this structure:

```json
{
    "success": true,
    "plugin": "sip-plugin-name",
    "action_type": "functionality_action", 
    "action": "specific_operation",
    "message": "Success message",
    "data": {
        // Response data
    }
}
```

## User Interface Standards

### Element Naming Conventions

1. HTML IDs for containers:
   - `#functionality-container`: Main container for a functionality
   - `#functionality-table`: Table for functionality data
   - `#functionality-form`: Form for functionality operations

2. CSS Classes:
   - `.sip-element`: General SiP element
   - `.sip-dialog`: Dialog box
   - `.sip-toast`: Toast notification
   - `.sip-btn`: Button
   - `.sip-panel`: Panel

### DataTables Implementation

1. Initialize DataTables with SiP standard options:
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
    // Column definitions
});
```

2. Use standard column definitions:
```javascript
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
```

## Plugin Integration Checklist

Use this checklist to ensure your SiP plugin is properly integrated:

### PHP Integration

- [ ] Main plugin file includes sip-plugin-framework.php
- [ ] AJAX shell is included and properly configured
- [ ] All functionality-specific files are included
- [ ] AJAX response methods use SiP_AJAX_Response class
- [ ] Never use WordPress's wp_send_json functions
- [ ] All handlers follow the switch-case pattern for routing
- [ ] Error handling is consistent with appropriate error messages

### JavaScript Integration

- [ ] All modules follow the recommended module pattern
- [ ] All AJAX requests use SiP.Core.utilities.createFormData
- [ ] All AJAX requests use SiP.Core.ajax.handleAjaxAction
- [ ] Success handlers are registered for all action types
- [ ] Event handlers are properly attached and managed
- [ ] UI interactions use the standard SiP Core utilities
- [ ] Progress dialog is used for batch operations
- [ ] No direct use of jQuery.ajax or XMLHttpRequest
- [ ] Console.log statements use DEBUG_MODE flags or are removed in production

### UI Integration

- [ ] Standard CSS classes are used
- [ ] DataTables initialization follows the standard pattern
- [ ] Dialog boxes use the sip-dialog class
- [ ] Toast notifications use SiP.Core.utilities.toast.show
- [ ] Spinners are managed through SiP.Core.utilities.spinner

### General Standards

- [ ] File and directory structure matches the standard
- [ ] Naming conventions are consistent
- [ ] Code style is consistent (indentation, brackets, etc.)
- [ ] Comments are present for complex operations
- [ ] No unnecessary dependencies
- [ ] Proper error handling throughout

By adhering to these standards, you ensure that your SiP plugin integrates properly with the SiP Plugin Suite and provides a consistent experience across the entire ecosystem.