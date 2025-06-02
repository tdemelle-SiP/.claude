# SiP Plugin Suite Technical Backlog - Organized & Prioritized

This file tracks technical improvements and refactoring ideas for the SiP Plugin Suite, organized by priority and category.

## 🔴 Critical Priority (P0)
*Must be addressed immediately - blocking issues or critical bugs*

### 1. Fix Debug System Initialization During Shop Loading
**Category:** Bug Fix  
**Impact:** High - Blocks development workflow  
**Effort:** Medium  

**Issue:** Debug logging doesn't work during API token entry and shop loading process. SiP.Core.debug is not available during new_shop action execution.

**Required Actions:**
1. Check debug system initialization order in platform loader
2. Verify debug state synchronization timing during AJAX operations
3. Ensure debug.js loads before plugin-specific scripts
4. Review debug toggle state persistence during page transitions

**Success Criteria:** Debug logs appear immediately during shop loading process

---

## 🟡 High Priority (P1)
*Should be addressed soon - significant improvements or standards compliance*

### 3. Propagate PHP Debug Logging to All SiP Plugins
**Category:** Standards Compliance  
**Impact:** High - Improves debugging  
**Effort:** Medium  

**Issue:** Inconsistent debug logging across PHP files, some using error_log() directly.

**Required Actions:**
1. Search all plugins for error_log() calls
2. Replace with sip_debug() using proper contexts
3. Remove debug code writing to files
4. Update documentation

**Success Criteria:** All PHP debug output uses sip_debug() consistently

---

### 4. Complete Function Documentation (JSDoc/PHPDoc)
**Category:** Documentation  
**Impact:** Medium - Improves maintainability  
**Effort:** Low  

**Issue:** Some functions still missing proper parameter documentation.

**Required Actions:**
1. Audit all JavaScript functions for JSDoc
2. Audit all PHP functions for PHPDoc
3. Add missing documentation
4. Focus on interface contracts, not implementation

**Success Criteria:** 100% of functions have proper documentation

---

### 5. Verify Code Compliance with Documentation
**Category:** Standards Compliance  
**Impact:** High - Ensures accuracy  
**Effort:** Medium  

**Required Actions:**
1. Create compliance checklist from documentation
2. Review all plugin code systematically
3. Update non-conforming code
4. Document any discovered patterns

**Success Criteria:** All code follows documented standards

---

### 6. Dead Code Elimination Audit
**Category:** Code Quality  
**Impact:** High - Reduces confusion and maintenance burden  
**Effort:** Medium  

**Issue:** Discovered functions that appear to create product table rows but aren't actually used. Likely more dead code exists throughout the codebase.

**Required Actions:**
1. Run the automated dead code detection script
2. Create execution traces for all major features
3. Compare function inventory against actual usage
4. Verify suspected dead code with logging
5. Remove confirmed dead code
6. Document what was removed and why

**Tools Created:**
- `/audits/find-dead-functions.js` - Browser-based function tracker
- `/audits/find-unused-functions.sh` - Filesystem-based scanner
- `/audits/dead-code-detection-guide.md` - Comprehensive guide

**Success Criteria:** 
- All unused functions identified and removed
- No functionality broken
- Codebase reduced by at least 10%

---

### 7. Integrate Dead Code Detector into Development Tools
**Category:** Developer Experience  
**Impact:** High - Makes dead code detection accessible to all developers  
**Effort:** Medium  

**Issue:** Current dead code detection requires console access or command line tools. Integration into sip-development-tools dashboard would make it part of standard workflow.

**Required Actions:**
1. Create PHP module: `/includes/dead-code-detector.php`
2. Create JavaScript module: `/assets/js/modules/dead-code-detector.js`
3. Add UI section to development tools dashboard
4. Implement static analysis functionality
5. Add results export capability
6. Update AJAX router for new actions
7. Add appropriate styles
8. Test with all SiP plugins

**Design Completed:**
- `/features/dead-code-detector-integration.md` - Full implementation plan

**Benefits:**
- No console access required
- Visual interface with sortable results
- Part of standard development workflow
- Results can be exported and tracked
- Both static and runtime analysis options

**Success Criteria:**
- Tool accessible from development dashboard
- Can scan any SiP plugin
- Results displayed in sortable table
- Export functionality works
- No false positives in core functionality

---

## 🟢 Medium Priority (P2)
*Important improvements for maintainability and performance*

### 6. Consolidate State Management
**Category:** Code Quality  
**Impact:** Medium - Improves consistency  
**Effort:** Medium  

**Issue:** Direct localStorage access scattered across modules.

**Required Actions:**
1. Create centralized state utilities in SiP Core
2. Update modules to use utilities
3. Remove direct localStorage access
4. Add validation and error handling

**Success Criteria:** All state management goes through centralized utilities

---

### 7. Standardize Error Handling
**Category:** Code Quality  
**Impact:** Medium - Improves debugging  
**Effort:** Medium  

**Issue:** Inconsistent error return formats across functions.

**Required Actions:**
1. Define standard error format for PHP and JS
2. Update all functions to follow standard
3. Create error code constants
4. Document error codes

**Success Criteria:** All errors follow consistent format

