# Testing and Debugging

Comprehensive guide for testing and troubleshooting SiP plugins throughout the development lifecycle.

## Overview

Testing and debugging SiP plugins involves multiple layers: browser console logging, PHP error tracking, WordPress debugging tools, and systematic testing approaches. This guide covers best practices for development, staging, and production environments.

## Debug Logging System

### Quick Start

The SiP Plugin Suite includes a centralized debug logging system controlled through a simple toggle.

#### Enable Debug Logging

1. Navigate to **SiP Development Tools → System Diagnostics**
2. Toggle **"Console Logging"** ON
3. Reload the page to see debug messages

#### Using Debug in Your Code

```javascript
// Access the debug object
const debug = SiP.Core.debug;

// Available methods
debug.log('Regular log message');
debug.error('Error message');
debug.warn('Warning message');
debug.info('Info message');
```

#### Standard Module Pattern

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

### Debug Logging Best Practices

1. **Use consistent prefixes** to identify modules:
   ```javascript
   debug.log('🟢 product-actions.js - init()');
   debug.log('📤 product-actions.js - Sending AJAX request');
   ```

2. **Log function entry/exit** for complex operations:
   ```javascript
   function complexOperation() {
       debug.log('➡️ Entering complexOperation()');
       // ... operation code ...
       debug.log('⬅️ Exiting complexOperation()');
   }
   ```

3. **Include relevant data** in logs:
   ```javascript
   debug.log('Processing products:', { count: products.length, ids: productIds });
   ```

4. **Use appropriate log levels**:
   - `debug.log()` - General information
   - `debug.info()` - Important state changes
   - `debug.warn()` - Potential issues
   - `debug.error()` - Actual errors

## Testing Workflow

### Local Development Testing

#### Environment Setup

1. **Local by Flywheel Configuration**:
   ```php
   // wp-config.php additions
   define('WP_DEBUG', true);
   define('WP_DEBUG_LOG', true);
   define('WP_DEBUG_DISPLAY', false);
   define('SCRIPT_DEBUG', true);
   ```

2. **Browser Developer Tools**:
   - Keep console open during development
   - Enable "Preserve log" to maintain logs across page reloads
   - Use network tab to monitor AJAX requests

#### Testing Checklist

- [ ] Enable SiP debug logging
- [ ] Enable WordPress debug mode
- [ ] Clear browser cache
- [ ] Test in multiple browsers
- [ ] Verify responsive behavior
- [ ] Check JavaScript console for errors
- [ ] Monitor network requests
- [ ] Review PHP error logs

### Staging Environment

#### Pre-Deployment Testing

1. **Data Migration Testing**:
   ```bash
   # Export local database
   wp db export local-backup.sql
   
   # Import to staging
   wp db import staging-data.sql
   
   # Update URLs
   wp search-replace 'local.dev' 'staging.example.com'
   ```

2. **Performance Testing**:
   - Use browser profiling tools
   - Monitor AJAX request times
   - Check for memory leaks
   - Verify caching behavior

3. **Integration Testing**:
   - Test with common plugins (WooCommerce, etc.)
   - Verify compatibility with themes
   - Check for conflicts

### Production Deployment

#### Safety Measures

1. **Disable Debug Output**:
   ```php
   define('WP_DEBUG', false);
   define('WP_DEBUG_LOG', false);
   define('WP_DEBUG_DISPLAY', false);
   ```

2. **Error Monitoring**:
   ```php
   // Custom error handler for production
   if (!WP_DEBUG) {
       set_error_handler('sip_production_error_handler');
   }
   
   function sip_production_error_handler($errno, $errstr, $errfile, $errline) {
       // Log to custom location
       error_log(sprintf('[%s] %s in %s on line %d', 
           date('Y-m-d H:i:s'), 
           $errstr, 
           $errfile, 
           $errline
       ), 3, WP_CONTENT_DIR . '/sip-error.log');
   }
   ```

## Debugging Tools

### PHP Error Logging

#### Custom Error Logging

```php
// Development logging
if (WP_DEBUG) {
    error_log('SiP Debug: ' . print_r($data, true));
}

// Conditional logging
function sip_debug_log($message, $data = null) {
    if (!WP_DEBUG) return;
    
    $log_entry = sprintf('[%s] %s', current_time('mysql'), $message);
    if ($data) {
        $log_entry .= ' - Data: ' . print_r($data, true);
    }
    
    error_log($log_entry);
}
```

