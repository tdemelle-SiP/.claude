# SiP Widget Terminal Display Implementation Guide

## Overview

This document provides a complete implementation guide for the SiP Printify Manager Extension widget terminal display. The terminal display shows real-time action messages and operation progress in a retro terminal-style interface (black background, colored text).

**Visual References**: See mockups at `C:\Users\tdeme\Documents\VSCode_Images_Repo\`:
- `WidgetWindowDesign01.png` - READY state
- `WidgetWindowDesign02.png` - PROCESSING state  
- `WidgetWindowDesign03.png` - SUCCESS completion state

## Terminal Display Architecture

### Display States

The terminal has three distinct display modes:

1. **READY State**
   - Bottom text: "READY" (green)
   - Center: Three dots "..." (green) OR transient one-off messages
   - Top header: Empty or previous status (dimmed after 5 seconds)

2. **PROCESSING State** 
   - Bottom text: "PROCESSING..." (green)
   - Center: Progress bar with percentage and current task message
   - Top header: Operation name (e.g., "Updating Mockups")
   - Triggered when `sipOperationStatus.state === 'active'`

3. **Transient Messages**
   - One-off action messages that appear without changing state
   - Replace dots temporarily in READY state
   - Do NOT trigger progress bar or change bottom status
   - Persist until replaced by another message

### Data Flow

```mermaid
graph TD
    A[Handler Operation] -->|reportStatus()| B[sipOperationStatus Storage]
    B -->|onChanged| C[updateOperationStatus()]
    
    D[One-off Actions] -->|ActionLogger.log()| E[updateWidgetDisplay()]
    
    C --> F[Terminal Display]
    E --> F
```

Two parallel systems update the display:

1. **Operation Progress** (Handler → Storage → Widget)
   - Handlers call `reportStatus(operation, task, progress, details)`
   - Sets `sipOperationStatus` in chrome.storage.local
   - Widget listens for storage changes
   - `updateOperationStatus()` updates terminal for PROCESSING state

2. **Action Messages** (Direct to Display)
   - Actions call `ActionLogger.log(category, action, details)`
   - `updateWidgetDisplay()` directly updates terminal
   - Shows transient messages without changing state

## Color Coding System

### Status Header Colors
The top header shows status with specific colors:
- **INFO**: Light grey (#cccccc)
- **SUCCESS**: Green (#00ff00)
- **ERROR**: Red (#ff3333)
- **WARNING**: Orange (#ffaa00)

### Action Message Colors
Action messages are colored by source AND current context:

| Message Source | When on WordPress | When on Printify |
|----------------|-------------------|-------------------|
| WordPress      | Bright blue (#00ccff) | Dimmer blue (#0088cc) |
| Printify       | Dimmer green (#00cc00) | Bright green (#00ff00) |

This color coding is already implemented in `action-logger.js:updateWidgetDisplay()`.

## Implementation Details

### HTML Structure (in widget-tabs-actions.js)

```html
<div class="sip-terminal-display">
    <div class="sip-terminal-screen" id="sip-terminal-screen">
        <!-- Status Header -->
        <div class="sip-terminal-header" id="sip-terminal-header">
            <span class="sip-terminal-header-text" id="sip-terminal-header-text"></span>
        </div>
        
        <!-- Terminal Content Container -->
        <div class="sip-terminal-content" id="sip-terminal-content">
            <!-- Progress Bar (shown during processing) -->
            <div class="sip-terminal-progress-wrapper hidden" id="sip-terminal-progress-wrapper">
                <div class="sip-terminal-progress-bar">
                    <div class="sip-terminal-progress-fill" id="sip-terminal-progress-fill"></div>
                </div>
                <span class="sip-terminal-progress-text" id="sip-terminal-progress-text">0%</span>
            </div>
            
            <!-- Message Display -->
            <div class="sip-terminal-message" id="sip-terminal-message">
                <div class="sip-terminal-dots" id="sip-terminal-dots">...</div>
            </div>
        </div>
        
        <!-- Terminal Status Line -->
        <div class="sip-terminal-status" id="sip-terminal-status">
            <span class="sip-terminal-status-text" id="sip-terminal-status-text">READY</span>
        </div>
    </div>
