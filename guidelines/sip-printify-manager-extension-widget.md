# SiP Printify Manager Browser Extension

**Repository Location**: Flexible - can be located anywhere on the file system when added via SiP Development Tools  
**GitHub:** https://github.com/tdemelle-SiP/sip-printify-manager-extension

<!-- DOCUMENTATION RULES:
1. ARCHITECTURAL WHY - Document WHY each component exists (constraints/requirements that necessitate it)
2. NO HISTORY - Current state only, not how we got here  
3. NO DUPLICATION - Each fact appears exactly once
4. EXAMPLES OVER EXPLANATIONS - Show, don't tell
5. UPDATE THE RIGHT SECTION - Check if info already exists before adding

ARCHITECTURAL WHY GUIDELINE:
For each component, briefly explain the constraint or requirement that makes it necessary.
Focus on: Chrome API limitations, message passing rules, code organization needs.
Keep it to 1-2 sentences per component.
-->

## 1. Overview

The SiP Printify Manager browser extension is a standalone Chrome Web Store extension that integrates with the SiP Printify Manager WordPress plugin. It provides enhanced mockup data access and automated workflow capabilities that cannot be achieved through Printify's public API alone.

## 2. Architecture Diagrams

These two diagrams work together to provide a complete understanding of the extension architecture:

- **Message Flow Diagram** - Shows HOW messages flow through the system, illustrating the specific paths and transformations of data between components
- **System Overview Diagram** - Shows WHAT components exist and their relationships, providing a structural view of the entire system

Read the Message Flow diagram first to understand the communication patterns, then use the System Overview to see how components are organized and related.

### Message Flow Diagram

<!-- This diagram follows the SiP Mermaid guidelines showing every function in the data flow -->
```mermaid
graph TB
    subgraph "WordPress Page Context"
        subgraph "User Actions"
            UserAction[User triggers action]
        end
        
        subgraph "WordPress Code"
            WPCode[PHP renders page<br/>-browser-extension-manager-]
            SendMsg[JS sends message<br/>-sendMessageToExtension-]
        end
    end
    
    subgraph "Extension Content Scripts"
        RelayListen[JS listens for postMessage<br/>-widget-relay.js-]
        RelayConvert[JS converts format<br/>-handlePostMessage-]
        RelaySend[JS sends to router<br/>-chrome.runtime.sendMessage-]
        
        PTAListen[JS monitors page<br/>-printify-tab-actions.js-]
        PTASend[JS sends events<br/>-chrome.runtime.sendMessage-]
        
        WTACreate[JS creates widget<br/>-widget-tabs-actions.js-]
        WTAListen[JS listens for storage<br/>-chrome.storage.onChanged-]
    end
    
    subgraph "Extension Background"
        RouterReceive[JS receives message<br/>-handleMessage-]
        RouterRoute[JS routes by type<br/>-importHandlers-]
        
        WHProcess[JS handles widget ops<br/>-WidgetDataHandler.handle-]
        PHProcess[JS handles Printify ops<br/>-PrintifyDataHandler.handle-]
        WPHRoute[JS routes WordPress cmd<br/>-WordPressHandler.handle-]
        
        RouterAPI[JS executes Chrome APIs<br/>-createTab/queryTabs/etc-]
    end
    
    subgraph "Storage"
        ChromeLocal[(Chrome Storage<br/>-sipWidgetState-)]
        TabPairs[(Chrome Storage<br/>-sipTabPairs-)]
    end
    
    UserAction -->|triggers| SendMsg
    SendMsg -->|window.postMessage| RelayListen
    RelayListen -->|processes| RelayConvert
    RelayConvert -->|chrome.runtime.sendMessage| RouterReceive
    
    PTAListen -->|detects changes| PTASend
    PTASend -->|chrome.runtime.sendMessage| RouterReceive
    
    RouterReceive -->|analyzes type| RouterRoute
    RouterRoute -->|type: widget| WHProcess
    RouterRoute -->|type: printify| PHProcess
    RouterRoute -->|type: wordpress| WPHRoute
    
    WHProcess -->|chrome.storage.set| ChromeLocal
    PHProcess -->|chrome.storage.set| ChromeLocal
    WHProcess -->|chrome.tabs API| RouterAPI
    
    RouterAPI -->|manages| TabPairs
    ChromeLocal -->|onChange| WTAListen
    WTAListen -->|updates| WTACreate
```

**Key Message Flow Patterns**:
1. **WordPress → Extension**: Uses `window.postMessage` (only way to communicate from page to extension)
2. **Content Script → Background**: Uses `chrome.runtime.sendMessage` (required for privileged operations)
3. **Handler Delegation**: WordPressHandler translates commands and delegates to appropriate handlers
4. **Response Path**: Follows same path in reverse, maintaining callback chain
5. **State Updates**: Chrome Storage onChange events trigger UI updates without message passing
6. **Single-Point Validation**: All message validation happens in the router, relay only performs security checks

### System Overview Diagram

<!-- This diagram shows the system architecture and component relationships -->
```mermaid
flowchart TD
    subgraph "WordPress Environment"
        WPPlugin[SiP Printify Manager Plugin<br/>-PHP/JavaScript-]
        WPAjax[AJAX Handlers<br/>-admin-ajax.php-]
        WPDatabase[(WordPress Database<br/>-wp_options table-)]
        BrowserExtMgr[Browser Extension Manager<br/>-browser-extension-manager.js-]
    end
    
    subgraph "Chrome Extension - Content Scripts"
        WidgetRelay[Message Relay<br/>-widget-relay.js-]
        WidgetUI[Widget UI Manager<br/>-widget-tabs-actions.js-]
        PrintifyMonitor[Printify Page Monitor<br/>-printify-tab-actions.js-]
        MockupActions[Mockup Library Actions<br/>-mockup-library-actions.js-]
    end
    
    subgraph "Chrome Extension - Background"
        Router[Central Message Router<br/>-widget-router.js-]
        WidgetHandler[Widget Operations<br/>-widget-data-handler.js-]
        PrintifyHandler[Printify Operations<br/>-printify-data-handler.js-]
        MockupHandler[Mockup Operations<br/>-mockup-update-handler.js-]
        WordPressHandler[WordPress Commands<br/>-wordpress-handler.js-]
    end
    
    subgraph "External Systems"
        PrintifyAPI[Printify.com<br/>-Web Pages & API-]
        ChromeAPIs[Chrome Extension APIs<br/>-tabs, storage, runtime-]
    end
    
    subgraph "Storage Layer"
        ChromeStorage[(Chrome Storage<br/>-Extension State-)]
        TabPairs[(Tab Pairing System<br/>-WordPress ↔ Printify-)]
    end
    
    %% Communication channels
    WPPlugin <-->|AJAX| WPAjax
    WPAjax <-->|SQL| WPDatabase
    BrowserExtMgr -->|postMessage| WidgetRelay
    WidgetRelay -->|chrome.runtime| Router
    
    %% Content script connections
    WidgetUI <-->|chrome.runtime| Router
    PrintifyMonitor -->|chrome.runtime| Router
    MockupActions <-->|chrome.tabs| Router
    
    %% Router to handlers
    Router -->|routes messages| WidgetHandler
    Router -->|routes messages| PrintifyHandler
    Router -->|routes messages| MockupHandler
    Router -->|routes messages| WordPressHandler
    
    %% Handler operations
    WidgetHandler <-->|chrome.tabs| ChromeAPIs
    PrintifyHandler <-->|monitors| PrintifyAPI
    MockupHandler <-->|updates| PrintifyAPI
    
    %% Storage connections
    WidgetHandler -->|chrome.storage| ChromeStorage
    PrintifyHandler -->|chrome.storage| ChromeStorage
    ChromeStorage -->|onChange events| WidgetUI
    Router <-->|manages| TabPairs
```
Legend

- **WP** WordPress admin page where the extension runs.  
- **CS** Content-script that attaches to the page and forwards messages.  
- **BG** Background script (router) that mediates extension-wide actions.  
- **UI** `SiPWidget.UI` namespace housing all widget commands.  
- **Widget** Injected UI element rendered in the page.  
- **PHP** Plugin AJAX handler (`sip-printify-manager/includes/...`).  
- **Printify** Remote Printify endpoints / site database.  

**Key System Components**:
- **WordPress Environment**: Plugin code that initiates operations and processes results
- **Content Scripts**: Page-specific code that monitors, captures data, and manages UI
- **Background Script**: Central router and handlers with full Chrome API access
- **Storage Layer**: Persistent state and cross-tab communication

