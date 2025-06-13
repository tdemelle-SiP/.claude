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

## 2. Message Flow Architecture

### 2.1 The Central Router Pattern

**ALL messages in the extension flow through widget-router.js - NO EXCEPTIONS**

The router is the single message hub that:
- Receives ALL incoming messages (postMessage from WordPress, chrome.runtime messages from action scripts)
- Routes to appropriate handlers based on message type
- Forwards Chrome API commands to widget-main.js
- Returns responses to the originator

### 2.2 Message Flow Diagram

```
INCOMING MESSAGES:
┌─────────────────┐     postMessage      ┌─────────────────┐
│   WordPress     │ ──────────────────> │                 │
│   Plugin Code   │                      │                 │
└─────────────────┘                      │                 │
                                         │                 │
┌─────────────────┐  chrome.runtime      │  widget-router  │
│ printify-tab-   │ ──────────────────> │      .js        │
│ actions.js      │    sendMessage       │                 │
└─────────────────┘                      │                 │
                                         │                 │
┌─────────────────┐  chrome.runtime      │                 │
│ widget-tabs-    │ ──────────────────> │                 │
│ actions.js      │    sendMessage       └────────┬────────┘
└─────────────────┘                               │
                                                  │ Routes based on
                                                  │ 'type' field
                                                  ▼
                        ┌─────────────────────────┴─────────────────────────┐
                        │                                                   │
                        ▼                                                   ▼
            ┌───────────────────────┐                          ┌───────────────────────┐
            │  widget-handlers.js   │                          │ printify-data-        │
            │                       │                          │ handlers.js           │
            │  Handles:             │                          │                       │
            │  - Widget operations  │                          │ Handles:              │
            │  - Navigation         │                          │ - Mockup fetching     │
            │  - Status updates     │                          │ - Data processing     │
            └───────────┬───────────┘                          └───────────┬───────────┘
                        │                                                   │
                        │ If needs Chrome APIs                              │
                        │                                                   │
                        └─────────────────────┬─────────────────────────────┘
                                              │
                                              ▼
                                    ┌─────────────────────┐
                                    │  widget-main.js     │
                                    │                     │
                                    │  ONLY:              │
                                    │  - Executes Chrome  │
                                    │    API commands     │
                                    │  - Returns results  │
                                    └─────────────────────┘
                                              
STATE UPDATES:
┌─────────────────┐                 ┌─────────────────────┐
│    Handlers     │ ─────────────> │  Chrome Storage     │
│  Update State   │                 │     (State)         │
└─────────────────┘                 └──────────┬──────────┘
                                               │
                                               │ onChange events
                                               ▼
                                    ┌─────────────────────┐
                                    │ widget-tabs-        │
                                    │ actions.js          │
                                    │ Updates widget UI   │
                                    └─────────────────────┘
```

### 2.3 Message Formats

#### Incoming Messages to Router

From WordPress (postMessage):
```javascript
{
    type: 'SIP_FETCH_MOCKUP',
    source: 'sip-printify-manager',
    productId: '123456',
    requestId: 'unique-id'  // For response matching
}
```

From Action Scripts (chrome.runtime.sendMessage):
```javascript
{
    type: 'widget' | 'printify',  // Determines which handler
    action: 'specificAction',     // The operation to perform
    data: {                       // Operation-specific data
        // ...
    }
}
```

#### Handler to widget-main.js Commands
```javascript
{
    command: 'CREATE_TAB' | 'QUERY_TABS' | 'FETCH_URL' | etc.,
    params: {
        // Command-specific parameters
    }
}
```

#### Response Format
```javascript
// Success
{
    success: true,
    data: object,
    message: string  // Optional
}

// Error
{
    success: false,
    error: 'Error message',
    code: 'ERROR_CODE',
    timestamp: Date.now()
}
```

**Note**: Error response formatting is centralized in `widget-error.js`. Content scripts use `SiPWidget.Error` methods, while `widget-main.js` uses the `ErrorResponse` helper object.

## 3. Component Responsibilities

