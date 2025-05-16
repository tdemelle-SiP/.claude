# Low-Risk AJAX Fixes

## 1. Standardize Action Hook Names (Very Low Risk)

### Current Issue
```php
// ajax-handler.php - Inconsistent naming
do_action('sip_dev_tools_handle_action', $action_type);
do_action('sip_printify_handle_action', $action_type);
```

### Fix
Create a standardized format:
```php
// ajax-handler.php
do_action('sip_plugin_handle_action', 'development-tools', $action_type);
do_action('sip_plugin_handle_action', 'printify-manager', $action_type);
```

Then update the shells to use:
```php
// development-tools-ajax-shell.php
add_action('sip_plugin_handle_action', 'sip_dev_tools_route_action', 10, 2);
function sip_dev_tools_route_action($plugin_id, $action_type) {
    if ($plugin_id !== 'development-tools') return;
    // ... existing routing logic
}
```

**Risk Level**: Minimal - Just adds consistency without breaking existing functionality

## 2. Move Success Handler Registration (Low Risk)

### Current Issue
```javascript
// shop-actions.js - Line 178
// Outside the module
SiP.Core.ajax.registerSuccessHandler('sip-printify-manager', 'shop_action', SiP.PrintifyManager.shopActions.handleSuccessResponse);
```

### Fix
Move inside the init function:
```javascript
function init() {
    console.log('         💰💻shop-actions.js:init():attachEventListeners()');
    attachMainShopEventListeners();
    
    // Register success handler during initialization
    SiP.Core.ajax.registerSuccessHandler(
        'sip-printify-manager', 
        'shop_action', 
        handleSuccessResponse
    );
}
```

**Risk Level**: Low - Just moves the registration timing, doesn't change functionality

## 3. Add Error Code Parameters (Low Risk)

### Current Issue
```php
// Missing error code parameter
SiP_AJAX_Response::error(
    'sip-printify-manager',
    'template_action',
    $template_action,
    'Unknown action requested: ' . $template_action
);
```

### Fix
Add the missing parameter:
```php
SiP_AJAX_Response::error(
    'sip-printify-manager',
    'Unknown action requested: ' . $template_action,
    'invalid_action',  // Add error code
    ['requested_action' => $template_action]  // Optional data
);
```

**Risk Level**: Low - The class already handles missing parameters gracefully

## 4. Create Debug Flag for Console Logging (Very Low Risk)

### Current Issue
```javascript
console.log('▶ shop-actions.js Loading...');
console.log('💰💻Clear shop button clicked');
```

### Fix
Add a debug flag at the top of each module:
```javascript
// shop-actions.js
const DEBUG_MODE = false; // Set to true during development

// Then wrap all console.logs
if (DEBUG_MODE) {
    console.log('▶ shop-actions.js Loading...');
}
```

Or better yet, create a debug logger:
```javascript
// In utilities.js
function debugLog(message, ...args) {
    if (window.SIP_DEBUG_MODE || false) {
        console.log(message, ...args);
    }
}

// Usage
debugLog('▶ shop-actions.js Loading...');
```

**Risk Level**: Very Low - Just wraps existing logs without removing them

## 5. Add Basic jQuery Object Caching (Low Risk)

### Current Issue
```javascript
$('#product-creation-container').show();
$('#shop-container').show();
$('#auth-container').hide();
```

### Fix
Add caching at the top of functions:
```javascript
function handleSuccessResponse(response) {
    // Cache jQuery objects at function start
    const $productContainer = $('#product-creation-container');
    const $shopContainer = $('#shop-container');
    const $authContainer = $('#auth-container');
    
    // Use cached objects
    $productContainer.show();
    $shopContainer.show();
    $authContainer.hide();
}
```

**Risk Level**: Low - Performance improvement with no functional changes

## 6. Standardize AJAX Response Format (Medium-Low Risk)

### Current Issue
Inconsistent response handling between plugins.

### Fix
Create a wrapper function in each ajax shell:
```php
// In each ajax shell
function sip_send_success($action, $data = [], $message = '') {
    SiP_AJAX_Response::success(
        'sip-printify-manager',  // or appropriate plugin ID
        $_POST['action_type'],   // from the request
        $action,
        $data,
        $message
    );
}

// Usage
sip_send_success('delete_template', $result, 'Template deleted successfully');
```

**Risk Level**: Medium-Low - Adds consistency without changing output format

## 7. Add Nonce Verification Helper (Low Risk)

### Current Issue
Direct nonce verification in multiple places.

### Fix
Add a helper function:
```php
// In ajax-handler.php
function sip_verify_ajax_nonce() {
    $nonce_action = 'sip-plugins-core_nonce';
    if (!isset($_POST['nonce']) || !wp_verify_nonce($_POST['nonce'], $nonce_action)) {
        SiP_AJAX_Response::error(
            'sip-plugins-core', 
            'Security check failed', 
            'nonce_verification'
        );
        return false;
    }
    return true;
}

// Usage in handlers
if (!sip_verify_ajax_nonce()) {
    return;
}
```

**Risk Level**: Low - Centralizes existing functionality

## Implementation Order

1. **Phase 1** (Lowest Risk):
   - Add debug flag for console logs
   - Move success handler registrations
   - Add missing error codes

2. **Phase 2** (Low Risk):
   - Standardize action hook names
   - Add jQuery object caching
   - Create response helpers

3. **Phase 3** (Medium-Low Risk):
   - Implement nonce verification helper
   - Standardize response formats across plugins

Each change can be implemented independently and tested before moving to the next.

## Testing Strategy

For each change:
1. Implement in one module first
2. Test all AJAX actions in that module
3. If successful, roll out to other modules
4. Keep old code commented for easy rollback

## Example Implementation

Here's how to implement the debug flag safely:

```javascript
// At the top of shop-actions.js
(function() {
    // Check for debug mode from various sources
    const DEBUG_MODE = 
        window.SIP_DEBUG_MODE || 
        localStorage.getItem('sip_debug') === 'true' ||
        false;
    
    // Create safe console wrapper
    const debug = {
        log: function(...args) {
            if (DEBUG_MODE) console.log(...args);
        },
        error: function(...args) {
            if (DEBUG_MODE) console.error(...args);
        },
        warn: function(...args) {
            if (DEBUG_MODE) console.warn(...args);
        }
    };
    
    // Replace all console.log with debug.log
    debug.log('▶ shop-actions.js Loading...');
    
    // Rest of the module...
})();
```

This approach allows toggling debug mode without code changes:
```javascript
// In browser console
localStorage.setItem('sip_debug', 'true');
// Reload page to see debug messages
```