**Reading the Diagrams Together**:
1. Use the Message Flow to trace a specific operation (e.g., navigation request)
2. Reference the System Overview to understand which components are involved
3. The Message Flow shows the "how" while System Overview shows the "what"
4. Together they provide complete architectural understanding

### Message Validation Diagram

<!-- Shows how messages are validated and where security checks occur -->
```mermaid
flowchart TB
    subgraph "Security Boundaries"
        WP[WordPress postMessage]
        Relay[widget-relay.js<br/>Security Checks Only]
        Router[widget-router.js<br/>Comprehensive Validation]
    end
    
    subgraph "Relay Security Checks"
        Origin[Origin Check<br/>event.origin === allowedOrigin]
        Source1[Source Filter 1<br/>Ignore sip-printify-extension]
        Source2[Source Filter 2<br/>Accept sip-printify-manager only]
    end
    
    subgraph "Router Validation"
        V1[Message Exists<br/>message != null]
        V2[Type Required<br/>message.type exists]
        V3[WORDPRESS_RELAY<br/>Special validation]
        V4[Action Required<br/>For specific types]
        V5[Handler Exists<br/>handlers type exists]
    end
    
    WP -->|postMessage| Relay
    Relay -->|1| Origin
    Origin -->|2| Source1
    Source1 -->|3| Source2
    Source2 -->|chrome.runtime| Router
    
    Router -->|1| V1
    V1 -->|2| V2
    V2 -->|3| V3
    V3 -->|4| V4
    V4 -->|5| V5
```

### Component Organization Diagram

<!-- Shows how components are organized across different contexts -->
```mermaid
graph TB
    subgraph "WordPress Environment"
        PHP[PHP Plugin Code]
        JS[JavaScript Modules]
        DB[(WordPress Database)]
    end
    
    subgraph "Content Scripts - WordPress"
        Relay[widget-relay.js<br/>Message Bridge]
        Widget1[widget-tabs-actions.js<br/>UI Manager]
        Detector[extension-detector.js<br/>Presence Announcer]
        ErrorCap1[error-capture.js<br/>Error Logger]
    end
    
    subgraph "Content Scripts - Printify"
        Widget2[widget-tabs-actions.js<br/>UI Manager]
        Monitor[printify-tab-actions.js<br/>Page Monitor]
        MockupLib[mockup-library-actions.js<br/>Mockup Selector]
        APIInt[printify-api-interceptor-actions.js<br/>API Discovery]
        ErrorCap2[error-capture.js<br/>Error Logger]
    end
    
    subgraph "Background Context"
        Router[widget-router.js<br/>Central Hub & Validator]
        subgraph "Handlers"
            WH[widget-data-handler.js]
            PH[printify-data-handler.js]
            WPH[wordpress-handler.js]
            MFH[mockup-fetch-handler.js]
            MUH[mockup-update-handler.js]
            APIH[printify-api-interceptor-handler.js]
        end
    end
    
    subgraph "Chrome APIs"
        Tabs[chrome.tabs]
        Storage[chrome.storage]
        Runtime[chrome.runtime]
        Action[chrome.action]
    end
    
    PHP --> JS
    JS -->|postMessage| Relay
    Relay -->|runtime| Router
    Widget1 -->|runtime| Router
    Widget2 -->|runtime| Router
    Monitor -->|runtime| Router
    MockupLib -->|runtime| Router
    APIInt -->|runtime| Router
    ErrorCap1 -->|ACTION_LOG| Router
    ErrorCap2 -->|ACTION_LOG| Router
    Router --> Handlers
    Router --> Tabs
    Router --> Storage
    Router --> Runtime
    Router --> Action
    Storage -->|onChange| Widget1
    Storage -->|onChange| Widget2
```

### Storage & State Diagram

<!-- Shows how state is managed across the extension with debug sync -->
```mermaid
graph LR
    subgraph "Chrome Storage Sync"
        WPUrl[wordpressUrl]
        APIKey[apiKey]
        DebugFlag[debug]
    end
    
    subgraph "Chrome Storage Local"
        Widget[sipWidgetState<br/>UI Position & Status]
        Pairs[sipTabPairs<br/>Tab Relationships]
        Logs[sipActionLogs<br/>Action History]
        OpStatus[sipOperationStatus<br/>Current Operation]
        Debug[sip_printify_debug_level<br/>Debug Settings]
        APIs[sipCapturedApis<br/>API Discovery]
        APICount[sipNewApisCount]
        Pending[pendingResearch]
        FetchStatus[fetchStatus_*<br/>Dynamic Keys]
    end
    
    subgraph "Runtime State"
        TabMap[Tab Pairs Map<br/>In-memory cache]
        Paused[Paused Operations<br/>Error recovery context]
        Handlers[Handler Registry]
    end
    
    subgraph "Debug Sync Pattern"
        WPMsg[Every WP Message<br/>includes debugLevel]
        RelaySync[Relay extracts<br/>debug level]
        Update[Auto-updates<br/>extension debug]
    end
    
    WPMsg --> RelaySync
    RelaySync --> Update
    Update --> Debug
    Widget -->|onChange| UI[Widget UI]
    TabMap -->|Persist| Pairs
    Paused -->|Temporary| Memory[Router Memory]
    APIs -->|onChange| APIInt[API Interceptor UI]
```

### Error Recovery Flow Diagram

<!-- Shows the pause/resume error recovery pattern -->
```mermaid
sequenceDiagram
    participant User
    participant Handler
    participant Router
    participant Tab
    participant Widget
    
    Handler->>Tab: Navigate to page
    Tab-->>Handler: Login required (404/error)
    Handler->>Router: pauseOperation(context)
    Router->>Tab: chrome.tabs.update (focus)
    Router->>Widget: Update status "paused"
    Widget->>User: Show "Please login" + Resume button
    
    Note over User: User fixes issue
    
    User->>Widget: Click Resume
    Widget->>Router: resumeOperation
    Router->>Handler: Continue with context
    Handler->>Tab: Retry operation
    Tab-->>Handler: Success
    Handler->>WordPress: Send response
```

### Message Type & Routing Diagram

<!-- Shows all message types and their routing through the system -->
```mermaid
flowchart LR
    subgraph "Message Sources"
        WP[WordPress<br/>SIP_* Commands]
        CS[Content Scripts<br/>Various Types]
        Icon[Extension Icon<br/>chrome.action]
    end
    
    subgraph "Router Message Types"
        RELAY[WORDPRESS_RELAY<br/>From widget-relay]
        ACTION[ACTION_LOG<br/>From error-capture]
        FORWARD[FORWARD_TO_TAB<br/>Internal routing]
        TYPES[widget<br/>printify<br/>wordpress<br/>api-interceptor<br/>mockup-update]
    end
    
    subgraph "WordPress Commands"
        NAV[SIP_NAVIGATE]
        OPEN[SIP_OPEN_TAB]
        TOGGLE[SIP_TOGGLE_WIDGET]
        SHOW[SIP_SHOW_WIDGET]
        CHECK[SIP_CHECK_STATUS]
        FETCH[SIP_FETCH_MOCKUPS]
        UPDATE[SIP_UPDATE_PRODUCT_MOCKUPS]
        CLEAR[SIP_CLEAR_STATUS]
        SYNC[SIP_SYNC_DEBUG_LEVEL]
    end
    
    subgraph "Handler Actions"
        WH_A[navigate<br/>toggleWidget<br/>showWidget<br/>updateState<br/>getConfig<br/>testConnection<br/>checkPluginStatus<br/>resumeOperation]
        PH_A[fetchMockups<br/>updateStatus]
        API_A[apiCaptured<br/>getCapturedApis<br/>clearCapturedApis<br/>toggleApiInterceptor]
    end
    
    WP --> RELAY
    CS --> TYPES
    CS --> ACTION
    Icon --> TOGGLE
    
    RELAY --> wordpress
    wordpress --> NAV --> WH_A
    wordpress --> FETCH --> PH_A
    
    widget --> WH_A
    printify --> PH_A
    api-interceptor --> API_A
```

### Data Flow Architecture Diagram

