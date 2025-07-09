# Mockup Synchronization Solution Plan

## Problem Summary
The Chrome extension's mockup synchronization feature shows "15 mockups to sync" but then reports "Adding 0, removing 0". This is because the mockup IDs from WordPress don't match what the content script expects on the Printify page.

## Root Cause
1. WordPress sends mockup IDs from blueprint example products (format: `blueprintProductId_variantId_sceneId_cameraAngle`)
2. The Printify page has different product IDs but the same variant and scene IDs
3. The content script was trying to match full IDs instead of matching by variant+scene combination
4. Chrome.runtime is blocked on Printify, so all data must flow through URL parameters

## Key Discoveries

### Mockup ID Structure
- **WordPress format**: `681e609756bd6df293015d73_72180_102756_left`
  - Part 1: Blueprint product ID (different from current product)
  - Part 2: Variant ID (e.g., 72180 = specific color like Black)
  - Part 3: Scene ID (e.g., 102756 = camera angle like Left)
  - Part 4: Camera angle label (e.g., "left", "context-2")

- **Printify page format**: Image URLs like `/mockup/{productId}/{variantId}/{sceneId}/`
  - Extract these to build ID: `mockup_${variantId}_${sceneId}_${productId}`

### Scene ID Mapping
```
102752 = Front
102754 = Right  
102756 = Left
102758 = Back
102760 = Context 1
102762 = Context 2
```

### Variant ID Mapping (Examples from testing)
```
72180 = Black
72182 = Navy
72183 = Pink
72184 = Red
105888 = Light Blue
108906 = Orange
108907 = Purple
108908 = Yellow
```

### Page Structure
- Multiple grids exist (typically 9), but only Grid 0 has checkboxes
- Each scene has its own view that must be navigated to
- Scene buttons: `button[data-testid="viewTypeCard"]`
- Active grid: `document.querySelectorAll('[data-testid="mockupItemsGrid"]')[0]`

## Proven Solution

### Test Results
Created test scripts that successfully:
1. Parsed WordPress mockup IDs to extract variant and scene IDs
2. Navigated to the correct scenes (Left, Context 2)
3. Found all 15 mockups by matching variant+scene IDs
4. Confirmed the checkboxes could be selected

### Implementation Steps

1. **Update the content script** (`mockup-library-actions.js`):
   ```javascript
   // Parse WordPress mockup IDs
   const desiredMockups = wordpressMockupIds.map(wpId => {
       const parts = wpId.split('_');
       return {
           variantId: parts[1],
           sceneId: parts[2]
       };
   });
   
   // Group by scene
   const mockupsByScene = {};
   desiredMockups.forEach(m => {
       if (!mockupsByScene[m.sceneId]) {
           mockupsByScene[m.sceneId] = [];
       }
       mockupsByScene[m.sceneId].push(m.variantId);
   });
   ```

2. **Navigate to each scene and synchronize**:
   - Click scene button to navigate
   - Wait for grid to load
   - Find mockups matching the variant IDs for that scene
   - Select/deselect as needed
   - Move to next scene

3. **Save after all scenes are processed**

### Code Location
- Content script: `/action-scripts/mockup-library-actions.js`
- Function to update: `synchronizeMockupSelections()`
- Current issue: Lines 484-492 where it tries to match full IDs

## Test Scripts Created
1. `test-mockup-matching.js` - Proves variant IDs don't match without scene navigation
2. `test-mockup-scene-navigation.js` - Proves the solution works by navigating scenes

## Default/Primary Image Selection

### Additional Requirement
The WordPress mockup selector allows choosing a default/primary image, but this is set on a different page:
- **Product details page**: `https://printify.com/app/product-details/{productId}`
- This is separate from the mockup library page where mockups are selected

### Implementation Approach
1. After saving mockup selections on the mockup library page
2. Navigate to the product details page
3. Find and set the primary/default image based on WordPress selection
4. Save the changes

### Data Structure
WordPress sends default mockup info in the selected mockups array:
```javascript
{
    id: "mockup_id_here",
    variant_ids: [],
    is_default: true,  // This indicates the default/primary image
    // ... other properties
}
```

### Product Details Page Structure
Based on investigation, the primary image selection works as follows:

1. **Page URL**: `https://printify.com/app/product-details/{productId}`
2. **Color tabs**: Buttons at top with text like "11oz, Black", "11oz, Pink", etc.
3. **Star buttons**: Each mockup has a star button with class `button icon-only-button secondary small`
4. **Primary indicator**: 
   - Primary mockup has star with class `label-button-icon filled notranslate`
   - Non-primary mockups have star with class `icon outlined notranslate`

### Implementation Steps for Primary Selection
1. Navigate to product details page after saving mockup selection
2. Parse the default mockup from WordPress data (has `is_default: true`)
3. Extract variant ID from the default mockup ID
4. Click the appropriate color tab if needed
5. Find the star button for that variant:
   ```javascript
   // Find button with star icon for specific variant
   const starButton = Array.from(document.querySelectorAll('button.icon-only-button'))
     .find(btn => {
       const container = btn.closest('[class*="mockup"]');
       const img = container?.querySelector('img');
       return img?.src.includes(`/${variantId}/`);
     });
   ```
6. Click the star button to set as primary
7. Save changes (if there's a save button)

## Next Steps
1. Update `mockup-library-actions.js` to implement the scene navigation approach
2. Add navigation to product details page for default image selection
3. Test with various products to ensure reliability
4. Handle edge cases (scene not found, navigation failures, etc.)

## Important Notes
- The mockup picker in WordPress shows example mockups from a blueprint, not actual product mockups
- Variant IDs are consistent between WordPress and Printify (they came from Printify originally)
- Must handle multiple scenes - can't just look at the currently visible grid
- All communication must go through URL parameters due to chrome.runtime blocking
- Default/primary image selection requires navigating to a separate page after mockup selection