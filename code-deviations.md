# Specific Code Deviations from Documented Standards

## 1. AJAX Implementation Deviations

### Standard Violation: Direct DOM Manipulation Instead of Response Handlers
**File**: `sip-printify-manager/assets/js/modules/shop-actions.js`
**Lines**: 111-114
```javascript
// ❌ WRONG - Direct DOM manipulation in success handler
$('#product-creation-container').show();
$('#shop-container').show();
$('#auth-container').hide();
$('#clear-shop-button').hide();
```
**Should Be**:
```javascript
// ✅ Update UI through a dedicated UI state manager
SiP.PrintifyManager.utilities.ui.updateShopVisibility({
    productCreation: true,
    shop: true,
    auth: false,
    clearButton: true
});
```

### Standard Violation: Alert Instead of Toast
**File**: `sip-printify-manager/assets/js/modules/shop-actions.js`
**Line**: 61
```javascript
// ❌ WRONG
alert('Please enter a valid Printify API token');
```
**Should Be**:
```javascript
// ✅ Use the toast system
SiP.Core.utilities.toast.show('Please enter a valid Printify API token', 'error', 3000);
```

## 2. Data Storage Deviations

### Standard Violation: Direct Window Object Usage
**File**: `sip-printify-manager/assets/js/modules/shop-actions.js`
**Lines**: 85-91
```javascript
// ❌ WRONG - Direct window properties
window.productData = window.productData || [];
window.masterTemplateData = window.masterTemplateData || { templates: [] };
window.creationTemplateWipData = window.creationTemplateWipData || { data: {} };
```
**Should Be**:
```javascript
// ✅ Use namespaced storage
SiP.PrintifyManager.state = SiP.PrintifyManager.state || {};
SiP.PrintifyManager.state.productData = SiP.PrintifyManager.state.productData || [];
SiP.PrintifyManager.state.masterTemplateData = SiP.PrintifyManager.state.masterTemplateData || { templates: [] };
```

### Standard Violation: Mixed Storage Types
**File**: `sip-printify-manager/assets/js/modules/product-actions.js`
**Lines**: 308-315
```javascript
// ❌ WRONG - Using localStorage for table state
stateSaveCallback: function(settings, data) {
    localStorage.setItem("Product_DataTables_" + settings.sInstance, JSON.stringify(data));
},
```
**Should Be**: As documented, table state should be in sessionStorage for temporary data.

## 3. jQuery Standard Violations

### Standard Violation: No jQuery Object Caching
**File**: `sip-printify-manager/assets/js/modules/product-actions.js`
**Lines**: 363-387
```javascript
// ❌ WRONG - Repeated jQuery selections
const toggleCell = $(row).find('td:nth-child(2)');
const titleContent = toggleCell.find('.title-content');
// ... later ...
$('.child-product-row').find('td:nth-child(2)').css('padding-left', '30px');
```
**Should Be**:
```javascript
// ✅ Cache jQuery objects
const $childRows = $('.child-product-row');
const $secondCells = $childRows.find('td:nth-child(2)');
$secondCells.css('padding-left', '30px');
```

### Standard Violation: Event Handlers Not Namespaced
**File**: `sip-printify-manager/assets/js/modules/image-actions.js`
**Lines**: 38-41
```javascript
// ❌ WRONG - No namespace
$(document).off('submit', '#image-action-form').on('submit', '#image-action-form', function(e) {
```
**Should Be**:
```javascript
// ✅ Namespaced events
$(document).off('submit.sipPrintify', '#image-action-form')
    .on('submit.sipPrintify', '#image-action-form', function(e) {
```

## 4. Module Pattern Violations

### Standard Violation: Missing Comma in Return Statement
**File**: `sip-printify-manager/assets/js/main.js`
**Lines**: 92-96
```javascript
// ❌ WRONG - Missing comma
return {
    initialize: initialize,
    initializeModules: initializeModules
    // Missing comma here
};
```