<!-- This diagram shows the elegant data flow architecture through the central hub -->
```mermaid
graph TB
    subgraph "Web Page Context"
        WP[WordPress Pages<br/>window.postMessage]
        CS[Content Scripts<br/>chrome.runtime.sendMessage]
    end
    
    subgraph "Extension Context"
        Hub[Central Router Hub<br/>Background Service Worker]
        
        subgraph "Message Formats"
            External[External Format<br/>type: 'SIP_*']
            Internal[Internal Format<br/>type: handler, action: name]
        end
    end
    
    subgraph "Chrome APIs Context"
        Tabs[chrome.tabs API]
        Storage[chrome.storage API]
        Runtime[chrome.runtime API]
    end
    
    subgraph "Storage Solutions"
        ChromeLocal[(Chrome Local Storage<br/>Extension State)]
        SessionState[Runtime Variables<br/>Tab Pairs, Paused Ops]
        WPDatabase[(WordPress Database<br/>Plugin Settings)]
    end
    
    subgraph "External Context"
        Printify[Printify.com<br/>Web Pages & APIs]
    end
    
    %% WordPress to Extension
    WP -->|postMessage<br/>SIP_* format| CS
    CS -->|Relay & Transform| Hub
    
    %% Hub as Central Mediator
    Hub -->|chrome.tabs.sendMessage| CS
    Hub -->|chrome.tabs.create/update| Tabs
    Hub -->|chrome.storage.set/get| Storage
    
    %% Storage flows
    Storage -->|Read/Write| ChromeLocal
    Hub -->|Maintains| SessionState
    WP -->|AJAX| WPDatabase
    
    %% Response flow
    Hub -->|sendResponse| CS
    CS -->|postMessage| WP
    
    %% Chrome Storage events
    ChromeLocal -.->|onChange events| CS
    
    %% External interactions
    Hub -->|via Tabs API| Printify
    CS -->|DOM Monitoring| Printify
    
    %% Format transformation
    External -.->|Transform| Internal
    Internal -.->|Transform| External
```

**Key Architectural Principles:**

1. **Context Isolation**: Each context (Web, Extension, Chrome APIs) has specific communication methods
2. **Central Hub Pattern**: All messages flow through the router, no direct cross-context communication
3. **Format Translation**: External (SIP_*) and Internal (handler/action) formats are translated at boundaries
4. **Storage Separation**: 
   - Chrome Storage for extension state (cross-tab sync)
   - Runtime variables for session data (tab pairs)
   - WordPress DB for plugin settings
5. **Event-Driven Updates**: Chrome Storage onChange events push updates to UI without polling

**Data Flow Elegance:**
- Single entry point (Router) for all messages
- Clear context boundaries with defined interfaces
- Automatic state propagation via storage events
- No circular dependencies or callback hell
- Clean separation between persistent and session data

### 2.1 Core Principles

**Push-Driven Communication**: The extension uses a push-driven architecture where:
- The extension announces its presence when ready (not polled by WordPress)
- State changes are pushed from extension to WordPress as they occur
- No periodic status checks or ping/pong patterns
- Event-driven updates ensure real-time synchronization
- **No state persistence**: Extension state is NOT saved between page loads - the extension must announce itself each time

This approach reduces unnecessary message traffic, provides more responsive user experience, and ensures accurate extension detection.

**Version Management Integration**: Extension version is communicated to WordPress on ready announcement but is NOT persisted. The extension must announce itself on each page load to be considered installed, ensuring accurate detection state.

**Data Processing Separation**: Extension acts as a "dumb pipe" capturing and relaying raw data, while WordPress handles all processing, validation, and business logic.

**Fresh Detection Model**: Extension installation state is never persisted. The extension must announce itself on each page load to be considered installed. This ensures the "Install Extension" button always appears when the extension is not actually present, eliminating stale state issues.


## 3. Technical Architecture

### 3.1 Version Communication Protocol

**Extension Ready Announcement**: Extension posts a message with type 'SIP_EXTENSION_READY', source identifier, version from manifest, and capabilities object to window.location.origin.

**WordPress Version Capture**: Browser extension manager captures version in memory only (`extensionState.version = data.version`) with no persistence - fresh detection required on each page load.

**Update Checking**: WordPress compares local version against stuffisparts server data for update notifications.

## 4. Architecture Rationale

### 4.1 Why This Architecture?

**Central Router Pattern**: All messages flow through widget-router.js because Chrome extensions don't allow content scripts to intercept runtime messages from other content scripts - they go directly to the background script.

**Separate Action/Handler Scripts**: Content scripts (actions) have limited Chrome API access, while background scripts (handlers) have full access. This separation enforces proper security boundaries.

**Handler Context Pattern**: Instead of message passing between router and handlers, handlers receive a router context object. This eliminates an unnecessary message hop and provides direct access to Chrome APIs.

### 4.2 The Central Router Pattern

**ALL messages in the extension flow through widget-router.js - NO EXCEPTIONS**

The router is the background script and the single message hub that:
- Receives ALL incoming messages (chrome.runtime messages from content scripts and relayed postMessages)
- Routes to appropriate handlers based on message type
- Executes Chrome API commands directly (no separate widget-main.js)
- Returns responses to the originator

### 4.3 Message Formats

**Two distinct formats for different contexts**:

**External (WordPress ↔ Extension)**: `{ type: 'SIP_*', source: 'sip-printify-manager', ... }`
- SIP_ prefix identifies our messages among all postMessages

**Internal (Extension components)**: `{ type: 'widget|printify|wordpress', action: '...', data: {...} }`
- Type routes to handler, action specifies operation

#### Message Format Conversion

The widget-relay.js converts external messages to internal format:

```javascript
// Actual implementation from widget-relay.js
function handlePostMessage(event) {
    // 1. Security checks (origin, source)
    if (event.origin !== allowedOrigin) return;
    if (data.source !== 'sip-printify-manager') return;
    
    // 2. Wrap and forward to router
    chrome.runtime.sendMessage({
        type: 'WORDPRESS_RELAY',
        data: {
            type: 'wordpress',
            action: data.type,        // SIP_SHOW_WIDGET becomes action
            data: data,
            requestId: data.requestId // Preserve for response correlation
        }
    }, function(response) {
        // 3. Send response back to WordPress
        window.postMessage({
            type: 'SIP_EXTENSION_RESPONSE',
            requestId: data.requestId,
            ...response
        }, allowedOrigin);
    });
}
```

**Key Point**: Never mix formats. External messages MUST use 'SIP_' prefix. Internal messages MUST use handler/action pattern.

#### Debug Level Synchronization

**Why it exists**: The extension needs to respect WordPress debug settings for consistent logging behavior across the entire SiP ecosystem.

**Implementation**: Every message from WordPress to the extension includes the current debug level:
```javascript
// In browser-extension-manager.js
function sendMessageToExtension(message, origin = '*') {
    const enrichedMessage = Object.assign({}, message, {
        debugLevel: SiP.Core.debug.getLevel(),      // 0=OFF, 1=NORMAL, 2=VERBOSE
        debugLevelName: SiP.Core.debug.getLevelName() // 'OFF', 'NORMAL', 'VERBOSE'
    });
    window.postMessage(enrichedMessage, origin);
}
```

**Extension Processing**: The relay checks every incoming message for debug level:
```javascript
// In widget-relay.js
if (data.debugLevel !== undefined && data.debugLevelName !== undefined) {
    SiPWidget.Debug.setDebugLevel(data.debugLevel, data.debugLevelName);
}
```

This ensures the extension always uses the correct debug level, updating immediately when changed in WordPress.

#### Request-Response Correlation

**Why Request IDs**: When multiple async operations run concurrently (e.g., fetching mockups for 4 blueprints), responses must be matched to their originating requests to prevent race conditions.

**Implementation Pattern**: WordPress sends requests with unique IDs (`operation_[itemId]_[timestamp]`) and sets up response listeners before sending. The message includes type, source, requestId, data, debugLevel (0-2), and debugLevelName. Response handlers match by requestId to correlate async responses.

**CRITICAL**: The relay preserves the requestId in wrapped responses. Extension → WordPress responses include `type: 'SIP_EXTENSION_RESPONSE'`, the preserved `requestId` from the original request, and the actual response data.

