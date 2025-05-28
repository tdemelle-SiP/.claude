# SiP Plugin Suite Technical Backlog

This file tracks technical improvements and refactoring ideas for the SiP Plugin Suite.

## High Priority

*Items that should be addressed soon due to bugs or significant issues*

### Fix Debug System Initialization During Shop Loading

**Current State:**
- Debug logging doesn't work during API token entry and shop loading process
- SiP.Core.debug is not available during new_shop action execution
- Logs only appear after page reload following shop loading

**Issue Analysis:**
- Debug system appears to initialize after shop loading actions complete
- May be related to timing of when debug state is synchronized
- Could be an issue with debug toggle state not being set before page actions

**Required Investigation:**
1. Check debug system initialization order in platform loader
2. Verify debug state synchronization timing during AJAX operations
3. Ensure debug.js loads before any plugin-specific scripts that might trigger early
4. Review debug toggle state persistence during page transitions

**Priority:** High - Significantly impacts development and debugging workflow

**Related Documentation:** [Debug Logging Guide](./guidelines/sip-development-debug-logging.md)

### Verify Code Compliance with Documentation

**Current State:**
- Documentation is mostly complete
- Need to ensure all plugin code follows documented standards

**Required Tasks:**
1. Create compliance checklist from documentation
2. Review all plugin code systematically
3. Update any non-conforming code
4. Document any discovered patterns not yet covered

**Priority:** High - Ensures documentation accurately reflects code

## Medium Priority

*Improvements that would enhance maintainability or performance*

### Standardize DataTable Lifecycle Management

**Context:**
Successfully resolved duplicate search field issue in sip-printify-manager but revealed broader table lifecycle management patterns that should be standardized across the platform.

**Issue Analysis:**
- **Root Cause Found:** "Clear Shop" action destroyed DataTable instance but orphaned the search field moved to header
- **Sequence:** Initialize table → Move search field to header → Clear shop destroys table → Reload creates new table + new search field → Result: 2 search fields in header
- **Fix Applied:** Added cleanup of moved search fields before table destruction in shop-actions.js

**Current DataTable Lifecycle Patterns:**
1. **Initialization:** Each plugin handles table creation independently
2. **Data Updates:** Mix of table.clear().rows.add() and full reinitialization  
3. **Cleanup:** Inconsistent cleanup of moved UI elements during destruction
4. **State Management:** Tables use individual localStorage keys

**Discovered Standards Gaps:**
1. **No Standard Cleanup Pattern:** When tables move UI elements (search fields, filters), destruction doesn't clean them up
2. **No Centralized Table Registry:** No way to track which tables exist and their state across plugins
3. **Inconsistent Detection Logic:** Mix of `$.fn.DataTable.isDataTable()` and variable checks
4. **No Standard UI Element Management:** Ad-hoc movement of search fields and filters

**Proposed Improvements (Long-term):**

#### Option A: Extend SiP.Core.state with Table Management
Add table-specific utilities to existing SiP.Core.state module:
```javascript
// Add to sip-plugins-core/assets/js/core/state.js
SiP.Core.state.tables = {
    register(pluginName, tableType, config) { /* track table registration */ },
    isInitialized(pluginName, tableType) { /* check if table exists */ },
    destroy(pluginName, tableType) { /* clean destruction with UI cleanup */ },
    cleanupMovedElements(pluginName, tableType) { /* remove orphaned UI elements */ }
};
```

#### Option B: Create Defensive UI Management Pattern
Standardize the initComplete pattern across all tables:
```javascript
initComplete: function() {
    // STANDARD DEFENSIVE PATTERN
    const targetContainer = ".search-target";
    if ($(targetContainer).find(".dt-search").length === 0) {
        // Only move if not already there
        let searchWrapper = $(this.api().table().container()).find(".dt-search");
        searchWrapper.appendTo(targetContainer);
    }
    // Similar pattern for filters
}
```

**Recommended Approach:**
- **Immediate:** Document the cleanup pattern used in the fix as standard practice
- **Phase 1:** Apply defensive UI management pattern to all existing tables  
- **Phase 2:** Consider extending SiP.Core.state if table management becomes more complex

**Affected Components:**
- All plugins with DataTables (sip-printify-manager, others in suite)
- SiP.Core.state module (potential extension)
- DataTables documentation and standards

**Benefits:**
- Prevents UI element orphaning across all plugins
- Establishes consistent table lifecycle patterns
- Leverages existing SiP Core architecture
- Creates foundation for future table management improvements

**Priority:** Medium - Fix implemented, standardization would prevent similar issues in other plugins

**Documentation Updates Needed:**
- Update sip-feature-datatables.md with cleanup patterns
- Add table lifecycle management section
- Document UI element movement best practices

## Creation Table Column Reorganization - Phase 2