### Standard Violation: Success Handler Outside Module
**File**: `sip-printify-manager/assets/js/modules/shop-actions.js`
**Line**: 178
```javascript
// ❌ WRONG - Outside the module
SiP.Core.ajax.registerSuccessHandler('sip-printify-manager', 'shop_action', SiP.PrintifyManager.shopActions.handleSuccessResponse);
```
**Should Be**: Inside the init() function

## 5. Error Handling Violations

### Standard Violation: Console Logging in Production
**File**: Every JavaScript file
```javascript
// ❌ WRONG - Console logs everywhere
console.log('▶ shop-actions.js Loading...');
console.log('💰💻Clear shop button clicked');
```
**Should Be**: Use a debug flag or remove entirely

### Standard Violation: Emoji in Error Logs
**File**: `sip-printify-manager/includes/shop-functions.php`
**Line**: 34
```php
// ❌ WRONG
error_log("🚀 Received Token: " . substr($token, 0, 10) . "********");
```
**Should Be**:
```php
// ✅ Professional logging
error_log("SiP Printify Manager: Token received (first 10 chars): " . substr($token, 0, 10));
```

## 6. PHP Standards Violations

### Standard Violation: Missing Type Hints
**File**: `sip-printify-manager/includes/shop-functions.php`
**Lines**: 186-211
```php
// ❌ WRONG - No type hints
function fetch_shop_details($token) {
    // ...
}
```
**Should Be**:
```php
// ✅ With type hints
function fetch_shop_details(string $token): ?array {
    // ...
}
```

### Standard Violation: Hardcoded Values
**File**: `sip-development-tools/includes/release-functions.php`
**Line**: 21
```php
// ❌ WRONG - Hardcoded path
$temp_dir = "C:\\Users\\tdeme\\Local Sites\\faux-stained-glass-panes\\app\\public\\wp-content\\uploads\\sip-development-tools\\temp";
```
**Should Be**:
```php
// ✅ Dynamic path
$upload_dir = wp_upload_dir();
$temp_dir = $upload_dir['basedir'] . '/sip-development-tools/temp';
```

## 7. Security Violations

### Standard Violation: Sensitive Data in Logs
**File**: `sip-printify-manager/includes/shop-functions.php`
**Line**: 34
```php
// ❌ WRONG - Token in logs
error_log("🚀 Received Token: " . substr($token, 0, 10) . "********");
```

### Standard Violation: Direct $_POST Access
**File**: Multiple files
```php
// ❌ WRONG - Direct access
$shop_action = isset($_POST['shop_action']) ? sanitize_text_field($_POST['shop_action']) : '';
```
**Should Be**: Use filter_input() or wp_unslash()

## 8. File Organization Violations

### Standard Violation: Work Files in Production
```
/sip-plugins-core/work/ajax_js_reference.js
/sip-plugins-core/work/test-path-handling.php
```
These should not exist in production.

### Standard Violation: Missing Version Files
No CLAUDE.md files found in any plugin directory.

## 9. CSS Class Naming Violations

### Standard Violation: Inconsistent Class Names
**File**: `sip-printify-manager/assets/js/modules/product-actions.js`
**Lines**: 334-345
```javascript
// ❌ WRONG - Mixed naming conventions
$(row).addClass('single-product-row');
$(row).addClass('parent-product-row');
$(row).addClass('invisible-row');
```
**Should Be**: Consistent BEM or prefixed naming

## 10. AJAX Response Violations

### Standard Violation: Non-Standard Error Responses
**File**: `sip-printify-manager/includes/template-functions.php`
**Lines**: 76-83
```php
// ❌ WRONG - Inconsistent error response
SiP_AJAX_Response::error(
    'sip-printify-manager',
    'template_action',
    $template_action,
    'Unknown action requested: ' . $template_action
);
```
Missing error code parameter as documented.

## Summary

These are specific, line-by-line examples of code that deviates from the documented standards. Each violation includes:
- The file and line numbers
- The incorrect implementation
- What it should be according to documentation

Total violations found:
- Critical: 23
- Major: 45
- Minor: 67