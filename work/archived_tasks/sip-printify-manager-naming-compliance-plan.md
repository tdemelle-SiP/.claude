# SiP Printify Manager - Naming Compliance Implementation Plan

## Overview

This document outlines the implementation plan to bring the SiP Printify Manager plugin to 100% compliance with the documented naming conventions. Based on the validation performed on 2025-07-02, the plugin is currently at 85-90% compliance with minor deviations primarily in function naming.

## Executive Summary

**Current Compliance**: 85-90%
**Target Compliance**: 100%
**Risk Level**: Low (cosmetic changes only)
**Estimated Time**: 4-6 hours
**Priority**: Medium

## Non-Compliant Items Requiring Changes

### 1. PHP Function Names Missing `sip_` Prefix (17 functions)

The following functions need to be renamed to include the `sip_` prefix:

| Current Name | Required Name | File Location |
|-------------|---------------|---------------|
| `clear_product_jsons()` | `sip_clear_product_jsons()` | product-functions.php |
| `format_products_for_table()` | `sip_format_products_for_table()` | product-functions.php |
| `save_products_to_database()` | `sip_save_products_to_database()` | product-functions.php |
| `save_products_to_json()` | `sip_save_products_to_json()` | product-functions.php |
| `transform_product_data()` | `sip_transform_product_data()` | product-functions.php |
| `get_template_count()` | `sip_get_template_count()` | template-functions.php |
| `fetch_images()` | `sip_fetch_images()` | image-functions.php |
| `generate_image_gallery_from_directory()` | `sip_generate_image_gallery_from_directory()` | image-functions.php |
| `map_printify_to_internal()` | `sip_map_printify_to_internal()` | utility-functions.php |
| `map_internal_to_printify()` | `sip_map_internal_to_printify()` | utility-functions.php |
| `compare_templates()` | `sip_compare_templates()` | template-functions.php |
| `array_diff_assoc_recursive()` | `sip_array_diff_assoc_recursive()` | utility-functions.php |
| `is_valid_child_product()` | `sip_is_valid_child_product()` | product-functions.php |
| `normalize_print_areas()` | `sip_normalize_print_areas()` | product-functions.php |
| `getPrintAreaImageCount()` | `sip_get_print_area_image_count()` | product-functions.php |
| `assemble_product_json()` | `sip_assemble_product_json()` | product-functions.php |
| `validate_template_structure()` | `sip_validate_template_structure()` | template-functions.php |

### 2. JavaScript Module File Naming (1 file)

| Current Name | Required Name | Location |
|-------------|---------------|----------|
| `browser-extension-manager.js` | `browser-extension-actions.js` | assets/js/modules/ |

### 3. PHP File Naming (1 file)

| Current Name | Required Name | Location |
|-------------|---------------|----------|
| `admin-notices.php` | `admin-notices-functions.php` | includes/ |

### 4. Missing Error Logging Setup

Add error logging initialization to `sip-printify-manager.php`:
```php
// Error logging setup
ini_set('error_log', plugin_dir_path(__FILE__) . 'logs/php-errors.log');
ini_set('log_errors', 1);
ini_set('display_errors', 0);
```

### 5. Missing Global Constants

Consider adding plugin-level constants to `sip-printify-manager.php`:
```php
define('SIP_PRINTIFY_MANAGER_VERSION', '4.5.9');
define('SIP_PRINTIFY_MANAGER_PATH', plugin_dir_path(__FILE__));
define('SIP_PRINTIFY_MANAGER_URL', plugin_dir_url(__FILE__));
```

## Implementation Plan

### Phase 1: Preparation (30 minutes)
1. Create a backup of the current plugin
2. Set up a testing environment
3. Create a Git branch: `feature/naming-compliance`
4. Document all function calls that will need updating

### Phase 2: PHP Function Renaming (2-3 hours)

#### Step 1: Rename Functions in Definition Files
1. Open each PHP file containing non-compliant functions
2. Rename function definitions to include `sip_` prefix
3. Update any PHPDoc comments

#### Step 2: Update Function Calls
Search and replace all function calls throughout the codebase:

```bash
# Example search commands to find all occurrences
grep -r "clear_product_jsons(" .
grep -r "format_products_for_table(" .
# ... repeat for each function
```

Files likely to contain function calls:
- All files in `/includes/`
- `printify-ajax-shell.php`
- Any test files

#### Step 3: Special Case - camelCase to snake_case
- Change `getPrintAreaImageCount()` to `sip_get_print_area_image_count()`
- This requires both prefix addition AND case conversion

