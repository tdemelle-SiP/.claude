# SiP Plugin Suite Technical Backlog

This file tracks technical improvements and refactoring ideas for the SiP Plugin Suite.

## High Priority

*Items that should be addressed soon due to bugs or significant issues*

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