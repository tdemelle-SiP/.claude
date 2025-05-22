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

