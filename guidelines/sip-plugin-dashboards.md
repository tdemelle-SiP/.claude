# Implementing Dashboards

This guide explains how to create admin dashboards for SiP plugins. Dashboards are the main interface where users interact with your plugin's functionality. This guide builds on concepts from the [Plugin Creation](./sip-plugin-creation.md) and [AJAX Implementation](./sip-plugin-ajax.md) guides.

## Dashboard Structure Overview

SiP plugin dashboards follow a consistent pattern:

1. **Standard Header** - Uses `sip_render_standard_header()` with optional action buttons
2. **Main Content Area** - Contains tables, forms, and controls
3. **Data Tables** - For displaying plugin data with actions
4. **Action Forms** - Dropdown menus with execute buttons
5. **Modals/Dialogs** - For complex interactions

## Step 1: Create the Dashboard Method

In your main plugin class, implement the required `render_dashboard()` method:

```php
public static function render_dashboard() {
    // Use standard header from core plugin
    sip_render_standard_header(
        'Your Plugin Name',
        admin_url('admin.php?page=sip-plugins') // Optional back link
    );
    
    // Include your dashboard view
    include plugin_dir_path(__FILE__) . 'views/dashboard.php';
}
```

## Step 2: Create the Dashboard View

Create `views/dashboard.php` with the dashboard structure:

```php
<?php
// Prevent direct access
if (!defined('ABSPATH')) exit;

// Get necessary data
$settings = get_option('sip_your_plugin_settings', []);
$data = sip_get_your_plugin_data();
?>

<div class="wrap sip-dashboard-wrapper">
    
    <!-- Optional spinner overlay -->
    <div id="overlay">
        <img id="spinner" src="<?php echo esc_url(plugins_url('sip-plugins-core/assets/images/spinner.webp')); ?>" alt="Loading...">
    </div>
    
    <!-- Main dashboard content -->
    <div id="dashboard-container">
        
        <!-- Section with header and actions -->
        <div class="sip-section">
            <div class="section-header">
                <h2><?php esc_html_e('Section Title', 'your-text-domain'); ?></h2>
                
                <!-- Action form -->
                <form id="section-action-form" class="action-form">
                    <label for="section_action" class="screen-reader-text">
                        <?php esc_html_e('Actions', 'your-text-domain'); ?>
                    </label>
                    
                    <select name="section_action" id="section_action">
                        <option value="action1"><?php esc_html_e('Action 1', 'your-text-domain'); ?></option>
                        <option value="action2"><?php esc_html_e('Action 2', 'your-text-domain'); ?></option>
                        <option value="reload_data"><?php esc_html_e('Reload Data', 'your-text-domain'); ?></option>
                    </select>
                    
                    <input type="submit" value="<?php esc_attr_e('Execute', 'your-text-domain'); ?>" 
                           class="button button-secondary" />
                </form>
            </div>
            
            <!-- Data table container -->
            <div id="table-container" class="table-container">
                <table id="data-table" class="wp-list-table widefat fixed striped">
                    <thead>
                        <tr>
                            <th><?php esc_html_e('ID', 'your-text-domain'); ?></th>
                            <th><?php esc_html_e('Name', 'your-text-domain'); ?></th>
                            <th><?php esc_html_e('Status', 'your-text-domain'); ?></th>
                            <th><?php esc_html_e('Actions', 'your-text-domain'); ?></th>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Table content populated via JavaScript -->
                    </tbody>
                </table>
            </div>
        </div>
        
    </div>
    
    <!-- Toast container for notifications -->
    <div id="toast-container"></div>
    
</div>
```

## Step 3: Add Standard Header with Custom Actions

The standard header supports custom right-side content:

