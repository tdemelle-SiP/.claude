# SiP Plugin Suite Technical Backlog

This file tracks technical improvements and refactoring ideas for the SiP Plugin Suite.

## High Priority

*Items that should be addressed soon due to bugs or significant issues*

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

### Testing and Debugging Documentation

**Completed Tasks:**
- Created comprehensive `sip-development-testing.md`
- Integrated debug logging system documentation
- Added testing workflows for all environments
- Included common issues with solutions
- Added performance testing guidelines

**Completion Date:** Documentation now complete

