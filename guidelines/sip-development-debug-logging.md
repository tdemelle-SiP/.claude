# SiP Development Debug Logging

This guide explains how to use the centralized debug logging system in SiP plugins. This system is integrated into the [SiP Plugins Platform](./sip-plugin-platform.md) architecture.

## Overview

The SiP Plugin Suite includes a centralized debug logging system for both JavaScript and PHP that allows developers to control debug output through a simple toggle. This helps keep logs clean in production while providing detailed logging during development.

The system provides:
- **JavaScript Debug**: Console logging with `SiP.Core.debug`
- **PHP Debug**: File-based logging with `SiP_Debug` class and `sip_debug()` helper

## Quick Start

### For Developers

#### JavaScript Debug Logging

1. **Using Debug in Your Code**:
   ```javascript
   // In any module
   const debug = SiP.Core.debug;
   
   debug.log('Regular log message');
   debug.error('Error message');
   debug.warn('Warning message');
   debug.info('Info message');
   ```

2. **Standard Module Pattern**:
   ```javascript
   SiP.YourPlugin.moduleName = (function($) {
       const debug = SiP.Core.debug;
       
       debug.log('▶ module-name.js Loading...');
       
       function init() {
           debug.log('🟢 module-name.js - init()');
           // Your initialization code
       }
       
       return {
           init: init
       };
   })(jQuery);
   ```

#### PHP Debug Logging

1. **Using Debug in PHP**:
   ```php
   // Simple debug message
   sip_debug('Processing template', 'template_ops');
   
   // With data
   sip_debug('API response received', 'api_call', $response);
   
   // Error logging (always logs regardless of debug setting)
   sip_error('Failed to connect to API', 'api_call', [
       'url' => $api_url,
       'error' => $error_message
   ]);
   ```

2. **Using the Debug Class Directly**:
   ```php
   // For more control over plugin identification
   SiP_Debug::log('Custom message', 'sip-printify-manager', 'context', $data);
   
   // Check if debug is enabled
   if (SiP_Debug::isEnabled()) {
       // Perform expensive debug operations
       $debug_data = generate_debug_report();
       SiP_Debug::log('Debug report', 'my-plugin', 'report', $debug_data);
   }
   ```

3. **Standard Contexts**:
   - `ajax_request` - AJAX request handling
   - `api_call` - External API calls
   - `file_ops` - File system operations
   - `template_ops` - Template operations
   - `creation_setup` - Creation table operations
   - `db_query` - Database operations
   - `cache_ops` - Cache operations
   - `system_test` - Debug system testing

4. **When to Use Class Methods vs Helper Functions**:
   
   Use helper functions for most cases:
   ```php
   sip_debug('Message', 'context', $data);
   sip_error('Error message', 'context', $data);
   ```
   
   Use class methods directly when:
   - You need to specify the plugin name explicitly (e.g., in AJAX handlers)
   - The automatic plugin detection might fail (deep call stacks)
   - You're in sip-plugins-core itself
   
   ```php
   SiP_Debug::log('Message', 'my-plugin', 'context', $data);
   SiP_Debug::error('Error', 'my-plugin', 'context', $data);
   ```

### For End Users

1. **Enable Debug Logging**:
   - Go to any SiP plugin dashboard with the standard header
   - Toggle "Console Logging" ON in the header
   - Reload the page to see debug messages when prompted

2. **Disable Debug Logging**:
   - Toggle "Console Logging" OFF in the header
   - Reload the page when prompted - console will be clean

## Implementation Details

### JavaScript Core Debug Module

Located in `sip-plugins-core/assets/js/core/debug.js`, this module provides:

```javascript
SiP.Core.debug = {
    log: function() { /* ... */ },
    error: function() { /* ... */ },
    warn: function() { /* ... */ },
    info: function() { /* ... */ },
    group: function() { /* ... */ },
    groupEnd: function() { /* ... */ },
    groupCollapsed: function() { /* ... */ },
    table: function() { /* ... */ },
    time: function() { /* ... */ },
    timeEnd: function() { /* ... */ },
    isEnabled: function() { /* ... */ },
    enable: function() { /* ... */ },
    disable: function() { /* ... */ },
    syncWithWordPressOption: function() { /* ... */ }
};
```

