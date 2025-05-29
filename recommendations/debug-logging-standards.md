# Debug Logging Standards

## Current State

The code contains multiple `error_log()` calls that appear to be debug statements:
```php
error_log("👉sip_handle_creation_setup_action - POST data being sent...");
error_log("👉Template name from request: " . $template_name);
```

These are always active and write to the PHP error log regardless of debug settings.

## Existing Debug Infrastructure

1. **Custom Log Location**: Set in sip-plugins-core main file
2. **Debug Toggle**: WordPress option `sip_debug_enabled`
3. **JavaScript Debug**: Comprehensive `SiP.Core.debug` system

## Recommendation

### Create PHP Debug Utility

Add to sip-printify-manager or sip-plugins-core:

```php
/**
 * SiP Debug Logger
 * 
 * Provides centralized debug logging that respects debug settings
 */
class SiP_Debug {
    private static $instance = null;
    private $enabled = false;
    private $log_file = '';
    
    private function __construct() {
        $this->enabled = get_option('sip_debug_enabled') === 'true';
        $this->log_file = WP_PLUGIN_DIR . '/sip-plugins-core/logs/debug.log';
    }
    
    public static function log($message, $context = '') {
        if (!self::$instance) {
            self::$instance = new self();
        }
        
        if (!self::$instance->enabled) {
            return;
        }
        
        $timestamp = current_time('mysql');
        $plugin = 'sip-printify-manager';
        $formatted = "[{$timestamp}] [{$plugin}] [{$context}] {$message}" . PHP_EOL;
        
        error_log($formatted, 3, self::$instance->log_file);
    }
}

// Helper function
function sip_debug($message, $context = '') {
    SiP_Debug::log($message, $context);
}
```

### Usage Pattern

Replace current error_log calls:
```php
// Old
error_log("👉Template name from request: " . $template_name);

// New
sip_debug("Template name from request: " . $template_name, 'creation_setup');
```

### Benefits

1. **Controlled Output**: Only logs when debug is enabled
2. **Consistent Format**: Timestamps, plugin identification
3. **Separate Debug Log**: Doesn't pollute error log
4. **Context Tracking**: Easy to filter by operation
5. **Performance**: No output in production

### Migration Steps

1. Add debug utility class to plugin
2. Replace all `error_log()` calls with `sip_debug()`
3. Remove emoji prefixes (use context parameter instead)
4. Test with debug enabled/disabled

### Debug Categories

Establish standard contexts:
- `ajax_request` - AJAX request handling
- `creation_setup` - Creation table operations  
- `template_ops` - Template operations
- `api_call` - External API calls
- `file_ops` - File system operations