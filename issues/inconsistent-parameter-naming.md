# Inconsistent Parameter Naming Issue

## Problem
The codebase uses two different parameter names for the same purpose when passing template names in AJAX requests:
- `template_title` - Used in template-actions.js
- `creation_template_wip_name` - Used in creation-table-actions.js, json-editor-actions.js, sync-products-to-shop-actions.js

## Current State
The PHP code in `sip_check_and_load_template_wip()` checks for both to maintain compatibility:
```php
$template_name = isset($_POST['template_title']) ? 
    sanitize_text_field($_POST['template_title']) : 
    (isset($_POST['creation_template_wip_name']) ? 
        sanitize_text_field($_POST['creation_template_wip_name']) : null);
```

## Impact
- Confusing for developers
- Requires extra checking logic
- Makes the codebase less maintainable

## Recommendation
Standardize on a single parameter name across all JavaScript files. Since we're already using `basename` as the standardized way to handle template names, consider:
1. Use `template_name` consistently (aligns with function parameter)
2. OR use `template_basename` to be explicit about what's being passed

## Files Affected
- `/assets/js/modules/template-actions.js` - Uses `template_title`
- `/assets/js/modules/creation-table-actions.js` - Uses `creation_template_wip_name`
- `/assets/js/modules/json-editor-actions.js` - Uses `creation_template_wip_name`
- `/assets/js/modules/sync-products-to-shop-actions.js` - Uses `creation_template_wip_name`
- `/includes/creation-table-setup-functions.php` - Checks both parameters

## Note
This is not backward compatibility code - it's an inconsistency that should be addressed to improve code clarity and maintainability.