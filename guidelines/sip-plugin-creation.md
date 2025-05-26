# Creating a New SiP Plugin

Understand the [SiP Plugins Platform](./sip-plugins-platform.md) architecture before proceeding.

This guide walks you through creating a new SiP plugin from scratch, presenting standards and conventions in the context where you'll use them.

## Prerequisites

- SiP Plugins Core must be installed and activated
- WordPress development environment setup
- Understanding of PHP and JavaScript

## Step 1: Create Plugin Directory Structure

Create a new directory in your WordPress plugins folder following this structure:

```
wp-content/plugins/
└── sip-your-plugin-name/               # Plugin directory (must start with 'sip-')
    ├── sip-your-plugin-name.php        # Main plugin file (matches directory name)
    ├── includes/                       # PHP includes
    │   ├── {prefix}-ajax-shell.php     # AJAX handler shell (e.g., printify-ajax-shell.php)
    │   └── *-functions.php             # Functionality-specific files
    ├── assets/                         # Frontend assets
    │   ├── css/                        # Stylesheets  
    │   │   └── modules/                # Module-specific CSS (when needed)
    │   ├── js/                         # JavaScript files
    │   │   ├── core/                   # Core JS utilities (plugin-specific)
    │   │   │   └── utilities.js        # Plugin-specific utilities
    │   │   ├── main.js                 # Main initialization file
    │   │   └── modules/                # Feature-specific JS modules
    │   │       └── *-actions.js        # Action handler modules
    │   └── images/                     # Images and icons
    ├── views/                          # HTML templates (if needed)
    │   └── dashboard-html.php          # Dashboard view
    ├── work/                           # Development files and documentation
    └── vendor/                         # Third-party dependencies (if any)
```

### Directory Patterns from Existing Plugins

**SiP Printify Manager Example:**
```
sip-printify-manager/
├── includes/
│   ├── printify-ajax-shell.php         # Plugin-specific prefix
│   ├── image-functions.php
│   ├── product-functions.php
│   └── template-functions.php
├── assets/
│   ├── css/
│   │   └── modules/                    # Modular CSS organization
│   │       ├── base.css
│   │       ├── modals.css
│   │       └── tables.css
│   └── js/
│       ├── main.js
│       └── modules/
│           ├── image-actions.js
│           ├── product-actions.js
│           └── template-actions.js
└── views/
    └── dashboard-html.php
```

### Naming Convention Standards

#### PHP Files
- Main plugin file: `sip-plugin-name.php`
- AJAX handler shell: `{plugin-prefix}-ajax-shell.php` (e.g., `printify-ajax-shell.php`)
- Function files: `{functionality}-functions.php` (e.g., `shop-functions.php`, `image-functions.php`)
- Classes: `SiP_ClassName` (e.g., `SiP_Product_Manager`)
- Functions: `sip_function_name()` (e.g., `sip_handle_product_action()`)
- Constants: `SIP_CONSTANT_NAME` (e.g., `SIP_PLUGIN_VERSION`)

#### AJAX Shell Naming Pattern
Each plugin uses its own prefix for the AJAX shell:
- `printify-ajax-shell.php` for SiP Printify Manager
- `woocommerce-monitor-ajax-shell.php` for SiP WooCommerce Monitor
- `development-tools-ajax-shell.php` for SiP Development Tools

#### JavaScript Files
- Module files: `{functionality}-actions.js` (e.g., `image-actions.js`, `shop-actions.js`)
- Utility files: `utilities.js`
- Namespaces: `SiP.ModuleName` (e.g., `SiP.PrintifyManager`)
- Functions: `camelCase()` (e.g., `handleProductSubmit()`)
- Constants: `UPPER_CASE` (e.g., `MAX_FILE_SIZE`)

#### CSS Files
- Main stylesheet: `sip-plugin-name.css`
- Component styles: `{component}.css` (e.g., `modals.css`, `tables.css`)
- Classes: `sip-component-name` (e.g., `sip-modal-dialog`)
- IDs: `sip-specific-element` (e.g., `sip-product-table`)