#### Handler Chrome API Requests
Handlers can request Chrome API execution by calling router methods directly:
```javascript
// In handler:
const result = await router.createTab({ url: 'https://example.com' });
const tabs = await router.queryTabs({ url: '*://printify.com/*' });
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

**Note**: Error response formatting is centralized in `widget-error.js`. Content scripts use `SiPWidget.Error` methods. The background script (router and handlers) returns plain error objects with `success: false`.

## 6. Component Responsibilities

### 6.1 File Structure
```
browser-extension/
├── manifest.json               # Extension configuration (Manifest V3)
├── background.js               # Service worker loader - imports all modules
│   Why: Manifest V3 service workers require importScripts() to load modules
├── core-scripts/
│   ├── widget-router.js        # Background script - Central message router & Chrome API executor
│   ├── widget-relay.js         # Content script - Relays WordPress postMessages to router
│   ├── widget-debug.js         # Debug utilities (dual context support)
│   ├── widget-error.js         # Error response formatting
│   ├── action-logger.js        # Structured action logging system
│   ├── error-capture.js        # JavaScript error capture and logging
│   └── widget-styles.css       # Widget styling
├── action-scripts/
│   ├── extension-detector.js            # Extension presence announcer
│   ├── widget-tabs-actions.js          # Widget UI creation and button handling
│   ├── printify-tab-actions.js         # Printify page monitoring and scraping
│   ├── printify-api-interceptor-actions.js # API discovery monitor
│   └── mockup-library-actions.js       # Mockup selection updates on Printify
├── handler-scripts/
│   ├── widget-data-handler.js          # Widget operation logic
│   ├── printify-data-handler.js        # Printify data processing
│   ├── wordpress-handler.js            # WordPress message routing
│   ├── printify-api-interceptor-handler.js # API discovery processing
│   ├── mockup-fetch-handler.js         # Blueprint mockup fetching
│   └── mockup-update-handler.js        # Product mockup updates
├── assets/                     # Images and static files
│   ├── config.json            # Optional pre-configuration
│   └── images/                # Extension icons and UI assets
└── validate-manifest.js        # Build tool for manifest validation
```

**Manifest Configuration**:
```json
{
    "background": {
        "service_worker": "background.js"
    },
    "content_scripts": [
        {
            "matches": ["https://printify.com/*"],
            "js": [
                "core-scripts/widget-debug.js",
                "core-scripts/widget-error.js",
                "action-scripts/printify-tab-actions.js",
                "action-scripts/printify-api-interceptor-actions.js",
                "action-scripts/widget-tabs-actions.js"
            ]
        },
        {
            "matches": ["*://*/wp-admin/*"],
            "js": [
                "core-scripts/widget-debug.js",
                "core-scripts/widget-error.js",
                "core-scripts/widget-relay.js",
                "action-scripts/extension-detector.js",
                "action-scripts/widget-tabs-actions.js"
            ]
        }
    ]
}
```

**Naming Standards**:

**Action Scripts** (content scripts that detect events and send messages):
- Must end with `-actions.js` suffix
- Examples: `widget-tabs-actions.js`, `printify-tab-actions.js`, `printify-api-interceptor-actions.js`
- Located in `action-scripts/` directory

**Handler Scripts** (background scripts that process messages):
- Must end with `-handler.js` suffix (always singular)
- Examples: `widget-data-handler.js`, `printify-data-handler.js`, `printify-api-interceptor-handler.js`
- Located in `handler-scripts/` directory

**Paired Features**: Complex features should have matching action/handler pairs:
- `printify-api-interceptor-actions.js` → `printify-api-interceptor-handler.js`
- This makes it clear which handler processes which action script's events

### 6.2 Core Scripts

#### widget-router.js (Background Script)
**Why it exists**: Chrome extensions require a background script to access privileged APIs (tabs, cross-origin requests). Making the router the background script ensures ALL messages flow through one central point as documented.

- Receives ALL chrome.runtime.sendMessage calls from content scripts
- Routes messages to handlers based on 'type' field  
- Executes Chrome API commands directly (no separate widget-main.js)
- Provides router context to handlers with Chrome API methods
- Sends responses back to message originators
- Forwards messages to content scripts via chrome.tabs.sendMessage when needed

#### widget-relay.js (Content Script - WordPress pages only)
**Why it exists**: WordPress can only use window.postMessage() which content scripts can receive, but the router (background script) cannot. This relay bridges that gap.

- Listens for postMessage events from WordPress
- Performs minimal security checks (origin and source)
- Relays WordPress messages to router via chrome.runtime.sendMessage
- Returns responses back to WordPress via postMessage
- All comprehensive validation happens in the router

#### widget-debug.js (Core Debug Module)
**Why it exists**: Provides centralized debug logging that respects WordPress debug levels and works across all extension contexts.

**Architectural Constraint - Dual Context Support**: Chrome Manifest V3 requires the extension to operate in two distinct JavaScript contexts:
- **Service Worker (background.js)**: No DOM access, uses `self` global object
- **Content Scripts**: Run in web pages, have `window` global object

Both contexts require debug logging, so the module detects its environment using `typeof window !== 'undefined'`. This is not defensive coding but necessary environment detection mandated by Chrome's extension architecture.

- Provides debug methods that respect enabled/disabled state
- **Automatically synchronizes with WordPress debug level on every received message**
- Works in conjunction with action-logger.js for structured logging

See also: [SiP Debug System Documentation](./sip-development-testing-debug.md#browser-extension-integration) for complete debug system overview.

**Debug Levels**:
- **OFF** (0): No logging output
- **NORMAL** (1): Important operations and errors only  
- **VERBOSE** (2): All debug messages including detailed traces

**Key Functions**:
- `setDebugLevel(level, levelName)` - Updates debug level and persists to storage
- `normal(message)` - Logs at NORMAL level (important operations)
- `verbose(message)` - Logs at VERBOSE level (detailed traces)
- `log(message)` - Logs at VERBOSE level (for backward compatibility)
- `error(message)` - Logs errors at NORMAL level
- `warn(message)` - Logs warnings at NORMAL level

**Usage Pattern**:
```javascript
const debug = SiPWidget.Debug;

