# SiP Development Testing & Debug

Comprehensive guide for testing, debugging, and troubleshooting SiP plugins throughout the development lifecycle. The system provides centralized debug logging for both JavaScript and PHP with three levels: OFF, NORMAL, and VERBOSE.

## Why This System Exists

The SiP plugin suite requires consistent debugging across multiple plugins, languages (JS/PHP), and environments. This centralized system ensures:
- Clean production logs (debug output disabled by default)
- Consistent logging interface across all plugins
- Performance-conscious implementation (minimal overhead when disabled)
- Synchronized debug state between client and server
- Granular control over log verbosity with three simple levels

## Debug Logging System

### Quick Start

#### Set Debug Level
1. Navigate to any SiP plugin dashboard with standard header
2. Use the **Debug** dropdown in the header to select: Off, Normal, or Verbose
3. Or use console: `sipDebug.setLevel('OFF'|'NORMAL'|'VERBOSE')`

#### Debug Levels

- **OFF**: No logging output
- **NORMAL**: Important operations and all errors  
- **VERBOSE**: All debug messages including module loading

#### JavaScript Debug Usage

```javascript
// Access debug object (always available via platform)
const debug = SiP.Core.debug;

// Logging methods by level
debug.normal('Important operation completed');  // Shows in NORMAL and VERBOSE
debug.operation('User clicked save');          // Alias for normal() - more semantic
debug.log('Detailed debug info');              // Shows only in VERBOSE (for migration)
debug.verbose('Very detailed trace');          // Shows only in VERBOSE
debug.error('Error message');                  // Shows in NORMAL and VERBOSE
debug.warn('Warning message');                 // Shows in NORMAL and VERBOSE
debug.info('Info message');                    // Shows in NORMAL and VERBOSE

// Other methods (show in NORMAL and VERBOSE)
debug.group('Group name');
debug.groupEnd();
debug.groupCollapsed('Collapsed group');
debug.table(data);
debug.time('timer-name');
debug.timeEnd('timer-name');

// Check current level
debug.getLevel();        // Returns 0 (OFF), 1 (NORMAL), or 2 (VERBOSE)
debug.getLevelName();    // Returns 'OFF', 'NORMAL', or 'VERBOSE'
```

#### Source Attribution

All log messages now include their source file and line number automatically:
```
[ajax.js:42] Processing request...
[template-actions.js:156] Template saved successfully
```

#### PHP Debug Usage

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

### Standard Module Pattern

```javascript
SiP.YourPlugin.moduleName = (function($) {
    const debug = SiP.Core.debug;
    
    // Module loading logs are VERBOSE level (detailed tracing)
    debug.verbose('▶ module-name.js Loading...');
    
    function init() {
        // Initialization is important - use normal() for NORMAL level
        debug.normal('🟢 module-name.js initialized');
        attachEventListeners();
    }
    
    function attachEventListeners() {
        // Event listener attachment is detailed - stays verbose
        debug.verbose('📎 Attaching event listeners');
        
        $(document).on('click', '.action-button', function(e) {
            // User interactions are often important - consider normal()
            debug.normal('🔘 Action button clicked');
            debug.verbose('Button target:', e.target);
            handleAction(e);
        });
    }
    
    function performOperation(data) {
        debug.normal('📤 Starting important operation');
        debug.verbose('Operation data:', data);
        
        try {
            // ... operation code ...
            debug.normal('✅ Operation completed successfully');
        } catch (error) {
            debug.error('❌ Operation failed:', error);
        }
    }
    
    return {
        init: init
    };
})(jQuery);
```

### Migration Strategy

During migration from the old system to the new levels:

1. **All existing `debug.log()` calls now require VERBOSE mode** - This prevents noise in NORMAL mode
2. **Identify important operations** that should be visible in NORMAL mode:
   - Module initialization confirmations
   - User-triggered actions
   - API calls and responses
   - Successful completions of major operations
   - All errors and warnings
3. **Update important logs** to use `debug.normal()` instead of `debug.log()`
4. **Keep detailed logs** as `debug.log()` or explicitly use `debug.verbose()`

### Migration Examples

#### Example: Module Loading
```javascript
// Before - all these show only in VERBOSE now
debug.log('▶ SiP.Core.ajax Loading...');
debug.log('▶ shop-actions.js Loading...');
debug.log('▶ product-actions.js Loading...');

// After - organized by importance
debug.verbose('▶ ajax.js Loading...');          // Keep individual loads verbose
debug.verbose('▶ shop-actions.js Loading...');
debug.normal('▶ SiP Printify Manager modules initialized'); // One summary for NORMAL
```