```php
// Add custom buttons to the header
$right_content = '<div id="button-container">
    <button id="help-button" class="button button-secondary" title="Get Help">
        <span class="dashicons dashicons-editor-help"></span> Help
    </button>
    <button id="settings-button" class="button button-primary">
        ' . esc_html__('Settings', 'your-text-domain') . '
    </button>
</div>';

sip_render_standard_header('Your Plugin Name', $right_content);
```

### Header Debug Toggle

For SiP Development Tools and other plugins that need debug functionality, the standard header includes a debug toggle. The `sip_render_standard_header()` function automatically includes this toggle which utilizes a dual-storage approach:

1. **WordPress Option**: Server-side state stored as `sip_debug_enabled`
2. **localStorage**: Client-side state under `sip-core['sip-development-tools']['console-logging']`

The toggle is handled by `header-debug-toggle.js` which ensures both storage mechanisms stay in sync. When implementing a plugin that uses debug logging:

1. Make sure to include core scripts with debug toggle support:

```php
// In your enqueue_admin_scripts method
public function enqueue_admin_scripts() {
    // Core debug module must be loaded first
    wp_enqueue_script('sip-core-debug');
    wp_enqueue_script('sip-core-state');
    // Only add debug toggle on SiP plugin pages
    if ($is_sip_page) {
        wp_enqueue_script('sip-core-header-debug-toggle');
    }
    
    // Localize debug settings
    wp_localize_script('sip-core-debug', 'sipCoreSettings', array(
        'debugEnabled' => get_option('sip_debug_enabled', 'false')
    ));
}
```

2. Use the standard debug utility in your JavaScript modules:

```javascript
// In your module
const debug = SiP.Core.debug;
debug.log('Module initialized');
```

For more details on using the debug system, see the [Debug Logging Guide](./sip-development-debug-logging.md).