debug.normal('Important operation started');     // Shows in NORMAL and VERBOSE
debug.verbose('Detailed operation data:', data); // Shows only in VERBOSE
debug.error('Operation failed:', error);         // Shows in NORMAL and VERBOSE
```

**Initialization**: The debug module initializes synchronously with sensible defaults (VERBOSE level) to ensure it's immediately available when other modules load. Chrome storage state is loaded asynchronously after initialization to update settings without blocking module loading.

**Storage Format**:
```javascript
// Chrome storage keys:
// 'sip_printify_debug_level' - Current debug level (0, 1, or 2)
// 'sip_printify_debug_level_name' - Level name ('OFF', 'NORMAL', 'VERBOSE')
```

**Note**: Console log capture has been replaced by the action-logger.js system which provides structured, meaningful logging of extension actions rather than mirroring console output.

#### action-logger.js (Action Logging System)
**Why it exists**: Provides structured logging of extension actions rather than mirroring console output. This gives meaningful insights into what the extension is actually doing, with timing, status, and context information.

**Key Features**:
- Structured log entries with categories, timing, and status
- Respects WordPress debug levels (OFF/NORMAL/VERBOSE)
- Automatic storage management (1MB limit)
- Tab context for each action
- Duration tracking for operations

**Categories**:
- `WORDPRESS_ACTION` - Requests from WordPress
- `NAVIGATION` - Tab navigation operations
- `DATA_FETCH` - Data scraping and fetching
- `API_CALL` - API interceptions
- `STATE_CHANGE` - Extension state updates
- `ERROR` - Operation failures
- `AUTH` - Authentication events

**Public API**:
- `log(category, action, details)` - Log an action
- `normal(category, action, details)` - Log at NORMAL level
- `verbose(category, action, details)` - Log at VERBOSE level
- `startTiming(operationId)` - Start timing an operation
- `endTiming(operationId)` - End timing and return duration
- `getLogs(callback)` - Retrieve stored logs
- `clearLogs()` - Clear all logs
- `setDebugLevel(level, levelName)` - Update debug level

#### error-capture.js (JavaScript Error Capture)
**Why it exists**: Captures all JavaScript errors, unhandled promise rejections, and console errors across all tabs for comprehensive debugging support.

**Key Features**:
- Window error handler for runtime errors
- Unhandled promise rejection capture
- Console.error interception
- Sends errors to action logger when available
- Falls back to background script logging

**Error Types Captured**:
- JavaScript runtime errors with stack traces
- Unhandled promise rejections
- Console.error calls
- Includes URL, line/column numbers, timestamps

**Message Types**:
- Sends `ACTION_LOG` messages with category `'console-error'` to background script

### 6.3 Action Scripts

#### extension-detector.js
**Why it exists**: The SiP ecosystem needs to know which extensions are installed to provide appropriate UI and functionality. This script announces the extension's presence on relevant pages.

- Announces extension presence to WordPress pages
- **Conditional behavior based on page**:
  - On SiP Plugins Core dashboard (`page=sip-plugins`): Only announces when requested via `SIP_REQUEST_EXTENSION_STATUS` message
  - On SiP Printify Manager pages (`page=sip-printify-manager`): Announces immediately for plugin functionality
- Sends extension information: slug, name, version, isInstalled
- Lightweight script with minimal overhead

**Implementation**: On the SiP Plugins Core dashboard, waits for `SIP_REQUEST_EXTENSION_STATUS` message before announcing. On SiP Printify Manager pages, announces immediately after DOM is ready.

#### widget-tabs-actions.js
**Why it exists**: The widget UI needs to be injected into specific pages (SiP Printify Manager and Printify) to provide consistent user access. Separating UI from page-specific logic keeps code organized.

- Creates and manages the floating widget UI
- **Only shows on**: SiP Printify Manager pages (`page=sip-printify-manager`) and Printify.com
- Handles widget button clicks (navigation, status checks, etc.)
- Updates widget display based on Chrome storage changes
- Sends user-initiated actions to router
- Does NOT handle Printify page-specific actions

#### printify-tab-actions.js
**Why it exists**: Printify pages need specific DOM monitoring and scraping logic that would bloat the general widget code. This separation keeps Printify-specific logic isolated.

- Monitors Printify pages for DOM changes
- Detects page state and product information
- Detects inventory changes (future)
- Sends detected events to router
- Does NOT handle widget UI

#### printify-api-interceptor-actions.js
**Why it exists**: API interception is a complex feature requiring significant code for request monitoring and pattern analysis. It warrants its own dedicated file for maintainability.

- Intercepts Printify API calls via fetch and XMLHttpRequest
- Captures API patterns and responses
- Extracts path parameters and endpoint information
- Sends captured data to router for processing
- Manages interceptor state (enable/disable)
- Dispatches custom DOM events for UI updates

**Message Types Handled**:
- `toggleApiInterceptor` - Enable/disable interception
- `getApiInterceptorStatus` - Returns status and counts
- `getCapturedApis` - Returns captured API data
- `clearNewApisCount` - Resets new API counter

#### mockup-library-actions.js
**Why it exists**: Handles the complex task of detecting page state, updating mockup selections, and managing save operations on Printify's mockup library pages.

- Detects page issues (login required, 404, errors)
- Checks mockup library page readiness
- Updates mockup checkbox selections programmatically
- Triggers save operations
- Monitors save completion status
- Provides page state information to handlers

**Message Types Handled**:
- `CHECK_MOCKUP_PAGE_READY` - Returns page ready state
- `UPDATE_MOCKUP_SELECTIONS` - Updates mockup selections
- `CHECK_SAVE_STATUS` - Returns save operation status

### 6.4 Handler Scripts

#### widget-data-handler.js
**Why it exists**: Widget operations (navigation, config, UI state) are distinct from data operations and need their own business logic layer in the background context.

Processes widget-related operations:
- Navigation between tabs
- Widget state management
- Configuration updates
- **Required actions**: `showWidget`, `toggleWidget`, `navigate`, `updateState`, `getConfig`, `updateConfig`, `testConnection`, `checkPluginStatus`

#### mockup-fetch-handler.js
**Why it exists**: Mockup fetching is a complex multi-step operation requiring tab management and API interception. This dedicated handler isolates all mockup-related logic and provides clean separation from other extension functionality.

Processes mockup fetching operations:
- Navigates to Printify mockup library pages
- Intercepts `generated-mockups-map` API responses  
- Returns **raw API response data** without processing
- Returns data via sendResponse callback (relay handles WordPress delivery)
- **Required actions**: `fetchMockups`

**ARCHITECTURAL PRINCIPLE**: The extension acts as a "dumb pipe" that only captures and relays raw data. All data processing, validation, and transformation happens on the WordPress side. This separation enables easier debugging, faster iteration, and clearer responsibilities.

**CRITICAL**: This handler MUST NOT use chrome.tabs.sendMessage to send data to WordPress. All responses MUST go through the sendResponse callback which the relay will properly format and deliver via postMessage.

#### printify-data-handler.js
**Why it exists**: Complex multi-step operations like api interception need coordination logic that can access Chrome APIs. Separating this from UI logic enables cleaner testing and maintenance.

Processes Printify data operations:
- Data validation and formatting
- WordPress API communication coordination
- Status update management
- Routes mockup requests to MockupFetchHandler

#### wordpress-handler.js
**Why it exists**: WordPress sends differently formatted messages (SIP_FETCH_MOCKUPS vs fetchMockups). This handler translates WordPress commands to the extension's internal message format.

Routes WordPress postMessage commands to appropriate handlers:
- Converts WordPress message formats to extension formats
- Routes to widget or printify handlers based on command
- **Supported commands**: `SIP_FETCH_MOCKUPS`, `SIP_NAVIGATE`, `SIP_SHOW_WIDGET`, `SIP_CHECK_STATUS`

#### printify-api-interceptor-handler.js
**Why it exists**: Captured API data needs processing and storage logic separate from the capture mechanism. This separation allows the action script to focus on interception while the handler manages data.

Processes captured API data:
- Analyzes API patterns
- Stores discovered endpoints
- Manages API knowledge base

## 7. Chrome Extension Constraints

### 7.1 API Access Limitations

**Background Script (widget-router.js and handlers loaded by background.js)**
- Full Chrome API access
- Can make cross-origin requests
- Can manage tabs, windows, storage
- Runs as a service worker in Manifest V3
- **CRITICAL**: No DOM access - cannot use `window`, `document`, or DOM APIs
- Must check `typeof window !== 'undefined'` before using window
- Service worker errors prevent ALL content scripts from loading

**Content Scripts (action scripts and widget-relay.js)**
- Limited Chrome API access
- Can use: chrome.storage, chrome.runtime.sendMessage
- CANNOT use: chrome.tabs, chrome.windows, cross-origin fetch
- Must request privileged operations from the background script

### 7.2 Message Passing Architecture

**Key Constraint**: Content scripts cannot intercept chrome.runtime.sendMessage calls from other content scripts. These messages go directly to the background script.

This is why the router MUST be the background script - it's the only way to receive all messages as documented.

**Message Flow**:
- postMessage can only be received by content scripts injected into the page
- chrome.runtime.sendMessage sends messages directly to the background script (router)
- The router uses chrome.tabs.sendMessage to communicate with specific content scripts
- WordPress postMessage messages are relayed to the router by widget-relay.js

### 7.3 Tab Pairing System

**Why it exists**: The widget's "Go to..." navigation feature requires maintaining relationships between WordPress admin tabs and Printify tabs to ensure navigation reuses existing tabs instead of creating new ones.

#### Architecture Overview

The tab pairing system uses a bidirectional pairing model:

```javascript
// Runtime cache in widget-router.js
const tabPairs = new Map(); // Map<tabId, pairedTabId>

// Persistent storage in chrome.storage.local
{
    sipTabPairs: {
        "123": "456",  // Tab 123 is paired with tab 456
        "456": "123"   // Tab 456 is paired with tab 123 (bidirectional)
    }
}
```

#### Key Concepts

1. **Bidirectional Pairing**: Each tab knows its pair, enabling navigation in both directions
2. **Persistence**: Pairs survive page reloads via chrome.storage.local
3. **Automatic Cleanup**: Pairs are removed when either tab closes
4. **One-to-One Relationships**: Each tab can only be paired with one other tab
5. **Smart Navigation**: Avoids unnecessary reloads by checking if the paired tab is already on the target URL

#### Tab Pairing Flow

**Initial Navigation** (WordPress → Printify):
1. User clicks "Go to Printify" in widget
2. Widget sends navigation message with current tab ID
3. Router checks if current tab has a paired Printify tab
4. If no pair exists, creates new Printify tab and establishes pairing
5. If pair exists and is valid, navigates to the paired tab

**Return Navigation** (Printify → WordPress):
1. User clicks "Go to WordPress" in widget
2. Widget sends navigation message with current tab ID
3. Router finds the paired WordPress tab
4. Navigates to the paired WordPress tab (always exists as it initiated the pair)

#### Implementation Details

**Tab Pairing Code Example**:
```javascript
// From widget-router.js
async function navigateTab(tabId, url, destination) {
    // Check for existing paired tab
    const pairedTabId = tabPairs.get(tabId);
    
    if (pairedTabId) {
        // Verify paired tab still exists
        const tabs = await chrome.tabs.query({ windowId: chrome.windows.WINDOW_ID_CURRENT });
        const pairedTab = tabs.find(t => t.id === pairedTabId);
        
        if (pairedTab) {
            // Check if already on target URL
            if (pairedTab.url.includes(url)) {
                // Just switch focus
                await chrome.tabs.update(pairedTabId, { active: true });
                return { success: true, action: 'switched-focus', tabId: pairedTabId };
            } else {
                // Navigate existing paired tab
                await chrome.tabs.update(pairedTabId, { url: url, active: true });
                return { success: true, action: 'reused-pair', tabId: pairedTabId };
            }
        }
    }
    
    // Create new tab with pairing
    const newTab = await chrome.tabs.create({ url: url, active: true });
    createTabPair(tabId, newTab.id);
    return { success: true, action: 'created-pair', tabId: newTab.id };
}

