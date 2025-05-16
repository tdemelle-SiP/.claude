# Creating a New SiP Plugin

This guide walks you through creating a new SiP plugin from scratch, presenting standards and conventions in the context where you'll use them.

## Prerequisites

- SiP Plugins Core must be installed and activated
- WordPress development environment setup
- Understanding of PHP and JavaScript

## Step 1: Create Plugin Directory Structure

Create a new directory in your WordPress plugins folder following this structure:

```
wp-content/plugins/
└── sip-your-plugin-name/            # Plugin directory (must start with 'sip-')
    ├── sip-your-plugin-name.php     # Main plugin file (matches directory name)
    ├── includes/                    # PHP includes
    │   ├── plugin-ajax-shell.php    # AJAX handler shell (required)
    │   └── *-functions.php          # Functionality-specific files
    ├── assets/                      # Frontend assets
    │   ├── css/                     # Stylesheets
    │   ├── js/                      # JavaScript files
    │   │   ├── core/                # Core JS utilities
    │   │   └── modules/             # Feature-specific JS modules
    │   └── images/                  # Images and icons
    └── views/                       # HTML templates (if needed)
```

### Naming Convention Standards
- Plugin directory and main file MUST start with `sip-`
- Use lowercase with hyphens for file names: `sip-plugin-name.php`
- Functionality files: `{feature}-functions.php` (e.g., `shop-functions.php`)
- JavaScript modules: `{feature}-actions.js` (e.g., `product-actions.js`)

## Step 2: Create Main Plugin File

Create `sip-your-plugin-name.php` with this structure:

```php
<?php
/*
Plugin Name: SiP Your Plugin Name
Description: Brief description of what your plugin does
Version: 1.0.0
Author: Stuff is Parts, LLC
*/

if (!defined('ABSPATH')) exit; // Exit if accessed directly

// Error logging setup (optional but recommended)
ini_set('error_log', plugin_dir_path(__FILE__) . 'logs/php-errors.log');
ini_set('log_errors', 1);
ini_set('display_errors', 0);

// Include SiP Plugin Framework
require_once WP_PLUGIN_DIR . '/sip-plugins-core/sip-plugin-framework.php';

// Include AJAX shell
require_once plugin_dir_path(__FILE__) . 'includes/plugin-ajax-shell.php';

// Include functionality files
$includes = [
    'feature1-functions.php',
    'feature2-functions.php',
    // Add more as needed
];

foreach ($includes as $file) {
    require_once plugin_dir_path(__FILE__) . 'includes/' . $file;
}

// Main plugin class
class SiP_Your_Plugin_Name {
    private static $instance = null;
    
    // Plugin initialization
    private function __construct() {
        // Register with SiP framework
        add_action('plugins_loaded', array($this, 'init'));
        
        // Hook for admin scripts and styles
        add_action('admin_enqueue_scripts', array($this, 'enqueue_admin_assets'));
        
        // Hook for activation
        register_activation_hook(__FILE__, array($this, 'activate'));
    }
    
    // Singleton pattern
    public static function get_instance() {
        if (null === self::$instance) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    // Initialize plugin with SiP framework
    public function init() {
        if (class_exists('SiP_Plugin_Framework')) {
            SiP_Plugin_Framework::init_plugin(
                'Your Plugin Name',
                __FILE__,
                'SiP_Your_Plugin_Name'
            );
        }
    }
    
    // Enqueue admin assets
    public function enqueue_admin_assets($hook) {
        // Only load on our plugin pages
        if (strpos($hook, 'sip-your-plugin-name') === false) {
            return;
        }
        
        // CSS
        wp_enqueue_style(
            'sip-your-plugin-css',
            plugin_dir_url(__FILE__) . 'assets/css/admin.css',
            array(),
            '1.0.0'
        );
        
        // JavaScript
        wp_enqueue_script(
            'sip-your-plugin-js',
            plugin_dir_url(__FILE__) . 'assets/js/main.js',
            array('jquery', 'sip-core-js'),
            '1.0.0',
            true
        );
        
        // Localize script with AJAX data
        wp_localize_script('sip-your-plugin-js', 'sipYourPluginAjax', array(
            'ajaxUrl' => admin_url('admin-ajax.php'),
            'nonce' => wp_create_nonce('sip-ajax-nonce'),
            'plugin' => 'sip-your-plugin-name'
        ));
    }
    
    // Plugin activation
    public function activate() {
        // Create any necessary database tables or options
        // Set up initial plugin data
    }
    
    // Required method for SiP framework
    public static function render_dashboard() {
        // Render your plugin's main admin page
        sip_render_standard_header(
            'Your Plugin Name',
            admin_url('admin.php?page=sip-plugins')
        );
        
        include plugin_dir_path(__FILE__) . 'views/dashboard.php';
    }
}

// Initialize the plugin
SiP_Your_Plugin_Name::get_instance();
```