</div>
```

### Operation Status Structure

Handlers use `reportStatus()` with this structure:
```javascript
async function reportStatus(operation, task, progress, details = '', cancellable = false) {
    const status = {
        operation: operation,    // e.g., "Updating Mockups"
        task: task,             // e.g., "Opening mockup library"
        progress: progress,     // 0-100
        details: details,       // Multi-line details for completion
        cancellable: cancellable,
        state: 'active',
        message: `${operation} in progress`,
        timestamp: Date.now()
    };
    
    await chrome.storage.local.set({ sipOperationStatus: status });
}
```

### Message Dimming Behavior

Messages and status headers dim to 50% opacity after 5 seconds:
- New messages reset opacity to 100%
- Dimmed messages remain visible until replaced
- Timer is cleared when new messages arrive

## Key Implementation Files

### 1. widget-tabs-actions.js
Contains `updateOperationStatus()` function that:
- Listens for `sipOperationStatus` storage changes
- Updates terminal display based on state
- Manages progress bar visibility
- Handles message dimming timers

### 2. action-logger.js  
Contains `updateWidgetDisplay()` function that:
- Handles one-off action messages
- Implements color coding based on source/context
- Updates status header and message content
- Already working correctly - DO NOT MODIFY

### 3. Handler files (mockup-update-handler.js, mockup-fetch-handler.js)
- Use `reportStatus()` for progress updates
- Must use `SiPWidget.ActionLogger` (not `window.action` which doesn't exist in service workers)
- Set state to 'idle' after operation completes

## Common Issues and Solutions

### Issue 1: Undefined Elements
**Problem**: `updateOperationStatus` references `progressDetails` and `cancelWrapper` that don't exist.
**Solution**: Remove these references - they're from old UI design.

### Issue 2: Service Worker Context
**Problem**: `window.action` undefined in service worker handlers.
**Solution**: Use `SiPWidget.ActionLogger.log()` instead.

### Issue 3: Missing Color Coding
**Problem**: Operation status messages don't have color coding.
**Solution**: Apply same color logic from `updateWidgetDisplay()` to operation messages.

### Issue 4: Artificial Success State
**Problem**: Code creates false distinction between completion and processing.
**Solution**: SUCCESS is just a status header, not a separate state. Terminal remains in PROCESSING until operation sets state to 'idle'.

## Completion Behavior

When an operation completes:
1. Handler calls `reportStatus('Update Complete', 'Success message', 100, details)`
2. Terminal shows:
   - Header: "SUCCESS" (green) or operation name
   - Progress: 100% 
   - Message: Detailed completion info
3. After 2 seconds, handler sets `state: 'idle'`
4. Terminal returns to READY state

## Testing Checklist

- [ ] READY state shows green "..." dots
- [ ] One-off messages appear without hiding READY status
- [ ] PROCESSING state shows progress bar and hides dots
- [ ] Progress updates from 0% to 100%
- [ ] Messages dim to 50% opacity after 5 seconds
- [ ] New messages reset opacity to 100%
- [ ] WordPress messages are blue (bright on WordPress, dim on Printify)
- [ ] Printify messages are green (bright on Printify, dim on WordPress)
- [ ] Status headers use correct colors (INFO=grey, SUCCESS=green, ERROR=red, WARNING=orange)
- [ ] Completion shows detailed message at 100%
- [ ] Terminal returns to READY after operation completes

## Critical Architecture Notes

1. **Two Separate Progress Systems**: 
   - WordPress plugin tracks batch progress across multiple operations
   - Extension widget tracks individual operation progress
   - These work together but are completely separate

2. **Message Persistence**:
   - Messages stay visible (dimmed) until replaced
   - No setTimeout to hide messages - only to dim them

3. **State Management**:
   - Only handlers should set `sipOperationStatus`  
   - One-off messages should never change terminal state
   - State changes only through storage updates, not direct manipulation

## Implementation Plan - Required Code Changes

### Step 1: Fix updateOperationStatus() Basic Structure

**File**: `action-scripts/widget-tabs-actions.js`

**1.1 Add message dimming timer at module level**:
```javascript
// Track message dimming timer
let messageDimTimer = null;
```

**1.2 Clear timer at start of updateOperationStatus()**:
```javascript
function updateOperationStatus(status) {
    // Widget might not be initialized yet
    if (!widget) {
        return;
    }
    
    // Clear any existing dim timer
    if (messageDimTimer) {
        clearTimeout(messageDimTimer);
        messageDimTimer = null;
    }
```

**1.3 Remove references to non-existent elements** (around line 1640+):
```javascript
// DELETE THIS ENTIRE SECTION:
// Update details
if (status.details) {
    progressDetails.innerHTML = status.details;
    progressDetails.classList.remove('sip-hidden');
} else {
    progressDetails.classList.add('sip-hidden');
}

// Show/hide cancel button
if (status.cancellable) {
    cancelWrapper.classList.remove('sip-hidden');
} else {
    cancelWrapper.classList.add('sip-hidden');
}
```

### Step 2: Fix PROCESSING State Display

**2.1 Update the PROCESSING state section** to show operation header and task message with colors:
```javascript
// Processing state
terminalStatusText.textContent = 'PROCESSING...';
terminalProgressWrapper.classList.remove('hidden');
terminalDots.style.display = 'none';
terminalHeaderText.textContent = status.operation || '';
terminalHeaderText.style.opacity = '1'; // Reset opacity
terminalHeaderText.style.color = '#00ff00'; // Default green

// Update progress bar
const percentage = status.progress || 0;
terminalProgressText.textContent = `${percentage}%`;
terminalProgressFill.style.width = `${percentage}%`;

// Determine message color based on context
const isOnWordPress = window.location.href.includes('/wp-admin/');
const isOnPrintify = window.location.href.includes('printify.com');

// Heuristic: determine source from operation name
const siteType = status.operation && status.operation.includes('WordPress') ? 
    'WordPress Site' : 'Printify Site';

let actionColor = '#00ff00'; // Default green
if (siteType === 'WordPress Site') {
    actionColor = isOnWordPress ? '#00ccff' : '#0088cc';
} else if (siteType === 'Printify Site') {
    actionColor = isOnPrintify ? '#00ff00' : '#00cc00';
}

// Show the task message
terminalDots.style.display = 'none';
const messageDiv = document.createElement('div');
messageDiv.id = 'sip-terminal-log-entry';
messageDiv.style.color = actionColor;
messageDiv.style.fontSize = '12px';
messageDiv.textContent = status.task || status.message || '';
terminalMessage.innerHTML = '';
terminalMessage.appendChild(messageDiv);

// Set timer to dim message after 5 seconds
messageDimTimer = setTimeout(() => {
    if (messageDiv && messageDiv.parentNode) {
        messageDiv.style.opacity = '0.5';
    }
}, 5000);
```

### Step 3: Fix Completion Display

**3.1 Update completion detection** to stay in PROCESSING state:
```javascript
// Check if this is completion (100%)
if (status.progress === 100) {
    // Still PROCESSING, just showing completion
    terminalStatusText.textContent = 'PROCESSING...';
    terminalProgressWrapper.classList.remove('hidden');
    
    // Determine status type from content
    let statusText = 'SUCCESS';
    let statusColor = '#00ff00'; // Green for success
    
    if (status.operation && (status.operation.includes('Failed') || 
        (status.details && status.details.includes('failed')))) {
        statusText = 'ERROR';
        statusColor = '#ff3333'; // Red for error
    }
    
    terminalHeaderText.textContent = statusText;
    terminalHeaderText.style.color = statusColor;
    terminalHeaderText.style.opacity = '1';
    
    // Show completion details
    terminalDots.style.display = 'none';
    const messageDiv = document.createElement('div');
    messageDiv.style.color = '#00ff00';
    messageDiv.style.fontSize = '12px';
    messageDiv.style.lineHeight = '1.6';
    messageDiv.innerHTML = status.details.replace(/\n/g, '<br>');
    terminalMessage.innerHTML = '';
    terminalMessage.appendChild(messageDiv);
    
    // Set timer to dim after 5 seconds
    messageDimTimer = setTimeout(() => {
        if (messageDiv && messageDiv.parentNode) {
            messageDiv.style.opacity = '0.5';
        }
        if (terminalHeaderText) {
            terminalHeaderText.style.opacity = '0.5';
        }
    }, 5000);
}
```

### Step 4: Fix Handler Service Worker Context

**File**: `handler-scripts/mockup-update-handler.js` (and any other handlers)

**Replace all instances of**:
```javascript
if (window.action) {
    window.action.info('Message', details);
}
```

**With**:
```javascript
if (SiPWidget.ActionLogger) {
    SiPWidget.ActionLogger.log(
        SiPWidget.ActionLogger.CATEGORIES.DATA_FETCH,
        'Message',
        details
    );
}
```

### Step 5: Ensure Consistent reportStatus() Structure

**In all handler files**, ensure `reportStatus()` uses this structure:
```javascript
async function reportStatus(operation, task, progress, details = '', cancellable = false) {
    const status = {
        operation: operation,    // e.g., "Updating Mockups"
        task: task,             // e.g., "Opening mockup library"
        progress: progress,     // 0-100
        details: details,       // Multi-line details for completion
        cancellable: cancellable,
        state: 'active',
        message: `${operation} in progress`,
        timestamp: Date.now()
    };
    
    await chrome.storage.local.set({ sipOperationStatus: status });
}
```

### Step 6: Verify Idle State Reset

Ensure handlers set state to 'idle' after completion:
```javascript
// After showing completion for 2 seconds
setTimeout(() => {
    chrome.storage.local.set({ 
        sipOperationStatus: { state: 'idle', timestamp: Date.now() } 
    });
}, 2000);
```

## Implementation Order

1. First fix the basic structure issues (Step 1)
2. Test that the widget doesn't throw errors
3. Implement PROCESSING state display (Step 2)
4. Test with an active operation
5. Fix completion handling (Step 3)
6. Fix service worker logging (Step 4)
7. Verify all handlers use consistent structure (Steps 5-6)
8. Full integration test