# Implementing Dashboards

This guide explains how to create admin dashboards for SiP plugins. Dashboards are the main interface where users interact with your plugin's functionality.

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

For data tables, use DataTables with server-side processing:

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

For complex interactions, use jQuery UI dialogs:

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

### Initial Data Loading

Load data when the dashboard initializes:

```javascript
jQuery(document).ready(function($) {
    // Load initial data
    loadDashboardData();
    
    function loadDashboardData() {
        const formData = SiP.Core.utilities.createFormData(
            'sip-your-plugin',
            'load_dashboard',
            'get_all'
        );
        
        SiP.Core.ajax.handleAjaxAction(
            'sip-your-plugin',
            'load_dashboard',
            formData
        )
        .then(function(response) {
            // Update UI with data
            updateDashboard(response.data);
        })
        .catch(function(error) {
            SiP.Core.utilities.toast.show('Failed to load dashboard data', 5000);
        });
    }
});
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

Handle bulk operations on selected items:

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

### JavaScript Side
- [ ] Initialized DataTables for data display
- [ ] Implemented action form handlers
- [ ] Added error handling for all AJAX calls
- [ ] Used standard spinner and toast utilities
- [ ] Registered success handlers for AJAX responses

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

## Common Pitfalls

1. **Don't forget escaping** - Always escape output
2. **Don't skip loading indicators** - Users need feedback
3. **Don't use custom spinners** - Use Core utilities
4. **Don't forget nonce verification** - Security is crucial
5. **Don't hardcode strings** - Use proper text domains

## Next Steps

- [Implementing AJAX Functionality](./ajax-implementation.md) - For dashboard interactions
- [DataTables Integration](./datatables-integration.md) - For advanced tables
- [UI Components](./ui-components.md) - For using standard components
- [Modals and Toasts](./modals-toasts.md) - For user interactions