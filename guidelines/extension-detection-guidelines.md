# Extension Detection Guidelines

## Overview

This document defines the standardized request-based detection pattern for browser extensions in the SiP plugin ecosystem.

### Core Principles
- WordPress initiates detection via request
- Extensions respond only when asked
- Single detection method across all plugins
- All UI updates happen via events
- Fresh detection for every status check
- Purely event-driven architecture

## What

```mermaid
sequenceDiagram
    participant UI as WordPress UI<br/>(plugin-dashboard.js,<br/>shop-actions.js, etc.)
    participant BEM as Browser Extension Manager<br/>(browser-extension-actions.js)
    participant Relay as Extension Relay<br/>(wordpress-relay.js)
    participant Router as Extension Router<br/>(widget-router.js)
    participant Handler as WordPress Handler<br/>(wordpress-handler.js)
    
    Note over UI: Page loads, needs extension status
    
    UI->>BEM: browserExtensionManager.checkStatus()
    BEM->>BEM: checkExtensionStatus()
    
    Note over BEM: Send detection request
    BEM->>Relay: window.postMessage({<br/>  type: 'wordpress',<br/>  action: 'SIP_REQUEST_EXTENSION_STATUS',<br/>  source: 'sip-printify-manager'<br/>}, window.location.origin)
    
    Note over Relay: validateWordPressMessage(event)
    Relay->>Relay: 1. Check event.origin === allowedOrigin<br/>2. Check event.source !== window<br/>3. Validate source === 'sip-plugins-core' ||<br/>source === 'sip-printify-manager'
    
    Note over Relay: sendWordPressMessageToRouter(message)
    Relay->>Router: chrome.runtime.sendMessage({<br/>  type: 'wordpress',<br/>  action: 'SIP_REQUEST_EXTENSION_STATUS',<br/>  source: 'sip-plugins-core'<br/>})
    
    Note over Router: handleMessage(message, sender, sendResponse)
    Router->>Router: Validate message has 'type' field
    Router->>Router: Route to handler based on type: 'wordpress'
    
    Router->>Handler: handler.handle({<br/>  type: 'wordpress',<br/>  action: 'SIP_REQUEST_EXTENSION_STATUS',<br/>  ...<br/>}, sender, sendResponse, routerContext)
    
    Note over Handler: Check request.action
    Handler->>Handler: case 'SIP_REQUEST_EXTENSION_STATUS'
    Handler->>Handler: Get manifest version & capabilities
    
    Handler-->>Router: sendResponse({<br/>  success: true,<br/>  type: 'SIP_EXTENSION_DETECTED',<br/>  extension: {<br/>    slug: 'sip-printify-manager-extension',<br/>    version: manifest.version,<br/>    capabilities: {...}<br/>  }<br/>})
    
    Router-->>Relay: Chrome runtime response
    
    Note over Relay: Inside sendWordPressMessageToRouter callback
    Relay->>Relay: if (response) {<br/>  window.postMessage(response, allowedOrigin)<br/>}
    
    Relay-->>BEM: window.postMessage({<br/>  success: true,<br/>  type: 'SIP_EXTENSION_DETECTED',<br/>  extension: {<br/>    slug: 'sip-printify-manager-extension',<br/>    version: manifest.version,<br/>    capabilities: {...}<br/>  }<br/>}, window.location.origin)
    
    Note over BEM: Handle response
    BEM->>BEM: if (event.data.type === 'SIP_EXTENSION_DETECTED')
    BEM->>UI: $(document).trigger('extensionDetected', extension)
    
    Note over UI: extensionHandler() listens for event
    UI->>UI: Update UI with extension info
```

## How

### Message Flow
- WordPress sends messages in internal format: `{ type: 'wordpress', action: 'SIP_REQUEST_EXTENSION_STATUS', source: 'sip-printify-manager' }`
- Extension relay validates origin and source before forwarding
- Extension router validates all messages have a `type` field
- Router checks `type` field to route to wordpress-handler.js
- Handler checks `request.action` to determine specific command
- Response is sent directly without wrapping
- Relay passes messages through unchanged in both directions

### Key Functions

1. **validateWordPressMessage(event)** in wordpress-relay.js:
   - Listens for postMessage events from WordPress
   - Validates origin matches current site
   - Validates source is 'sip-plugins-core' or 'sip-printify-manager'
   - Prevents relaying extension's own messages

2. **sendWordPressMessageToRouter(message)** in wordpress-relay.js:
   - Sends validated messages to background script via chrome.runtime.sendMessage
   - Handles responses in callback
   - Posts responses back to WordPress via postMessage

3. **extensionHandler()** in plugin-dashboard.js:
   - Sets up listener for 'extensionDetected' events
   - Updates UI when extensions are detected
   - Manages extension status display in tables

## Why

- **ALL messages through router**: Security model requires single validation point
- **Two-layer validation**: Origin/source validation in relay, type/structure validation in router
- **Consistent message format**: No transformation needed throughout the flow
- **Event-driven detection**: No state storage prevents stale data
- **Request-based pattern**: Extension only responds when asked, reducing noise
- **Secure bridge architecture**: wordpress-relay.js acts as secure bridge between WordPress (postMessage) and extension (Chrome runtime messaging)