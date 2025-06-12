# SiP Printify Manager Browser Extension

**Version:** 4.3.0  
**Last Updated:** January 21, 2025

<!-- DOCUMENTATION RULES:
1. NO JUSTIFICATIONS - Document WHAT, not WHY
2. NO HISTORY - Current state only, not how we got here
3. NO DUPLICATION - Each fact appears exactly once
4. EXAMPLES OVER EXPLANATIONS - Show, don't tell
5. UPDATE THE RIGHT SECTION - Check if info already exists before adding
-->

## 1. Overview

The SiP Printify Manager browser extension bridges WordPress and Printify, enabling functionality not available through Printify's public API. It provides a floating widget interface for real-time operations and data synchronization between the two platforms.

### Quick Architecture

```
WordPress Admin ←→ Extension Widget ←→ Printify.com
     ↓                    ↓                ↓
WordPress DB      Chrome Storage    Printify API
```

## 2. System Architecture

### 2.1 Communication Channels

The extension uses three distinct communication channels optimized for their specific purposes:

#### Command Channel (postMessage)
- **Purpose**: Trigger operations from WordPress admin
- **Direction**: WordPress → Extension
- **Example**: `window.postMessage({ type: 'SIP_FETCH_MOCKUP', productId: '123' }, '*')`

#### Data Channel (REST API)
- **Purpose**: Store operation results in WordPress
- **Direction**: Extension → WordPress
- **Authentication**: Custom header `X-SiP-API-Key: [32-character-key]`
- **Endpoints**:
  - `POST /wp-json/sip-printify/v1/mockup-data`
  - `POST /wp-json/sip-printify/v1/extension-status`
  - `GET /wp-json/sip-printify/v1/plugin-status`
  - `POST /wp-json/sip-printify/v1/extension-key`

#### State Channel (Chrome Storage)
- **Purpose**: Synchronize UI state across all tabs
- **Direction**: Bidirectional (all tabs)
- **Storage**: `chrome.storage.local` with 5MB limit
- **Sync Time**: Visual updates within 100ms of state change

### 2.2 Components

```
browser-extension/
├── core-scripts/                    # Infrastructure
│   ├── widget-main.js              # Background service worker
│   ├── widget-ui.js                # Widget interface
│   ├── widget-message-router.js    # Message routing
│   ├── widget-debug.js             # Debug utilities
│   └── widget-styles.css           # Widget styling
├── action-scripts/                  # User actions
│   ├── widget-actions.js           # Widget UI actions
│   ├── printify-tab-actions.js    # Printify page actions
│   └── api-interceptor.js         # API discovery monitor
├── handler-scripts/                 # Request processing
│   ├── widget-handlers.js          # Widget requests
│   └── printify-data-handlers.js  # Printify data processing
└── assets/                         # Static resources
```

### 2.3 Data Flow

#### Operation Flow
```
1. WordPress Admin → postMessage → Extension Widget
2. Widget → chrome.runtime.sendMessage → Background Script
3. Background → chrome.tabs.sendMessage → Printify Tab
4. Printify Tab → Executes Operation → Returns Data
5. Background → fetch() → WordPress REST API
6. WordPress → Stores in MySQL → Updates Display
```

#### State Synchronization
```
Any Tab → chrome.storage.local.set() → All Tabs Receive onChange Event
```

## 3. Widget Specifications
<!-- Widget UI, behavior, and visual requirements ONLY -->

### 3.1 Widget UI Structure (Top to Bottom)

#### 1. Header
- Title: "SiP Printify Manager"
- Minimize/Maximize toggle button
- Close button (if appropriate for context)

#### 2. Connection Status
- **Visual Indicator**: Green/red dot based on configuration and plugin status
- **Connection Requirements**: WordPress URL + valid API key
- **Status Messages**:
  - "Extension Ready" (on WordPress when connected)
  - "Connected to WordPress" (on Printify when connected)  
  - "Not Connected" (when missing configuration)
  - "Plugin not active" (when WordPress plugin is deactivated)
- **Actions**: "Check Again" button appears when plugin is deactivated

#### 3. Progress Dialog Area
- Progress bar with percentage display
- Progress text for status messages
- Ready state indicator
- Operation-specific progress tracking

#### 4. Action Buttons
- **Tab Switch Button**: Navigate between WordPress/Printify
- **History Button**: Show operation history
- **API Interceptor Toggle**: Enable/disable API discovery
  - Visual pip indicator when active
  - Animated border (Scanning.gif) during capture
  - Count of new APIs discovered

### 3.2 Widget Behavior

#### Persistence
- Widget position stored in Chrome Storage (persists across sessions)
- UI state (expanded/collapsed) persists per session
- Operation history retained based on storage thresholds

#### Synchronization
- Widget instances on different tabs stay in sync via Chrome Storage
- State updates debounced to prevent excessive storage writes
- Visual updates occur within 100ms of state change

#### Non-Intrusive
- Widget has z-index of 999999 to stay on top
- Drag boundaries prevent widget from leaving viewport
- Click-through to page elements when widget is collapsed