## Step 2: Create Main Plugin File

Create `sip-your-plugin-name.php` with this structure:

```php
<?php
/*
Plugin Name: SiP Your Plugin Name
Description: Brief description of what your plugin does
Version: 1.0.0
Author: Stuff is Parts, LLC
Requires Plugins: sip-plugins-core
*/

if (!defined('ABSPATH')) exit; // Exit if accessed directly

// Error logging setup (optional but recommended)
ini_set('error_log', plugin_dir_path(__FILE__) . 'logs/php-errors.log');
ini_set('log_errors', 1);
ini_set('display_errors', 0);

// Check for minimum core version compatibility
$required_core_version = '2.8.9';
$core_plugin_data = get_plugin_data(WP_PLUGIN_DIR . '/sip-plugins-core/sip-plugins-core.php', false, false);
$current_core_version = $core_plugin_data['Version'] ?? '0.0.0';

if (version_compare($current_core_version, $required_core_version, '<')) {
    add_action('admin_notices', function() use ($required_core_version, $current_core_version) {
        echo '<div class="notice notice-error"><p><strong>SiP Your Plugin Name:</strong> Requires SiP Plugins Core version ' . $required_core_version . ' or higher. Current version: ' . $current_core_version . '. Please update SiP Plugins Core first.</p></div>';
    });
    return; // Stop plugin initialization
}

// Include SiP Plugin Framework
require_once WP_PLUGIN_DIR . '/sip-plugins-core/includes/plugin-framework.php';

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
        // The storage manager handles database table creation
        // and folder creation automatically when the plugin is registered
        
        // Add any plugin-specific initialization here
        // For example, setting default options:
        add_option('sip_your_plugin_settings', array(
            'feature1_enabled' => true,
            'feature2_enabled' => false
        ));
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

// Register storage configuration with the centralized storage manager
sip_plugin_storage()->register_plugin('sip-your-plugin-name', array(
    'database' => array(
        'tables' => array(
            'items' => array(
                'version' => '1.0.0',
                'create_sql' => "CREATE TABLE IF NOT EXISTS {table_name} (
                    id INT(11) NOT NULL AUTO_INCREMENT,
                    name VARCHAR(255) NOT NULL,
                    description TEXT,
                    status VARCHAR(50) DEFAULT 'active',
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    PRIMARY KEY (id),
                    KEY status (status)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;"
            )
        )
    ),
    'folders' => array(
        'data',
        'exports',
        'logs',
        'cache'
    )
));
```

### Plugin Header Standards
- Plugin Name: Must start with "SiP"
- Author: Should be "Stuff is Parts, LLC"
- Version: Start at 1.0.0 and follow semantic versioning

## Step 3: Configure Storage Management

Register your plugin's storage needs with the centralized storage manager. This should be done after initializing your plugin instance.

### Storage Registration Pattern

```php
// Register storage configuration with the centralized storage manager
sip_plugin_storage()->register_plugin('sip-your-plugin-name', array(
    'database' => array(
        'tables' => array(
            'table_name' => array(
                'version' => '1.0.0',
                'custom_table_name' => 'sip_custom_name', // Optional
                'drop_existing' => false, // Only true during development
                'create_sql' => "CREATE TABLE IF NOT EXISTS {table_name} ..."
            )
        )
    ),
    'folders' => array(
        'folder1',
        'folder2',
        'nested/folder'
    )
));
```

### Key Points:
- **Automatic Creation**: Folders and tables are created automatically during plugin activation
- **Version Management**: Database schema changes are tracked by version
- **Path Access**: Use `sip_plugin_storage()->get_folder_path()` to get folder paths
- **No Manual Creation**: Never use `wp_mkdir_p()` or manual `CREATE TABLE` queries

### Example Usage in Functions:

```php
// Get a folder path
$logs_dir = sip_plugin_storage()->get_folder_path('sip-your-plugin-name', 'logs');

// Get plugin URL
$plugin_url = sip_plugin_storage()->get_plugin_url('sip-your-plugin-name');

// Save a file
$export_dir = sip_plugin_storage()->get_folder_path('sip-your-plugin-name', 'exports');
file_put_contents($export_dir . '/data.json', json_encode($data));
```

## Step 4: Create AJAX Handler Shell

Create `includes/{plugin-prefix}-ajax-shell.php` to handle AJAX requests. For comprehensive AJAX implementation details, see the [AJAX Guide](./sip-plugin-ajax.md):

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
        case 'feature1_action':
            sip_handle_feature1_action();
            break;
            
        case 'feature2_action':
            sip_handle_feature2_action();
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

### AJAX Routing Standards
- Register handler with `sip_plugin_handle_action` hook (note: no plugin name in hook)
- Use switch statement for action routing
- Always include default case with error response
- Use `SiP_AJAX_Response` class for all responses
- Follow the error response signature: `error($plugin, $message, $action)`

### AJAX Routing Standards
- Register handler with `sip_{plugin}_handle_action` hook
- Use switch statement for action routing
- Always include default case with error response
- Use `SiP_AJAX_Response` class for all responses

## Step 5: Create Feature Functions

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

## Step 6: Create JavaScript Module

Create `assets/js/modules/feature1-actions.js`:

### Module Organization Principle

**Code should be associated with the interface where it's called.**

This principle guides how functionality is distributed across modules:

- **Product Table Actions**: If a "Create Template" button exists in the product table, the `createTemplate()` function belongs in `product-actions.js`, not `template-actions.js`
- **Template Table Actions**: Actions executed from the template table interface go in `template-actions.js`
- **Cross-Table Actions**: The Product Creation Table initialization is in `template-actions.js` because it's triggered from the template table's "Create New Products" action

Example:
```javascript
// In product-actions.js - because the action originates from product table
function createTemplateFromProduct(productId) {
    // Creates a template from selected product
}

// In template-actions.js - because the action originates from template table  
function createProductsFromTemplate(templateId) {
    // Initializes Product Creation Table with template
}

// In creation-table-actions.js - because these actions happen within that interface
function saveCreationTable() {
    // Saves creation table changes
}
```

### Component Architecture

SiP plugins are built on these core components provided by SiP Plugins Core:

- **Core Libraries**:
  - `ajax.js`: Standardized AJAX request/response handling
  - `utilities.js`: Common utility functions used across plugins
  - `state.js`: Client-side state management
  
- **UI Components**:
  - Standardized headers via `sip_render_standard_header()`
  - Common CSS/styling system
  - Progress dialog system for batch operations

- **Update System**:
  - Custom plugin updater connecting to Stuff is Parts server
  - Centralized version checking via `init_plugin_updater()`
  - Plugin self-registration pattern for update checks

### Standard Module Structure:

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

### Module Organization Best Practices (2025-01-21)
- **Consolidate Related Functionality**: Group all operations for a single interface (e.g., dashboard table) in one module
- **Avoid Cross-Module Dependencies**: Each module should be self-contained
- **Use Proper Data Passing**: Pass data via module initialization, not global variables
- **Example**: All plugin table operations (render, update, install, delete) belong in `plugin-dashboard.js`, not separate files

## Step 7: Create Main JavaScript File

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

## Step 8: Create Dashboard View

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

## Step 9: Add CSS Styling

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

## Step 10: Implement DataTables (if needed)

For server-side data tables. Follow the [DataTables Integration Guide](./sip-feature-datatables.md) for detailed configuration options:

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

## Step 11: Test Your Plugin

1. Check plugin activation
2. Verify menu appears under SiP Plugins
3. Test AJAX functionality
4. Check console for JavaScript errors
5. Verify responses follow standard format

## Step 12: Final Checklist

Before releasing your plugin, review these additional resources:
- For dashboard implementation, review the [Dashboards Guide](./sip-plugin-dashboards.md)

Use this checklist before considering your plugin complete:

### PHP Integration
- [ ] Main plugin file includes includes/plugin-framework.php
- [ ] AJAX shell is included and properly configured
- [ ] All functionality-specific files are included
- [ ] AJAX response methods use SiP_AJAX_Response class:
  - [ ] SiP_AJAX_Response::success() for successful responses
  - [ ] SiP_AJAX_Response::error() for error responses
  - [ ] SiP_AJAX_Response::datatable() for server-side DataTables (when using server-side pagination/filtering/sorting)
- [ ] Never use WordPress's wp_send_json functions
- [ ] All handlers follow the switch-case pattern for routing
- [ ] Plugin is registered with core via SiP_Plugin_Framework::init_plugin()
- [ ] The plugin implements a static render_dashboard() method
- [ ] Standard headers use sip_render_standard_header() function
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

### File Structure
- [ ] Directory structure matches the standard
- [ ] File and directory structure matches the standard
- [ ] Naming conventions are consistent
- [ ] Code style is consistent (indentation, brackets, etc.)
- [ ] Plugin name starts with 'sip-'
- [ ] AJAX shell follows plugin-specific naming pattern

### UI Standards
- [ ] Standard CSS classes are used (sip-panel, sip-btn, sip-dialog)
- [ ] DataTables initialization follows the standard pattern
- [ ] Dialog boxes use the sip-dialog class
- [ ] Toast notifications use SiP.Core.utilities.toast.show
- [ ] Spinners are managed through SiP.Core.utilities.spinner

### General Standards
- [ ] Comments are present for complex operations
- [ ] No unnecessary dependencies
- [ ] Proper error handling throughout
- [ ] Follows the module organization principle (code with interface)

## Common Pitfalls to Avoid

1. **Don't use WordPress's `wp_send_json()` functions** - Always use `SiP_AJAX_Response`
2. **Don't create custom AJAX endpoints** - Use the centralized handler
3. **Don't skip parameter validation** - Always validate and sanitize
4. **Don't forget to register your plugin** - Use `SiP_Plugin_Framework::init_plugin()`
5. **Don't use custom spinners** - Use `SiP.Core.utilities.spinner`

## Dependency Management Standards

### Plugin Headers

All SiP child plugins must include the `Requires Plugins` header:

```php
/*
Plugin Name: SiP Your Plugin Name
...
Requires Plugins: sip-plugins-core
*/
```

### Version Compatibility

Child plugins must check for minimum core version compatibility:

```php
// Check for minimum core version compatibility
$required_core_version = '2.8.9';
$core_plugin_data = get_plugin_data(WP_PLUGIN_DIR . '/sip-plugins-core/sip-plugins-core.php', false, false);
$current_core_version = $core_plugin_data['Version'] ?? '0.0.0';

if (version_compare($current_core_version, $required_core_version, '<')) {
    add_action('admin_notices', function() use ($required_core_version, $current_core_version) {
        echo '<div class="notice notice-error"><p><strong>Your Plugin Name:</strong> Requires SiP Plugins Core version ' . $required_core_version . ' or higher. Current version: ' . $current_core_version . '. Please update SiP Plugins Core first.</p></div>';
    });
    return; // Stop plugin initialization
}
```

### Automated Dependency Management

The SiP release system automatically:

1. **Detects current core version** during child plugin releases
2. **Updates `Requires Plugins` header** with version requirement (e.g., `sip-plugins-core (2.8.9+)`)
3. **Prevents version conflicts** by ensuring child plugins require the appropriate core version

### Release Workflow

**For Breaking Changes:**
1. Release core plugin with breaking changes first
2. Child plugin releases automatically require the new core version
3. Users must update core before child plugins will activate

**For Compatible Updates:**
- Core patches (2.8.9 → 2.8.10) don't require child plugin updates
- Existing version requirements remain valid

### WordPress Standards Compliance

This approach follows WordPress 6.5+ dependency management standards:

- Uses official `Requires Plugins` header
- Provides graceful failure with admin notices
- Prevents fatal errors through version checking
- Enforces proper update sequencing

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