### PHP Core Debug Module

Located in `sip-plugins-core/includes/class-sip-debug.php`, this module provides:

```php
class SiP_Debug {
    public static function log($message, $plugin = 'sip-plugins-core', $context = '', $data = null);
    public static function error($message, $plugin = 'sip-plugins-core', $context = '', $data = null);
    public static function isEnabled();
    public static function clearLog();
}

// Helper functions
function sip_debug($message, $context = '', $data = null);
function sip_error($message, $context = '', $data = null);
```

**Key Features:**
- Respects the same `sip_debug_enabled` WordPress option as JavaScript debug
- Automatically detects calling plugin from file path
- Writes to `/wp-content/plugins/sip-plugins-core/logs/sip-debug.log`
- Error logging always active (writes to `sip-php-errors.log`)
- JSON encodes data parameters for easy reading
- Includes timestamp, plugin name, and context in log entries
- Uses Eastern Time (ET) with 12-hour AM/PM format

**Log Format:**
```
[2025-01-29 10:15:23 AM ET] [sip-printify-manager][template_ops] Processing template: Template Name | Data: {"id":123,"status":"active"}
```

### How It Works

The debug system uses a dual-storage approach. For details on the dual-storage pattern, see the [Data Storage Guide](./sip-plugin-data-storage.md#client-server-synchronized-state).

Debug logging combines server-side and client-side state management to ensure consistent behavior:

1. **WordPress Option**: Server-side state stored in the `sip_debug_enabled` WordPress option
2. **localStorage**: Client-side state stored in `sip-core['sip-development-tools']['console-logging']`
3. **WordPress + JS Sync**: Settings passed from PHP to JavaScript using `wp_localize_script()`
4. **Debug Toggle UI**: Controls in standard headers to update both states simultaneously
5. **Console Output**: Debug methods that respect the current state

The debug toggle system implemented in `header-debug-toggle.js` ensures that:

- The UI toggle reflects the current state from both sources
- Toggling updates both the WordPress option and localStorage state
- Users are prompted to reload after changing the setting
- The debug state is consistent across all browsers and users

### Setting Up in PHP

In your plugin's main file or enqueue scripts function:

```php
// Localize debug settings in your enqueue_admin_scripts function
wp_localize_script('sip-core-debug', 'sipCoreSettings', array(
    'debugEnabled' => get_option('sip_debug_enabled', 'false')
));
```

### Core Files

1. **debug.js**: JavaScript core module that provides debug methods and state checking
2. **class-sip-debug.php**: PHP debug class providing file-based logging
3. **header-debug-toggle.js**: UI toggle that syncs between client and server state
4. **core-ajax-shell.php**: Server-side handler for toggle AJAX requests

For more details on the dual storage pattern, see the [Data Storage Guide](./sip-plugin-data-storage.md#client-server-synchronized-state).

## Best Practices

For comprehensive testing approaches, see the [Testing Guide](./sip-development-testing.md).

### DO ✅

1. **Use Descriptive Messages**:
   ```javascript
   debug.log('🟢 Product created successfully', { id: productId });
   ```

2. **Use Appropriate Log Levels**:
   ```javascript
   debug.error('❌ API request failed:', error);
   debug.warn('⚠️ Deprecated function called');
   debug.info('ℹ️ Cache refreshed');
   ```

3. **Use Emojis for Visual Scanning**:
   ```javascript
   debug.log('▶ Module loading...');
   debug.log('🟢 Success');
   debug.log('🔴 Failed');
   debug.log('⚠️ Warning');
   ```

4. **Group Related Logs**:
   ```javascript
   debug.group('Processing products');
   products.forEach(product => {
       debug.log('Processing:', product.name);
   });
   debug.groupEnd();
   ```

### DON'T ❌

1. **Don't Use console or error_log Directly**:
   ```javascript
   // Wrong
   console.log('Debug message');
   
   // Right
   debug.log('Debug message');
   ```
   
   ```php
   // Wrong
   error_log('Debug message');
   
   // Right
   sip_debug('Debug message', 'context');
   ```

2. **Don't Include Console Logs in PHP Files**:
   ```php
   // Wrong - console.log in PHP-generated JavaScript
   <script>
       console.log('Plugin file:', <?php echo json_encode($file); ?>);
       console.log('Active plugins:', <?php echo json_encode($active_plugins); ?>);
   </script>
   
   // Right - Use wp_localize_script() and debug in JS files
   <?php
   wp_localize_script('plugin-script', 'pluginData', [
       'file' => $file,
       'activePlugins' => $active_plugins
   ]);
   ?>
   
   // In your separate JS file:
   debug.log('Plugin file:', pluginData.file);
   debug.log('Active plugins:', pluginData.activePlugins);
   ```

3. **Don't Add Fallbacks**:
   ```javascript
   // Wrong - unnecessary defensive coding
   const debug = SiP.Core.debug || console;
   
   // Right - Core is always loaded first
   const debug = SiP.Core.debug;
   ```

4. **Don't Log Sensitive Data**:
   ```javascript
   // Wrong
   debug.log('User password:', password);
   
   // Right
   debug.log('Authentication successful');
   ```

## Common Patterns

### Early Page Logging

**Best Practice**: Don't use inline JavaScript in PHP view files. Instead, use `wp_localize_script()` to pass PHP data to your JavaScript files.

**Example**:

In your PHP file (e.g., `sip-printify-manager.php`):
```php
wp_localize_script('sip-main', 'sipPluginData', array(
    'hasToken' => !empty($token),
    'shopName' => $shop_name,
    'data' => $processed_data
));
```

In your JavaScript file (e.g., `main.js`):
```javascript
// Early initialization before module definition
(function() {
    if (window.sipPluginData) {
        const debug = SiP.Core.debug;
        debug.log('▶ Initializing with:', sipPluginData);
        
        // Set up window variables or other initialization
        window.myData = sipPluginData.data;
    }
})();
```

This approach:
- Keeps JavaScript in `.js` files where it belongs
- Avoids timing issues with script loading
- Follows WordPress best practices
- Makes code more maintainable

For dashboard-specific implementation, see the [Dashboard Guide](./sip-plugin-dashboards.md#debug-logging-in-dashboards).

### Module Loading
```javascript
debug.log('▶ module-name.js Loading...');
```

### Function Entry/Exit
```javascript
function processData(data) {
    debug.log('→ processData() called with:', data);
    
    // Process...
    
    debug.log('← processData() completed');
}
```

### AJAX Debugging
```javascript
debug.log('📤 AJAX Request:', { action, data });
// ... make request ...
debug.log('📥 AJAX Response:', response);
```

### Error Handling
```javascript
try {
    // Operation
} catch (error) {
    debug.error('Operation failed:', {
        error: error.message,
        stack: error.stack,
        context: relevantData
    });
}
```

## Performance Considerations

- Debug calls are lightweight when disabled
- No string concatenation occurs when disabled
- Safe to leave debug statements in production code
- Minimal overhead compared to direct console calls

## Troubleshooting

1. **Debug Messages Not Showing**:
   - Check if debug is enabled in the standard header toggle
   - Reload the page after toggling
   - Verify that both WordPress option and localStorage are in sync
   - Use browser dev tools to check `SiP.Core.debug.isEnabled()`

2. **Too Many Messages**:
   - Use more specific log levels
   - Group related messages
   - Consider conditional logging for loops

3. **Missing Debug Object**:
   - Ensure sip-plugins-core is active
   - Check script loading order
   - Core must load before other plugins

4. **Toggle Not Working**:
   - Check for AJAX errors in browser console
   - Verify that both the wp_localize_script and localStorage are working
   - Check permissions for updating the WordPress option

## Examples

### Basic Module Setup
```javascript
SiP.PrintifyManager.productActions = (function($) {
    const debug = SiP.Core.debug;
    
    debug.log('▶ product-actions.js Loading...');
    
    function init() {
        debug.log('🟢 product-actions.js - init()');
        attachEventListeners();
    }
    
    function attachEventListeners() {
        debug.log('📎 Attaching event listeners');
        
        $(document).on('click', '.product-btn', function(e) {
            debug.log('🔘 Product button clicked', e.target);
            handleProductAction(e);
        });
    }
    
    return {
        init: init
    };
})(jQuery);
```

### AJAX Request Logging
```javascript
function fetchProducts() {
    debug.log('🔄 Fetching products...');
    
    const formData = createFormData();
    debug.log('📤 Request data:', formData);
    
    ajax.handleAjaxAction('sip-printify-manager', 'product_action', formData)
        .then(response => {
            debug.log('✅ Products fetched:', response.data);
            return response;
        })
        .catch(error => {
            debug.error('❌ Failed to fetch products:', error);
            throw error;
        });
}
```

### Conditional Debug Output
```javascript
function processLargeDataset(items) {
    debug.group('Processing dataset');
    debug.log(`Processing ${items.length} items`);
    
    items.forEach((item, index) => {
        // Only log every 100th item to avoid spam
        if (index % 100 === 0) {
            debug.log(`Progress: ${index}/${items.length}`);
        }
        
        processItem(item);
    });
    
    debug.log('✅ Dataset processing complete');
    debug.groupEnd();
}
```

### PHP AJAX Handler Example
```php
function sip_handle_template_action() {
    sip_debug('Template action handler started', 'ajax_request', $_POST);
    
    $action = isset($_POST['template_action']) ? sanitize_text_field($_POST['template_action']) : '';
    
    switch ($action) {
        case 'create_template':
            sip_debug('Creating new template', 'template_ops');
            $result = create_template($_POST);
            
            if ($result['success']) {
                sip_debug('Template created successfully', 'template_ops', $result);
            } else {
                sip_error('Template creation failed', 'template_ops', $result);
            }
            break;
            
        default:
            sip_error('Invalid template action', 'ajax_request', ['action' => $action]);
    }
}
```

### PHP API Integration Example
```php
function fetch_printify_products($shop_id) {
    sip_debug("Fetching products for shop: {$shop_id}", 'api_call');
    
    $api_url = "https://api.printify.com/v1/shops/{$shop_id}/products.json";
    
    $response = wp_remote_get($api_url, [
        'headers' => [
            'Authorization' => 'Bearer ' . get_option('printify_api_token')
        ]
    ]);
    
    if (is_wp_error($response)) {
        sip_error('API request failed', 'api_call', [
            'url' => $api_url,
            'error' => $response->get_error_message()
        ]);
        return false;
    }
    
    $body = wp_remote_retrieve_body($response);
    $data = json_decode($body, true);
    
    sip_debug('Products fetched successfully', 'api_call', [
        'count' => count($data['data'] ?? [])
    ]);
    
    return $data;
}
```

## Using the Header Debug Toggle

The header toggle is the easiest way for users to control debugging. See the [Dashboard Implementation Guide](./sip-plugin-dashboards.md#header-debug-toggle) for integration examples.

The most user-friendly way to control debug logging is through the standard header toggle:

1. **Include the Toggle**:
   - The toggle is automatically included in the standard header
   - Ensure your dashboard uses `sip_render_standard_header()`

2. **Setup Script Dependencies**:
   ```php
   // In your enqueue scripts function
   wp_register_script('your-main-script', 'path/to/script.js', 
       array('jquery', 'sip-core-debug', 'sip-core-state', 'sip-core-header-debug-toggle')
   );
   ```

3. **Localize the Debug Setting**:
   ```php
   wp_localize_script('sip-core-debug', 'sipCoreSettings', array(
       'debugEnabled' => get_option('sip_debug_enabled', 'false')
   ));
   ```

For more detailed implementation of dashboards with the debug toggle, see the [Dashboard Implementation Guide](./sip-plugin-dashboards.md#header-debug-toggle).

## Summary

The SiP debug logging system provides:
- Centralized control over console output (JavaScript) and log files (PHP)
- Consistent logging interface across all plugins and languages
- Easy toggle for development vs production
- Performance-conscious implementation
- Clean, organized output in both console and log files
- Synchronized state between client and server
- Automatic plugin detection in PHP logs
- Context-based log categorization

Use it liberally during development - it has minimal impact when disabled and greatly improves debugging efficiency across both JavaScript and PHP code.