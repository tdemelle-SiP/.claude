## Task: Refactor Extension Logging from Console Mirror to Action-Based System
**Date Started:** 2025-07-03 17:15

### Task Understanding
**What:** Remove the console log capture/relay system and implement an action-based logging system where the extension only logs meaningful actions it performs, not WordPress console output.

**Why:** The current system sends every WordPress console log to the extension, creating massive message traffic and duplicate logs. The extension should only log its own actions (navigation, API calls, data fetching) not mirror WordPress logs.

**Success Criteria:** 
- No more "Relaying message from WordPress to background" logs
- Extension only logs actions it takes, not WordPress console output
- Clean, actionable logs showing extension operations
- Reduced message traffic between WordPress and extension

### Documentation Review
- [x] sip-printify-manager-extension-widget.md - Extension architecture and debug system
- [x] sip-development-testing-debug.md - Debug levels and logging patterns
- [x] Coding_Guidelines_Snapshot.txt - Fix root causes, single source of truth

### Files to Modify
1. `/sip-printify-manager/assets/js/modules/browser-extension-actions.js`
   - Remove `setupConsoleLogCapture()` function (lines 644-719)
   - Remove call to `setupConsoleLogCapture()` in init() (line 73)
   - Clean up comments about console capture

2. `/sip-printify-manager-extension/core-scripts/widget-debug.js`
   - Remove handling of `SIP_CONSOLE_LOG` messages
   - Keep extension's own debug logging
   - Update to focus on action logging

3. `/sip-printify-manager-extension/core-scripts/action-logger.js` (NEW FILE)
   - Create structured action logger
   - Log categories: WORDPRESS_ACTION, NAVIGATION, DATA_FETCH, API_CALL, STATE_CHANGE, ERROR, AUTH
   - Store in Chrome storage for cross-tab access

4. `/sip-printify-manager-extension/core-scripts/widget-router.js`
   - Add action logging for received WordPress messages
   - Log navigation attempts and results
   - Remove console relay handling

5. `/sip-printify-manager-extension/handler-scripts/*.js`
   - Add action logging to all handlers
   - Log what they're doing, not console output

6. `/sip-printify-manager-extension/action-scripts/*.js`
   - Add action logging for data scraping
   - Log found/not found results

### Implementation Plan
1. Remove console capture from WordPress side
2. Create action logger module for extension
3. Update router to log actions instead of console relay
4. Update handlers to use action logger
5. Update action scripts to log their operations
6. Test that all key operations are logged
7. Verify no console duplication
8. Update documentation

### Questions/Blockers
1. Should the action logger use the existing debug levels (OFF/NORMAL/VERBOSE)?
   - Answer: Yes, maintain consistency with SiP debug system
   
2. Should we keep the History viewer feature but show action logs instead?
   - Answer: Yes, repurpose for viewing action history

3. What format should action logs use?
   - Answer: Structured with timestamp, category, action, details