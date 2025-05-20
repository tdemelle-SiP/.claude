# SiP Development Debug Logging

This guide explains how to use the centralized debug logging system in SiP plugins. This system is integrated into the [SiP Plugins Platform](./sip-plugins-platform.md) architecture.

## Overview

The SiP Plugin Suite includes a centralized debug logging system that allows developers to control console output through a simple toggle. This helps keep the console clean in production while providing detailed logging during development.

## Quick Start

### For Developers

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

### For End Users

1. **Enable Debug Logging**:
   - Go to any SiP plugin dashboard with the standard header
   - Toggle "Console Logging" ON in the header
   - Reload the page to see debug messages when prompted

2. **Disable Debug Logging**:
   - Toggle "Console Logging" OFF in the header
   - Reload the page when prompted - console will be clean

## Implementation Details

### Core Debug Module

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

1. **debug.js**: Core module that provides debug methods and state checking
2. **header-debug-toggle.js**: UI toggle that syncs between client and server state
3. **core-ajax-shell.php**: Server-side handler for toggle AJAX requests

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

1. **Don't Use console Directly**:
   ```javascript
   // Wrong
   console.log('Debug message');
   
   // Right
   debug.log('Debug message');
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
- Centralized control over console output
- Consistent logging interface across all plugins
- Easy toggle for development vs production
- Performance-conscious implementation
- Clean, organized console output
- Synchronized state between client and server

Use it liberally during development - it has minimal impact when disabled and greatly improves debugging efficiency.