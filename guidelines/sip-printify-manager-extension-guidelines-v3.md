# SiP Printify Manager Extension – Integrated Documentation {#top}

---

### TABLE OF CONTENTS

- [1. Overview](#overview)
- [2. Main Architecture - The Three Contexts](#architecture)
- [3. Content Scripts](#content-scripts)
- [4. Message Handlers](#message-handlers)
- [5. Widget UI & Terminal Display](#widget-ui-terminal-display)
- [6. Author Checklist](#author-checklist)

---

## 1. OVERVIEW {#overview}

### WHAT

The SiP Printify Manager Extension links three contexts to automate Printify product management in ways that are unavailable through the Printify public API:

1. **Browser Extension Context (Service Worker)** – Router, Message Handlers, Storage
2. **WordPress Admin Page Context** – WordPress Admin Page DOM, Widget UI, Content Scripts
3. **Printify Page Context** – Printify Page DOM, Printify Internal API, Widget UI, Content Scripts, Dynamic Scripts

### WHY

Printify's public API omits mock‑up images and some product attributes needed for SiP's automated template creation. The browser extension bridges that gap by harvesting data directly from the live Printify site while staying in sync with the WordPress plugin via in‑page messaging. The extension's three context architecture preserves security boundaries and minimises maintenance risk: each context can evolve independently while the relay and router that intermediates between them enforce a stable contract.

---

## 2. MAIN ARCHITECTURE - The Three Contexts {#architecture}

This block documents the extension's full three context architecture and their component parts.  All parts are fully detailed in the linked blocks that follow.

### I. WHAT

**Diagram 2: Main Architecture**

```mermaid
graph TD
  Chrome((Chrome<br/>Extension System))
  
  subgraph "Browser Extension Context (Service Worker)"
    Router((Router<br/>see HOW 2A))
    Router <-. tab pairs, config .-> Storage[(chrome.storage<br/>see HOW 2C)]
    Handlers <-. operation status .-> Storage
    Router --> Handlers[Message Handlers<br/>see Section 4]
    Storage --> EventLogs[(Event Logs<br/>sipExtensionLogs<br/>see Section 5)]
  end

  subgraph "WordPress Tab Context"
    WPPage[/WordPress Admin Page/]
    WPCS[Content Scripts<br/>see Section 3]
    WPCS --> WUI1[Widget UI<br/>see Section 5]
    WPCS -->|postMessage| WPPage
    WPPage -->|postMessage| WPCS
    WPCS -->|chrome.runtime| Router
    WPCS <-. widget state .-> Storage
    WUI1 <-. widget state .-> Storage
  end

  subgraph "Printify Tab Context"
    PrintifyPage[/Printify.com Page/]
    PCS[Content Scripts<br/>see Section 3]
    PCS --> WUI2[Widget UI<br/>see Section 5]
    DIS[Dynamically Injected Scripts]
    InternalAPI[(Printify Internal API XHR)]
    PrintifyPage --> InternalAPI
    InternalAPI -. intercept .-> DIS
    PrintifyPage -. URL params .-> PCS
    PCS -. DOM manipulation .-> PrintifyPage
    PCS <-. widget state .-> Storage
    WUI2 <-. widget state .-> Storage
    DIS -. API data .-> Router
    Router -. URL params .-> PrintifyPage
    Router -. inject scripts .-> DIS
    Router -.->|DISPLAY_UPDATE| PCS
    Router -.->|DISPLAY_UPDATE| WPCS
  end
  
  Chrome -.->|injects| WPCS
  Chrome -.->|injects| PCS
  
  %% Style definitions
  classDef userFacingStyle fill:#90EE90,stroke:#228B22,stroke-width:2px
  classDef routerStyle fill:#87CEEB,stroke:#4682B4,stroke-width:2px
  classDef scriptStyle fill:#E6F3FF,stroke:#4169E1,stroke-width:1px
  classDef storageStyle fill:#F8F3E8,stroke:#8B7355,stroke-width:2px
  classDef externalStyle fill:#FFFEF7,stroke:#DAA520,stroke-width:1px
  classDef groupStyle fill:#F3E8F8,stroke:#8B7AB8,stroke-width:2px
  classDef chromeStyle fill:#E6F3FF,stroke:#4169E1,stroke-width:2px
  
  %% Apply styles to nodes
  class WPPage,PrintifyPage,WUI1,WUI2 userFacingStyle
  class Router routerStyle
  class WPCS,PCS,DIS scriptStyle
  class Storage,EventLogs storageStyle
  class InternalAPI externalStyle
  class Handlers scriptStyle
  class Chrome chromeStyle
```

**Diagram Legend:**

**Color Coding:**
- 🟩 **Green** - User-facing elements (web pages, UI widgets)
- 🔵 **Sky Blue** - Router (central message hub)
- 🔷 **Light Blue** - Script files and code components
- 🟣 **Purple** - Grouping/organizational nodes
- 🟫 **Tan** - Storage components
- 🟡 **Yellow** - External APIs/services
- ⬜ **Gray** - Actions/processes

### II. HOW

#### 2A The Router

> The Router (`widget-router.js`) is the extension's central message dispatcher, running in the Service Worker context. **All messages pass through the Router** - there are no direct connections between contexts. This single-point message flow ensures consistent validation, logging, and error handling.
> 
> The Router:
> - **Validates** incoming messages for required `context`, `action`, and `source` fields
> - **Routes** messages to registered handlers using compound keys (`context:action`)
> - **Preserves** `requestId` from incoming messages in all responses automatically
> - **Stores** all events in chrome.storage for historical viewing
> - **Forwards** display updates to all extension tabs (WordPress and Printify)
> - **Wraps Chrome APIs** with consistent error handling
> - **Manages tab pairing** ONLY for navigation (prevents duplicate tabs)
> - **Injects scripts** dynamically when manifest-declared scripts can't access needed APIs
> - **Updates extension badge** via chrome.action API to show status (✓ green for success, ! orange for warnings)
> 
> Message flow: Content Scripts → `chrome.runtime.sendMessage()` → Router → Handler → `chrome.tabs.sendMessage()` → Content Scripts
> 
> **Critical: Async Message Listener Configuration:**
> When the Router's `handleMessage` function is async, the chrome.runtime.onMessage listener MUST return `true` to keep the message channel open:
> ```javascript
> // CORRECT - Returns true for async handleMessage
> chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
>     handleMessage(message, sender, sendResponse);  // async function
>     return true;  // CRITICAL: Keep channel open for async response
> });
> 
> // WRONG - Channel closes before async handleMessage completes
> chrome.runtime.onMessage.addListener(handleMessage);  // No return true!
> ```
> 
> **Symptoms of missing `return true` in listener:**
> - Extension detection fails (button doesn't hide despite widget showing as connected)
> - Messages reach service worker but responses never arrive at WordPress page
> - 43 debugging steps in circles with false symptoms from debugging artifacts
> - "Could not establish connection" errors when testing from console
> 
> This is separate from handlers returning `true` (documented in Section 4) - both the listener AND async handlers must return `true`.
> 
> **Message Format:**
> All messages use the standardized format:
> ```javascript
> // Success format:
> {
>     context: 'wordpress' | 'printify' | 'extension',
>     action: 'SIP_FETCH_MOCKUPS' | 'SIP_NAVIGATE' | etc.,
>     source: 'sip-printify-manager' | 'sip-printify-extension',
>     requestId: 'mockup_123_1737547890123_x7k9m2p',  // Optional - preserved in responses
>     data: { ... }  // Optional payload
> }
> 
> // Error format:
> {
>     context: 'wordpress' | 'printify' | 'extension',
>     action: 'SIP_FETCH_MOCKUPS' | 'SIP_NAVIGATE' | etc.,
>     source: 'sip-printify-manager' | 'sip-printify-extension',
>     requestId: 'mockup_123_1737547890123_x7k9m2p',  // Optional - preserved in responses
>     error: 'Error message string'  // Error description
> }
> ```
> 
> **Field Definitions:**
> - **context** = Origin/category (where the message comes from)
> - **action** = Specific operation to perform (what to do)
> - **source** = Sender identification (which plugin/extension sent it)
> - **data** = Optional payload for the action (success cases)
> - **error** = Error message string (error cases, mutually exclusive with data)
> 
> **Handler Registration Pattern:**
> The Router implements a WordPress AJAX-style registration system that mirrors the SiP plugin pattern exactly:
> ```javascript
> // Register handlers with two-parameter pattern like WordPress
> registerHandler('wordpress', '*', wordpressHandler);  // Wildcard for all WordPress actions
> registerHandler('wordpress', 'SIP_FETCH_MOCKUPS', mockupFetchHandler);  // Specific action
> 
> // Routing logic tries specific first, then wildcard
> const handler = handlers[`${context}:${action}`] || handlers[`${context}:*`];
> ```
> 
> **Terminal Display Integration:**
> The Router stores and forwards operation messages for the terminal display:
> - Action messages: One-off status with category (success/error/warning/info)
> - Operation messages: Progress-tracked with percentage and completion status
> 
> These messages are:
> 1. Stored in `sipExtensionLogs` (max 500 entries) using internal storage format
> 2. Forwarded to tabs via `SIP_DISPLAY_UPDATE` messages (standardized format)
> 
> **Internal Storage Format (sipExtensionLogs):**
> ```javascript
> // Action entry (one-off status)
> {
>     type: 'action',
>     message: 'Blueprint updated',
>     category: 'success',  // or 'error', 'warning', 'info'
>     timestamp: 1634567890123
> }
> 
> // Operation entry (progress-tracked)
> {
>     type: 'operation',
>     progress: 45,        // 0-100
>     message: 'Updating mockups...',
>     complete: false,     // true when operation finishes
>     timestamp: 1634567890123
> }
> ```
> 
> **Display Update Messages:**
> The Router forwards display updates using standardized format:
> ```javascript
> {
>     context: 'extension',
>     action: 'SIP_DISPLAY_UPDATE',
>     source: 'sip-printify-manager-extension',
>     data: {
>         type: 'action',  // or 'operation'
>         message: '...',
>         category: '...',  // for actions
>         progress: 45,     // for operations
>         complete: false   // for operations
>     }
> }
> ```
> 
> **Critical: Async Storage Race Condition:**
> The `storeEventLog()` function uses `chrome.storage.local.set()` which is asynchronous. When multiple log entries are written in quick succession without awaiting, a race condition occurs where later writes can overwrite earlier ones before they complete. To prevent this:
> - **Always** use `await storeEventLog(data)` to ensure sequential writes
> - **Never** call `storeEventLog()` without await in loops or rapid sequences
> - This applies to all contexts where `storeEventLog()` is called
> 
> **Injected Tabs Tracking:**
> To prevent "Could not establish connection" errors, the Router maintains a Set of tab IDs where content scripts are loaded:
> - Content scripts announce readiness via `chrome.runtime.sendMessage({ context: 'extension', action: 'SIP_CONTENT_SCRIPT_READY', source: 'sip-printify-manager-extension' })`
> - Router adds tabs to Set after successful script injection during `onInstalled`
> - Tabs removed from Set when closed (`onRemoved`) or navigating (`onUpdated` with status='loading')
> - `forwardDisplayUpdate` only sends to tabs in this Set
> 
> **Tab Pairing Usage Guidelines:**
> - ✅ **USE** for `navigateTab()` - Prevents duplicate tabs, reuses existing ones
> - ❌ **DON'T USE** for message broadcasting - Use injectedTabs tracking instead
> - ❌ **DON'T USE** for display updates - Terminal should update in all contexts
> 
> <details>
> <summary>Message Broadcasting Pattern (Current Implementation)</summary>
> 
> ```javascript
> // Only send to tabs we know have content scripts
> for (const tabId of injectedTabs) {
>     try {
>         await chrome.tabs.sendMessage(tabId, {
>             context: 'extension',
            action: 'SIP_DISPLAY_UPDATE',
            source: 'sip-printify-manager-extension',
>             data: data
>         });
>     } catch (error) {
>         // Tab closed or navigated - remove from Set
>         injectedTabs.delete(tabId);
>     }
> }
> ```
> 
> </details>
> 
> **Dynamic Script Injection:** The Router uses `chrome.scripting.executeScript()` in two scenarios:
> 1. **API Interception**: When Printify's restrictions prevent manifest-declared content scripts from accessing needed APIs, the Router dynamically injects scripts that can intercept XHR responses and access Printify's internal data structures.
> 2. **Install/Update Events**: During extension install or update (`onInstalled`), the Router injects the full set of content scripts into already-open WordPress and Printify tabs, matching exactly what manifest.json declares for each context. This ensures pre-existing tabs receive complete extension functionality without requiring a page refresh.
> 
> **Pause/Resume System:** The Router includes built-in operation pausing for user intervention:
> - `pauseOperation(tabId, issue, instructions)` - Pauses operation and shows UI with instructions
> - `resumeOperation()` - Resumes when user clicks the resume button in the widget
> - Messages use internal format: `{ context: 'extension', action: 'SIP_RESUME_OPERATION', source: 'sip-printify-extension' }`
> - Automatically focuses the problematic tab and displays pause status in widget
> 
> **Configuration Loading:** The Router attempts to load pre-configuration from `assets/config.json`:
> - Contains optional pre-configured settings: `wordpressUrl`, `apiKey`, `autoSync`, `configured`
> - If `configured: true`, these settings are automatically applied on extension install
> - Falls back to chrome.storage.sync if config.json is unavailable
> - Useful for enterprise deployments with pre-configured extensions

#### 2B Documentation Links

> The following sections detail elements referenced in the Main Architecture Diagram.
>- **Content Scripts** → [Section 3: Content Scripts](#content-scripts)
>- **Message Handlers** → [Section 4: Message Handlers](#message-handlers)
>- **Widget UI & Terminal Display** → [Section 5: Widget UI & Terminal Display](#widget-ui-terminal-display)
>- **chrome.storage** → [See HOW 2C below](#storage-how)

#### 2C Storage {#storage-how}

> Chrome provides two storage areas for persisting extension data:
> 
> <details>
> <summary>Storage API Comparison</summary>
> 
> | API | Scope | Quota | Use Cases |
> |-----|-------|-------|-----------|
> | **chrome.storage.local** | Device-specific | 10MB | Large data, logs, state |
> | **chrome.storage.sync** | Synced across devices | 100KB total, 8KB per item | User settings, config |
> 
> </details>
> 
> <details>
> <summary>View all storage keys</summary>
> 
> | Key | Scope | Purpose | Schema | Size |
> |-----|-------|---------|----------|------|
> | `sipExtensionLogs` | local | Event logging for terminal display | Array of message objects (see Section 5) | Capped at 500 entries |
> | `sipWidgetState` | local | Widget UI persistence | `{isVisible, isExpanded, position, terminalContent, terminalState}` | ~1KB |
> | `sipTabPairs` | local | WP↔Printify tab mapping | `{[wpTabId]: printifyTabId}` bidirectional | ~500B |
> | `sipOperationStatus` | local | Current operation tracking | `{state, operation, task, progress, issue, timestamp}` | ~2KB |
> | `sip-extension-state` | local | Extension pause/resume state | `{isPaused, timestamp}` | ~100B |
> | `sipDiscoveries` | local | Printify data discovery catalog | `{api_endpoints[], dom_patterns[], data_structures[]}` (see Section 5) | ~10KB |
> | `fetchStatus_*` | local | Temporary fetch results | `{status, error, data, timestamp}` per product | ~50KB each |
> | `wordpressUrl` | sync | Cross-device WP URL | String URL | ~100B |
> | `apiKey` | sync | Cross-device auth | String (variable length) | ~50B |
> 
> </details>
> 
> <details>
> <summary>Storage Access Pattern</summary>
> 
> ```javascript
> // Read from storage
> chrome.storage.local.get(['sipWidgetState'], (result) => {
>   const state = result.sipWidgetState || {};
> });
> 
> // Write to storage  
> chrome.storage.local.set({
>   sipOperationStatus: { state: 'idle', timestamp: Date.now() }
> });
> ```
> 
> </details>
> 
> The extension auto-configures on WordPress admin pages by capturing the site URL and storing it in sync storage for cross-device access.

### III. WHY

Printify blocks Chrome.Runtime so content Scripts declared in manifest.json cannot use chrome.runtime features on the Printify site. However, the router can dynamically inject scripts to intercept API responses and relay data back.

Host permissions are limited to printify.com and wp-admin domains to minimize Chrome Web Store review friction while maintaining necessary access.

Web accessible resources include assets needed across origins: config.json, logo images, loading animation, and widget-styles.css.

---

## 3. CONTENT SCRIPTS {#content-scripts}

Content scripts are JavaScript files injected by Chrome into web pages based on URL patterns defined in manifest.json. They provide the bridge between web pages and the extension's background service worker.

### I. WHAT

**Diagram 3: Content Scripts Architecture**
```mermaid
graph LR
  Chrome((Chrome<br/>Extension System))
  
  subgraph "Browser Extension Context (Service Worker)"
    subgraph "Service Worker"
      SW[background.js] --> Router((widget-router.js))
      SW --> Handlers[Handler Scripts]
    end
    
    Storage[(chrome.storage)]
  end
  
  subgraph "WordPress Tab Context"
    subgraph "WordPress Bundle (Content Scripts)"
      WPBundle[WordPress Bundle<br/>manifest.json:43-59]
      WPBundle --> WE[widget-error.js<br/>see HOW 3C]
      WPBundle --> WTD1[widget-terminal-display.js<br/>see Section 5]
      WPBundle --> EC1[error-capture.js<br/>see HOW 3C]
      WPBundle --> WR[wordpress-relay.js<br/>see HOW 3A]
      WPBundle --> WT1[widget-tabs-actions.js<br/>see HOW 3C & Section 5]
      WPBundle --> WSS[widget-styles.css]
    end
    
    WPPage[/WordPress Admin Page<br/>wp-admin/*/]
    WR -->|postMessage| WPPage
    WPPage -->|postMessage| WR
  end
  
  subgraph "Printify Tab Context"
    subgraph "Printify Bundle (Content Scripts)"
      PBundle[Printify Bundle<br/>manifest.json:27-42]
      PBundle --> WE2[widget-error.js<br/>see HOW 3C]
      PBundle --> WTD2[widget-terminal-display.js<br/>see Section 5]
      PBundle --> EC2[error-capture.js<br/>see HOW 3C]
      PBundle --> WT2[widget-tabs-actions.js<br/>see HOW 3C & Section 5]
      PBundle --> MLA[mockup-library-actions.js<br/>see HOW 3B]
      PBundle --> PDA[product-details-actions.js<br/>see HOW 3B]
    end
    
    PrintifyPage[/Printify.com Pages/]
    MLA -.->|mockup selection| PrintifyPage
    PDA -.->|product inspection| PrintifyPage
  end
  
  WR -->|chrome.runtime| Router
  Router -->|chrome.tabs| WR
  Router -.->|DISPLAY_UPDATE| WTD1
  Router -.->|DISPLAY_UPDATE| WTD2
  Router -.->|inject scripts| PrintifyPage
  WT1 -.->|widget state| Storage
  WT2 -.->|widget state| Storage
  
  Chrome -.->|injects per<br/>manifest.json| WPBundle
  Chrome -.->|injects per<br/>manifest.json| PBundle
  
  %% Style definitions
  classDef userFacingStyle fill:#90EE90,stroke:#228B22,stroke-width:2px
  classDef routerStyle fill:#87CEEB,stroke:#4682B4,stroke-width:2px
  classDef scriptStyle fill:#E6F3FF,stroke:#4169E1,stroke-width:1px
  classDef storageStyle fill:#F8F3E8,stroke:#8B7355,stroke-width:2px
  classDef groupStyle fill:#F3E8F8,stroke:#8B7AB8,stroke-width:2px
  classDef chromeStyle fill:#E6F3FF,stroke:#4169E1,stroke-width:2px
  
  %% Apply styles
  class WPPage,PrintifyPage userFacingStyle
  class Router routerStyle
  class WE,WE2,WTD1,WTD2,EC1,EC2,WR,WT1,WT2,MLA,PDA scriptStyle
  class Storage storageStyle
  class WPBundle,PBundle groupStyle
  class Chrome chromeStyle
```
[← Back to Diagram 2: Main Architecture](#architecture)

### II. HOW

The Browser Extension Context shows the Service Worker, which is Chrome's background execution environment for the extension. The Service Worker loads background.js, which in turn imports all the handler scripts and the Router via `importScripts()`.

#### 3A wordpress-relay.js

> The `wordpress-relay.js` script acts as a secure message bridge between WordPress pages and the extension. It uses two separate listeners to handle bidirectional communication while preventing infinite loops.
> 
> <details>
> <summary>View relay architecture and functions</summary>
> 
> **Two-Listener Architecture:**
> 
> 1. **`window.addEventListener('message')`** - Receives messages FROM WordPress page
>    - Validates origin matches `window.location.origin`
>    - Ignores messages with `source: 'sip-printify-manager-extension'` to prevent loops
>    - Forwards valid WordPress messages (`source: 'sip-printify-manager'` or `sip-plugins-core`) to Router via `chrome.runtime.sendMessage`
> 
> 2. **`chrome.runtime.onMessage.addListener`** - Receives messages FROM Router/handlers  
>    - Listens for responses with `source: 'sip-printify-manager-extension'`
>    - Forwards these responses back to WordPress page via `window.postMessage`
>    - This enables handlers to send responses that reach the WordPress plugin
> 
> | Function | Purpose | Implementation |
> |----------|---------|----------------|
> | Origin validation | Security check | Only accepts messages from `window.location.origin` |
> | Source filtering | Prevents loops | Ignores messages from `sip-printify-manager-extension` |
> | Message forwarding | WP → Router | Validates source is `sip-printify-manager` or `sip-plugins-core` |
> | Response relay | Router → WP | Forwards responses with `source: 'sip-printify-manager-extension'` via `window.postMessage` |
> | Terminal display | Log events | Sends action/operation messages to Router |
> 
> **Critical Design:**
> The same source value (`sip-printify-manager-extension`) is used for both:
> - Ignoring messages in the window listener (preventing loops)
> - Forwarding messages in the chrome.runtime listener (enabling responses)
> 
> This ensures responses can flow back to WordPress while preventing infinite message loops.
> 
> </details>

#### 3B Printify-Specific Scripts

> The Printify bundle includes scripts that handle Printify-specific automation and data extraction:
> 
> <details>
> <summary>Printify-Specific Scripts Table</summary>
> 
> | Script | Purpose | When Active |
> |--------|---------|-------------|
> | **mockup-library-actions.js** | Automates mockup selection by clicking UI elements based on scene names | Mockup library page when automation parameters present |
> | **product-details-actions.js** | Extracts product data, mockup URLs, and variant information from DOM | Product detail pages |
> 
> </details>
> 
> **Communication Patterns:**
> - Scripts use `chrome.runtime.sendMessage()` to send messages to the Router
> - Router uses `chrome.tabs.sendMessage()` to send messages to content scripts
> - Router can inject additional scripts via `chrome.scripting.executeScript()` (shown as "inject scripts" arrow)

#### 3C Shared Bundle Scripts

> Both WordPress and Printify bundles include these core scripts for error handling and UI:
> 
> <details>
> <summary>Shared Bundle Scripts Table</summary>
> 
> | Script | Purpose | Shared Functionality |
> |--------|---------|---------------------|
> | **widget-error.js** | Global error handler | Provides `window.showError()` for consistent error display |
> | **widget-terminal-display.js** | Terminal display component | Receives DISPLAY_UPDATE messages and shows real-time progress |
> | **error-capture.js** | Runtime error interceptor | Catches uncaught errors and promise rejections for logging |
> | **widget-tabs-actions.js** | Widget UI creator | Builds the floating widget interface, manages state, includes Discovery Tool for Printify data collection (see Section 5) |
> 
> </details>
> 
> **Other Bundle Contents:**
> - **widget-styles.css** - Comprehensive styles for the floating widget UI
>   - Injected into WordPress pages via manifest and dynamically into other pages
>   - Includes styles for: floating widget, terminal display, modal dialogs, toast notifications
>   - Responsive design with drag-and-drop support and smooth animations
>   - Dark theme terminal with syntax highlighting for log entries
>   - Listed in web_accessible_resources for cross-origin access

### III. WHY

Chrome's content script architecture provides security isolation between web pages and extension code. Scripts injected into web pages run in an "isolated world" with access to the DOM but not the page's JavaScript, preventing malicious sites from accessing extension APIs. The two-bundle approach reflects the different needs: WordPress pages need the relay to communicate with the plugin, while Printify pages need automation scripts to interact with the UI. The postMessage/chrome.runtime message flow bridges these isolated contexts while maintaining security boundaries.

---

## 4. MESSAGE HANDLERS {#message-handlers}

Message handlers process messages received by the Router based on their context and action, implementing the extension's core functionality.

**Handler Architecture:**
The extension mirrors the WordPress AJAX pattern exactly:
- **Context-based routing**: Messages routed by their `context` field (wordpress|printify|extension)
- **Plain function handlers**: No object wrappers or methods, just functions with switch statements
- **Two-parameter registration**: `registerHandler(context, action, handler)` like WordPress
- **Wildcard support**: Context handlers use '*' to handle all actions from that context

**Message Format:**
All messages follow the standardized structure:
```javascript
{
    context: 'wordpress' | 'printify' | 'extension',
    action: 'SIP_FETCH_MOCKUPS' | 'SIP_NAVIGATE' | etc.,
    source: 'sip-printify-manager' | 'sip-printify-extension',
    requestId: 'mockup_123_1737547890123_x7k9m2p',  // Optional - for request/response correlation
    data: { ... }  // Optional payload
}
```

**Request ID Correlation:**
- WordPress plugins generate unique request IDs using `SiP.Core.utilities.generateRequestId(prefix)`
- Format: `prefix_timestamp_random` (e.g., `mockup_123_1737547890123_x7k9m2p`)
- The Router preserves `requestId` in responses automatically
- Enables matching async responses to their originating requests
- Critical for operations like concurrent mockup fetches

**Action Naming Convention:**
All actions use `SIP_` prefix with CAPS_WITH_UNDERSCORES:
- Consistent with WordPress/PHP conventions
- Universal prefix indicates SiP system membership
- Context field already indicates origin

**⚠️ CRITICAL: Service Worker Context**
All message handlers run in the Service Worker context (same as the Router). This means:
- ❌ **CANNOT** use `chrome.runtime.sendMessage()` - it won't work within the same context
- ✅ **MUST** use direct router methods for reporting status:
  - `router.reportOperation(progress, message, complete)` - For progress-tracked operations
  - `router.reportAction(message, category)` - For one-off status messages

This is a common source of bugs where operation messages don't appear in the terminal display.

**⚠️ CRITICAL: Async Operations Require Two `return true` Statements**
For async message handling to work correctly:
1. **The listener** must return `true` (see Section 2A for Router configuration)
2. **The handler** must return `true` when calling sendResponse asynchronously

Both are required - if either is missing, the message channel closes prematurely and responses are lost.

### I. WHAT

**Diagram 4: Message Handlers Architecture**
```mermaid
graph TD
  subgraph "Service Worker (Background)"
    Router((Router<br/>Message Dispatcher))
    
    subgraph "Handler Registration"
      REG[registerHandler Function<br/>see HOW 4F]
    end
    
    subgraph "Context Handlers"
      WH[wordpress-handler.js<br/>see HOW 4A]
      EH[extension-handler.js<br/>see HOW 4B]
      PH[printify-handler.js<br/>see HOW 4C]
    end
    
    subgraph "Specific Action Handlers"
      MFH[mockup-fetch-handler.js<br/>see HOW 4D]
      MUH[mockup-update-handler.js<br/>see HOW 4E]
    end
    
    REG -->|wordpress:*| WH
    REG -->|extension:*| EH
    REG -->|printify:*| PH
    REG -->|wordpress:SIP_FETCH_MOCKUPS| MFH
    REG -->|wordpress:SIP_UPDATE_PRODUCT_MOCKUPS| MUH
  end
  
  WPPage[/"WordPress Page"/] --> WPRelay[wordpress-relay.js]
  WPRelay -->|{context: 'wordpress',<br/>action: 'SIP_*'}| Router
  
  Router -->|Route by compound key| REG
  Router -. commands .-> CS[Content Scripts]
  Router -. events .-> EventLogs[(Event Logs)]
  
  %% Style definitions
  classDef userFacingStyle fill:#90EE90,stroke:#228B22,stroke-width:2px
  classDef routerStyle fill:#87CEEB,stroke:#4682B4,stroke-width:2px
  classDef scriptStyle fill:#E6F3FF,stroke:#4169E1,stroke-width:1px
  classDef storageStyle fill:#F8F3E8,stroke:#8B7355,stroke-width:2px
  
  %% Apply styles
  class WPPage userFacingStyle
  class Router routerStyle
  class WH,EH,PH,MFH,MUH,WPRelay,CS,REG scriptStyle
  class EventLogs storageStyle
```
[← Back to Diagram 2: Main Architecture](#architecture)

### II. HOW

#### 4A WordPress Handler

> Processes commands from the WordPress plugin:
> 
> <details>
> <summary>View WordPress message types</summary>
>
> | Message Type | Action | Response |
> |--------------|--------|----------|
> | `SIP_REQUEST_EXTENSION_STATUS` | Confirms extension is active | `SIP_EXTENSION_DETECTED` |
> | `SIP_NAVIGATE` | General navigation request | Success/failure |
> | `SIP_OPEN_TAB` | Opens new tab with URL | Tab ID or error |
> | `SIP_TOGGLE_WIDGET` | Toggles widget collapsed/expanded | Success/failure |
> | `SIP_SHOW_WIDGET` | Ensures widget is visible | Success/failure |
> | `SIP_FETCH_MOCKUPS` | Initiates mockup data fetch (routes to MockupFetchHandler) | `SIP_MOCKUP_DATA` response |
> | `SIP_UPDATE_PRODUCT_MOCKUPS` | Updates product mockups (routes to MockupUpdateHandler) | `SIP_MOCKUP_UPDATE_COMPLETE` |
> | `SIP_CLEAR_STATUS` | Clears operation status | Success/failure |
> 
> **Key Functions:**
> - Routes messages to appropriate handlers based on action
> - Widget commands handled within this handler
> - Mockup operations routed to their specific handlers
> - Returns standardized success/error responses
> 
> **Extension Detection Pattern:**
> 
> | Component | Implementation | Purpose |
> |-----------|----------------|---------|
> | Two‑stage widget display | Content scripts always injected, widget revealed only on `SIP_SHOW_WIDGET` | Prevents widget clutter |
> | Message identification | Via `source` string (`sip‑printify-extension`) | Distinguishes from other extensions |
> | Validation chain | origin → source → structure | Security verification |
> | Stateless detection | Request/response each time; no proactive announcements | Reduces message noise |
> | Edge‑case handling | Missing `source`, cross‑origin messages, self‑responses | Robustness |
>
> </details>

#### 4B Extension Handler

> Processes extension-internal messages for UI control, status updates, and error logging:
> 
> <details>
> <summary>View extension handler actions</summary>
> 
> | Action | Purpose | Implementation |
> |--------|---------|----------------|
> | `SIP_SHOW_WIDGET` | Makes widget visible | Shows widget UI |
> | `SIP_TOGGLE_WIDGET` | Toggle widget collapsed/expanded | Updates widget state |
> | `SIP_LOG_ERROR` | Log error to extension logs | Stores in sipExtensionLogs |
> | `SIP_UPDATE_PROGRESS` | Update operation progress | Updates terminal display |
> | `SIP_CLEAR_LOGS` | Clear log history | Clears sipExtensionLogs |
> | `SIP_PING` | Health check | Returns pong response |
> | `SIP_CHECK_STATUS` | Get current operation status | Returns status object |
> 
> **Key Implementation:**
> - Handles all `context: 'extension'` messages
> - Uses switch statement to route actions
> - Direct access to chrome.storage for state management
> - Auto-expands widget on operation messages
> 
> </details>

#### 4C Printify Handler

> Processes data and responses from Printify pages:
> 
> <details>
> <summary>View Printify handler actions</summary>
> 
> | Action | Purpose | Response |
> |--------|---------|----------|
> | `SIP_UPDATE_STATUS` | Update operation status | Status stored |
> | `SIP_GET_STATUS` | Get current status | Returns status object |
> | `SIP_PRODUCT_DATA` | Product data from page | Processed and stored |
> | `SIP_MOCKUP_API_RESPONSE` | Intercepted API response | Transforms and forwards data |
> | `SIP_REPORT_ERROR` | Error from Printify page | Logs error |
> 
> **Key Implementation:**
> - Handles all `context: 'printify'` messages
> - Processes intercepted Printify API responses
> - Transforms raw Printify data to SiP format
> - Reports status back to WordPress
> 
> </details>

#### 4D Mockup Fetch Handler

> Handles the complex operation of fetching mockup data from Printify:
> 
> <details>
> <summary>Mockup Fetch Operation Flow</summary>
> 
> **Operation Flow:**
> 1. Receives `SIP_FETCH_MOCKUPS` from WordPress with blueprint data
> 2. Navigates to Printify mockup library page
> 3. Injects API interceptor script
> 4. Waits for Printify API response
> 5. Transforms data and returns to WordPress
> 
> **Script Injection Architecture:**
> The handler injects two scripts into different execution contexts on the Printify page:
> 
> 1. **ISOLATED World Script** (`setupMessageRelay`):
>    - Runs in Chrome's isolated context with access to chrome.runtime API
>    - Listens for window messages from MAIN world
>    - Forwards messages to Router via `chrome.runtime.sendMessage()`
>    - Messages already in standardized format, forwarded as-is
> 
> 2. **MAIN World Script** (`interceptMockupAPI`):
>    - Runs in page context with access to Printify's JavaScript environment
>    - Intercepts fetch/XHR responses for mockup data
>    - Posts messages using standardized format:
>    ```javascript
>    window.postMessage({
>        context: 'printify',
>        action: 'SIP_MOCKUP_API_RESPONSE',
>        source: 'sip-printify-manager-extension',
>        data: mockupData  // For success
>        // OR
>        error: 'Error message'  // For errors
>    }, window.location.origin);
>    ```
> 
> **Why Two Scripts:** Printify blocks chrome.runtime in content scripts, but the MAIN world can access Printify's data. The ISOLATED world bridges this gap by relaying messages to the Router.
> 
> **Progress Reporting:**
> ```javascript
> router.reportOperation(10, `Fetching Mockups: Preparing to fetch mockup data for ${displayName}`);
> router.reportOperation(25, 'Fetching Mockups: Navigating to mockup library...');
> router.reportOperation(45, 'Fetching Mockups: Loading mockup data...');
> router.reportOperation(90, 'Fetching Mockups: Processing mockup data...');
> router.reportOperation(100, 'Fetching Mockups: Complete', true);
> ```
> 
> **Blueprint Name Usage:**
> - Receives `blueprint_name` in request data
> - Uses name in all progress messages for user clarity
> - Falls back to `Blueprint #${blueprint_id}` if name missing
> 
> </details>

#### 4E Mockup Update Handler

> Handles updating product mockups on Printify:
> 
> <details>
> <summary>Mockup Update Operation Flow</summary>
> 
> **Operation Flow:**
> 1. Receives `SIP_UPDATE_PRODUCT_MOCKUPS` with product and mockup data
> 2. Navigates to product page with automation parameters
> 3. Content scripts automatically select mockups
> 4. Monitors for completion or issues
> 5. Handles pause/resume for user intervention
> 
> **Pause/Resume System:**
> - Detects when manual intervention needed
> - Pauses operation with clear instructions
> - Shows resume button in widget
> - Continues when user resolves issue
> 
> **Error Handling:**
> - Validates product exists before navigation
> - Checks mockup availability
> - Reports specific errors to terminal
> - Allows retry after error resolution
> 
> </details>

#### 4F Message Validation

> All messages pass through comprehensive validation in the Router:
>
> 1. **Structure Check**: Message must have `context`, `action`, and `source` fields
> 2. **Context Validation**: Must be one of: wordpress, printify, extension
> 3. **Source Validation**: WordPress messages verified by source and origin
> 4. **Handler Lookup**: Uses compound key `${context}:${action}` or wildcard `${context}:*`
> 5. **Response Wrapping**: Success/error responses formatted consistently
> 6. **Event Logging**: All action/operation messages stored in sipExtensionLogs
> 7. **Display Forwarding**: Updates broadcast to all extension tabs via DISPLAY_UPDATE
>
> **Registration Pattern Example:**
> ```javascript
> function registerHandler(context, action, handler) {
>     if (typeof handler !== 'function') {
>         console.error(`Invalid handler for ${context}:${action}: must be a function`);
>         return;
>     }
>     
>     const key = `${context}:${action}`;
>     handlers[key] = handler;
>     console.log(`Registered handler for ${key}`);
> }
> ```

#### 4G Request/Response Correlation

> For async operations that need response matching, the extension uses request IDs:
>
> **Implementation Flow:**
> 1. WordPress generates unique ID: `SiP.Core.utilities.generateRequestId('operation_123')`
> 2. Includes `requestId` in message to extension
> 3. Router automatically preserves `requestId` in all responses
> 4. WordPress matches response by checking `requestId` field
>
> **Example: Concurrent Mockup Fetches**
> ```javascript
> // WordPress Plugin Side:
> const requestId = SiP.Core.utilities.generateRequestId('mockup_' + blueprintId);
> 
> window.postMessage({
>     context: 'wordpress',
>     action: 'SIP_FETCH_MOCKUPS',
>     source: 'sip-printify-manager',
>     requestId: requestId,  // Will be preserved in response
>     data: { blueprint_id: blueprintId }
> }, '*');
> 
> // Listen for response with matching requestId
> window.addEventListener('message', function(event) {
>     if (event.data && 
>         event.data.action === 'SIP_MOCKUP_DATA' &&
>         event.data.requestId === requestId) {
>         // This is our response
>         processResponse(event.data);
>     }
> });
> 
> // Extension Handler Side:
> function mockupFetchHandler(request, sender, sendResponse) {
>     // Do async work...
>     sendResponse({
>         success: true,
>         context: 'extension',
>         action: 'SIP_MOCKUP_DATA',
>         source: 'sip-printify-manager-extension',
>         // requestId automatically preserved by router
>         data: { mockupData: {...} }
>     });
>     return true; // Keep channel open for async
> }
> ```
>
> **Benefits:**
> - Multiple operations can run concurrently without confusion
> - Each request can have independent timeout handling
> - Request/response pairs are easily traced in logs
> - Stale responses from previous operations are ignored

### III. WHY

The handler architecture mirrors WordPress AJAX exactly, making it immediately familiar to SiP developers. The two-parameter registration pattern (`context`, `action`) creates a predictable system where handlers can be registered at any granularity - from handling all messages from a context to handling a single specific action.

Using plain functions instead of object wrappers reduces complexity and matches WordPress conventions. The compound key routing (`context:action`) with wildcard fallback provides flexibility while maintaining clear boundaries. Universal SIP_ prefix for actions prevents naming collisions while the context field already indicates message origin.

Separating complex operations (mockup fetch/update) into dedicated handlers keeps the codebase modular and maintainable. The direct router method calls from handlers (instead of chrome.runtime.sendMessage) avoid the common bug where messages disappear because they can't be sent within the same Service Worker context.

---

## 5. WIDGET UI & TERMINAL DISPLAY {#widget-ui-terminal-display}

The Widget UI provides a floating interface for monitoring extension operations, viewing logs, and debugging issues across both WordPress and Printify contexts. The terminal display system within the widget shows real-time progress and historical event logs.

### I. WHAT

**Diagram 5: Widget UI & Terminal Display Architecture**
```mermaid
graph TD
  subgraph "Service Worker"
    Router((Router<br/>Message Hub))
    Storage[(chrome.storage<br/>sipExtensionLogs)]
    Router -->|Store events| Storage
  end
  
  subgraph "Widget UI Components"
    WTA[widget-tabs-actions.js<br/>Widget Creator]
    WTD[widget-terminal-display.js<br/>Terminal Component]
    
    subgraph "UI Elements"
      FW[Floating Widget Container<br/>see HOW 5A]
      Terminal[Terminal Display<br/>see HOW 5B]
      LogViewer[Log Viewer<br/>see HOW 5C]
      Modal[Modal System<br/>see HOW 5D]
      Controls[Control Buttons<br/>see HOW 5E]
    end
    
    WTA --> FW
    WTA --> Modal
    WTA --> Controls
    WTD --> Terminal
    WTD --> LogViewer
  end
  
  subgraph "Context-Specific Features"
    WP[WordPress Context<br/>- View discoveries only<br/>- Shows on: SiP Manager admin pages]
    PR[Printify Context<br/>- Collect & view discoveries<br/>- API interception<br/>- Shows on: all printify.com pages]
  end
  
  %% Data flow
  Router -->|DISPLAY_UPDATE| WTD
  Storage -->|Read logs| LogViewer
  WTA --> WP
  WTA --> PR
  
  %% Storage connections
  FW <-->|widget state| Storage
  PR <-->|discoveries| Storage
  
  %% External triggers
  ExtIcon[Extension Icon] -->|toggleWidget| WTA
  Messages[Extension Messages] -->|SIP_SHOW_WIDGET| WTA
  
  %% Style definitions
  classDef userFacingStyle fill:#90EE90,stroke:#228B22,stroke-width:2px
  classDef storageStyle fill:#F8F3E8,stroke:#8B7355,stroke-width:2px
  classDef actionStyle fill:#F0F0F0,stroke:#808080,stroke-width:1px
  classDef scriptStyle fill:#E6F3FF,stroke:#4169E1,stroke-width:1px
  classDef contextStyle fill:#F3E8F8,stroke:#8B7AB8,stroke-width:2px
  classDef routerStyle fill:#87CEEB,stroke:#4682B4,stroke-width:2px
  
  %% Apply styles
  class WTA,WTD scriptStyle
  class FW,Terminal,LogViewer,Modal,Controls userFacingStyle
  class Storage storageStyle
  class ExtIcon,Messages actionStyle
  class WP,PR contextStyle
  class Router routerStyle
```
[← Back to Diagram 2: Main Architecture](#architecture)

### II. HOW

#### 5A Widget Container

> The floating widget is created once per tab by widget-tabs-actions.js and persists across page navigations:
>
> <details>
> <summary>Widget Container Components</summary>
> 
> | Component | Purpose | Implementation |
> |-----------|---------|----------------|
> | **Container** | Main UI frame | Draggable, collapsible, saves position to storage |
> | **Header** | Title & controls | "SiP Extension" with expand/collapse button |
> | **Body** | Content area | Contains terminal display and controls |
> | **State Persistence** | Remember UI state | Saves to `sipWidgetState` in chrome.storage |
> 
> </details>

#### 5B Terminal Display

> The terminal display component (widget-terminal-display.js) shows real-time operation progress and action messages:
>
> The terminal receives display updates via `SIP_DISPLAY_UPDATE` messages from the Router.
> See Section 2A for the internal storage format and message structure.
>
> <details>
> <summary>Terminal Display Data Processing</summary>
> 
> The terminal component:
> - Receives `SIP_DISPLAY_UPDATE` messages from the Router
> - Extracts the `data` field which contains the terminal display information  
> - Renders based on `type` field:
>   - `'action'`: Shows status message with colored category indicator
>   - `'operation'`: Shows progress bar with percentage
> - Auto-expands widget when operations start (not on completion)
> 
> </details>
>
> **Display States:**
> - **Idle (READY)**: No active operations, shows "..." or previous message
> - **Active (PROCESSING...)**: Operation in progress with percentage
> - **Completion**: Shows SUCCESS/ERROR/WARNING briefly, then returns to idle
>
> **Auto-Expand Behavior:**
> - Widget automatically expands when receiving an operation message (not complete)
> - Ensures users see operation progress without manual interaction
> - Only triggers if widget is currently collapsed
> - Implemented in `TerminalDisplay.autoExpandWidget()` method

#### 5C Log Viewer

> The log viewer shows historical events from `sipExtensionLogs`:
>
> <details>
> <summary>Log Viewer Column Mapping</summary>
> 
> | Column | Source | Display Logic |
> |--------|--------|---------------|
> | Time | `timestamp` | Locale time string |
> | Site | Current domain | `window.location.hostname` |
> | Status | Derived | Actions: SUCCESS/ERROR/WARNING/INFO<br>Operations: Progress % or COMPLETE |
> | Category | `type` | ACTION or OPERATION |
> | Action | `message` | The message text |
> 
> </details>
>
> **Features:**
> - 500 entry limit (automatic trimming)
> - Copy to clipboard functionality
> - Clear logs button
> - Auto-refresh on new events

#### 5D Modal System

> VanillaModal implementation for dialogs:
> - Discovery Report modal
> - Future: Configuration dialogs
> - Saves position between uses
> - Dark theme styling

#### 5E Control Buttons

> Widget control interface:
>
> <details>
> <summary>Control Button Functions</summary>
> 
> | Button | Function | Visibility |
> |--------|----------|------------|
> | Expand/Collapse | Toggle widget size | Always |
> | Clear Terminal | Clear log display | Always |
> | Copy Log | Copy logs to clipboard | Always |
> | Hide Widget | Hide until next trigger | Always |
> | Discovery Report | View collected data | Shows "NEW" badge when unseen items |
> 
> </details>

#### 5F Discovery Tool

> The Discovery Tool passively collects Printify data patterns:
>
> **Implementation (Printify Context Only):**
> - `initDiscoverySystem()` - Called once on page load
> - `analyzePageOnce()` - DOM analysis for data attributes
> - `setupDiscoveryIntercept()` - Fetch API interception
> - `saveDiscoveries()` - Deduplicates and stores findings
>
> <details>
> <summary>Discovery Storage Schema</summary>
> 
> ```javascript
> // sipDiscoveries storage structure
> {
>   api_endpoints: [{
>     url: string,
>     method: string,
>     timestamp: number,
>     hasSeenBefore: boolean
>   }],
>   dom_patterns: [{
>     pattern: string,
>     example: string,
>     count: number,
>     timestamp: number,
>     hasSeenBefore: boolean
>   }],
>   data_structures: [{
>     name: string,
>     fields: string[],
>     source: string,
>     timestamp: number,
>     hasSeenBefore: boolean
>   }]
> }
> ```
> 
> </details>

### III. WHY

The Widget UI serves as the primary debugging interface for the extension, providing real-time visibility into operations without requiring developer tools. The terminal display system replaces the previous ActionLogger with a unified approach where all messages flow through the Router for consistent logging and display.

The separation between high-level batch progress (WordPress) and granular operation progress (Extension) enables fluid user experience without complex polling. The 500-line log buffer and auto-hide behavior balance information availability with screen real estate.

Display updates are broadcast to tabs tracked in the `injectedTabs` Set, ensuring terminal visibility regardless of message origin (WordPress tab, Printify tab, or service worker). This approach eliminates both the "no origin tab" problem when handlers run in service worker context and the "Could not establish connection" errors from sending to tabs without content scripts. Tab pairing remains focused solely on its primary purpose: preventing duplicate tabs during navigation.

---

## 6. AUTHOR CHECKLIST {#author-checklist}

- [ ] All code in specified files is documented in WHW blocks
- [ ] Intro sentence explains each block scope
- [ ] Each WHAT layer present with clear architecture (diagram or bullets)
- [ ] HOW layers collectively contains all implementation detail and do not repeat information
- [ ] WHY layer does not repeat HOW layer
- [ ] WHW Blocks in the hierarchy hang together through node references
- [ ] Links, file paths, and diagram references verified


[Back to Top](#top)