#### Viewing Logs

```bash
# View WordPress debug log
tail -f wp-content/debug.log

# View PHP error log
tail -f /var/log/php/error.log

# Filter SiP-specific entries
grep "SiP" wp-content/debug.log
```

### Browser Console

#### Console Commands

```javascript
// View all SiP modules
console.log(window.SiP);

// Check if debug is enabled
console.log(SiP.Core.debug.isEnabled());

// Manually enable debug (temporary)
SiP.Core.debug.enable();

// View specific module state
console.log(SiP.PrintifyManager.productActions);
```

#### Debugging AJAX Requests

```javascript
// Override AJAX handler temporarily
const originalAjax = SiP.Core.ajax.request;
SiP.Core.ajax.request = function(options) {
    console.log('AJAX Request:', options);
    return originalAjax.call(this, options).then(
        response => {
            console.log('AJAX Response:', response);
            return response;
        },
        error => {
            console.error('AJAX Error:', error);
            throw error;
        }
    );
};
```

### WordPress Debug Mode

#### Advanced Debug Configuration

```php
// Enable query logging
define('SAVEQUERIES', true);

// Log all errors
@ini_set('log_errors', 'On');
@ini_set('error_log', ABSPATH . 'wp-content/debug.log');

// Display deprecation notices
define('WP_DEBUG_DISPLAY', true);
error_reporting(E_ALL);
```

#### Query Monitoring

```php
// View slow queries
add_action('shutdown', function() {
    if (!defined('SAVEQUERIES') || !SAVEQUERIES) return;
    
    global $wpdb;
    $queries = $wpdb->queries;
    
    foreach ($queries as $query) {
        if ($query[1] > 0.1) { // Queries taking > 0.1 seconds
            error_log('Slow query: ' . $query[0] . ' - Time: ' . $query[1]);
        }
    }
});
```

## Common Issues and Solutions

### AJAX Debugging

#### Issue: AJAX Request Returns 0

**Common Causes**:
1. Action not registered properly
2. Nonce verification failing
3. Incorrect action name

**Debugging Steps**:
```javascript
// 1. Check action registration
debug.log('Registered actions:', SiP.Core.ajax.getRegisteredActions());

// 2. Verify request data
$('#test-button').on('click', function() {
    const formData = SiP.Core.utilities.createFormData('plugin', 'handler', 'action');
    debug.log('Form data:', Array.from(formData.entries()));
    
    SiP.Core.ajax.handleAjaxAction('plugin', 'handler', formData)
        .then(response => debug.log('Success:', response))
        .catch(error => debug.error('Error:', error));
});
```

**PHP Side Debugging**:
```php
add_action('wp_ajax_sip_test_action', function() {
    error_log('Action triggered with data: ' . print_r($_POST, true));
    
    // Verify nonce
    if (!check_ajax_referer('sip_test_nonce', 'nonce', false)) {
        error_log('Nonce verification failed');
        wp_die('Invalid nonce');
    }
    
    wp_send_json_success(['message' => 'Test successful']);
});
```

### JavaScript Errors

#### Issue: Module Not Loading

**Debugging Steps**:
```javascript
// 1. Check script enqueue order
console.log('Scripts loaded:', jQuery('script[src*="sip"]'));

// 2. Verify dependencies
if (typeof SiP === 'undefined') {
    console.error('SiP Core not loaded');
} else if (typeof SiP.Core === 'undefined') {
    console.error('SiP.Core not initialized');
}

// 3. Check for syntax errors
try {
    SiP.YourPlugin.module.init();
} catch (error) {
    console.error('Module initialization error:', error);
}
```

#### Issue: Event Handlers Not Working

**Common Solutions**:
```javascript
// Use event delegation for dynamic content
$(document).on('click', '.dynamic-button', function() {
    debug.log('Dynamic button clicked');
});

// Ensure DOM is ready
$(document).ready(function() {
    // Initialize after DOM load
    SiP.YourPlugin.module.init();
});

// Check for multiple event bindings
$('.button').off('click').on('click', function() {
    // Prevents duplicate handlers
});
```

### PHP Errors

#### Issue: White Screen of Death

**Debugging Steps**:
1. Enable error display temporarily:
   ```php
   ini_set('display_errors', 1);
   ini_set('display_startup_errors', 1);
   error_reporting(E_ALL);
   ```

