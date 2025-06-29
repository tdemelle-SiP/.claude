## Task: Fix CSP Error in SiP Printify Manager Browser Extension Manager
**Date Started:** 2025-06-29 01:36

### Task Understanding
**What:** Fix Content Security Policy (CSP) errors caused by inline styles in the browser-extension-manager.js file that prevent the extension installation wizard from displaying properly.

**Why:** WordPress environments with strict CSP settings block inline styles for security reasons, causing the extension installation wizard to fail to render correctly.

**Success Criteria:** 
- Remove all inline styles from JavaScript-generated HTML
- Move styles to external CSS file
- Ensure wizard displays and functions correctly
- Maintain all existing functionality

### Documentation Review
- [x] Working Task Planning Template
- [x] SiP Printify Manager Extension Widget Guidelines
- [x] Index.md - Documentation structure

### Files to Modify
1. `/mnt/c/Users/tdeme/Local Sites/faux-stained-glass-panes/app/public/wp-content/plugins/sip-printify-manager/assets/js/modules/browser-extension-manager.js`
2. `/mnt/c/Users/tdeme/Local Sites/faux-stained-glass-panes/app/public/wp-content/plugins/sip-printify-manager/assets/css/browser-extension.css`

### Implementation Plan
1. [x] Identify all inline styles in browser-extension-manager.js
2. [x] Create CSS classes for each inline style
3. [x] Add CSS classes to browser-extension.css
4. [x] Replace inline styles with CSS classes in JavaScript
5. [ ] Test wizard functionality
6. [ ] Verify CSP compliance

### Inline Styles Found
1. Line 375: `style="width: 33.33%"` - Progress bar initial width
2. Line 380: `style="display: none;"` - Previous button initial state
3. Line 387: `style="display: none;"` - Finish button initial state
4. Line 520: `.css('width', percentage + '%')` - Dynamic progress bar width
5. Line 558-564: Multiple inline styles in reload notice dialog
6. Line 562: Dynamic background image URL for spinner

### Questions/Blockers
- Need to handle dynamic styles (progress bar width, spinner URL) without inline styles
- May need to use CSS custom properties or data attributes for dynamic values

### Solution Strategy
1. Use CSS classes for static styles (hidden buttons, text alignment, etc.)
2. Use data attributes for dynamic values (progress width)
3. Use CSS custom properties for dynamic URLs
4. Replace jQuery .css() with addClass/removeClass or data attribute updates

### Changes Made

#### CSS Changes (browser-extension.css)
1. Added `.sip-hidden` class for elements that need to be hidden
2. Added `.sip-initial-progress` class for initial progress bar width
3. Added data attribute selectors for dynamic progress values (0%, 33%, 66%, 100%)
4. Added `.sip-reload-notice` and related classes for the reload dialog
5. Added `.sip-spinner-icon` class with background image URL
6. Added `.open-tab-btn` class for button spacing

#### JavaScript Changes (browser-extension-manager.js)
1. Replaced `style="width: 33.33%"` with `class="sip-initial-progress" data-progress="33"`
2. Replaced `style="display: none;"` with `class="sip-hidden"`
3. Updated `updateProgress()` to use `attr('data-progress')` instead of `.css('width')`
4. Updated `showStep()` to use `addClass/removeClass('sip-hidden')` instead of `.toggle()`
5. Replaced all inline styles in reload notice with CSS classes
6. Removed `style="margin-left: 10px;"` from open tab button

### Result
All inline styles have been removed and replaced with CSP-compliant CSS classes and data attributes. The wizard should now work in environments with strict Content Security Policy settings.