// Bidirectional pairing storage
function createTabPair(tab1Id, tab2Id) {
    tabPairs.set(tab1Id, tab2Id);
    tabPairs.set(tab2Id, tab1Id);  // Bidirectional
    saveTabPairs();
}
```

#### Message Flow for Navigation

1. **Content Script** sends navigation message with type 'widget', action 'navigate', and target URL. The currentTabId is automatically added by the background script from sender.tab.id.

2. **Handler** extracts the current tab ID from the sender context and passes it to router.navigateTab() along with the URL and destination.

#### Lifecycle Management

**Tab Close Cleanup**: Chrome's `tabs.onRemoved` listener automatically calls `removeTabPair()` which cleans both sides of the bidirectional pairing.

**Storage Persistence**:
- Pairs are loaded on extension startup
- Pairs are saved after each create/remove operation
- Storage key uses SiP prefix convention: `sipTabPairs`

## 8. Common Operations

### 8.1 Status Update Flow

1. WordPress plugin: `window.postMessage({ type: 'SIP_CHECK_STATUS', source: 'sip-printify-manager' })`
2. widget-relay.js receives postMessage and relays to router via chrome.runtime.sendMessage
3. widget-router.js receives and routes to widget-data-handler.js (via wordpress-handler.js)
4. Handler uses router context to check plugin status
5. Handler updates Chrome storage with status
6. widget-tabs-actions.js updates UI from storage change
7. Response sent back through relay to WordPress

### 8.2 Adding New Features

To add a new feature (e.g., inventory monitoring):

1. **Add action detection** in appropriate action script
2. **Define message format**: `{ type: 'printify', action: 'inventoryChanged', data: {...} }`
3. **Add handler logic** in appropriate handler file
4. **If routing through wordpress-handler.js**, ensure the target handler implements the action
5. **Add any Chrome API methods** to router context if needed
6. **Update Chrome storage schema** for new state
7. **Update widget UI** to display new information

**CRITICAL**: When adding routing in wordpress-handler.js, you MUST implement the corresponding action in the target handler.

## 9. Implementation Standards

### 9.1 Module Pattern

All scripts use IIFE pattern with SiPWidget namespace:

**Content Scripts**: Use `window.SiPWidget` namespace with `window.widgetDebug` for logging. Returns public API object with init() and other public methods.

**Background Scripts** (service workers): Use `self.SiPWidget` namespace (not `window`) with console directly for logging. Returns public API with handle() method.

### 9.2 Message Handling Pattern

**CRITICAL**: Async handlers MUST return `true` to keep the message channel open. Without this, Chrome will close the channel before the async response is sent, causing "The message port closed before a response was received" errors.

Every handler follows this pattern:
- Receives: `request`, `sender`, `sendResponse`, `router` parameters
- Logs the action being processed
- Uses switch statement for action routing
- For async operations: MUST return `true` to keep channel open
- For sync operations: No return statement needed
- Always sends response with success/error structure

**Common Patterns**:

1. **Async with immediate response wrapper** (Recommended): Use async IIFE to wrap all async operations, then return `true`
2. **Promise chain pattern**: Chain promises with .then()/.catch(), then return `true`
3. **Synchronous response**: Send response immediately, no return statement needed

### 9.3 Handler Context

Handlers run in the background script context and have access to router methods. They can call router methods directly (e.g., `router.createTab()`) and must return `true` for async operations.

### 9.4 Public API Naming Standard  

**Purpose** Prevent future `ReferenceError` issues and keep the extension extensible by enforcing a single, namespaced surface for all UI commands.

| Rule | Rationale | Example |
|------|-----------|---------|
| **Expose every UI function under `SiPWidget.UI` only.** | Makes the API explicit and discoverable; avoids accidental globals.| `SiPWidget.UI.showWidget()` |
| **Never call a bare function such as `showWidget()` or `toggleWidget()` from any script (wrapper, relay, handler, or content-script).** | Guarantees the call site never outruns the module loader; eliminates race conditions. | _Wrong:_ `showWidget();`<br>_Right:_ `SiPWidget.UI.showWidget();` |
| **If WordPress code requires a global function, create it inside `widget-tabs-actions.js` and mark it clearly.** | Provides clear API surface for WordPress integration. | `window.showWidget = SiPWidget.UI.showWidget; // WordPress integration` |
| **Future commands** (e.g. `refreshWidget`, `resizeWidget`) **must follow the same pattern**. | Keeps extension growth predictable. | `SiPWidget.UI.refreshWidget();` |

**Implementation Checklist**: Search for bare function calls (`showWidget(`, `toggleWidget(`), refactor to use `SiPWidget.UI.*`, remove unnecessary `window.*` aliases, and document new commands in the pattern table.


## 10. Widget UI Features

### 10.1 Action History Viewer

**Why it exists**: During complex operations like mockup fetching that span multiple tabs (WordPress ↔ Printify), understanding the sequence of actions performed by the extension is crucial for debugging. The action logger provides structured, meaningful logs of what the extension actually does.

#### Implementation Architecture

**Action Logging System**:
- **Extension Side** (`action-logger.js`): Logs structured actions with categories, timing, and status
- **WordPress Side**: Sends only actionable requests (no console mirroring)
- **Storage**: Chrome local storage with 1MB limit and automatic cleanup
- **Categories**: WORDPRESS_ACTION, NAVIGATION, DATA_FETCH, API_CALL, STATE_CHANGE, ERROR, AUTH

#### Action Categories

The system logs these types of extension actions:
- **WORDPRESS_ACTION**: Requests received from WordPress plugin
- **NAVIGATION**: Tab navigation and pairing operations
- **DATA_FETCH**: Data scraping and mockup fetching
- **API_CALL**: Printify API interceptions
- **STATE_CHANGE**: Extension state updates
- **ERROR**: Operation failures
- **AUTH**: Authentication events

#### Usage Flow

1. **History Button**: User clicks History button in extension widget
2. **Log Retrieval**: `SiPWidget.ActionLogger.getLogs()` retrieves action history
3. **Window Creation**: New popup window opens with formatted action viewer
4. **Features Available**:
   - **Action Timeline**: Chronological list of extension actions
   - **Duration Tracking**: Shows how long each operation took
   - **Status Indicators**: Success/failure for each action
   - **Tab Information**: Shows which tab performed the action
   - **Copy Functionality**: Export action history for analysis

#### Technical Details

**Action Structure**:
```javascript
{
    timestamp: Date.now(),
    category: 'WORDPRESS_ACTION',
    action: 'fetchMockups', 
    tabId: 123,
    tabName: 'SiP Printify Manager',
    duration: 1234, // milliseconds
    status: 'success', // or 'failure'
    details: { /* action-specific data */ }
}
```

**Debug Level Integration**:
- **OFF** (0): No action logging
- **NORMAL** (1): Important operations (WordPress actions, navigation, errors)
- **VERBOSE** (2): All actions including detailed traces

**Storage Management**:
- Key: 'sipActionLogs' in Chrome local storage
- Automatic cleanup when approaching 1MB limit
- Persists through page reloads
- Respects WordPress debug level settings

#### User Experience