#### Responsive
- Minimum viewport: 320px width
- Widget scales down on mobile devices
- Touch-friendly drag handles for mobile

#### Vertical Space Conservation
- Expanded widget must fit within typical viewport heights
- Minimize padding/margins (5-10px max for sections)
- Target max height: ~400px expanded

### 3.3 Widget Implementation Details

#### Drag Behavior & Window Scaling
```javascript
function constrainToViewport(x, y) {
    const widget = document.querySelector('.sip-widget');
    const rect = widget.getBoundingClientRect();
    const maxX = window.innerWidth - rect.width;
    const maxY = window.innerHeight - rect.height;
    
    return {
        x: Math.max(0, Math.min(x, maxX)),
        y: Math.max(0, Math.min(y, maxY))
    };
}

window.addEventListener('resize', debounce(() => {
    const currentPos = getWidgetPosition();
    const validPos = constrainToViewport(currentPos.x, currentPos.y);
    
    if (validPos.x !== currentPos.x || validPos.y !== currentPos.y) {
        updateWidgetPosition(validPos);
    }
}, 100));
```

#### SPA Navigation Handling
```javascript
// Monitor for Printify SPA route changes
let lastUrl = location.href;
new MutationObserver(() => {
    const url = location.href;
    if (url !== lastUrl) {
        lastUrl = url;
        handleRouteChange(url);
    }
}).observe(document, { subtree: true, childList: true });
```

## 4. Implementation Standards
<!-- Code patterns, message formats, error handling ONLY -->

### 4.1 Module Pattern

All modules use the IIFE pattern with SiPWidget namespace:

```javascript
var SiPWidget = SiPWidget || {};
SiPWidget.ModuleName = (function() {
    'use strict';
    
    const debug = window.widgetDebug || { log: () => {}, error: () => {}, warn: () => {} };
    
    // Private members
    let privateVar = null;
    
    // Private functions
    function privateFunction() {}
    
    // Public API
    return {
        init: function() {
            debug.log('🟢 Module initializing');
        },
        publicMethod: function() {}
    };
})();
```

### 4.2 Message Formats

#### Chrome Runtime Messages
```javascript
{
    action: 'operation_name',
    data: {
        // Operation-specific data
    }
}
```

#### postMessage Format
```javascript
{
    type: 'SIP_MESSAGE_TYPE',
    source: 'sip-printify-manager',
    requestId: 'unique-id', // For response matching
    // Message-specific fields
}
```

#### REST API Response
```javascript
// Success
{
    success: true,
    data: object,
    message: string
}

// Error
{
    success: false,
    error: 'Error message',
    code: 'ERROR_CODE',
    timestamp: Date.now()
}
```

### 4.3 Error Handling Pattern

Every operation follows this standardized pattern:

```javascript
async function executeOperation(operation) {
    try {
        // Update state: pending
        await updateOperationState(operation.id, 'pending');
        
        // Execute with timeout
        const result = await withTimeout(
            performOperation(operation),
            30000 // 30 second timeout
        );
        
        // Update state: complete
        await updateOperationState(operation.id, 'complete', result);
        
    } catch (error) {
        // Update state: error
        await updateOperationState(operation.id, 'error', null, error);
        
        // Determine if retryable
        if (isRetryable(error)) {
            await scheduleRetry(operation);
        }
    }
}
```

### 4.4 Debug Framework

All modules use `window.widgetDebug`:
```javascript
const debug = window.widgetDebug || { log: () => {}, error: () => {}, warn: () => {} };
debug.log('🟢 Module initialized');
debug.error('❌ Operation failed:', error);
debug.warn('⚠️ Potential issue detected');
```

## 5. API Reference
<!-- Message types, endpoints, schemas ONLY -->

### 5.1 Chrome Messages

#### Widget Control
- `action: 'updateWidgetState'` - Update widget UI state
- `action: 'navigateToTab'` - Switch between WordPress/Printify tabs
- `action: 'toggleApiInterceptor'` - Enable/disable API monitoring

#### Data Operations
- `action: 'fetchMockupsForProduct'` - Scrape mockup data
- `action: 'syncMockupData'` - Send data to WordPress
- `action: 'updateOperationStatus'` - Update operation progress

### 5.2 REST Endpoints

#### POST /wp-json/sip-printify/v1/mockup-data
Store scraped mockup data.

**Request:**
```json
{
    "productId": "123456",
    "mockupData": {
        "images": [...],
        "metadata": {...}
    },
    "timestamp": "2025-01-21T10:30:00Z"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Mockup data stored successfully",
    "stored_count": 5
}
```

### 5.3 Storage Schema

#### sipWidgetState
```javascript
{
    isExpanded: boolean,
    position: { x: number, y: number },
    isConnected: boolean,
    apiInterceptorEnabled: boolean,
    currentOperation: {
        id: string,
        type: string,
        status: 'pending' | 'in_progress' | 'complete' | 'error',
        progress: number,
        startTime: number,
        message?: string,
        data?: object
    },
    operationHistory: [{
        id: string,
        type: string,
        status: 'complete' | 'error',
        timestamp: number,
        duration: number,
        message: string,
        errorDetails?: string
    }]
}
```