#### Example: User Actions
```javascript
// Before
debug.log('Create template button clicked');
debug.log('Button data:', $(this).data());

// After
debug.normal('🔘 Create template action triggered');  // User action = NORMAL
debug.verbose('Button data:', $(this).data());       // Details = VERBOSE
```

#### Example: AJAX Operations
```javascript
// Before
debug.log('Starting product sync');
debug.log('Sync response:', response);

// After
debug.normal('📤 Starting product sync');        // Operation start = NORMAL
debug.verbose('Sync response:', response);       // Response data = VERBOSE
debug.normal('✅ Products synced successfully'); // Success = NORMAL
debug.error('❌ Product sync failed:', error);   // Errors always show
```

### PHP Debug Implementation

```php
// Standard contexts for categorizing logs
$contexts = [
    'ajax_request',   // AJAX request handling
    'api_call',       // External API calls
    'file_ops',       // File system operations
    'template_ops',   // Template operations
    'creation_setup', // Creation table operations
    'db_query',       // Database operations
    'cache_ops',      // Cache operations
    'system_test'     // Debug system testing
];

// AJAX handler example
function sip_handle_template_action() {
    sip_debug('Template action handler started', 'ajax_request', $_POST);
    
    $action = sanitize_text_field($_POST['template_action'] ?? '');
    
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
    }
}
```

### When to Use Class Methods vs Helper Functions

**Use helper functions (most cases):**
```php
sip_debug('Message', 'context', $data);
sip_error('Error message', 'context', $data);
```

**Use class methods directly when:**
- You need to specify plugin name explicitly (e.g., in AJAX handlers)
- Automatic plugin detection might fail (deep call stacks)
- You're in sip-plugins-core itself

```php
SiP_Debug::log('Message', 'my-plugin', 'context', $data);
SiP_Debug::error('Error', 'my-plugin', 'context', $data);
```

## Testing Workflow

### Local Development Setup

```php
// wp-config.php additions
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
define('SCRIPT_DEBUG', true);
```

### Testing Checklist

#### Before Development
- [ ] Enable SiP debug logging via header toggle
- [ ] Enable WordPress debug mode
- [ ] Configure browser dev tools (preserve logs, disable cache)
- [ ] Create test data set

#### During Development
- [ ] Monitor JavaScript console for errors
- [ ] Check network tab for AJAX issues
- [ ] Review PHP error logs regularly
- [ ] Test edge cases and error conditions
- [ ] Verify responsive behavior

#### Before Deployment
- [ ] Disable debug output in production
- [ ] Run full test suite
- [ ] Test on staging environment
- [ ] Performance profiling
- [ ] Review all error logs

## Common Issues and Solutions

### AJAX Debugging

#### Issue: AJAX Returns 0

```javascript
// Debug the request
const formData = SiP.Core.utilities.createFormData('plugin', 'action_type', 'action');
debug.log('Form data:', Array.from(formData.entries()));

// Check server response
SiP.Core.ajax.handleAjaxAction('plugin', 'action_type', formData)
    .then(response => debug.log('Success:', response))
    .catch(error => debug.error('Error:', error));
```

```php
// PHP side debugging
add_action('sip_plugin_handle_action', function($plugin_id, $action_type) {
    error_log('Action triggered: ' . $plugin_id . ' - ' . $action_type);
    error_log('POST data: ' . print_r($_POST, true));
}, 10, 2);
```

### JavaScript Module Loading

```javascript
// Verify dependencies loaded
if (typeof SiP === 'undefined') {
    console.error('SiP Core not loaded');
} else if (typeof SiP.Core === 'undefined') {
    console.error('SiP.Core not initialized');
} else {
    debug.log('Dependencies loaded correctly');
}

// Check module initialization
try {
    SiP.YourPlugin.module.init();
    debug.log('Module initialized successfully');
} catch (error) {
    debug.error('Module initialization failed:', error);
}
```

### Performance Monitoring

```javascript
// Measure execution time
debug.time('expensive-operation');
performExpensiveOperation();
debug.timeEnd('expensive-operation');

// Monitor AJAX performance
const startTime = performance.now();
SiP.Core.ajax.request(options).then(response => {
    const duration = performance.now() - startTime;
    debug.log(`Request completed in ${duration.toFixed(2)}ms`);
});

// Check memory usage
if (performance.memory) {
    debug.log('Memory usage:', {
        used: Math.round(performance.memory.usedJSHeapSize / 1048576) + ' MB',
        total: Math.round(performance.memory.totalJSHeapSize / 1048576) + ' MB'
    });
}
```