**Action Viewer Window**:
- **Timeline View**: Actions displayed chronologically
- **Action Details**: Category, description, duration, status
- **Tab Context**: Shows which tab performed each action
- **Filtering**: View by category or status
- **Performance Metrics**: Total time for operations

**Integration Points**:
- **Widget Button**: Seamlessly integrated into existing widget UI
- **Real-time Updates**: Actions appear as they happen
- **Export Options**: Copy action history for debugging

## 11. Storage Management

### 11.1 State Storage

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

### 11.2 Storage Limits

- Chrome storage has 5MB limit
- Monitor usage and prune old operation history
- Use efficient data structures

## 12. Configuration and Deployment

### 12.1 Extension Configuration

**Two modes**: Pre-configured (`assets/config.json` with wordpressUrl, apiKey, configured:true) or user-configured (via extension popup).

**⚠️ SECURITY**: Never commit `config.json` with real API keys. Already in `.gitignore`.

### 12.2 Configuration Loading Order

1. On startup, router checks for `assets/config.json`
2. If found AND `configured: true`, uses those values
3. Values are copied to Chrome storage for persistence
4. If not found or `configured: false`, loads from Chrome storage
5. Updates extension badge based on configuration state:
   - ✓ Green badge: Configured and ready
   - ! Orange badge: Configuration required

**Note**: The `config.json` file is included in manifest's `web_accessible_resources` to allow the background script to fetch it using `chrome.runtime.getURL()`.

## 13. WordPress Integration

### 13.1 Extension Detection and Installation Flow

**Chrome Limitation**: Content scripts don't auto-inject into already-open tabs after installation. The extension handles this by programmatically injecting scripts on install.

#### Installation Flow - Detailed

```mermaid
sequenceDiagram
    User->>Chrome: Install Extension
    Chrome->>Router: chrome.runtime.onInstalled
    Router->>WordPress Tabs: Inject content scripts
    Content Scripts->>WordPress: SIP_EXTENSION_READY
    WordPress->>UI: Hide install button, show widget
    Note over WordPress: State not persisted (fresh detection each load)
```

#### Implementation Details

**Extension Side - Programmatic Injection** (widget-router.js): On install/update, automatically injects content scripts and CSS into open WordPress admin tabs for immediate availability without reload.

**Extension Side - Announcement** (widget-relay.js): After 100ms delay, posts `SIP_EXTENSION_READY` with version and capabilities.

**WordPress Side - Detection** (browser-extension-manager.js): WordPress initializes with extension not detected, listens for `SIP_EXTENSION_READY`, updates state in memory only, hides install button, and triggers jQuery event.

#### Message Flow Directions

**WordPress → Extension**:
- WordPress uses `window.postMessage()` (only option for web pages)
- `widget-relay.js` receives and forwards to background via `chrome.runtime.sendMessage()`
- Relay is REQUIRED because background scripts can't receive postMessages

**Extension → WordPress**:
- Content scripts use `window.postMessage()` directly
- No relay needed - direct communication
- `widget-relay.js` announces presence, not relaying

#### Key Benefits

1. **Fresh Detection Each Load**: Extension must announce itself on every page load
2. **No Stale State**: No persistence means no false positives for extension detection
3. **Clean Architecture**: Each component has clear responsibility
4. **Reliable Detection**: Push-driven model with no saved state ensures accuracy
5. **Install Button Visibility**: Always shows when extension not detected

### 13.2 Supported WordPress Commands

The extension supports the following commands from WordPress:

| Command | Purpose | Handler |
|---------|---------|---------|
| `SIP_NAVIGATE` | Navigate to URL in new/existing tab | Widget handler |
| `SIP_OPEN_TAB` | Open URL in new tab | Widget handler |
| `SIP_TOGGLE_WIDGET` | Toggle widget visibility | Widget handler |
| `SIP_SHOW_WIDGET` | Show the widget | Widget handler |
| `SIP_CHECK_STATUS` | Check plugin connection status | Widget handler |
| `SIP_FETCH_MOCKUPS` | Fetch mockup data from Printify | Printify handler |
| `SIP_UPDATE_PRODUCT_MOCKUPS` | Update product mockups via internal API | Printify handler |
| `SIP_PUBLISH_PRODUCTS` | Publish products via internal API | Printify handler |

**Note**: Any other command will receive an error response with code `UNKNOWN_ACTION`.

### 13.3 Sending Commands

From WordPress plugin:
Commands are sent via `window.postMessage()` with a specific type, source identifier, unique request ID, and command-specific data.

#### Example: Mockup Fetching
WordPress sends a `SIP_FETCH_MOCKUPS` message containing blueprint ID, product ID, shop ID, and user ID. The extension processes this request and returns a response wrapped as `SIP_EXTENSION_RESPONSE` with a matching request ID, containing the mockup data.

#### Example: Update Product Mockups
WordPress sends a `SIP_UPDATE_PRODUCT_MOCKUPS` message with product IDs, shop ID, and an array of selected mockups. The extension navigates to the product mockup page, makes internal API calls, and returns success/failure status for each mockup update.

#### Example: Publish Products
WordPress sends a `SIP_PUBLISH_PRODUCTS` message with an array of products (containing WordPress product ID, Printify product ID, and title) and shop ID. The extension makes internal API calls to publish each product and returns success/failure status for each.

### 13.4 jQuery Events

The browser-extension-manager triggers these jQuery events for inter-module communication:

- **`extensionReady`**: Triggered when extension announces it's ready via `SIP_EXTENSION_READY`, passing the extension version and capabilities.

- **`extensionInstalled`**: Triggered when extension is first installed via `SIP_EXTENSION_INSTALLED`, passing a flag indicating first install and the extension version.

Modules can listen for these events to react to extension state changes using jQuery's event system.

### 13.5 Extension Detection on Authentication Page

The SiP Printify Manager authentication page includes a two-step process where Step 1 checks for extension installation.

#### Implementation Pattern

**HTML Structure** (dashboard-html.php):
Two div elements are used - one showing the install button and instructions (visible by default), and another showing the success message (hidden by default).

**JavaScript Detection** (shop-actions.js):
Listens for the `extensionReady` event from browser-extension-manager. When received, it hides the "not detected" div, shows the "detected" div, and marks the extension install section as completed.

**Why This Pattern**:
- Initial state is clear: extension not detected (only one div visible)
- Detection uses existing event system (no duplicate listeners)
- UI updates are coordinated through jQuery events

**Key Points**:
- The `browser-extension-manager.js` handles all extension communication
- Other modules listen for the `extensionReady` jQuery event
- No direct `window.addEventListener` for extension messages in individual modules
- DOM marker detection used for extension presence verification

### 13.6 Common Pitfalls - MUST READ

**CRITICAL: Understanding Message Boundaries**

1. **chrome.tabs.sendMessage ONLY reaches content scripts**
   ```javascript
   // WRONG - WordPress pages cannot receive this:
   chrome.tabs.sendMessage(tabId, { data: 'something' });
   
   // CORRECT - Use the relay pattern documented above
   ```

2. **WordPress pages can ONLY receive postMessage**
   - WordPress has NO chrome.runtime.onMessage listener
   - WordPress has NO access to Chrome Extension APIs
   - ALL Extension → WordPress communication MUST use postMessage

3. **The Relay is One-Way for Responses**
   - widget-relay.js forwards WordPress → Extension messages
   - Extension responses come back through the SAME relay
   - Do NOT attempt to bypass the relay with direct messaging

**Why This Architecture**: Chrome's security model creates strict boundaries between web pages and extensions. The relay pattern is the ONLY reliable way to bridge these boundaries.

### 13.7 REST API Endpoints

Extension calls these WordPress endpoints:
- `POST /wp-json/sip-printify/v1/extension-status`
- `GET /wp-json/sip-printify/v1/plugin-status`

Authentication via header: `X-SiP-API-Key: [32-character-key]`

## 14. Pause/Resume Error Recovery System

### 14.1 Overview

The pause/resume system provides interactive error handling for page load failures during automated operations. When the extension encounters login requirements, 404 errors, or page load issues, it pauses operations, focuses the problematic tab, and provides clear instructions for users to resolve the issue before resuming.

### 14.2 Architecture

#### Core Components

**Router State Management** (`widget-router.js`): Maintains `pausedOperation` state variable. The `pauseOperation()` stores operation context, while `resumeOperation()` retrieves and clears the stored operation.