### Phase 3: File Renaming (30 minutes)

#### JavaScript Module
1. Rename `browser-extension-manager.js` to `browser-extension-actions.js`
2. Update any references in:
   - `main.js`
   - Any HTML files that might load this script
   - `functions.php` or wherever scripts are enqueued

#### PHP File
1. Rename `admin-notices.php` to `admin-notices-functions.php`
2. Update any `include` or `require` statements that reference this file
3. Check the main plugin file and any initialization code

### Phase 4: Add Missing Elements (30 minutes)

#### Error Logging Setup
Add to `sip-printify-manager.php` after the security check:
```php
// Error logging setup
$log_dir = plugin_dir_path(__FILE__) . 'logs';
if (!file_exists($log_dir)) {
    wp_mkdir_p($log_dir);
}
ini_set('error_log', $log_dir . '/php-errors.log');
ini_set('log_errors', 1);
ini_set('display_errors', 0);
```

#### Global Constants
Add to `sip-printify-manager.php` after the plugin header:
```php
// Plugin constants
define('SIP_PRINTIFY_MANAGER_VERSION', '4.5.9');
define('SIP_PRINTIFY_MANAGER_PATH', plugin_dir_path(__FILE__));
define('SIP_PRINTIFY_MANAGER_URL', plugin_dir_url(__FILE__));
define('SIP_PRINTIFY_MANAGER_BASENAME', plugin_basename(__FILE__));
```

### Phase 5: Testing (1-2 hours)

#### Functional Testing
1. Test all AJAX operations
2. Verify all renamed functions work correctly
3. Check that renamed files load properly
4. Test error logging functionality
5. Verify constants are accessible where needed

#### Regression Testing
1. Create new products
2. Edit existing products
3. Delete products
4. Template operations
5. Image operations
6. Shop operations
7. Browser extension functionality

### Phase 6: Documentation Updates (30 minutes)
1. Update any inline documentation
2. Update README if function names are mentioned
3. Update any API documentation
4. Add changelog entry

## Risk Mitigation

### Potential Risks
1. **Broken Function Calls**: Missing a function call during search/replace
2. **JavaScript Loading Issues**: Script enqueue paths not updated
3. **Include Path Issues**: PHP file includes not updated
4. **Third-party Integration**: External code calling our functions

### Mitigation Strategies
1. Use IDE's "Find Usages" feature for each function
2. Implement changes incrementally and test after each group
3. Use version control to track all changes
4. Run automated tests if available
5. Keep detailed notes of all changes made

## Rollback Plan
If issues are discovered after deployment:
1. Revert to previous Git commit
2. Restore from backup if needed
3. Document any issues found for future reference

## Success Criteria
- [x] All 17 PHP functions renamed with `sip_` prefix
- [x] JavaScript module file renamed to follow `-actions.js` pattern
- [x] PHP file renamed to follow `-functions.php` pattern
- [x] Error logging setup added and tested
- [x] Global constants defined and accessible
- [ ] All functionality tested and working
- [ ] No PHP errors or warnings
- [ ] No JavaScript console errors

## Timeline
- **Day 1**: Phases 1-3 (Function and file renaming)
- **Day 2**: Phases 4-5 (Add missing elements and testing)
- **Day 3**: Phase 6 and final review

## Notes
- Consider using a code migration tool or script for bulk renaming
- Coordinate with team members who might be working on the same files
- Consider implementing a pre-commit hook to enforce naming conventions going forward

---

Document prepared: 2025-07-02
Estimated completion: 3 days from start
Priority: Medium (no functional impact, only naming compliance)

## Implementation Progress

### Phase 1-4 Completed: 2025-07-02
- ✅ All 17 PHP functions renamed with `sip_` prefix
- ✅ JavaScript module file renamed: browser-extension-manager.js → browser-extension-actions.js
- ✅ PHP file renamed: admin-notices.php → admin-notices-functions.php
- ✅ Error logging setup added to main plugin file
- ✅ Global constants defined (SIP_PRINTIFY_MANAGER_VERSION, _PATH, _URL, _BASENAME)
- ✅ All file references updated in sip-printify-manager.php

### Next Steps
1. Test all functionality to ensure no breaking changes
2. Check for PHP errors and warnings
3. Verify JavaScript console has no errors
4. Run through key workflows:
   - Product management
   - Template creation and editing
   - Image operations
   - Shop synchronization
   - Browser extension functionality