### Context
The creation table column reorganization (Phase 1) was partially completed but revealed fundamental structural issues:

1. **Current State**: 
   - Added 3 new columns (row_number, selector, visibility) to align data across row types
   - Template/child summary rows are manually injected after DataTables initialization
   - Content is injected into summary rows via jQuery after table draw
   - CSS uses nth-child selectors for column widths
   - Nested `<td>` elements in print_area causing invalid HTML

2. **Issues Found**:
   - Variant rows have misaligned columns due to print_area HTML structure
   - Tags column not truncating despite CSS rules
   - Title columns expanding inconsistently across row types
   - `table-layout: fixed` only respects first DOM row, not injected rows
   - nth-child selectors are fragile and hard to maintain

### Proposed Solution

#### 1. Fix Immediate Issues
- **Fix nested TD bug**: Modify `buildImageCells()` to not create `<td>` elements
- **Replace nth-child with column classes**: Use `.title-column`, `.tags-column` etc for all column styling
- **Ensure consistent data formatting**: All data should be formatted before passing to DataTables

#### 2. Restructure Using DataTables Conventions

**Current Approach (problematic):**
```javascript
// In initComplete
api.row.add(variantData); // Add variant rows
api.draw();
buildTemplateSummaryCells(); // Manually inject content
buildChildProductSummaryCells(); // More manual injection
```

**Proposed Approach:**
```javascript
// In rowGroup.startRender
return `<tr class="template-summary-row">
    <td class="row-number-column"></td>
    <td class="select-column"></td>
    <!-- ... all 12 cells with classes but empty content ... -->
</tr>`;

// After draw, inject content into existing structure
$('.template-summary-row .colors-column').html(colorSwatches);
```

**Benefits:**
- DataTables manages all row structure
- Consistent column count guaranteed
- `table-layout: fixed` works properly
- Sorting can be triggered after content injection

#### 3. Implementation Steps

1. **Update rowGroup.startRender** (creation-table-setup-actions.js lines 322-387):
   - Create full 12-column structure with empty cells
   - Add all necessary classes to cells
   - Remove inline content generation

2. **Fix buildImageCells** (creation-table-setup-actions.js line 1507):
   - Change from creating `<td>` to creating `<div>` wrapper only
   - Ensure image selection functionality preserved

3. **Update CSS** (tables.css):
   - Replace all nth-child selectors with class-based selectors
   - Ensure truncation works on injected content
   - Test with `table-layout: fixed`

4. **Test injection timing**:
   - Verify content injection works after draw
   - Add `api.draw()` after injection to resort if needed
   - Confirm state management (expand/collapse) still works

### Files to Modify
1. `/assets/js/modules/creation-table-setup-actions.js`
   - Lines 322-387 (rowGroup.startRender)
   - Lines 1507-1545 (buildImageCells)
   - Lines 773-896 (buildTemplateSummaryCells)
   - Lines 1239-1498 (buildChildProductSummaryCells)

2. `/assets/css/modules/tables.css`
   - Lines 707-777 (column width definitions)
   - Remove all creation table nth-child selectors
   - Add class-based column width rules

### Testing Checklist
- [ ] All row types have 12 columns
- [ ] Tags column truncates properly
- [ ] Title column maintains consistent width
- [ ] Print area shows images without nested TDs
- [ ] Row selection works correctly
- [ ] Expand/collapse functionality preserved
- [ ] Sorting works after content injection
- [ ] No JavaScript errors in console

### Notes
- Current truncation of description to 100 chars in JS should remain
- Consider applying similar truncation to tags in JavaScript
- Image selection code in image-actions.js (line 780) uses `.image-cell input.creation-table-image-select` - must preserve this structure

**Priority:** High - Current implementation has fundamental structural issues affecting usability

## Low Priority / Future Enhancements

*Nice-to-have improvements for future consideration*

### Refactor Window Storage to Data Module Pattern

**Current State:**
- Data is stored directly on the window object (`window.masterTemplateData`, etc.)
- No encapsulation or validation
- Global namespace pollution

**Proposed Solution:**
Create dedicated data modules using the module pattern:

```javascript
// /assets/js/modules/data-store.js
SiP.PrintifyManager.dataStore = (function() {
    let templates = [];
    let images = [];
    let products = [];
    
    return {
        init(data) { /* ... */ },
        getTemplates() { /* ... */ },
        getImages() { /* ... */ },
        // etc.
    };
})();
```

**Benefits:**
- Proper encapsulation
- Data validation
- Better debugging
- Prevents external modification
- Could integrate with SiP.Core.state system

**Scope:**
- Create data-store.js module
- Update all references from window.* to dataStore methods
- Add validation and error handling
- Consider using SiP.Core.state for persistence

**Affected Files:**
- Most JavaScript files that currently use window storage
- Would require systematic refactoring

**Priority:** Low - Current window storage works, this is a clean code improvement

