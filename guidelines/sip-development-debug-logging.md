# SiP Development Debug Logging

This guide explains how to use the centralized debug logging system in SiP plugins.

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
   - Go to SiP Development Tools → System Diagnostics
   - Toggle "Console Logging" ON
   - Reload the page to see debug messages

2. **Disable Debug Logging**:
   - Toggle "Console Logging" OFF
   - Reload the page - console will be clean

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
    timeEnd: function() { /* ... */ }
};
```

### How It Works

1. **State Management**: Debug state is stored in localStorage
2. **Toggle Control**: UI toggle in Development Tools updates the state
3. **Conditional Output**: Debug methods only output when enabled
4. **Consistent Interface**: Same API as console object

## Best Practices

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

2. **Don't Add Fallbacks**:
   ```javascript
   // Wrong - unnecessary defensive coding
   const debug = SiP.Core.debug || console;
   
   // Right - Core is always loaded first
   const debug = SiP.Core.debug;
   ```

3. **Don't Log Sensitive Data**:
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
   - Check if debug is enabled in Development Tools
   - Reload the page after toggling
   - Verify SiP.Core.debug exists in console

2. **Too Many Messages**:
   - Use more specific log levels
   - Group related messages
   - Consider conditional logging for loops

3. **Missing Debug Object**:
   - Ensure sip-plugins-core is active
   - Check script loading order
   - Core must load before other plugins

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

## Summary

The SiP debug logging system provides:
- Centralized control over console output
- Consistent logging interface across all plugins
- Easy toggle for development vs production
- Performance-conscious implementation
- Clean, organized console output

Use it liberally during development - it has minimal impact when disabled and greatly improves debugging efficiency.