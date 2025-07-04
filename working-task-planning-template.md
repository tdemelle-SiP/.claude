## Task: Change "History" Button to "View Log" with Simple Modal Display
**Date Started:** 2025-07-04

### Task Understanding
**What:** Update the SiP Printify Manager Chrome Extension to:
1. Change the "History" button text to "View Log"
2. Present the action log in a simpler modal window (similar to progress dialog's log viewer)
3. Add a resizable, scrollable text window with copy and close buttons

**Why:** The current History implementation is too complex. The user wants a simpler presentation using a modal window similar to the progress dialog's log viewer functionality.

**Success Criteria:** 
- History button text changed to "View Log"
- Clicking View Log opens a modal window (not a new browser window)
- Modal contains scrollable text area with action logs
- Modal has Copy Log and Close buttons
- Modal is resizable and draggable

### Documentation Review
- [x] sip-printify-manager-extension-widget.md - Extension architecture, action logger system (lines 783-862)
- [x] Coding_Guidelines_Snapshot.txt - Process requirements and standards
- [x] Current implementation in widget-tabs-actions.js (lines 345-350, 793-802)

### Code Analysis
From widget-tabs-actions.js review:
- Line 345-350: History button HTML with icon and "History" text
- Line 793-802: `handleHistoryView()` function that opens new window
- Line 808-1099: `openConsoleLogWindow()` creates full browser window with styled log viewer

From action-logger.js review:
- Structured action logging system with categories
- `getLogs(callback)` method to retrieve stored logs
- Logs include timestamp, category, action, status, details

From sip-printify-manager-extension-widget.md:
- Action logger provides structured logging (not console logs)
- Categories: WORDPRESS_ACTION, NAVIGATION, DATA_FETCH, API_CALL, STATE_CHANGE, ERROR, AUTH
- Each log entry has timestamp, category, action, tabId, tabName, duration, status, details

### Root Cause Analysis
The current implementation opens a new browser window which is overly complex. User wants a simpler modal approach similar to how the progress dialog shows logs.

### Files to Modify
1. `/action-scripts/widget-tabs-actions.js`
   - Change button text from "History" to "View Log" (line 349)
   - Replace `handleHistoryView()` to show modal instead of new window
   - Add modal creation code using simple DOM manipulation
   - Implement copy and close functionality within modal

### Implementation Plan
1. Change button text from "History" to "View Log" in the HTML
2. Create new `showLogModal()` function to replace window approach
3. Build modal with:
   - Title bar with "Action Log" title
   - Scrollable text area showing formatted logs
   - Copy Log button that copies to clipboard
   - Close button (X) in title bar
   - Resizable borders
4. Use action-logger.js `getLogs()` to retrieve structured logs
5. Format logs as simple text (timestamp, category, action, status)
6. Style modal to match extension's existing UI patterns

### Questions/Blockers
1. Should the modal use the extension's existing CSS classes or inline styles?
2. Should we show all log details or just the essential fields?

### Notes
- The action logger already provides structured logs, not console logs
- Progress dialog shows a simpler approach we can emulate
- Modal should be lighter weight than current full window implementation