**Error Detection** (`mockup-library-actions.js`): The `detectPageIssue()` function checks for login pages (URL contains '/login' or password input exists), 404 errors (title or content indicators), and general error pages (error class elements). Returns array of detected issues or null.

### 14.3 Operation Flow

#### Pause Flow
1. **Error Detection**: Content script detects page load issue
2. **Operation Pause**: Handler stores operation context in router
3. **Tab Focus**: Chrome focuses the problematic tab
4. **UI Update**: Widget shows pause status with clear instructions
5. **User Action**: User fixes the issue (logs in, navigates to correct page)

#### Resume Flow
1. **User Clicks Resume**: Widget sends resume request
2. **Context Retrieval**: Router retrieves paused operation
3. **Operation Continues**: Handler resumes from where it left off
4. **Success Response**: Operation completes and responds to WordPress

### 14.4 Implementation Example

**Error Detection and Pause Implementation**:
```javascript
// From mockup-update-handler.js
async function waitForPageReady(tabId, router) {
    // Wait for page to load
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Check for page issues
    const issues = await chrome.tabs.sendMessage(tabId, {
        type: 'checkPageState'
    });
    
    if (issues && issues.length > 0) {
        // Pause operation with context
        await router.pauseOperation({
            type: 'mockup-update',
            handler: 'mockup-update',
            context: {
                tabId: tabId,
                productId: this.currentProductId,
                mockups: this.pendingMockups
            },
            reason: issues[0],
            message: getErrorMessage(issues[0])
        });
        
        // Focus problematic tab
        await chrome.tabs.update(tabId, { active: true });
        
        // Update widget UI
        await chrome.storage.local.set({
            sipWidgetState: {
                operationStatus: 'paused',
                pauseReason: getErrorMessage(issues[0])
            }
        });
        
        return { paused: true };
    }
    
    return { ready: true };
}

// From widget-data-handler.js - Resume handling
case 'resumeOperation':
    const pausedOp = await router.resumeOperation();
    if (pausedOp && pausedOp.handler === 'mockup-update') {
        // Re-dispatch to mockup handler with saved context
        return handlers['mockup-update'].handle(
            { action: 'updateMockups', data: pausedOp.context },
            sender,
            sendResponse,
            router
        );
    }
    break;
```

### 14.5 Widget UI Integration

**Status Display** (`widget-tabs-actions.js`): The `updateOperationStatus()` function updates the widget UI to show pause status with warning icon, message, and resume button when status is 'paused'.

### 14.6 Error Messages

The system provides user-friendly messages for common issues:

| Issue | Message |
|-------|---------|
| `login_required` | "Please log in to Printify, then click Resume" |
| `page_not_found` | "Page not found. Please navigate to the correct page and click Resume" |
| `page_error` | "Page failed to load. Please refresh the page and click Resume" |
| `permission_denied` | "Access denied. Please check your permissions and click Resume" |

### 14.7 Best Practices

1. **Always Include Resume Handler**: Specify which handler should process the resume
2. **Store Minimal Context**: Only store what's needed to resume the operation
3. **Clear Instructions**: Provide specific actions users should take
4. **Tab Focus**: Always focus the problematic tab for user convenience
5. **Graceful Degradation**: Operations should handle both pause and non-pause scenarios

### 14.8 Adding Pause/Resume to New Operations

To add pause/resume support to a new operation:

1. **Add Error Detection**: Check for page issues during operation
2. **Store Context**: Use `router.pauseOperation()` with operation details
3. **Update UI**: Send status update to widget
4. **Handle Resume**: Add case in `widget-data-handler.js` for your operation type
5. **Test Scenarios**: Test with login pages, 404s, and network errors

## 14. Development Guidelines

### 14.1 Widget Visibility Requirements

**Widget Initialization**:
- Widget MUST start with `sip-visible` class for immediate visibility
- Default position MUST be within viewport bounds
- For top-right positioning: `x: window.innerWidth - 340, y: 20` (accounts for 320px expanded width)
- Position validation should account for both collapsed (60px) and expanded (320px) widths

**CSS Classes**:
- `sip-visible`: Required for widget to be visible (adds opacity: 1, visibility: visible)
- `collapsed`/`expanded`: Controls widget state
- Never rely on inline styles for critical visibility

**Debugging "Missing" Widget**:
1. Check if widget is actually loaded but positioned off-screen
2. Look for `[Widget UI]` console messages
3. Inspect DOM for `#sip-floating-widget` element
4. Verify position values in inline styles

### 14.2 Adding New Operations

1. Start with the trigger (user action or page event)
2. Define the message format
3. Add routing logic if new handler type
4. Implement handler logic
5. Define Chrome API commands if needed
6. Update storage schema if needed
7. Update UI components if needed

### 14.3 Debugging

- Enable debug mode: `chrome.storage.local.set({sip_printify_debug: true})`
- Check router for message flow
- Verify message formats match documentation
- Check Chrome DevTools for both page and extension contexts

### 14.4 Testing Checklist

- [ ] Run `node validate-manifest.js` to check manifest integrity
- [ ] Check chrome://extensions for ANY errors or warnings
- [ ] Click "service worker" link and check for console errors
- [ ] Verify no BOM characters in JSON files: `file manifest.json` should show "ASCII text" not "UTF-8 Unicode (with BOM) text"
- [ ] Add `console.log()` at top of problematic scripts to verify they load
- [ ] Check that widget appears on screen (not just loaded)
- [ ] Messages route correctly through widget-router.js
- [ ] Handlers process actions and return proper responses
- [ ] Chrome API commands execute directly in router context
- [ ] State updates propagate via Chrome storage
- [ ] Widget UI reflects state changes
- [ ] Error cases return standardized error responses

### 14.5 Common Pitfalls

**Manifest Corruption**:
- Chrome silently fails on manifest parsing errors
- BOM characters cause content_scripts to not load
- Always validate manifest.json before testing
- Check service worker console for hidden errors

**Partial Loading**:
- Extension can appear to work with corrupt manifest
- Background scripts may load while content scripts don't
- Programmatic injection can mask manifest issues

### 14.6 Content Security Policy (CSP) Compliance

**Why it matters**: WordPress and many web applications enforce Content Security Policy to prevent XSS attacks. Extensions must be CSP-compliant to function correctly.

**CSP Restrictions**:
- No inline scripts (`<script>` tags in HTML strings)
- No inline event handlers (`onclick`, `onload`, etc.)
- No `document.write()` or `eval()`
- Limited inline styles (some CSPs block all inline styles)

**Implementation Patterns**: Avoid inline scripts and event handlers. Instead of using HTML strings with `onclick` attributes or `<script>` tags, create elements programmatically and attach event listeners with `addEventListener()`. Never use `document.write()` or `eval()`.

**Widget CSP Compliance**:
- All styles in `widget-styles.css` with CSS classes
- Dynamic values use data attributes: `data-progress="50"`
- Event handlers attached via `addEventListener()`
- DOM built programmatically, never with HTML strings

**Testing for CSP**:
1. Add CSP header to test page: `Content-Security-Policy: script-src 'self';`
2. Check browser console for CSP violation errors
3. Verify all functionality works without inline scripts/styles


## Appendices

### A. Chrome Assets

Images requiring chrome.runtime.getURL must be declared in manifest.json under `web_accessible_resources` with appropriate resource paths and match patterns.

### B. Architecture Implementation Notes

The router MUST be the background script because:
1. Chrome extensions don't allow content scripts to intercept runtime messages
2. All chrome.runtime.sendMessage calls go directly to the background script
3. This is the only way to achieve the "ALL messages flow through router" requirement

Key implementation details:
1. background.js loads all modules via importScripts in the correct order
2. Handlers are loaded in the background context and receive router context
3. widget-relay.js handles WordPress postMessage relay in content script context
4. All Chrome API execution happens directly in the router, no separate executor needed

## 15. Common Issues and Troubleshooting

### 15.1 Message Port Closed Error

**Error**: "The message port closed before a response was received"

**Cause**: Handler function didn't return `true` for async operations

**Solution**: Always return `true` at the end of async handler functions to keep the message channel open. Without this return statement, Chrome closes the channel before the async response can be sent.

### 15.2 Tab Navigation Issues

**Issue**: Operations requiring Printify access fail when no Printify tab is open

**Solution**: The `navigateTab` function in widget-router.js automatically checks for existing paired tabs, creates new tabs if needed, and maintains tab pairing. Handlers should always use `router.navigateTab()` for Printify operations to get the tab ID.


