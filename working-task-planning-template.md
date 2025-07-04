## Task: Fix Mockup Preview Window Scaling and Translation Issues
**Date Started:** 2025-07-04

### Task Understanding
**What:** Fix the mockup preview window in template-actions.js so that it scales properly from the edges (not the center) and translates correctly from the mouse click position.

**Why:** The current implementation has two issues:
1. Scaling appears to expand outward from the middle instead of pulling from the edge being dragged
2. Translation offsets the window from the point of the mouse click 
3. Default window size on initial load was too small

**Success Criteria:** 
- Window scales correctly from the edge being dragged (like native OS windows)
- Window appears at or near the mouse click position
- Initial window size is reasonable (not too small)
- Dragging and resizing feel natural and expected

### Documentation Review
- [x] sip-printify-manager-architecture.md - Template mockup selection system (lines 207-493)
- [x] sip-feature-ui-components.md - SiP modal system with draggable/resizable features (lines 470-636)
- [x] Coding_Guidelines_Snapshot.txt - Fix root causes, verify data structures

### Code Analysis
From template-actions.js review:
- Line 812: Modal is created using `SiP.Core.modal.create()` with draggable and resizable options
- Lines 816-823: Modal options include width: 800, minWidth: 600, minHeight: 400
- The modal system is from SiP Core (modal.js)

From SiP Core modal.js review:
- Lines 139-161: Draggable implementation uses jQuery UI with containment: 'window'
- Lines 164-184: Resizable implementation uses jQuery UI with handles on all sides
- Line 169: No containment specified for resizable (allows free resizing)
- Lines 107-113 & 455-462: Modal position is set with CSS transform for centering

From modals.css review:
- Lines 31-38: Modal content has margin: 5% auto and max-width: 700px
- Lines 42-44: Resizable modals remove max-width constraint
- Lines 69-72: GPU acceleration enabled for smooth movement
- Lines 199-212: Resizable modal body fills available space

### Root Cause Analysis
1. **Scaling Issue**: The modal is using CSS transform: translate(-50%, -50%) for centering, which causes the resize to appear to expand from center. When resizing, the transform remains active.

2. **Translation Issue**: The saved position from localStorage may have the transform still applied, causing offset from click position.

3. **Default Size**: Width of 800px is reasonable, but the modal may be constrained by CSS or appear smaller due to centering.

### Files to Modify
1. `/sip-plugins-core/assets/js/core/modal.js`
   - Fix position/transform handling during resize operations
   - Ensure transform is cleared when dragging starts
   - Handle position correctly when loading from saved state

2. `/sip-printify-manager/assets/js/modules/template-actions.js`
   - Potentially adjust initial size settings if needed
   - No changes needed if core modal fix resolves issues

### Implementation Plan
1. Analyze the exact transform/position state during resize operations
2. Modify modal.js to clear transforms when dragging/resizing starts
3. Ensure saved positions don't include transform offsets
4. Test dragging from all edges to ensure natural behavior
5. Verify saved state loads correctly without offset
6. Test with different initial window sizes

### Questions/Blockers
None - the issue is clearly in the modal positioning/transform handling in the SiP Core modal system.

### Notes
- The modal system uses jQuery UI draggable/resizable
- CSS transforms for centering interfere with resize behavior
- Position persistence may be saving transformed coordinates