2. Check error logs:
   ```bash
   tail -f /var/log/apache2/error.log
   tail -f wp-content/debug.log
   ```

3. Isolate the issue:
   ```php
   // Deactivate all plugins except SiP Core
   // Reactivate one by one to find conflict
   ```

#### Issue: Memory Limit Errors

**Solutions**:
```php
// Increase memory limit
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');

// Monitor memory usage
error_log('Memory usage: ' . memory_get_usage(true) / 1024 / 1024 . ' MB');
error_log('Peak memory: ' . memory_get_peak_usage(true) / 1024 / 1024 . ' MB');

// Free memory after operations
unset($large_array);
gc_collect_cycles();
```

## Best Practices

### Error Logging Strategy

1. **Development Environment**:
   - Log everything for debugging
   - Display errors for immediate feedback
   - Use verbose debug messages

2. **Staging Environment**:
   - Log errors but don't display
   - Monitor performance metrics
   - Test error handling

3. **Production Environment**:
   - Log critical errors only
   - Never display errors to users
   - Implement error notifications

### Console Logging Guidelines

1. **Remove debug logs before production**:
   ```javascript
   // Development
   debug.log('Processing started');
   
   // Production - wrapped in condition
   if (WP_DEBUG) {
       debug.log('Processing started');
   }
   ```

2. **Use meaningful messages**:
   ```javascript
   // Bad
   debug.log('here');
   debug.log(data);
   
   // Good
   debug.log('Product update initiated', { productId: id, action: 'update' });
   debug.log('API response received', { status: response.status, data: response.data });
   ```

3. **Group related logs**:
   ```javascript
   console.group('Batch Operation');
   debug.log('Starting batch process');
   items.forEach(item => {
       debug.log('Processing item:', item.id);
   });
   debug.log('Batch complete');
   console.groupEnd();
   ```

### Performance Testing

1. **Measure execution time**:
   ```javascript
   console.time('Operation');
   // ... operation code ...
   console.timeEnd('Operation');
   ```

2. **Profile memory usage**:
   ```javascript
   if (performance.memory) {
       debug.log('Memory usage:', {
           used: Math.round(performance.memory.usedJSHeapSize / 1048576) + ' MB',
           total: Math.round(performance.memory.totalJSHeapSize / 1048576) + ' MB'
       });
   }
   ```

3. **Monitor AJAX performance**:
   ```javascript
   const startTime = performance.now();
   
   SiP.Core.ajax.request(options).then(response => {
       const duration = performance.now() - startTime;
       debug.log(`Request completed in ${duration.toFixed(2)}ms`);
   });
   ```

## Testing Checklist

### Before Development
- [ ] Set up local environment with debug enabled
- [ ] Configure error logging
- [ ] Install browser developer extensions
- [ ] Create test data set

### During Development
- [ ] Use debug logging consistently
- [ ] Test edge cases
- [ ] Verify error handling
- [ ] Check memory usage
- [ ] Monitor network requests

### Before Deployment
- [ ] Run full test suite
- [ ] Test on staging environment
- [ ] Verify production settings
- [ ] Review error logs
- [ ] Performance profiling

### After Deployment
- [ ] Monitor error logs
- [ ] Check user reports
- [ ] Verify functionality
- [ ] Review performance metrics

## Quick Reference

### Common Debug Commands

```javascript
// Enable debug logging
SiP.Core.debug.enable();

// Check SiP modules
console.log(window.SiP);

// View AJAX registry
console.log(SiP.Core.ajax.getHandlers());

// Test AJAX endpoint
SiP.Core.ajax.request({
    action: 'test_action',
    data: { test: true }
}).then(console.log).catch(console.error);
```

### PHP Debug Snippets

```php
// Quick debug log
error_log('SiP Debug: ' . print_r($variable, true));

// Backtrace
error_log(print_r(debug_backtrace(DEBUG_BACKTRACE_IGNORE_ARGS), true));

// Memory usage
error_log('Memory: ' . memory_get_usage(true) / 1024 / 1024 . ' MB');

// Execution time
$start = microtime(true);
// ... code ...
error_log('Execution time: ' . (microtime(true) - $start) . ' seconds');
```

By following these testing and debugging practices, you can maintain high-quality SiP plugins and quickly resolve issues as they arise.