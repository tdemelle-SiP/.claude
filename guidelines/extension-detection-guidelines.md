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
    participant Relay as Extension Relay<br/>(widget-relay.js)
    participant Router as Extension Router<br/>(widget-router.js)
    participant Handler as WordPress Handler<br/>(wordpress-handler.js)
    
    Note over UI: Page loads, needs extension status
    
    UI->>BEM: browserExtensionManager.checkStatus()
    BEM->>BEM: checkExtensionStatus()
    
    Note over BEM: Send detection request
    BEM->>Relay: window.postMessage({<br/>  type: 'wordpress',<br/>  action: 'SIP_REQUEST_EXTENSION_STATUS',<br/>  source: 'sip-printify-manager'<br/>}, window.location.origin)
    
    Note over Relay: handleWordPressMessage(event)
    Relay->>Relay: Validate origin === window.location.origin
    Relay->>Relay: Validate source === 'sip-plugins-core' ||<br/>source === 'sip-printify-manager'
    
    Note over Relay: Forward unchanged (no transformation)
    Relay->>Router: chrome.runtime.sendMessage({<br/>  type: 'wordpress',<br/>  action: 'SIP_REQUEST_EXTENSION_STATUS',<br/>  source: 'sip-plugins-core'<br/>})
    
    Note over Router: handleMessage(message, sender, sendResponse)
    Router->>Router: Log WordPress action (no transformation needed)
    Router->>Router: Route to handler based on type: 'wordpress'
    
    Router->>Handler: handler.handle({<br/>  type: 'wordpress',<br/>  action: 'SIP_REQUEST_EXTENSION_STATUS',<br/>  ...<br/>}, sender, sendResponse, routerContext)
    
    Note over Handler: Check request.action
    Handler->>Handler: case 'SIP_REQUEST_EXTENSION_STATUS'
    Handler->>Handler: Get manifest version & capabilities
    
    Handler-->>Router: sendResponse({<br/>  success: true,<br/>  type: 'SIP_EXTENSION_DETECTED',<br/>  extension: {<br/>    slug: 'sip-printify-manager-extension',<br/>    version: manifest.version,<br/>    capabilities: {...}<br/>  }<br/>})
    
    Router-->>Relay: chrome.runtime response
    
    Note over Relay: Pass response directly (no wrapping)
    Relay-->>BEM: window.postMessage({<br/>  success: true,<br/>  type: 'SIP_EXTENSION_DETECTED',<br/>  extension: {<br/>    slug: 'sip-printify-manager-extension',<br/>    version: manifest.version,<br/>    capabilities: {...}<br/>  }<br/>}, window.location.origin)
    
    Note over BEM: Handle response
    BEM->>BEM: if (event.data.type === 'SIP_EXTENSION_DETECTED')
    BEM->>UI: $(document).trigger('extensionDetected', extension)
    UI->>UI: Update UI with extension info
    
    Note over UI: Example of other commands
    
    UI->>BEM: browserExtensionManager.sendMessage({...})
    BEM->>Relay: window.postMessage({<br/>  type: 'wordpress',<br/>  action: 'SIP_SHOW_WIDGET',<br/>  source: 'sip-printify-manager'<br/>}, window.location.origin)
    
    Note over Relay,Handler: Same flow - ALL messages go through router
```

## How

- WordPress sends messages in internal format: `{ type: 'wordpress', action: 'SIP_REQUEST_EXTENSION_STATUS', source: 'sip-printify-manager' }`
- Extension router checks `type` field to route to wordpress-handler.js
- Handler checks `request.action` to determine specific command
- Response is sent directly without wrapping
- Relay passes messages through unchanged in both directions

## Why

- **ALL messages through router**: Security model requires single validation point
- **Consistent message format**: No transformation needed throughout the flow
- **Event-driven detection**: No state storage prevents stale data
- **Request-based pattern**: Extension only responds when asked, reducing noise