## Debug Best Practices

### Log Level Guidelines

#### NORMAL Level - Important Operations Only
Use `debug.normal()` or `debug.operation()` for:
- ✅ Plugin/module initialization confirmations
- ✅ User-triggered actions (button clicks, form submissions)
- ✅ API request start/completion
- ✅ Major operation success/failure
- ✅ State changes that affect user experience
- ✅ All errors and warnings (use debug.error() and debug.warn())

Note: `debug.operation()` is an alias for `debug.normal()` - use whichever reads better in context.

#### VERBOSE Level - Detailed Tracing
Use `debug.verbose()` or `debug.log()` for:
- 📋 Module loading announcements
- 📋 Event listener attachments
- 📋 Detailed operation steps
- 📋 Data dumps and object contents
- 📋 Loop iterations and progress
- 📋 Internal state changes
- 📋 Performance measurements

### DO ✅

1. **Choose the right level for your message**:
   ```javascript
   // NORMAL - User needs to know this happened
   debug.normal('🟢 Product created successfully', { id: productId });
   
   // VERBOSE - Developer debugging info
   debug.verbose('Product data before save:', productData);
   ```

2. **Use appropriate methods for errors and warnings**:
   ```javascript
   debug.error('❌ API request failed:', error);    // Always visible in NORMAL+
   debug.warn('⚠️ Deprecated function called');    // Always visible in NORMAL+
   debug.normal('ℹ️ Cache refreshed');             // Important info
   debug.verbose('Cache stats:', cacheStats);      // Detailed info
   ```

3. **Group related operations with appropriate levels**:
   ```javascript
   debug.group('Batch Processing');
   debug.normal(`Processing ${items.length} items`);
   items.forEach(item => debug.verbose('Processing:', item.id));
   debug.normal('✅ Batch complete');
   debug.groupEnd();
   ```

4. **Include relevant data without sensitive information**:
   ```php
   // Good - helpful context
   sip_debug('User authenticated', 'auth', ['user_id' => $user_id]);
   
   // Bad - exposes sensitive data
   sip_debug('Login attempt', 'auth', ['password' => $password]);
   ```

5. **Take advantage of automatic source attribution**:
   ```javascript
   // No need to include file name - it's automatic!
   debug.normal('Operation started');
   // Output: [template-actions.js:45] Operation started
   ```

### DON'T ❌

1. **Don't use console.log or error_log directly**:
   ```javascript
   // Wrong
   console.log('Debug message');
   
   // Right
   debug.log('Debug message');
   ```

2. **Don't include console logs in PHP-generated JavaScript**:
   ```php
   // Wrong - inline JavaScript
   echo "<script>console.log('Data: " . json_encode($data) . "');</script>";
   
   // Right - use wp_localize_script
   wp_localize_script('my-script', 'myData', $data);
   // Then in JS file: debug.log('Data:', myData);
   ```

3. **Don't leave debug code uncommented in production**:
   ```javascript
   // Development
   debug.log('Detailed operation trace', complexData);
   
   // Production - remove or wrap
   if (SiP.Core.debug.isEnabled()) {
       debug.log('Detailed operation trace', complexData);
   }
   ```

## Log Files and Locations

### JavaScript Console
- Browser developer console
- Controlled by header toggle
- No file output

### PHP Debug Logs
- **Debug log**: `/wp-content/plugins/sip-plugins-core/logs/sip-debug.log`
- **Error log**: `/wp-content/plugins/sip-plugins-core/logs/sip-php-errors.log`
- **WordPress debug**: `/wp-content/debug.log` (if WP_DEBUG_LOG enabled)

### Log Format
```
[2025-01-29 10:15:23 AM ET] [sip-printify-manager][template_ops] Processing template: Template Name | Data: {"id":123,"status":"active"}
```

## Quick Reference Commands