### 3.1 File Structure
```
browser-extension/
├── core-scripts/
│   ├── widget-main.js          # Chrome API command executor
│   ├── widget-router.js        # Central message router
│   ├── widget-debug.js         # Debug utilities
│   ├── widget-error.js         # Error response formatting
│   └── widget-styles.css       # Widget styling
├── action-scripts/
│   ├── widget-tabs-actions.js  # Widget UI creation and button handling
│   ├── printify-tab-actions.js # Printify page monitoring and scraping
│   └── printify-api-interceptor.js # API discovery monitor
├── handler-scripts/
│   ├── widget-data-handlers.js # Widget operation logic
│   ├── printify-data-handlers.js # Printify data processing
│   └── printify-api-interceptor-handler.js # API discovery processing
└── assets/                     # Images and static files
```

**Naming Convention**: Complex features should have matching action/handler pairs:
- `printify-api-interceptor.js` → `printify-api-interceptor-handler.js`
- This makes it clear which handler processes which action script's events

### 3.2 Core Scripts

#### widget-router.js
- Listens for postMessage from WordPress
- Listens for chrome.runtime.sendMessage from all scripts
- Routes messages to handlers based on 'type' field
- Forwards Chrome API commands from handlers to widget-main.js
- Returns responses to message originators

#### widget-main.js  
- Executes Chrome API commands ONLY
- No business logic or message routing
- Commands: CREATE_TAB, QUERY_TABS, SEND_TAB_MESSAGE, FETCH_URL, etc.
- Returns command results to router

### 3.3 Action Scripts

#### widget-tabs-actions.js
- Creates and manages the floating widget UI
- Handles widget button clicks (navigation, status checks, etc.)
- Updates widget display based on Chrome storage changes
- Sends user-initiated actions to router
- Does NOT handle Printify page-specific actions

#### printify-tab-actions.js
- Monitors Printify pages for DOM changes
- Scrapes mockup data when requested
- Detects inventory changes (future)
- Sends detected events to router
- Does NOT handle widget UI

#### printify-api-interceptor.js
- Intercepts Printify API calls
- Captures API patterns and responses
- Sends captured data to router for processing

### 3.4 Handler Scripts

#### widget-data-handlers.js
Processes widget-related operations:
- Navigation between tabs
- Widget state management
- Configuration updates

#### printify-data-handlers.js
Processes Printify data operations:
- Mockup data fetching coordination
- Data validation and formatting
- WordPress API communication coordination

#### printify-api-interceptor-handler.js
Processes captured API data:
- Analyzes API patterns
- Stores discovered endpoints
- Manages API knowledge base

## 4. Chrome Extension Constraints

### 4.1 API Access Limitations

**Background Script (widget-main.js)**
- Full Chrome API access

**Content Scripts (everything else)**
- Limited Chrome API access
- Can use: chrome.storage, chrome.runtime.sendMessage
- CANNOT use: chrome.tabs, chrome.windows, cross-origin fetch
- Must request privileged operations from widget-main.js

This is WHY the architecture requires widget-main.js as a command executor.

### 4.2 Message Passing Constraints

- postMessage can only be received by scripts injected into the page
- chrome.runtime.sendMessage is for internal extension communication
- The router must be a content script to receive both types

## 5. Common Operations

### 5.1 Mockup Fetching Flow

1. WordPress plugin: `window.postMessage({ type: 'SIP_FETCH_MOCKUP', productId: '123' })`
2. widget-router.js receives and routes to printify-data-handlers.js
3. Handler requests tab info: sends command to widget-main.js
4. Handler requests scraping: router sends message to printify-tab-actions.js
5. printify-tab-actions.js scrapes and returns data
6. Handler formats data and requests WordPress API call
7. widget-main.js executes API call and returns result
8. Handler updates Chrome storage with status
9. widget-tabs-actions.js updates UI from storage change

### 5.2 Adding New Features

To add a new feature (e.g., inventory monitoring):