---

### 8. Optimize Table Highlighting Performance
**Category:** Performance  
**Impact:** Medium - Better UX  
**Effort:** Medium  

**Issue:** Multiple DOM traversals and redundant operations.

**Required Actions:**
1. Batch table operations
2. Create coordinated highlighting manager
3. Cache jQuery selectors
4. Reduce function call overhead

**Success Criteria:** Table updates complete in <100ms

---

### 9. Standardize DataTable Lifecycle Management
**Category:** Architecture  
**Impact:** Medium - Prevents bugs  
**Effort:** High  

**Issue:** Inconsistent table lifecycle management causing orphaned UI elements.

**Required Actions:**
1. Document cleanup pattern from shop-actions fix
2. Apply defensive UI management to all tables
3. Consider extending SiP.Core.state for tables
4. Update DataTables documentation

**Success Criteria:** No orphaned UI elements after table destruction

---

### 10. Extract Common Code Patterns
**Category:** Code Quality  
**Impact:** Medium - Reduces duplication  
**Effort:** Low  

**Issue:** Repeated validation and ID extraction logic.

**Required Actions:**
1. Create shared validation utilities
2. Extract common patterns
3. Document utilities
4. Update existing code

**Success Criteria:** No duplicate validation logic

---

### 11. Simplify Complex Functions
**Category:** Code Quality  
**Impact:** Medium - Improves readability  
**Effort:** Medium  

**Issue:** Functions doing too many things with deep nesting.

**Required Actions:**
1. Break large functions into smaller ones
2. Extract complex conditionals
3. Apply single responsibility principle
4. Add tests for extracted functions

**Success Criteria:** Average function length <15 lines

---

## 📘 Documentation Priority (P2)
*Documentation improvements for better developer experience*

### 12. Create SiP Printify Manager Quick Reference
**Category:** Documentation  
**Impact:** High - Improves efficiency  
**Effort:** Low  

**Required Actions:**
1. Create 30-second solutions section
2. Add essential patterns checklist
3. Build emergency troubleshooting guide
4. Add visual diagrams

**Success Criteria:** Developers find answers in <60 seconds

---

### 13. Add Progressive Implementation Guides
**Category:** Documentation  
**Impact:** Medium - Better onboarding  
**Effort:** Medium  

**Required Actions:**
1. Create step-by-step guides for key features
2. Add implementation checklists
3. Document common pitfalls
4. Provide working examples

**Success Criteria:** New developers can implement features without help

---

### 14. Create Advanced Topics Section
**Category:** Documentation  
**Impact:** Low - For advanced users  
**Effort:** Medium  

**Required Actions:**
1. Document performance strategies
2. Add extension patterns
3. Include testing strategies
4. Document migrations

**Success Criteria:** Advanced patterns documented

---

## 🔵 Low Priority (P3)
*Nice-to-have improvements*

### 15. Remove Inline JavaScript from Plugin Dashboards
**Category:** Code Quality  
**Impact:** Low - Improves consistency  
**Effort:** Medium  

**Issue:** Some plugins still have inline JavaScript in view files.

**Required Actions:**
1. Extract inline JS to external files
2. Use wp_localize_script() for data
3. Update affected plugins
4. Document as standard

**Success Criteria:** No inline JavaScript in any plugin

---

### 16. Refactor Window Storage to Data Module Pattern
**Category:** Architecture  
**Impact:** Low - Clean code  
**Effort:** High  

**Issue:** Data stored directly on window object.

**Required Actions:**
1. Create data-store.js module
2. Update all window.* references
3. Add validation
4. Consider SiP.Core.state integration

**Success Criteria:** No direct window object storage

---

### 17. Create AI-Specific Quick Start Guide
**Category:** Documentation  
**Impact:** Low - Nice to have  
**Effort:** Low  

**Required Actions:**
1. Create AI-README.md
2. Add quick context
3. Include critical rules
4. Reference main docs

**Success Criteria:** AI agents onboard faster

---

## 📊 Priority Matrix

| Priority | Count | Focus Area |
|----------|-------|------------|
| P0 (Critical) | 2 | Bug fixes, UI issues |
| P1 (High) | 5 | Standards compliance, documentation, dead code, dev tools |
| P2 (Medium) | 11 | Code quality, performance, docs |
| P3 (Low) | 3 | Nice-to-have improvements |

## 🎯 Recommended Execution Order

### Sprint 1 (Week 1)
1. Fix Debug System Initialization (P0)
2. Complete Function Documentation (P1)
3. Create Quick Reference Guide (P2)

### Sprint 2 (Week 2)
1. Fix Creation Table Columns (P0)
2. Propagate PHP Debug Logging (P1)

### Sprint 3 (Week 3)
1. Dead Code Elimination Audit (P1)
2. Verify Code Compliance (P1)
3. Consolidate State Management (P2)

### Sprint 4 (Week 4)
1. Standardize Error Handling (P2)
2. Optimize Table Performance (P2)
3. Extract Common Patterns (P2)

### Future Sprints
- Remaining P2 items
- P3 items as time permits

## ✅ Completed Items
*Move items here when complete, with completion date*

[Previous completed items remain in original backlog.md file]