### 5.4 Chrome Assets

When adding images that need `chrome.runtime.getURL()`, they MUST be declared in manifest.json:

```json
"web_accessible_resources": [{
    "resources": [
        "assets/images/Scanning.gif",
        "core-scripts/widget-styles.css"
    ],
    "matches": ["<all_urls>"]
}]
```

## 6. Storage Management

### 6.1 Usage Monitoring

```javascript
async function checkStorageUsage() {
    const usage = await chrome.storage.local.getBytesInUse();
    const limit = chrome.storage.local.QUOTA_BYTES; // 5,242,880 bytes
    const percentUsed = (usage / limit) * 100;
    
    if (percentUsed > 50) {
        await pruneOperationHistory();
    }
    
    return { usage, limit, percentUsed };
}
```

### 6.2 History Pruning

```javascript
async function pruneOperationHistory() {
    const state = await chrome.storage.local.get('sipWidgetState');
    const operations = state.sipWidgetState?.operationHistory || [];
    
    while (operations.length > 10) {
        const currentSize = JSON.stringify(operations).length;
        const targetSize = 100000; // ~100KB for operation history
        
        if (currentSize <= targetSize) break;
        
        operations.shift(); // Remove oldest
    }
    
    await chrome.storage.local.set({
        sipWidgetState: { ...state.sipWidgetState, operationHistory: operations }
    });
}
```

## 7. Security & Performance

### 7.1 Security Requirements

1. **API Key Protection**
   - Never store API keys in content scripts
   - Pass through background script only
   - Use secure message channels

2. **Data Validation**
   - Validate all incoming messages
   - Sanitize data before storage
   - Check origin for postMessage

3. **Operation Authorization**
   - Verify operations are user-initiated
   - Implement rate limiting if needed
   - Log suspicious activity

### 7.2 Performance Considerations

1. **State Updates**
   - Debounce rapid state updates
   - Use Chrome Storage efficiently (5MB limit)
   - Clean up completed operations after success

2. **Resource Usage**
   - No polling or regular checks
   - Everything is event-driven
   - Efficient resource usage with no background timers

3. **Message Handling**
   - Minimize message payload size
   - Use batch operations where possible
   - Implement proper timeout handling

## 8. Code Deviations

Current implementation deviations from standards. Remove rows as issues are fixed.

| Component | Standard | Current Implementation | Priority | Location | Fix Approach |
|-----------|----------|------------------------|----------|----------|--------------|
| Debug Framework | `window.widgetDebug` | Mix of `console.log` and `debug.log` | High | widget-main.js:25-28, widget-ui.js:various | Find/replace all console.* with debug.* |
| Message Router | All Chrome messages via router | Some direct `window.postMessage` | Medium | widget-ui.js:793-798 | Route through SiPWidget.MessageRouter |
| Configuration | Centralized config module | Direct access in content scripts | Medium | widget-ui.js:76-80 | Create SiPWidget.Config module |
| Error Format | Standard error object | Various formats | Medium | Multiple handlers | Use standard format from section 4.3 |
| Input Validation | All handlers validate | Some missing validation | Low | Various handlers | Add validation at handler entry points |

## Appendices

### A. Development Phases

1. **Phase 1: Foundation** ✓ Complete
   - Widget interface
   - Tab pairing
   - Basic mockup fetching

2. **Phase 2: API Discovery** (In Progress)
   - API interception
   - Pattern recognition
   - Endpoint documentation

3. **Phase 3: Lifecycle Tracking** (Planned)
   - Product state monitoring
   - Publish process tracking
   - Status synchronization

### B. Chrome Extension Constraints

Background scripts have full Chrome API access:
- `chrome.tabs.*`
- `chrome.windows.*`
- `chrome.runtime.*`

Content scripts have limited access:
- `chrome.storage.*`
- `chrome.runtime.sendMessage()`
- No `chrome.tabs.*` access

### C. Testing Checklist

#### Basic Functionality
- [ ] Widget appears on both WordPress and Printify pages
- [ ] Widget can be dragged and position persists
- [ ] Widget can be expanded/collapsed with state persisting

#### Connection Status
- [ ] Shows correct status messages
- [ ] Check Again button works when plugin deactivated
- [ ] API key validation works

#### Navigation
- [ ] Tab switch button shows correct text
- [ ] Navigation works in both directions

#### Data Operations
- [ ] Mockup fetching completes successfully
- [ ] Progress updates display correctly
- [ ] Errors are properly displayed

### D. Common Patterns

```javascript
// Starting an operation
chrome.storage.local.set({ 
    sipWidgetState: { 
        ...currentState, 
        currentOperation: operation 
    } 
});

// Updating progress
chrome.storage.local.set({ 
    'sipWidgetState.currentOperation.progress': percentComplete 
});

// Handling errors
catch (error) {
    await updateOperationState(operation.id, 'error', null, error);
    showUserNotification(error.message);
}
```