### Plugin Header Standards
- Plugin Name: Must start with "SiP"
- Author: Should be "Stuff is Parts, LLC"
- Version: Start at 1.0.0 and follow semantic versioning

## Step 3: Create AJAX Handler Shell

Create `includes/plugin-ajax-shell.php`:

```php
<?php
if (!defined('ABSPATH')) exit;

// Register with central SiP AJAX handler
function sip_your_plugin_register_ajax_handler() {
    add_action('sip_your_plugin_handle_action', 'sip_your_plugin_route_action');
}
add_action('init', 'sip_your_plugin_register_ajax_handler');

// Route actions to specific handlers
function sip_your_plugin_route_action($action_type) {
    switch ($action_type) {
        case 'feature1_action':
            sip_handle_feature1_action();
            break;
            
        case 'feature2_action':
            sip_handle_feature2_action();
            break;
            
        default:
            SiP_AJAX_Response::error(
                'sip-your-plugin-name',
                'unknown',
                'unknown',
                'Invalid action type: ' . $action_type
            );
            break;
    }
}
```

### AJAX Routing Standards
- Register handler with `sip_{plugin}_handle_action` hook
- Use switch statement for action routing
- Always include default case with error response
- Use `SiP_AJAX_Response` class for all responses

## Step 4: Create Feature Functions

Create `includes/feature1-functions.php`:

```php
<?php
if (!defined('ABSPATH')) exit;

// Handle feature1 actions
function sip_handle_feature1_action() {
    $specific_action = isset($_POST['feature1_action']) 
        ? sanitize_text_field($_POST['feature1_action']) 
        : '';
    
    switch ($specific_action) {
        case 'create_item':
            sip_create_item();
            break;
            
        case 'update_item':
            sip_update_item();
            break;
            
        case 'delete_item':
            sip_delete_item();
            break;
            
        default:
            SiP_AJAX_Response::error(
                'sip-your-plugin-name',
                'feature1_action',
                'unknown',
                'Unknown action: ' . $specific_action
            );
            break;
    }
}

// Create item function
function sip_create_item() {
    // Validate required parameters
    if (!isset($_POST['item_name'])) {
        SiP_AJAX_Response::error(
            'sip-your-plugin-name',
            'feature1_action',
            'create_item',
            'Missing required parameter: item_name'
        );
        return;
    }
    
    $item_name = sanitize_text_field($_POST['item_name']);
    
    // Perform the operation
    // ... your business logic here ...
    
    // Return success response
    SiP_AJAX_Response::success(
        'sip-your-plugin-name',
        'feature1_action',
        'create_item',
        ['item_id' => $new_item_id],
        'Item created successfully'
    );
}

// Update item function
function sip_update_item() {
    // Similar pattern: validate, process, respond
}

// Delete item function  
function sip_delete_item() {
    // Similar pattern: validate, process, respond
}
```

### Function Standards
- Function names: `sip_handle_{feature}_action()`
- Operation functions: `sip_{operation}_{item}()`
- Always sanitize input data
- Always validate required parameters
- Always use `SiP_AJAX_Response` for responses

## Step 5: Create JavaScript Module

Create `assets/js/modules/feature1-actions.js`:

```javascript
var SiP = SiP || {};
window.SiP = window.SiP || {};
SiP.YourPlugin = SiP.YourPlugin || {};

console.log('▶ feature1-actions.js Loading...');

SiP.YourPlugin.feature1Actions = (function($, ajax, utilities) {
    
    // Initialize module
    function init() {
        console.log('         🟡 feature1-actions.js:init()');
        attachEventListeners();
    }
    
    // Attach event listeners
    function attachEventListeners() {
        $(document).on('click', '.create-item-btn', handleCreateItem);
        $(document).on('click', '.update-item-btn', handleUpdateItem);
        $(document).on('click', '.delete-item-btn', handleDeleteItem);
    }
    
    // Handle create item
    function handleCreateItem(e) {
        e.preventDefault();
        
        // Create form data
        const formData = utilities.createFormData(
            'sip-your-plugin-name',
            'feature1_action',
            'create_item'
        );
        
        // Add item data
        formData.append('item_name', $('#item-name').val());
        
        // Send request
        return ajax.handleAjaxAction(
            'sip-your-plugin-name',
            'feature1_action',
            formData
        )
        .then(function(response) {
            utilities.toast.show('Item created successfully', 3000);
            // Update UI as needed
            return response;
        })
        .catch(function(error) {
            utilities.toast.show('Error: ' + error.message, 5000);
            throw error;
        });
    }
    
    // Handle update item
    function handleUpdateItem(e) {
        // Similar pattern
    }
    
    // Handle delete item
    function handleDeleteItem(e) {
        // Similar pattern
    }
    
    // Handle successful responses
    function handleSuccessResponse(response) {
        if (!response.success) {
            return response;
        }
        
        switch(response.action) {
            case 'create_item':
                // Handle create response
                $('#items-table').DataTable().ajax.reload();
                break;
                
            case 'update_item':
                // Handle update response
                break;
                
            case 'delete_item':
                // Handle delete response
                break;
                
            default:
                console.warn('Unhandled action:', response.action);
        }
        
        return response;
    }
    
    // Public API
    return {
        init: init,
        handleSuccessResponse: handleSuccessResponse
    };
    
})(jQuery, SiP.Core.ajax, SiP.Core.utilities);

// Register success handler
SiP.Core.ajax.registerSuccessHandler(
    'sip-your-plugin-name',
    'feature1_action',
    SiP.YourPlugin.feature1Actions.handleSuccessResponse
);
```

### JavaScript Standards
- Namespace: `SiP.YourPlugin.moduleName`
- Module pattern with IIFE
- Always use `SiP.Core.utilities.createFormData()`
- Always use `SiP.Core.ajax.handleAjaxAction()`
- Register success handler for each action type

## Step 6: Create Main JavaScript File

Create `assets/js/main.js`:

```javascript
var SiP = SiP || {};
window.SiP = window.SiP || {};
SiP.YourPlugin = SiP.YourPlugin || {};

jQuery(document).ready(function($) {
    console.log('▶ SiP Your Plugin Main JS Loading...');
    
    // Initialize all modules
    if (SiP.YourPlugin.feature1Actions) {
        SiP.YourPlugin.feature1Actions.init();
    }
    
    if (SiP.YourPlugin.feature2Actions) {
        SiP.YourPlugin.feature2Actions.init();
    }
    
    // Add more module initializations as needed
    
    console.log('✅ SiP Your Plugin Main JS Loaded');
});
```

## Step 7: Create Dashboard View

Create `views/dashboard.php`:

```php
<?php if (!defined('ABSPATH')) exit; ?>

<div class="wrap sip-your-plugin-dashboard">
    <!-- Your plugin interface here -->
    <div class="sip-panel">
        <h2>Feature 1</h2>
        <button class="button create-item-btn">Create New Item</button>
        
        <table id="items-table" class="wp-list-table widefat fixed striped">
            <!-- Table content -->
        </table>
    </div>
</div>
```

## Step 8: Add CSS Styling

Create `assets/css/admin.css`:

```css
/* Use SiP standard classes */
.sip-your-plugin-dashboard {
    /* Dashboard styles */
}

.sip-panel {
    background: #fff;
    border: 1px solid #ccd0d4;
    box-shadow: 0 1px 1px rgba(0,0,0,.04);
    margin: 20px 0;
    padding: 20px;
}

/* Follow SiP naming conventions */
.sip-btn {
    /* Button styles */
}

.sip-dialog {
    /* Dialog styles */
}
```

## Step 9: Implement DataTables (if needed)

For server-side data tables, add to your JavaScript:

```javascript
$('#items-table').DataTable({
    processing: true,
    serverSide: true,
    ajax: {
        url: sipCoreAjax.ajaxUrl,
        type: 'POST',
        data: function(data) {
            data.action = 'sip_handle_ajax_request';
            data.plugin = 'sip-your-plugin-name';
            data.action_type = 'feature1_action';
            data.feature1_action = 'get_items';
            data.nonce = sipCoreAjax.nonce;
            return data;
        },
        dataSrc: function(response) {
            return response.data.items;
        }
    },
    columns: [
        { data: 'id', title: 'ID' },
        { data: 'name', title: 'Name' },
        // Add more columns
    ]
});
```

And in PHP:

```php
function sip_get_items() {
    // Get DataTables parameters
    $draw = isset($_POST['draw']) ? intval($_POST['draw']) : 1;
    $start = isset($_POST['start']) ? intval($_POST['start']) : 0;
    $length = isset($_POST['length']) ? intval($_POST['length']) : 10;
    
    // Get your data
    $items = []; // Fetch from database
    $total = 100; // Total records
    $filtered = 100; // Filtered records
    
    // Return DataTables response
    SiP_AJAX_Response::datatable(
        'sip-your-plugin-name',
        'feature1_action',
        'get_items',
        $items,
        $total,
        $filtered,
        'Items retrieved successfully'
    );
}
```

## Step 10: Test Your Plugin

1. Check plugin activation
2. Verify menu appears under SiP Plugins
3. Test AJAX functionality
4. Check console for JavaScript errors
5. Verify responses follow standard format

## Step 11: Final Checklist

Use this checklist before considering your plugin complete:

### PHP Integration
- [ ] Main plugin file includes sip-plugin-framework.php
- [ ] AJAX shell is properly configured
- [ ] All responses use SiP_AJAX_Response class
- [ ] Plugin registers with SiP_Plugin_Framework::init_plugin()
- [ ] Implements static render_dashboard() method
- [ ] Uses sip_render_standard_header() for headers

### JavaScript Integration
- [ ] All AJAX requests use SiP.Core.utilities.createFormData()
- [ ] All AJAX requests use SiP.Core.ajax.handleAjaxAction()
- [ ] Success handlers registered for all action types
- [ ] Follows module pattern structure
- [ ] Uses SiP.Core.utilities for UI feedback

### File Structure
- [ ] Directory structure matches standard
- [ ] File naming conventions followed
- [ ] Plugin name starts with 'sip-'

### UI Standards
- [ ] Uses standard CSS classes (sip-panel, sip-btn, etc.)
- [ ] DataTables follow standard implementation
- [ ] Spinners managed through SiP.Core.utilities.spinner

## Common Pitfalls to Avoid

1. **Don't use WordPress's `wp_send_json()` functions** - Always use `SiP_AJAX_Response`
2. **Don't create custom AJAX endpoints** - Use the centralized handler
3. **Don't skip parameter validation** - Always validate and sanitize
4. **Don't forget to register your plugin** - Use `SiP_Plugin_Framework::init_plugin()`
5. **Don't use custom spinners** - Use `SiP.Core.utilities.spinner`

## Next Steps

After creating your basic plugin structure:

1. Add more features following the same patterns
2. Implement settings pages if needed
3. Add update mechanism support
4. Create documentation for your specific functionality

## Need Help?

- Review existing SiP plugins for examples
- Check the SiP Code Standards documentation
- Follow the established patterns consistently