The debug toggle provides a UI to turn on/off debug logs, prompts the user to reload the page when changed, and ensures settings persist across all browsers. The toggle correctly syncs state between client and server storage systems as outlined in the [Data Storage Guide](./sip-plugin-data-storage.md#client-server-synchronized-state).

## Step 4: Implement Action Forms

Action forms follow a consistent pattern with dropdowns and execute buttons:

```javascript
// Handle action form submission
$('#section-action-form').on('submit', function(e) {
    e.preventDefault();
    
    const action = $('#section_action').val();
    const formData = SiP.Core.utilities.createFormData(
        'sip-your-plugin',
        'section_action',
        action
    );
    
    // Show spinner
    const spinnerId = SiP.Core.utilities.spinner.show('#execute-button');
    
    // Execute action
    SiP.Core.ajax.handleAjaxAction(
        'sip-your-plugin',
        'section_action',
        formData
    )
    .then(function(response) {
        // Handle success
        SiP.Core.utilities.toast.show('Action completed successfully', 3000);
        
        // Reload table if needed
        if (action === 'reload_data') {
            $('#data-table').DataTable().ajax.reload();
        }
    })
    .catch(function(error) {
        SiP.Core.utilities.toast.show('Error: ' + error.message, 5000);
    })
    .finally(function() {
        SiP.Core.utilities.spinner.hide(spinnerId);
    });
});
```

## Step 5: Initialize DataTables

For data tables, use DataTables with server-side processing. For more DataTables patterns and options, refer to the [DataTables Integration Guide](./sip-feature-datatables.md):

```javascript
$(document).ready(function() {
    $('#data-table').DataTable({
        processing: true,
        serverSide: true,
        ajax: {
            url: sipCoreAjax.ajaxUrl,
            type: 'POST',
            data: function(data) {
                data.action = 'sip_handle_ajax_request';
                data.plugin = 'sip-your-plugin';
                data.action_type = 'get_table_data';
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
            { 
                data: 'status',
                render: function(data) {
                    return '<span class="status-' + data + '">' + data + '</span>';
                }
            },
            { 
                data: null,
                orderable: false,
                render: function(data, type, row) {
                    return '<button class="button edit-btn" data-id="' + row.id + '">Edit</button>' +
                           '<button class="button delete-btn" data-id="' + row.id + '">Delete</button>';
                }
            }
        ]
    });
});
```

## Step 6: Add Modal Dialogs

For user interactions, implement modal dialogs. For standardized modal patterns, see the [Modals Guide](./sip-feature-modals.md):

```javascript
// Create a dialog
function showEditDialog(itemId) {
    const dialog = $('<div></div>')
        .attr('title', 'Edit Item')
        .appendTo('body');
    
    // Load content via AJAX
    const formData = SiP.Core.utilities.createFormData(
        'sip-your-plugin',
        'get_edit_form',
        'get'
    );
    formData.append('item_id', itemId);
    
    SiP.Core.ajax.handleAjaxAction(
        'sip-your-plugin',
        'get_edit_form',
        formData
    )
    .then(function(response) {
        dialog.html(response.data.html);
        
        dialog.dialog({
            modal: true,
            width: 500,
            buttons: {
                'Save': function() {
                    saveChanges(itemId);
                    $(this).dialog('close');
                },
                'Cancel': function() {
                    $(this).dialog('close');
                }
            },
            close: function() {
                $(this).remove();
            }
        });
    });
}
```

## Dashboard CSS Structure

Use consistent CSS classes for styling:

```css
/* Dashboard wrapper */
.sip-dashboard-wrapper {
    width: 100%;
    max-width: 1200px;
    margin: 20px 0;
}

/* Section styling */
.sip-section {
    background: #fff;
    border: 1px solid #ccd0d4;
    box-shadow: 0 1px 1px rgba(0,0,0,.04);
    margin-bottom: 20px;
    padding: 20px;
}

/* Section header with actions */
.section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}

.section-header h2 {
    margin: 0;
}

/* Action forms */
.action-form {
    display: flex;
    gap: 10px;
    align-items: center;
}

/* Table containers */
.table-container {
    overflow-x: auto;
}

/* Spinner overlay */
#overlay {
    display: none;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.5);
    z-index: 9999;
}

#overlay img {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
}
```

## Common Dashboard Patterns

### Debug Logging in Dashboards

**Best Practice**: Don't use inline JavaScript. Instead, use `wp_localize_script()` to pass data from PHP to JavaScript. See the [Debug Logging Guide](./sip-development-debug-logging.md#early-page-logging) for details.

**Example Implementation**:

In your plugin's PHP file:
```php
// In enqueue_admin_scripts method
wp_localize_script('sip-main', 'sipDashboardData', array(
    'hasApiKey' => !empty($settings['api_key']),
    'apiKeyPreview' => !empty($settings['api_key']) ? substr($settings['api_key'], 0, 4) . '...' : '',
    'shopData' => $shop_data
));
```

In your JavaScript file:
```javascript
// Early initialization in main.js
(function() {
    if (window.sipDashboardData) {
        const debug = SiP.Core.debug;
        const data = sipDashboardData;
        
        debug.log('▶ Dashboard initializing...');
        
        if (data.hasApiKey) {
            debug.log('🔑 API Key found: ' + data.apiKeyPreview);
        } else {
            debug.log('⚠️ No API key configured - showing setup form');
        }
        
        // Set up window variables if needed
        window.shopData = data.shopData;
    }
})();
```

This approach keeps all JavaScript in `.js` files and maintains clean separation between PHP and JavaScript.

### Initial Data Loading

There are two primary patterns for loading dashboard data:

#### Pattern 1: Server-Side Data Loading (Recommended)

Use `wp_localize_script()` to pass data from PHP to JavaScript. This is more efficient and reliable:

**PHP Side:**
```php
// In your enqueue_admin_scripts method
public function enqueue_admin_scripts() {
    // Get the data once in PHP
    $dashboard_data = $this->get_dashboard_data();
    
    // Pass to JavaScript
    wp_localize_script('your-plugin-script', 'yourPluginData', [
        'dashboardData' => $dashboard_data,
        'settings' => get_option('your_plugin_settings', [])
    ]);
}
```

**JavaScript Side:**
```javascript
// Module-scope variables to store the data
let dashboardData = {};
let pluginSettings = {};

function init(serverData, serverSettings) {
    // Store server data in module scope
    dashboardData = serverData || {};
    pluginSettings = serverSettings || {};
    
    $(document).ready(function() {
        // Use the data immediately - no AJAX call needed
        renderDashboard();
        attachEventHandlers();
    });
}

// Initialize with localized data
if (typeof yourPluginData !== 'undefined') {
    init(yourPluginData.dashboardData, yourPluginData.settings);
}
```

#### Pattern 2: Client-Side AJAX Loading

Use this when data must be fetched dynamically or is too large for localization:

```javascript
jQuery(document).ready(function($) {
    const debug = SiP.Core.debug;
    debug.log('🚀 Dashboard ready, loading initial data...');
    
    // Load initial data
    loadDashboardData();
    
    function loadDashboardData() {
        const formData = SiP.Core.utilities.createFormData(
            'sip-your-plugin',
            'load_dashboard',
            'get_all'
        );
        
        debug.log('📤 Loading dashboard data...');
        
        SiP.Core.ajax.handleAjaxAction(
            'sip-your-plugin',
            'load_dashboard',
            formData
        )
        .then(function(response) {
            debug.log('✅ Dashboard data loaded:', response.data);
            // Update UI with data
            updateDashboard(response.data);
        })
        .catch(function(error) {
            debug.error('❌ Failed to load dashboard data:', error);
            SiP.Core.utilities.toast.show('Failed to load dashboard data', 5000);
        });
    }
});
```

### Dashboard Refresh Strategies

After performing operations (install, activate, etc.), you need to refresh the dashboard. There are two approaches:

#### Page Reload (Recommended)

**Advantages:**
- Simple and reliable
- Handles all edge cases automatically  
- Guarantees fresh data from WordPress core
- No additional AJAX endpoints needed

**Usage:**
```javascript
// After successful operation
setTimeout(function() {
    window.location.reload();
}, 1000); // Brief delay for user feedback
```

#### AJAX Refresh (Advanced)

**Advantages:**
- Better user experience (no page flash)
- Preserves scroll position and form state
- Faster perceived performance

**Requirements:**
- Must create additional endpoint to fetch updated data
- Must handle all edge cases manually
- More complex error handling

**Implementation:**
```javascript
// Only use if you have a dedicated refresh endpoint
function refreshDashboard() {
    const formData = SiP.Core.utilities.createFormData(
        'your-plugin',
        'dashboard_management',
        'get_updated_data'
    );
    
    SiP.Core.ajax.handleAjaxAction('your-plugin', 'dashboard_management', formData)
        .then(response => {
            // Update module-scope data
            dashboardData = response.data.dashboardData;
            
            // Re-render affected components
            renderDashboard();
        })
        .catch(error => {
            // Fall back to page reload if AJAX fails
            window.location.reload();
        });
}
```

**Guideline:** Use page reload unless you have a specific need for AJAX refresh and are willing to implement the additional endpoint.

### Dual-Purpose Functions

Some functions serve both initial loading and post-operation refresh:

```javascript
// Example: Plugin dashboard table loading
function loadPluginsTable() {
    // Shows loading indicator
    $('#plugins-loading').show();
    $('#plugins-table').hide();
    
    // Fetches current data from server
    const formData = SiP.Core.utilities.createFormData(
        'sip-plugins-core',
        'plugin_management', 
        'get_available_plugins'
    );
    
    SiP.Core.ajax.handleAjaxAction('sip-plugins-core', 'plugin_management', formData)
        .then(response => {
            if (response.success && response.data.plugins) {
                renderPluginsTable(response.data.plugins);
            } else {
                // Fallback to locally available data
                renderInstalledPluginsOnly();
            }
        })
        .catch(error => {
            // Graceful fallback 
            renderInstalledPluginsOnly();
        });
}

// Called during initial load
function init(installedPlugins, activePlugins) {
    // Store server data in module scope
    moduleInstalledPlugins = installedPlugins;
    moduleActivePlugins = activePlugins;
    
    $(document).ready(function() {
        loadPluginsTable(); // Initial load
        attachEventHandlers();
    });
}

// Could also be called for refresh (but page reload is simpler)
function refresh() {
    loadPluginsTable(); // Same function, fresh data
}
```

**Important:** These functions must handle both scenarios gracefully and include proper fallback mechanisms.

### Fallback Mechanisms

Always provide fallbacks when external data sources might fail:

```javascript
function loadDashboardData() {
    // Try to load from server
    SiP.Core.ajax.handleAjaxAction('plugin', 'action', formData)
        .then(response => {
            if (response.success && response.data) {
                renderWithServerData(response.data);
            } else {
                renderWithLocalData(); // Fallback
            }
        })
        .catch(error => {
            renderWithLocalData(); // Fallback
            showErrorNotice(); // Inform user
        });
}

function renderWithLocalData() {
    // Use whatever data is available locally
    if (moduleLocalData && Object.keys(moduleLocalData).length > 0) {
        renderDashboard(moduleLocalData);
        showWarningNotice('Showing cached data - server unavailable');
    } else {
        showEmptyState('No data available');
    }
}
```

### Progressive Disclosure

Show/hide sections based on conditions:

```javascript
// Show different sections based on plugin state
if (pluginSettings.isConfigured) {
    $('#main-dashboard').show();
    $('#setup-section').hide();
} else {
    $('#main-dashboard').hide();
    $('#setup-section').show();
}
```

### Bulk Actions

For operations on multiple items. Use [Progress Dialog](./sip-feature-progress-dialog.md) for complex batch operations:

```javascript
$('#bulk-action-form').on('submit', function(e) {
    e.preventDefault();
    
    const selectedIds = [];
    $('.item-checkbox:checked').each(function() {
        selectedIds.push($(this).val());
    });
    
    if (selectedIds.length === 0) {
        SiP.Core.utilities.toast.show('Please select items first', 3000);
        return;
    }
    
    // Process bulk action
    const dialog = SiP.Core.progressDialog.create({
        title: 'Processing Bulk Action',
        totalItems: selectedIds.length,
        waitForUserOnComplete: true
    });
    
    dialog.start();
    
    // Process items...
});
```

## Dashboard Checklist

Use this checklist when implementing dashboards:

### PHP Side
- [ ] Created `render_dashboard()` method in main class
- [ ] Used `sip_render_standard_header()` for consistent header
- [ ] Created dashboard view file in `views/` directory
- [ ] Implemented AJAX handlers for dashboard actions
- [ ] Added proper escaping for all output
- [ ] Added WordPress options for configuration settings
- [ ] Localized debug settings with `wp_localize_script()`

### JavaScript Side
- [ ] Initialized DataTables for data display
- [ ] Implemented action form handlers
- [ ] Added error handling for all AJAX calls
- [ ] Used standard spinner and toast utilities
- [ ] Registered success handlers for AJAX responses
- [ ] Utilized SiP.Core.debug utilities for consistent logging
- [ ] Ensured debug toggle works with WordPress options
- [ ] Confirmed all AJAX endpoints exist in backend code
- [ ] Implemented fallback mechanisms for external data sources
- [ ] Used module-scope variables for data that persists across functions
- [ ] Chose appropriate refresh strategy (page reload vs AJAX)

### UI/UX
- [ ] Consistent section structure with headers
- [ ] Action dropdowns with execute buttons
- [ ] Loading indicators for all async operations
- [ ] Toast notifications for user feedback
- [ ] Responsive layout that works on all screen sizes

## Best Practices

1. **Use Standard Components** - Always use SiP Core utilities
2. **Consistent Layout** - Follow the established dashboard patterns
3. **Progressive Loading** - Load data asynchronously
4. **Error Handling** - Always handle errors gracefully
5. **User Feedback** - Provide clear feedback for all actions
6. **Accessibility** - Include proper labels and ARIA attributes
7. **Data Synchronization** - For settings that affect both client and server, ensure proper sync between localStorage and WordPress options
8. **Dual-Purpose Functions** - Functions that handle both initial load and refresh must include proper fallback mechanisms
9. **Refresh Strategy** - Choose page reload for simplicity or AJAX refresh only when you can implement the required endpoints

## Common Pitfalls

1. **Don't forget escaping** - Always escape output
2. **Don't skip loading indicators** - Users need feedback
3. **Don't use custom spinners** - Use Core utilities
4. **Don't forget nonce verification** - Security is crucial
5. **Don't hardcode strings** - Use proper text domains
6. **Don't rely on one storage type only** - For system-wide settings like debug mode, use both client and server storage
7. **Don't embed JavaScript in PHP files** - Always maintain proper separation of concerns
8. **Don't remove dual-purpose functions without understanding their role** - Functions may serve both initial loading and refresh purposes
9. **Don't implement AJAX refresh without fallbacks** - Always have page reload as a backup strategy

## Separation of Concerns

One of the fundamental architectural principles in SiP plugins is maintaining clear separation between PHP and JavaScript:

### PHP Responsibilities
- Rendering basic HTML structure
- Processing data for display
- Passing data to JavaScript via wp_localize_script()
- Handling server-side AJAX operations

### JavaScript Responsibilities
- User interaction handling
- Dynamic UI updates
- Client-side validation
- Data manipulation and display
- Debug logging

### Proper PHP/JavaScript Data Exchange

**DO** ✅
```php
// PHP file
<?php
// Get plugin data
$plugin_data = get_plugins();
$active_plugins = get_option('active_plugins');

// Pass data to JavaScript properly
wp_localize_script('sip-plugin-script', 'sipPluginData', array(
    'plugins' => $plugin_data,
    'activePlugins' => $active_plugins
));
?>

<!-- HTML structure only in PHP view -->
<div id="plugins-table-container">
    <!-- JavaScript will populate this container -->
</div>
```

```javascript
// JavaScript file
const debug = SiP.Core.debug;

// Access localized data
debug.log('Plugins data:', sipPluginData.plugins);
debug.log('Active plugins:', sipPluginData.activePlugins);

// Populate table dynamically
function renderPluginsTable() {
    const plugins = sipPluginData.plugins;
    const activePlugins = sipPluginData.activePlugins;
    
    // Render table logic...
}
```

**DON'T** ❌
```php
<!-- Avoid this pattern -->
<script>
    // Direct JavaScript in PHP file
    console.log('Plugins:', <?php echo json_encode($plugins); ?>);
    
    // Embedding logic in PHP-generated JavaScript
    <?php foreach ($plugins as $file => $data) : ?>
        console.log('Plugin: <?php echo esc_js($file); ?>');
    <?php endforeach; ?>
</script>
```

### Advantages of Proper Separation

1. **Maintainability** - Easier to update either PHP or JavaScript independently
2. **Caching** - JavaScript files can be cached separately
3. **Error Handling** - Clearer debugging and error tracking
4. **Feature Toggling** - Easier to implement features like debug toggling
5. **Code Reuse** - Functions can be shared across different views
6. **Testing** - Simpler to write unit tests for separated code

## Next Steps

- [Data Storage and Handling](./sip-plugin-data-storage.md) - For understanding storage patterns
- [Debug Logging System](./sip-development-debug-logging.md) - For implementing debug logging
- [AJAX Implementation](./sip-plugin-ajax.md) - For dashboard interactions