## Task: Implement Mockup Selection and Product Publishing for SiP Printify Manager
**Date Started:** 2025-06-29 15:58

### Task Understanding
**What:** Design and implement a mockup selection interface that allows users to select which mockups they want associated with template child products before publication, and implement the product publishing functionality. Both features require integration with the sip-printify-manager-extension to make internal Printify API calls.

**Why:** The Printify Public API doesn't support removing/adding mockups or publishing products. This functionality is critical for completing the product creation workflow, allowing users to control which mockups are shown for their products and publish them when ready.

**Success Criteria:** 
1. Users can select mockups for templates with changes saved to template.json
2. Selected mockups are applied to all unpublished child products via extension
3. Users can publish products through the extension
4. Both processes have progress dialogs with proper logging
5. Code follows SiP platform standards and patterns

### Documentation Review
- [x] Coding_Guidelines_Snapshot.txt
- [x] index.md 
- [x] working-task-planning-template.md
- [x] sip-printify-manager-guidelines.md
- [x] sip-printify-manager-extension-widget.md
- [ ] sip-plugin-ajax.md
- [ ] sip-core-feature-ui-components.md
- [ ] sip-core-feature-progress-dialog.md
- [ ] sip-plugin-data-storage.md

### Files to Modify
1. `/sip-printify-manager/includes/template-functions.php` - Add mockup selection data handling
2. `/sip-printify-manager/includes/mockup-functions.php` - Add mockup selection operations
3. `/sip-printify-manager/includes/product-functions.php` - Add publishing operations
4. `/sip-printify-manager/assets/js/modules/template-actions.js` - Add mockup selection UI
5. `/sip-printify-manager/assets/js/modules/mockup-actions.js` - Add mockup selection dialog
6. `/sip-printify-manager/assets/js/modules/product-actions.js` - Add publishing functionality
7. `/sip-printify-manager/assets/css/modules/modals.css` - Add styles for mockup selection
8. Extension files (to be identified) - Add internal API calls for mockups and publishing

### Implementation Plan

**Phase 1: Mockup Selection Interface**
1. Add "Select Mockups" action to template table
2. Create modal dialog showing available mockups from blueprint
3. Load existing mockup data from local storage
4. Allow checkbox selection of desired mockups
5. Save selections to template.json with new `mockup_selection` field
6. Show visual indicator on templates with configured mockups

**Phase 2: Mockup Update via Extension**
1. Create progress dialog for batch mockup updates
2. Identify unpublished child products for the template
3. Send `SIP_UPDATE_PRODUCT_MOCKUPS` message to extension
4. Extension navigates to each product's mockup configuration page
5. Extension makes internal API calls to remove/add mockups
6. Report success/failure for each product
7. Provide retry option for failed updates

**Phase 3: Product Publishing**
1. Add "Publish" action to product table for unpublished products
2. Support bulk selection for publishing multiple products
3. Create progress dialog for batch publishing
4. Send `SIP_PUBLISH_PRODUCTS` message to extension
5. Extension makes internal API calls to publish products
6. Update product status to `publish_in_progress` then `published`
7. Report success/failure with retry options

### Key Architecture Decisions

**Template-Level Mockup Control**
- Mockup preferences stored at template level, not per product
- Ensures consistency across all products from a template
- Reduces configuration effort (configure once, apply to many)

**Extension Message Format**
```javascript
// Mockup Update
{
    type: 'SIP_UPDATE_PRODUCT_MOCKUPS',
    source: 'sip-printify-manager',
    requestId: 'unique-id',
    data: {
        product_id: 'wp-product-id',
        printify_product_id: 'printify-id',
        shop_id: 'shop-id',
        selected_mockups: [...]
    }
}

// Product Publishing
{
    type: 'SIP_PUBLISH_PRODUCTS',
    source: 'sip-printify-manager',
    requestId: 'unique-id',
    data: {
        products: [...],
        shop_id: 'shop-id'
    }
}
```

**Progress Dialog Pattern**
- Use existing `SiP.Core.progressDialog.processBatch()`
- Show real-time progress for each item
- Capture detailed logs for debugging
- Provide summary with retry options

### Critical Implementation Notes

1. **No Backward Compatibility** - Update all code to new patterns immediately
2. **Status Management** - Use `SiP_Product_Status` class constants only
3. **Extension Detection** - Extension must announce itself each page load
4. **AJAX Pattern** - Follow three-level action structure documented in sip-plugin-ajax.md
5. **UI Components** - Use SiP.Core utilities for all UI operations
6. **Error Handling** - Individual failures don't stop batch operations

### Research Requirements

1. **Printify Internal APIs** - Need to identify exact endpoints for:
   - Mockup configuration management
   - Product publishing
   
2. **Extension Capabilities** - Verify extension can:
   - Navigate to product mockup pages
   - Make internal API calls
   - Handle batch operations efficiently

### Questions Resolved

1. **Mockup changes apply to unpublished products only** - Published products should not be modified
2. **Template.json structure extended with `mockup_selection` field** - Maintains compatibility
3. **Extension uses push-driven communication** - WordPress initiates, extension responds
4. **Progress dialogs follow existing mockup fetching patterns** - Consistent UX

### Next Steps

After documentation updates are complete:
1. Begin Phase 1 implementation (mockup selection interface)
2. Test with existing mockup data
3. Coordinate with user on extension API research
4. Implement Phase 2 and 3 based on API findings