### Browser Console
```javascript
// Check debug level
SiP.Core.debug.getLevel()      // Returns 0, 1, or 2
SiP.Core.debug.getLevelName()  // Returns 'OFF', 'NORMAL', or 'VERBOSE'

// Set debug level
sipDebug.setLevel('OFF')       // No logging
sipDebug.setLevel('NORMAL')    // Important operations only
sipDebug.setLevel('VERBOSE')   // All debug messages

// View all SiP modules
console.log(window.SiP)

// Test AJAX endpoint
SiP.Core.ajax.request({
    action: 'test_action',
    data: { test: true }
}).then(console.log).catch(console.error)
```

### PHP Debug Snippets
```php
// Quick debug with context
sip_debug('Variable state', 'my_context', $variable);

// Execution timing
$start = microtime(true);
// ... code ...
sip_debug('Execution time', 'performance', [
    'duration' => microtime(true) - $start . ' seconds'
]);

// Memory monitoring
sip_debug('Memory usage', 'performance', [
    'current' => memory_get_usage(true) / 1024 / 1024 . ' MB',
    'peak' => memory_get_peak_usage(true) / 1024 / 1024 . ' MB'
]);
```

## Debugging Release Issues

### Release Process Debugging
**Why**: Release processes involve multiple systems (PHP, PowerShell, Git) making debugging complex. Systematic approaches help identify failure points.

#### Check Release Log Files
```bash
# Navigate to logs directory
cd wp-content/uploads/sip-development-tools/logs/

# View latest release log
tail -f release_sip-plugin-name_version_timestamp.log
```

#### Common Release Issues

1. **Log Shows "Success True" Table**
   - **Symptom**: Log ends with PowerShell hashtable output
   - **Cause**: PowerShell return value not suppressed
   - **Fix**: Ensure scripts use `$null = @{...}` instead of `return @{...}`

2. **Release Stuck on "Running"**
   - **Symptom**: UI never shows completion
   - **Cause**: PHP not detecting completion markers
   - **Check**: Look for `[COMPLETE]` or `[SUCCESS]` markers in log

3. **Extension Upload Fails**
   - **Symptom**: "Missing plugin parameter" error
   - **Cause**: API expects `plugin_slug` not `extension_slug`
   - **Fix**: Use consistent parameter names

#### PowerShell Script Debugging
```powershell
# Run script with VERBOSE log level
./release-plugin.ps1 -NewVersion "1.0.0" -PluginSlug "plugin-name" -MainFile "plugin.php" -LogLevel "VERBOSE"

# Enable Git trace for authentication issues
$env:GIT_TRACE = 1
$env:GIT_CURL_VERBOSE = 1
```

#### PHP Release Status Checking
```php
// Add debug output to release status check
error_log('SIP Debug - Log content length: ' . strlen($log_content));
error_log('SIP Debug - Looking for completion markers...');
error_log('SIP Debug - Found COMPLETE: ' . (strpos($log_content, '[COMPLETE]') !== false ? 'yes' : 'no'));
```

## Integration with Other Systems

### Dashboard Implementation
The debug toggle is automatically included when using the standard header. See [Dashboard Guide](./sip-plugin-dashboards.md) for implementation.

### AJAX Integration
Debug logging is essential for AJAX troubleshooting. See [AJAX Guide](./sip-plugin-ajax.md) for patterns.

### Data Storage Debugging
For debugging storage operations, see [Data Storage Guide](./sip-plugin-data-storage.md).

## Summary

The SiP debug and testing system provides:
- **Three-level logging system**: OFF, NORMAL, and VERBOSE
- **Automatic source attribution**: All logs show [filename.js:line]
- **Unified logging interface** for JavaScript and PHP
- **Gradual migration path**: Existing logs default to VERBOSE
- **Performance-conscious**: Minimal overhead when disabled
- **Clean production logs**: Use NORMAL for important operations only

### Key Changes from Previous System

1. **Three Levels Instead of On/Off**:
   - OFF: No logging
   - NORMAL: Important operations and errors only
   - VERBOSE: All debug messages (where existing logs go)

2. **New Methods**:
   - `debug.normal()` - For important operations (NORMAL level)
   - `debug.verbose()` - For detailed traces (VERBOSE level)
   - `debug.log()` - Now maps to VERBOSE for migration

3. **Automatic Source Info**:
   - All logs now show `[filename.js:line]` automatically
   - No need to manually include file names in messages

4. **Migration Strategy**:
   - All existing `debug.log()` calls require VERBOSE mode
   - Gradually identify important logs and change to `debug.normal()`
   - Keep detailed debugging as `debug.log()` or `debug.verbose()`

Use liberally during development - the system has minimal performance impact when disabled and greatly improves debugging efficiency.