### Remove Inline JavaScript from Plugin Dashboard Views

**Current State:**
- Several plugins have inline JavaScript in their dashboard view files:
  - `sip-woocommerce-monitor/views/dashboard-html.php` (lines 154-378)
  - `sip-plugins-core/sip-plugins-core.php` (lines 198-461)
- `sip-development-tools` already follows best practices

**Proposed Solution:**
Apply the same pattern used in sip-printify-manager:
1. Move inline JavaScript to external .js files
2. Use `wp_localize_script()` to pass PHP data to JavaScript
3. Enqueue scripts properly with dependencies

**Example Implementation:**
```php
// In PHP enqueue method
wp_localize_script('sip-monitor-main', 'sipMonitorData', array(
    'settings' => $settings,
    'nonce' => wp_create_nonce('sip-monitor-nonce')
));
```

```javascript
// In external JS file
(function() {
    if (window.sipMonitorData) {
        // Initialize with localized data
        const settings = sipMonitorData.settings;
        const nonce = sipMonitorData.nonce;
    }
})();
```

**Benefits:**
- Consistent architecture across all plugins
- Better security (CSP compliance)
- Improved caching
- Easier maintenance
- Follows WordPress best practices

**Scope:**
- sip-woocommerce-monitor: Extract tab functionality, AJAX calls, and event handling
- sip-plugins-core: Extract plugin management JavaScript
- Update documentation to reflect this as standard practice

**Priority:** Medium - Improves consistency across the plugin suite

## Completed Items

*Documentation and tasks that have been completed*

### Fix WordPress Plugin Update Cleanup Failures

**Issue:**
WordPress failing to delete 60+ files during SiP plugin updates, causing persistent update buttons and cleanup errors. Console showing multiple `unlink(): No such file or directory` errors during plugin update process.

**Error Pattern:**
```
unlink(/home/fsgpadmin/public_html/wp-content/upgrade/[plugin-folder]/[file]): No such file or directory
- Multiple files across various plugin updates
- Persistent "Update" buttons despite successful version changes
- Cleanup process failing consistently
```

**Root Cause Analysis:**
The direct update mechanism in `/sip-plugins-core/includes/core-ajax-shell.php` was experiencing cleanup failures due to concurrent plugin upgrades and insufficient cleanup parameters:

```php
// PROBLEMATIC - Missing cleanup parameters  
$upgrader = new Plugin_Upgrader(new WP_Ajax_Upgrader_Skin());
$result = $upgrader->install($download_url, array('overwrite_package' => true));
```

**Technical Problem:**
- **Concurrent upgrade conflicts:** Multiple plugin updates cause file deletion conflicts in `/wp-content/upgrade/`
- **Insufficient cleanup parameters:** Missing `clear_destination` and `abort_if_destination_exists` settings
- **Orphaned temporary files:** Previous failed upgrades leaving files that conflict with new upgrades
- **WordPress core bug #53705:** Documented issue with concurrent upgrades causing cleanup failures

**Note on upgrade() method:** 
Initially considered using `Plugin_Upgrader->upgrade()`, but this requires WordPress to already know about updates via the `update_plugins` transient, which defeats the purpose of the direct update tool that bypasses WordPress's update cache.

**Solution Applied:**
Enhanced the `install()` method with proper cleanup and parameters:

```php
// Clear upgrade directory before starting to prevent concurrent upgrade conflicts
$upgrade_dir = WP_CONTENT_DIR . '/upgrade/';
if (is_dir($upgrade_dir)) {
    $temp_files = glob($upgrade_dir . '*');
    foreach ($temp_files as $temp_file) {
        if (is_dir($temp_file)) {
            // Only remove directories older than 1 hour to avoid concurrent conflicts
            if (filemtime($temp_file) < (time() - 3600)) {
                wp_delete_file_from_directory($temp_file, true);
            }
        }
    }
}

$upgrader = new Plugin_Upgrader(new WP_Ajax_Upgrader_Skin());
$result = $upgrader->install($download_url, array(
    'overwrite_package' => true,
    'clear_destination' => true,
    'abort_if_destination_exists' => false,
    'clear_update_cache' => true
));
```

**Why This Fixes The Issue:**
- **Prevents concurrent conflicts:** Pre-cleans old temporary files before starting
- **Proper cleanup parameters:** `clear_destination` and `abort_if_destination_exists` settings
- **Maintains independence:** Still bypasses WordPress update cache/transients
- **Addresses WordPress core bug:** Implements recommended cleanup strategy

**Files Modified:**
- `/sip-plugins-core/includes/core-ajax-shell.php` (lines 183-204) - Added pre-upgrade cleanup and enhanced install() parameters

**Testing Expected:**
- Plugin updates should complete without cleanup errors
- Update buttons should clear properly after successful updates  
- No more `unlink()` file deletion failures
- Proper WordPress update process flow