1. **Add action detection** in appropriate action script
2. **Define message format**: `{ type: 'printify', action: 'inventoryChanged', data: {...} }`
3. **Add handler logic** in appropriate handler file
4. **Define any new commands** for widget-main.js
5. **Update Chrome storage schema** for new state
6. **Update widget UI** to display new information

## 6. Implementation Standards

### 6.1 Module Pattern

All content scripts use IIFE pattern with SiPWidget namespace:
```javascript
var SiPWidget = SiPWidget || {};
SiPWidget.ModuleName = (function() {
    'use strict';
    
    const debug = window.widgetDebug || { log: () => {}, error: () => {}, warn: () => {} };
    
    // Private members
    
    // Public API
    return {
        init: function() {},
        publicMethod: function() {}
    };
})();
```

### 6.2 Message Handling Pattern

Every handler follows this pattern:
```javascript
function handle(request, sender, sendResponse) {
    debug.log('Processing:', request.action);
    
    switch (request.action) {
        case 'specificAction':
            handleSpecificAction(request.data)
                .then(result => sendResponse(result))
                .catch(error => sendResponse(SiPWidget.Error.fromException(error)));
            return true; // Keep channel open
            
        default:
            sendResponse(SiPWidget.Error.create(
                'Unknown action: ' + request.action,
                SiPWidget.Error.CODES.UNKNOWN_ACTION
            ));
    }
}
```

### 6.3 Chrome API Command Pattern

Commands to widget-main.js:
```javascript
const result = await chrome.runtime.sendMessage({
    type: 'CHROME_API_COMMAND',
    command: 'CREATE_TAB',
    params: {
        url: 'https://example.com',
        active: true
    }
});
```

## 7. Storage Management

### 7.1 State Storage

All UI state stored in Chrome storage for cross-tab sync:
```javascript
chrome.storage.local.set({
    sipWidgetState: {
        isExpanded: boolean,
        position: { x, y },
        currentOperation: { /* ... */ },
        // Feature-specific state
    }
});
```

### 7.2 Storage Limits

- Chrome storage has 5MB limit
- Monitor usage and prune old operation history
- Use efficient data structures

## 8. WordPress Integration

### 8.1 Sending Commands

From WordPress plugin:
```javascript
window.postMessage({
    type: 'SIP_COMMAND_NAME',
    source: 'sip-printify-manager',
    requestId: generateUniqueId(),
    // Command-specific data
}, '*');
```

### 8.2 REST API Endpoints

Extension calls these WordPress endpoints:
- `POST /wp-json/sip-printify/v1/mockup-data`
- `POST /wp-json/sip-printify/v1/extension-status`
- `GET /wp-json/sip-printify/v1/plugin-status`

Authentication via header: `X-SiP-API-Key: [32-character-key]`

## 9. Development Guidelines

### 9.1 Adding New Operations

1. Start with the trigger (user action or page event)
2. Define the message format
3. Add routing logic if new handler type
4. Implement handler logic
5. Define Chrome API commands if needed
6. Update storage schema if needed
7. Update UI components if needed

### 9.2 Debugging

- Enable debug mode: `chrome.storage.local.set({sip_printify_debug: true})`
- Check router for message flow
- Verify message formats match documentation
- Check Chrome DevTools for both page and extension contexts

### 9.3 Testing Checklist

- [ ] Messages route correctly through widget-router.js
- [ ] Handlers process actions and return proper responses
- [ ] Chrome API commands execute in widget-main.js
- [ ] State updates propagate via Chrome storage
- [ ] Widget UI reflects state changes
- [ ] Error cases return standardized error responses

## Appendices

### A. Chrome Assets

Images requiring chrome.runtime.getURL must be in manifest.json:
```json
"web_accessible_resources": [{
    "resources": ["assets/images/Scanning.gif"],
    "matches": ["<all_urls>"]
}]
```

### B. Migration Notes

When implementing this architecture on existing code:
1. First implement the router without breaking existing flows
2. Gradually move message handling from widget-main.js to handlers
3. Update action scripts to use new message format
4. Remove old direct message patterns
5. Clean up any bypass routes

The key is maintaining functionality while transitioning to the central router pattern.