**Impact:**
- Fixes all SiP plugin update cleanup issues
- Eliminates persistent update button problems
- Ensures proper WordPress update compliance
- Prevents temporary file accumulation

**Completion Date:** May 2025

### Fix Production Console Errors from Debug File Writes

**Issue:** 
Console errors on live site caused by debug file_put_contents() calls attempting to write to non-existent directory paths in production environment.

**Error Messages:**
```
file_put_contents(/home/fsgpadmin/public_html/wp-c... Failed to open stream: No such file or directory
- Line 890: input_data.json
- Line 996: after_processing_placeholders.json  
- Line 1038: final_output.json
```

**Root Cause Analysis:**
- Debug file writes were executing in production environment
- `WP_CONTENT_DIR` constant resolving to production server path instead of expected local path
- Function `transform_product_data()` in `product-functions.php` contained debug code that wasn't environment-aware

**Investigation Process:**
1. Identified errors were occurring on live site, not local development
2. Located problematic debug file writes in `transform_product_data()` function
3. Found related issue with provisional gallery feature using same problematic pattern

**Solutions Applied:**

#### 1. Product Functions Debug Writes (Temporary Fix)
Added environment detection to prevent debug writes in production:
```php
// Development-only debug output
if (defined('WP_DEBUG') && WP_DEBUG && !defined('WP_ENVIRONMENT_TYPE') || (defined('WP_ENVIRONMENT_TYPE') && WP_ENVIRONMENT_TYPE !== 'production')) {
    $debug_dir = ABSPATH . 'wp-content/debug';
    if (!file_exists($debug_dir)) {
        wp_mkdir_p($debug_dir);
    }
    file_put_contents($debug_dir . '/input_data.json', json_encode($product, JSON_PRETTY_PRINT));
}
```

#### 2. Gallery Feature (Root Fix)
Disabled provisional gallery shortcode that was using same problematic pattern:
```php
// Temporarily disabled - causes WP_CONTENT_DIR path issues in production
// add_shortcode('sip_gallery', 'sip_printify_manager_gallery_shortcode');

function sip_printify_manager_gallery_shortcode() {
    return '<p>Gallery feature temporarily disabled.</p>';
    // return generate_image_gallery_from_directory();
}
```

**Files Modified:**
- `/sip-printify-manager/includes/product-functions.php` - Added environment checks to debug writes
- `/sip-printify-manager/includes/image-functions.php` - Disabled gallery shortcode registration

**Approach Rationale:**
- **Product functions:** Used environment detection as temporary fix since this debug code may be useful for development
- **Gallery feature:** Completely disabled since it was provisional and not in use yet
- **Root cause:** WP_CONTENT_DIR path issue left unresolved as it may indicate broader configuration issue

**Testing:**
- Confirmed console errors eliminated on live site
- Debug functionality preserved for development environments
- No impact on existing functionality since gallery was provisional

**Future Considerations:**
- Debug code in product functions should eventually be removed or made more robust
- Gallery feature needs proper path handling when development resumes
- Root WP_CONTENT_DIR configuration issue should be investigated if other instances occur

**Completion Date:** May 2025

### Fix Duplicate Search Fields in Image DataTable

**Issue:** 
Duplicate search fields appearing in image table header after entering API token and loading new shop in sip-printify-manager.

**Root Cause Analysis:**
- Initial page load: Table initialized with search field moved to header
- "Clear Shop" action: DataTable.destroy() called but search field orphaned in header  
- "Load New Shop" action: New table created with new search field → moved to header with existing field
- Result: Two search fields in same location

**Investigation Process:**
1. Added console.log debugging to trace execution flow during shop loading
2. Identified that `$.fn.DataTable.isDataTable('#image-table')` returned false after table destruction
3. Traced exact sequence through stack traces showing table destruction → reinitialization cycle
4. Found orphaned search field remaining in DOM after table cleanup

**Solution Applied:**
Added cleanup of moved UI elements before table destruction in shop-actions.js:
```javascript
// CLEANUP: Remove the search field that was moved to the header before destroying the table
$('.image-header-left-top h2 .dt-search').remove();
$('#image-table').DataTable().destroy();
```

**Files Modified:**
- `/sip-printify-manager/assets/js/modules/shop-actions.js` - Added search field cleanup in clear shop action

**Testing:**
- Verified fix prevents duplicate search fields during shop loading cycle
- Confirmed normal table functionality remains intact
- No side effects on other table operations

**Completion Date:** January 2025

### Testing and Debugging Documentation

**Completed Tasks:**
- Created comprehensive `sip-development-testing.md`
- Integrated debug logging system documentation
- Added testing workflows for all environments
- Included common issues with solutions
- Added performance testing guidelines

**Completion Date:** Documentation now complete

