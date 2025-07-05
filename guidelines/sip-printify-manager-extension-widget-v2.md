# SiP Printify Manager Browser Extension - Streamlined Documentation

**Repository**: https://github.com/tdemelle-SiP/sip-printify-manager-extension

## 1. Overview

The SiP Printify Manager browser extension bridges the gap between WordPress and Printify.com, enabling automated workflows and data access not available through Printify's public API.

**Core Problem**: WordPress plugins cannot directly access Printify's internal APIs or page data.

**Solution**: A Chrome extension that acts as a privileged intermediary, capturing data and executing operations on behalf of the WordPress plugin.

**Critical Limitation**: Printify blocks `chrome.runtime` access in content scripts, preventing traditional extension messaging. The extension uses URL parameters for mockup updates and has limited functionality on Printify pages.

## 2. Architecture

### Diagram Notation Guide

Following the SiP Mermaid guidelines, all diagrams use consistent notation:

**Box Types**:
- `[User action]` - User events (clicks, navigations)
- `[JS does something<br/>-functionName-]` - Code execution with function name
- `[(Storage Type<br/>-key-)]` - Storage with actual key names (cylinder shape for persistence)

**Connection Labels**:
- `-->|methodName|` - Function calls or API methods
- `-->|chrome.storage.set|` - Chrome API calls
- `-->|window.postMessage|` - Browser APIs
- `-.->|onChange|` - Event-driven connections

**Why This Notation**: Every function that touches data must be visible for implementation validation.

### 2.1 Master System Architecture

This diagram shows the complete extension architecture with key functions:

```mermaid
graph TB
    subgraph "WordPress Context"
        subgraph "User Events"
            UserAction[User clicks action button]
        end
        
        subgraph "Code Flow"
            WP[PHP renders page<br/>-sip_printify_manager_page-]
            BEM[JS sends message<br/>-sendMessageToExtension-]
        end
    end
    
    subgraph "Extension - Content Scripts"
        subgraph "WordPress Pages"
            RelayListen[JS listens postMessage<br/>-window.addEventListener-]
            RelayHandle[JS validates & wraps<br/>-handlePostMessage-]
            RelaySend[JS sends to router<br/>-chrome.runtime.sendMessage-]
            Detector[JS announces presence<br/>-announceExtension-]
            Widget1[JS creates widget UI<br/>-createWidget-]
        end
        
        subgraph "Printify Pages"
            Widget2[JS creates widget UI<br/>-createWidget-]
            Monitor[JS monitors page<br/>-observeDOM-]
            Mockup[JS reads URL params<br/>-checkUrlParameters-]
            AutoSelect[JS automates selection<br/>-executeSceneSelection-]
        end
        
        subgraph "Shared Scripts"
            Error[JS formats errors<br/>-formatError-]
            ErrorCap[JS captures errors<br/>-window.onerror-]
            Logger[JS logs actions<br/>-ActionLogger.log-]
            LogHelper[JS log shortcuts<br/>-action.info/error/warn-]
        end
    end
    
    subgraph "Extension - Background Service Worker"
        BG[JS loads modules<br/>-importScripts-]
        
        subgraph "Router Functions"
            RouterMsg[JS receives messages<br/>-handleMessage-]
            RouterVal[JS validates message<br/>-validateMessage-]
            RouterWrap[JS wraps response<br/>-wrapSendResponse-]
            RouterRoute[JS routes by type<br/>-routeToHandler-]
            RouterPause[JS pauses operation<br/>-pauseOperation-]
            RouterResume[JS resumes operation<br/>-resumeOperation-]
        end
        
        subgraph "Handler Functions"
            WHHandle[JS widget handler<br/>-handle-]
            PHHandle[JS printify handler<br/>-handle-]
            WPHRoute[JS routes wordpress<br/>-handle-]
            MFHandle[JS mockup fetch<br/>-handle-]
            MUHandle[JS mockup update<br/>-handle-]
        end
        
        subgraph "Chrome API Functions"
            NavTab[JS navigates tabs<br/>-navigateTab-]
            CreateTab[JS creates tab<br/>-chrome.tabs.create-]
            QueryTab[JS queries tabs<br/>-chrome.tabs.query-]
            SetStore[JS saves state<br/>-chrome.storage.set-]
            GetStore[JS loads state<br/>-chrome.storage.get-]
            InjectScript[JS injects scripts<br/>-chrome.scripting.executeScript-]
        end
        
        subgraph "Helper Functions"
            TestConn[JS test connection<br/>-testWordPressConnection-]
            CheckPlugin[JS check plugin<br/>-checkWordPressPluginStatus-]
            ExtractScene[JS extract scenes<br/>-extractSceneNames-]
        end
    end
    
    subgraph "Storage"
        ConfigStore[(Chrome Sync<br/>-wordpressUrl-<br/>-apiKey-)]
        StateStore[(Chrome Local<br/>-sipWidgetState-<br/>-sipTabPairs-<br/>-sipActionLogs-<br/>-sipOperationStatus-)]
    end
    
    %% User flow
    UserAction -->|click| BEM
    BEM -->|window.postMessage| RelayListen
    RelayListen -->|event| RelayHandle
    RelayHandle -->|validated| RelaySend
    RelaySend -->|chrome.runtime| RouterMsg
    
    %% Router flow
    BG -->|imports| RouterMsg
    RouterMsg -->|validates| RouterVal
    RouterVal -->|wraps| RouterWrap
    RouterWrap -->|routes| RouterRoute
    RouterRoute -->|type:widget| WHHandle
    RouterRoute -->|type:wordpress| WPHRoute
    RouterRoute -->|type:printify| PHHandle
    RouterRoute -->|SIP_FETCH_MOCKUPS| MFHandle
    RouterRoute -->|SIP_UPDATE_PRODUCT_MOCKUPS| MUHandle
    
    %% Handler operations
    WHHandle -->|calls| NavTab
    NavTab -->|uses| QueryTab
    NavTab -->|uses| CreateTab
    WHHandle -->|saves| SetStore
    SetStore -->|chrome.storage.local.set| StateStore
    MUHandle -->|calls| ExtractScene
    MUHandle -->|opens tab with params| CreateTab
    PHHandle -->|calls| InjectScript
    RouterMsg -->|lifecycle| TestConn
    RouterMsg -->|lifecycle| CheckPlugin
    
    %% Storage events
    StateStore -.->|onChange| Widget1
    StateStore -.->|onChange| Widget2
    
    %% Configuration
    GetStore -->|chrome.storage.sync.get| ConfigStore
    
    style RouterMsg fill:#f9f,stroke:#333,stroke-width:4px
    style RelayHandle fill:#bbf,stroke:#333,stroke-width:2px
```

**Reading the Master Diagram**:
- **Box Format**: `[Language action<br/>-functionName-]` shows what the code does and which function
- **Solid arrows (→)**: Active message/data flow with labels showing method calls
- **Dashed arrows (--->)**: Configuration or dependency relationships
- **Dotted arrows (-.->)**: Event-driven updates (storage onChange) or usage dependencies
- **Storage Format**: `[(Storage Type<br/>-key name-)]` shows actual storage keys
- **Subgraphs**: Execution contexts with different Chrome API capabilities

**Key Architecture Points**:
- **Router is the hub**: ALL runtime messages flow through handleMessage() in widget-router.js
- **Content scripts are limited**: Can only use chrome.runtime.sendMessage and chrome.storage (except on Printify where chrome.runtime is blocked)
- **Background has full access**: Service worker context with all Chrome APIs
- **Function visibility**: Every function that touches data is shown
- **One-way message flow**: WordPress → Relay → Router → Handler → Response
- **Printify limitation**: chrome.runtime blocked, mockup updates use URL parameters instead

### Understanding the Diagram Hierarchy

The Master System Architecture diagram above provides a complete view of the extension system, showing all major components and their relationships. However, to truly understand the implementation and validate that code matches architecture, we need function-level detail for specific flows.

The following detail diagrams expand specific aspects of the master architecture to show:
- **Every function that touches data** in that particular flow
- **The exact function names** from the code (shown in `-functionName-` format)
- **The specific operations** each function performs
- **Error handling paths** that might not be visible at the high level

Each detail diagram serves developers who need to:
- Trace a specific flow (e.g., "Why isn't my WordPress command working?")
- Implement changes to that flow (e.g., "Where do I add validation for tab operations?")
- Understand the complete chain of operations (e.g., "What happens between click and response?")

### 2.2 Complete Message Flow (Function Level)

**Purpose**: This diagram details the complete message flow from WordPress through the extension and back, showing every function call in sequence. Use this when tracing end-to-end communication issues or understanding the full request/response cycle.

This sequence diagram shows the exact function calls for a typical operation:

```mermaid
sequenceDiagram
    participant WP as WordPress
    participant Relay as widget-relay.js
    participant Router as widget-router.js  
    participant Handler as mockup-update-handler.js
    participant Chrome as Chrome APIs
    participant Logger as ActionLogger
    
    WP->>Relay: postMessage({type: 'SIP_UPDATE_MOCKUPS'})
    activate Relay
    Note over Relay: handlePostMessage(event)
    Relay->>Relay: validateOrigin(event.origin)
    Relay->>Relay: checkSource(data.source)
    
    Relay->>Router: chrome.runtime.sendMessage({<br/>type: 'WORDPRESS_RELAY',<br/>data: originalMessage})
    deactivate Relay
    
    activate Router
    Note over Router: handleMessage(message, sender, sendResponse)
    Router->>Router: validateMessage(message)
    Router->>Logger: ActionLogger.log('WORDPRESS_ACTION', 'Received: SIP_UPDATE_MOCKUPS')
    
    Router->>Router: importHandlers()
    Router->>Router: wrapSendResponse(sendResponse)
    Router->>Router: getHandler(message.type)
    
    Router->>Handler: handle(message, sender, wrappedResponse, routerContext)
    deactivate Router
    
    activate Handler
    Handler->>Handler: validateMockupData(message.data)
    Handler->>Chrome: routerContext.navigateTab(url, 'printify', tabId)
    activate Chrome
    Chrome->>Chrome: getPairedTab(tabId)
    Chrome->>Chrome: chrome.tabs.create({url: url})
    Chrome-->>Handler: {success: true, tabId: 123, action: 'created-pair'}
    deactivate Chrome
    
    alt Success Path
        Handler->>Handler: waitForPageReady(tabId)
        Handler->>Chrome: chrome.tabs.sendMessage(tabId, {action: 'updateSelections'})
        Chrome-->>Handler: {success: true}
        Handler->>Router: wrappedResponse({success: true, data: {...}})
        activate Router
        Router->>Logger: ActionLogger.log('WORDPRESS_ACTION', 'SUCCESS: SIP_UPDATE_MOCKUPS')
        Router->>Relay: originalSendResponse({success: true})
        deactivate Router
        activate Relay
        Relay->>WP: postMessage({type: 'SIP_EXTENSION_RESPONSE', success: true})
        deactivate Relay
    else Error Path
        Handler->>Handler: detectPageIssue()
        Handler->>Router: routerContext.pauseOperation(context)
        Handler->>Router: wrappedResponse({success: false, error: 'Login required'})
        activate Router
        Router->>Logger: ActionLogger.log('WORDPRESS_ACTION', 'ERROR: SIP_UPDATE_MOCKUPS - Login required')
        Router->>Relay: originalSendResponse({success: false, error: 'Login required'})
        deactivate Router
    else Timeout Path
        Note over Handler: Never calls wrappedResponse
        Note over Logger: Only "Received" log exists
        Note over WP: Chrome times out after ~5 minutes
    end
    deactivate Handler
```

### 2.3 Storage Architecture Detail (Function Level)

**Purpose**: This diagram expands the storage components from the master diagram, showing every function that reads, writes, or transforms storage data. Use this when investigating storage issues, implementing new storage features, or understanding data persistence patterns.

```mermaid
graph LR
    subgraph "Storage Functions"
        subgraph "Configuration"
            InitConfig[JS loads config<br/>-initializeConfig-]
            LoadConfig[JS reads storage<br/>-loadConfiguration-]
            UpdateConfig[JS saves config<br/>-updateConfig-]
        end
        
        subgraph "Tab Pairing"
            LoadPairs[JS loads pairs<br/>-loadTabPairs-]
            SavePairs[JS saves pairs<br/>-saveTabPairs-]
            CreatePair[JS creates pair<br/>-createTabPair-]
            RemovePair[JS removes pair<br/>-removeTabPair-]
            GetPaired[JS gets pair<br/>-getPairedTab-]
        end
        
        subgraph "Action Logging"  
            StoreLog[JS stores log<br/>-storeLog-]
            GetLogs[JS retrieves logs<br/>-getActionLogs-]
            ClearLogs[JS clears logs<br/>-clearActionLogs-]
        end
        
        subgraph "Widget State"
            SaveWidget[JS saves state<br/>-saveWidgetState-]
            LoadWidget[JS loads state<br/>-loadWidgetState-]
        end
    end
    
    subgraph "Chrome Storage"
        subgraph "Sync Storage"
            WPUrl[(chrome.storage.sync<br/>-wordpressUrl-)]  
            APIKey[(chrome.storage.sync<br/>-apiKey-)]
        end
        
        subgraph "Local Storage"
            WidgetState[(chrome.storage.local<br/>-sipWidgetState-)]
            TabPairs[(chrome.storage.local<br/>-sipTabPairs-)]
            ActionLogs[(chrome.storage.local<br/>-sipActionLogs-)]
            OpStatus[(chrome.storage.local<br/>-sipOperationStatus-)]
        end
    end
    
    subgraph "Runtime Cache"
        ConfigCache[config object]
        TabMapCache[tabPairs Map]
        TimingsCache[sipActionTimings]
    end
    
    %% Configuration flow
    InitConfig -->|calls| LoadConfig
    LoadConfig -->|chrome.storage.sync.get| WPUrl
    LoadConfig -->|chrome.storage.sync.get| APIKey
    LoadConfig -->|populates| ConfigCache
    UpdateConfig -->|chrome.storage.sync.set| WPUrl
    UpdateConfig -->|chrome.storage.sync.set| APIKey
    
    %% Tab pairing flow  
    LoadPairs -->|chrome.storage.local.get| TabPairs
    LoadPairs -->|populates| TabMapCache
    CreatePair -->|updates| TabMapCache
    CreatePair -->|calls| SavePairs
    SavePairs -->|chrome.storage.local.set| TabPairs
    GetPaired -->|reads| TabMapCache
    
    %% Action logging flow
    StoreLog -->|chrome.storage.local.get| ActionLogs
    ActionLogs -->|current logs| StoreLog
    StoreLog -->|appends & trims| ActionLogs
    GetLogs -->|chrome.storage.local.get| ActionLogs
    
    %% Widget state flow
    SaveWidget -->|chrome.storage.local.set| WidgetState
    LoadWidget -->|chrome.storage.local.get| WidgetState
    WidgetState -.->|onChange event| LoadWidget
```

**Storage Rationale**:
- **Sync vs Local**: Config in sync (small, needs roaming), state in local (larger, device-specific)
- **5MB Chrome limit**: Action logs auto-cleanup at 500 entries
- **Runtime state**: Performance-critical data kept in memory
- **Bidirectional pairs**: Enable navigation from either tab

### 2.4 Tab Pairing System Detail (Function Level)

**Purpose**: This diagram details the tab pairing system from the master diagram, showing how WordPress and Printify tabs maintain their bidirectional relationship. Use this when investigating navigation issues, implementing new tab operations, or understanding the pairing lifecycle.

```mermaid
sequenceDiagram
    participant User
    participant Widget as widget-tabs-actions.js
    participant Handler as widget-data-handler.js
    participant Router as widget-router.js
    participant Chrome as Chrome APIs
    
    User->>Widget: Click "Go to Printify" button
    activate Widget
    Widget->>Widget: handleButtonClick(event)
    Widget->>Widget: chrome.runtime.sendMessage({<br/>type: 'widget',<br/>action: 'navigate',<br/>data: {url, destination}})
    deactivate Widget
    
    Note over Handler: handle(message, sender, sendResponse, router)
    activate Handler
    Handler->>Handler: Extract sender.tab.id as currentTabId
    Handler->>Router: router.navigateTab(url, destination, currentTabId)
    deactivate Handler
    
    activate Router
    Note over Router: navigateTab(url, tabType, currentTabId)
    Router->>Router: getPairedTab(currentTabId)
    Router->>Router: tabPairs.get(123) // returns 456
    
    alt Paired tab exists (456)
        Router->>Chrome: chrome.tabs.get(456)
        Chrome-->>Router: pairedTab object
        
        alt Tab still exists
            Router->>Router: isSameUrl(pairedTab.url, targetUrl)
            
            alt Already on target URL
                Router->>Chrome: chrome.tabs.update(456, {active: true})
                Router->>Chrome: chrome.windows.update(windowId, {focused: true})
                Router-->>Handler: {success: true, action: 'switched-focus', tabId: 456}
            else Different URL
                Router->>Chrome: chrome.tabs.update(456, {url: url, active: true})
                Router-->>Handler: {success: true, action: 'reused-pair', tabId: 456}
            end
        else Tab was closed
            Router->>Router: removeTabPair(123)
            Router->>Router: tabPairs.delete(123)
            Router->>Router: tabPairs.delete(456)
            Router->>Router: saveTabPairs()
            Note over Router: Continue to create new tab
        end
    end
    
    opt No pair exists
        Router->>Chrome: chrome.tabs.create({url: url, active: true})
        Chrome-->>Router: newTab {id: 789}
        Router->>Router: createTabPair(123, 789)
        Router->>Router: tabPairs.set(123, 789)
        Router->>Router: tabPairs.set(789, 123) // Bidirectional
        Router->>Router: saveTabPairs()
        Router->>Chrome: chrome.storage.local.set({sipTabPairs: {...}})
        Router-->>Handler: {success: true, action: 'created-pair', tabId: 789}
    end
    deactivate Router
```

**Tab Pairing Rationale**:
- **User expectation**: "Go to" should reuse tabs, not proliferate them
- **Bidirectional**: Users navigate both directions equally
- **Smart reuse**: Avoids reload if already on target page
- **Automatic cleanup**: chrome.tabs.onRemoved ensures no orphaned pairs

## 3. Architectural Rationale

### 3.1 Why This Architecture?

**Chrome Extension Constraints**:
1. **Security boundaries**: Web pages cannot access Chrome APIs
2. **Message passing rules**: Content scripts cannot intercept messages between other content scripts
3. **Context isolation**: Background scripts have no DOM access

**Core Design Principles**:

1. **Push-Driven Architecture**: Extension announces presence; WordPress never polls
   - *Why*: Reduces message traffic, ensures accurate state
   - *Implementation*: Fresh detection on every page load

2. **"Dumb Pipe" Principle**: Extension captures raw data; WordPress processes it
   - *Why*: Keeps extension simple, business logic centralized
   - *Implementation*: Handlers return raw API responses

3. **Central Router Pattern**: All messages flow through one hub
   - *Why*: Chrome funnels all runtime messages to background script
   - *Constraint*: Content scripts cannot intercept each other's messages

4. **Infrastructure-Level Logging**: Response logging at router, not handlers
   - *Why*: Cross-cutting concern, guaranteed coverage
   - *Implementation*: Router wraps sendResponse before passing to handlers

5. **Fresh Detection Model**: Extension state never persisted between page loads
   - *Why*: Eliminates false positives, ensures accurate detection
   - *Implementation*: Extension must announce on every page load

### 3.2 Component Purposes

| Component | Purpose (WHY it exists) |
|-----------|------------------------|
| Component | Purpose (WHY it exists) | Constraint/Requirement |
|-----------|------------------------|------------------------|
| **widget-relay.js** | Bridge between postMessage and chrome.runtime | WordPress can only use postMessage |
| **widget-router.js** | Central message hub and Chrome API executor | Chrome sends all messages to background |
| **background.js** | Module loader for service worker | Manifest V3 requires importScripts |
| **Handlers** | Separate business logic from infrastructure | Easier testing, single responsibility |
| **Action Scripts** | Detect page events and user interactions | Content scripts have limited API access |
| **widget-error.js** | Standardize error responses | Consistent error format for WordPress |
| **action-logger.js** | Structured action history | Log extension actions for analysis |
| **Tab Pairing** | Reuse existing tabs | Users expect "Go to Printify" to reuse tabs |
| **Response Logging** | Visible operation outcomes | Timeout/failures need to be traceable |

## 4. Implementation Guide

### 4.1 Architectural Constraints

**Why Router MUST be the background script**:
- Chrome doesn't allow content scripts to intercept runtime messages between other content scripts
- ALL chrome.runtime.sendMessage() calls go directly to the background script
- This is why we achieve "ALL messages flow through router"

**Why extension state is never persisted**:
- Ensures "Install Extension" button always appears when extension not present
- Eliminates stale state from uninstalled extensions
- Forces push-driven model (extension announces when ready)

### 4.2 Message Formats

**External (WordPress ↔ Extension)**:
```javascript
{
    type: 'SIP_*',              // SIP_ prefix identifies our messages
    source: 'sip-printify-manager',
    requestId: 'unique_id',     // For async response correlation
    data: { /* command data */ }
}
```

**Internal (Extension components)**:
```javascript
{
    type: 'widget|printify|wordpress',  // Routes to handler
    action: 'specificAction',           // Handler method
    data: { /* action data */ }
}
```

### 4.4 Adding New Features

1. **Define the trigger** (user action or page event)
2. **Create message in action script**: 
   ```javascript
   chrome.runtime.sendMessage({
       type: 'printify',
       action: 'newFeature',
       data: { /* ... */ }
   });
   ```
3. **Add handler method**:
   ```javascript
   case 'newFeature':
       // Implementation
       sendResponse({success: true});
       return true; // CRITICAL for async
   ```

### 4.3 Action Logging Shortcuts

**New Global Helper** (action-log-helper.js):
```javascript
// Available in all content scripts
action.info('User action', { details });      // USER_ACTION category
action.error('Something failed', { error });  // ERROR category  
action.warn('Warning message', { data });     // WARNING category
action.data('Data fetched', { results });     // DATA_FETCH category
action.api('API called', { endpoint });       // API_CALL category
action.navigation('Tab navigated', { url });  // NAVIGATION category

// Replaces verbose calls like:
if (window.SiPWidget && window.SiPWidget.ActionLogger) {
    window.SiPWidget.ActionLogger.log(
        window.SiPWidget.ActionLogger.CATEGORIES.ERROR,
        'Something failed',
        { error: details }
    );
}
```

**Important**: Use action logging instead of console.log() to keep all log messages together in the action history. Console.log should only be used for critical environment issues (like chrome.runtime availability).

### 4.4 Mockup Scene Mapping

**Scene ID to Name Mapping** (mockup-update-handler.js):
```javascript
function extractSceneNames(selectedMockups) {
    const sceneIdToName = {
        '102752': 'Front',
        '102753': 'Right', 
        '102754': 'Back',
        '102755': 'Left'
    };
    
    const sceneNames = new Set();
    selectedMockups.forEach(mockup => {
        const parts = mockup.id.split('_');
        if (parts.length >= 3) {
            const sceneId = parts[2];
            const sceneName = sceneIdToName[sceneId];
            if (sceneName) {
                sceneNames.add(sceneName);
            }
        }
    });
    
    return Array.from(sceneNames);
}
```

**Mockup ID Format**: `mockup_{variant}_{scene}_{position}`
- Example: `mockup_19773102_102752_1`
- variant: 19773102 (product variant ID)
- scene: 102752 (maps to 'Front')
- position: 1 (position in scene)

**Why Hard-coded Mapping**: Printify's internal scene IDs are stable but not exposed in their UI. The mapping was determined by inspecting the mockup library page.

### 4.5 Chrome Architecture Constraints

**Service Worker (Background) Constraints**:
```javascript
// NO DOM access - this will fail in background.js:
// window.location  ❌
// document.querySelector  ❌

// Must check for window existence:
const isServiceWorker = typeof window === 'undefined';
const globalScope = isServiceWorker ? self : window;
```
*Why*: Chrome Manifest V3 service workers have no DOM

**Content Script Constraints**:
```javascript
// Limited Chrome API access:
chrome.storage.local.get()  ✓  // Allowed
chrome.runtime.sendMessage()  ✓  // Allowed (except on Printify)
chrome.tabs.create()  ❌  // Not allowed

// Must request privileged operations from background:
chrome.runtime.sendMessage({
    type: 'widget',
    action: 'navigate',
    data: { url: 'https://...' }
});

// CRITICAL: On Printify.com, chrome.runtime is BLOCKED:
chrome.runtime.sendMessage()  ❌  // Blocked by Printify
chrome.runtime.onMessage  ❌  // Blocked by Printify  
chrome.runtime.getURL()  ❌  // Blocked by Printify
chrome.runtime.getManifest()  ❌  // Blocked by Printify
```
*Why*: Security isolation between web pages and browser + Printify's additional restrictions

**Message Channel Constraints**:
```javascript
// Content scripts CANNOT intercept other content script messages
// This will NEVER receive messages from other content scripts:
chrome.runtime.onMessage.addListener((message, sender) => {
    // Only receives from background script
});
```
*Why*: Chrome routes all runtime messages through background

### 4.5 Critical Patterns

**Async Message Handling**:
```javascript
// MUST return true to keep channel open
case 'asyncAction':
    (async () => {
        const result = await someAsyncOperation();
        sendResponse(result);
    })();
    return true; // CRITICAL!
```

**Router Context Usage**:
```javascript
// Handlers receive router context with Chrome API methods
const tab = await router.navigateTab(url);
const result = await router.queryTabs({url: '*://printify.com/*'});
```

## 5. Storage Schema

```javascript
// Chrome Storage Local - accessed via chrome.storage.local.get/set
{
    sipWidgetState: {           // Managed by saveWidgetState(), loadWidgetState()
        isExpanded: boolean,
        position: {x: number, y: number},
        currentOperation: {...}
    },
    sipTabPairs: {             // Managed by saveTabPairs(), loadTabPairs()
        "123": "456",          // createTabPair() sets bidirectional
        "456": "123"           // removeTabPair() deletes both
    },
    sipActionLogs: [{          // Managed by storeLog(), getActionLogs()
        timestamp: number,
        category: string,
        action: string,
        details: {...}
    }],
    sipOperationStatus: {      // Set by pauseOperation(), resumeOperation()
        state: 'paused' | 'resuming',
        issue: string,
        instructions: string,
        showResumeButton: boolean
    },
    pendingResearch: {...},
    fetchStatus_*: {...}       // Dynamic keys for fetch operations
}

// Chrome Storage Sync - accessed via chrome.storage.sync.get/set
{
    wordpressUrl: string,      // Set by updateConfig()
    apiKey: string            // 32-character key, set by updateConfig()
}

// Runtime State (not persisted)
{
    tabPairs: Map,            // In-memory cache loaded by loadTabPairs()
    operationState: {         // Managed by pauseOperation()/resumeOperation()
        paused: boolean,
        pausedOperation: {...},
        pausedCallback: Function
    },
    handlers: Map,            // Message type to handler mapping
    config: {                 // Loaded from storage or config.json
        wordpressUrl: string,
        apiKey: string
    }
}
```

### 5.1 Extension Detection & Installation Flow (Function Level)

**Purpose**: This diagram details how the extension announces itself to WordPress pages and how the plugin detects the extension. Use this when investigating extension detection issues, implementing new announcement mechanisms, or understanding the push-driven architecture.

```mermaid
sequenceDiagram
    participant User
    participant Chrome
    participant Router as widget-router.js
    participant Detector as extension-detector.js
    participant BEM as browser-extension-manager.js
    
    User->>Chrome: Install Extension from Chrome Store
    Chrome->>Router: chrome.runtime.onInstalled event
    
    activate Router
    Note over Router: onInstalled listener (line 941)
    Router->>Router: initializeConfig()
    Router->>Chrome: chrome.tabs.query({url: '*://*/wp-admin/*'})
    Chrome-->>Router: Array of WordPress admin tabs
    
    loop For each WordPress tab
        Router->>Chrome: chrome.scripting.executeScript({<br/>target: {tabId: tab.id},<br/>files: ['widget-error.js',<br/>'widget-relay.js',<br/>'extension-detector.js']})
        
        Chrome->>Detector: Script injected and executed
        activate Detector
        Note over Detector: Script runs immediately
        
        alt On SiP Printify Manager page
            Detector->>Detector: checkPageContext()
            Detector->>Detector: Returns true (is manager page)
            Detector->>Detector: setTimeout(announceExtension, 100)
            
            Note over Detector: 100ms delay
            
            Detector->>Detector: announceExtension()
            Detector->>BEM: window.postMessage({<br/>type: 'SIP_EXTENSION_READY',<br/>source: 'sip-printify-extension',<br/>version: manifest.version})
        else On SiP Plugins Core page
            Detector->>Detector: checkPageContext()
            Detector->>Detector: Returns false (wait for request)
            Note over Detector: Waits for SIP_REQUEST_EXTENSION_STATUS
        end
        deactivate Detector
    end
    deactivate Router
    
    activate BEM
    Note over BEM: setupExtensionCommunication()
    BEM->>BEM: window.addEventListener('message', handleMessage)
    BEM->>BEM: handleMessage(event)
    BEM->>BEM: validateOrigin(event.origin)
    BEM->>BEM: updateExtensionState({<br/>isInstalled: true,<br/>version: data.version})
    BEM->>BEM: $('#install-extension-section').hide()
    BEM->>BEM: $(document).trigger('extensionReady')
    deactivate BEM
    
    Note over BEM: State NOT persisted<br/>Must announce every page load
```

**Why Programmatic Injection**: Content scripts don't auto-inject into already-open tabs after installation. Users expect immediate functionality without reload.

**Why 100ms Delay**: Ensures all scripts are fully loaded before announcing presence.

**Why No State Persistence**: Fresh detection eliminates false positives from uninstalled extensions.

## 6. Message Type Reference

### WordPress Commands (SIP_*)
| Command | Purpose | Handler |
|---------|---------|---------|
| SIP_NAVIGATE | Navigate to URL | widget |
| SIP_SHOW_WIDGET | Show widget UI | widget |
| SIP_CHECK_STATUS | Check connection | widget |
| SIP_FETCH_MOCKUPS | Get mockup data | printify |
| SIP_UPDATE_PRODUCT_MOCKUPS | Update mockups (via URL params) | printify |

### Internal Actions
| Type | Actions | Purpose |
|------|---------|---------|
| widget | navigate, showWidget, updateState | UI operations |
| printify | fetchMockups, updateStatus | Printify operations |
| wordpress | (routes SIP_* to handlers) | Message translation |

### 6.1 Message Format Transformation (Function Level)

**Purpose**: This diagram details how WordPress commands are transformed as they pass through the extension layers. Use this when investigating message format issues, implementing new message types, or understanding why messages arrive in different formats at different layers.

```mermaid
flowchart LR
    subgraph "WordPress Context"
        WP[JS builds message<br/>-sendMessageToExtension-]
        WPMsg["{
            type: 'SIP_UPDATE_PRODUCT_MOCKUPS',
            source: 'sip-printify-manager',
            requestId: 'req_123',
            data: { productId: 456 }
        }"]
    end
    
    subgraph "Relay Functions"
        R1[JS receives event<br/>-handlePostMessage-]
        R2[JS validates origin<br/>-event.origin check-]
        R3[JS validates source<br/>-data.source check-]
        R4[JS wraps message<br/>-chrome.runtime.sendMessage-]
        RelayMsg["{
            type: 'WORDPRESS_RELAY',
            data: {
                type: 'wordpress',
                action: 'SIP_UPDATE_PRODUCT_MOCKUPS',
                data: originalMessage,
                requestId: 'req_123'
            }
        }"]
    end
    
    subgraph "Router Functions"
        RO1[JS receives message<br/>-handleMessage-]
        RO2[JS detects relay<br/>-checkWordPressRelay-]
        RO3[JS extracts nested<br/>-message = message.data-]
        RO4[JS logs received<br/>-ActionLogger.log-]
        RO5[JS gets handler<br/>-getHandlerByType-]
        RO6[JS calls handler<br/>-handler.handle-]
    end
    
    subgraph "Handler Processing"
        H1[JS routes command<br/>-wordpress-handler.handle-]
        H2[JS converts to internal<br/>-mapWordPressAction-]
        H3[JS delegates to handler<br/>-PrintifyDataHandler.handle-]
        HandlerMsg["{
            type: 'printify',
            action: 'updateProductMockups',
            data: { productId: 456 }
        }"]
    end
    
    WP -->|creates| WPMsg
    WPMsg -->|window.postMessage| R1
    R1 -->|validates| R2
    R2 -->|checks| R3
    R3 -->|wraps| R4
    R4 -->|creates| RelayMsg
    RelayMsg -->|chrome.runtime| RO1
    RO1 -->|checks| RO2
    RO2 -->|extracts| RO3
    RO3 -->|logs| RO4
    RO4 -->|routes| RO5
    RO5 -->|calls| RO6
    RO6 -->|invokes| H1
    H1 -->|maps| H2
    H2 -->|creates| HandlerMsg
    H2 -->|delegates| H3
```

**Why Transform**: External format identifies our messages among all postMessages. Internal format routes to correct handler.

## 7. Key Features

### 7.1 Tab Pairing System
- Maintains bidirectional pairing between WordPress and Printify tabs
- Reuses existing tabs instead of creating new ones
- Automatically cleans up when tabs close

### 7.2 Pause/Resume Error Recovery (Function Level)

**Purpose**: This diagram details the pause/resume system that handles page errors (login required, 404, etc.) during operations. Use this when investigating error recovery, implementing new error types, or understanding how the extension maintains operation state across user interventions.

```mermaid
sequenceDiagram
    participant Handler as mockup-update-handler.js
    participant Router as widget-router.js
    participant Actions as mockup-library-actions.js
    participant Widget as widget-tabs-actions.js
    participant User
    
    activate Handler
    Note over Handler: waitForPageReady(tabId, router)
    Handler->>Chrome: chrome.tabs.sendMessage(tabId, {<br/>type: 'checkPageState'})
    
    activate Actions
    Actions->>Actions: detectPageIssue()
    Actions->>Actions: Check window.location.href.includes('/login')
    Actions->>Actions: Check document.querySelector('.error-404')
    Actions->>Actions: Check document.querySelector('[type="password"]')
    Actions-->>Handler: {issues: ['login_required']}
    deactivate Actions
    
    Handler->>Router: router.pauseOperation(tabId, 'login_required', 'Please log in')
    
    activate Router
    Note over Router: pauseOperation(tabId, issue, instructions)
    Router->>Router: operationState.paused = true
    Router->>Router: operationState.pausedOperation = {<br/>tabId, issue, instructions,<br/>timestamp: Date.now()}
    Router->>Chrome: chrome.tabs.update(tabId, {active: true})
    Router->>Chrome: chrome.windows.update(tab.windowId, {focused: true})
    Router->>Chrome: chrome.storage.local.set({<br/>sipOperationStatus: {<br/>state: 'paused',<br/>issue: issue,<br/>instructions: instructions,<br/>showResumeButton: true}})
    
    Router->>Router: return new Promise((resolve) => {<br/>operationState.pausedCallback = resolve})
    deactivate Router
    deactivate Handler
    
    Note over Widget: chrome.storage.onChanged listener
    activate Widget
    Widget->>Widget: handleStorageChange(changes)
    Widget->>Widget: updateOperationStatus(changes.sipOperationStatus)
    Widget->>Widget: showPauseUI(status)
    Widget->>User: Display "Please log in" + Resume button
    deactivate Widget
    
    Note over User: User logs in to Printify
    
    User->>Widget: Click Resume button
    activate Widget
    Widget->>Widget: handleResumeClick()
    Widget->>Chrome: chrome.runtime.sendMessage({<br/>type: 'widget',<br/>action: 'resumeOperation'})
    deactivate Widget
    
    activate Handler
    Note over Handler: widget-data-handler receives message
    Handler->>Router: router.resumeOperation()
    
    activate Router
    Note over Router: resumeOperation()
    Router->>Router: operationState.paused = false
    Router->>Router: const callback = operationState.pausedCallback
    Router->>Router: operationState.pausedOperation = null
    Router->>Router: operationState.pausedCallback = null
    Router->>Chrome: chrome.storage.local.set({<br/>sipOperationStatus: {<br/>state: 'resuming'}})
    Router->>Router: callback() // Resolves the promise
    deactivate Router
    
    Note over Handler: Promise resolves, operation continues
    Handler->>Handler: Retry operation from saved context
    Handler->>Actions: chrome.tabs.sendMessage(tabId, {<br/>action: 'updateMockupSelections'})
    Actions-->>Handler: {success: true}
    Handler->>Handler: sendResponse({success: true})
    deactivate Handler
```

**Why Pause/Resume**: Operations fail on login pages, 404s, permission errors. Users can fix issues without losing progress.

**Error Detection**:
```javascript
function detectPageIssue() {
    if (window.location.href.includes('/login')) return ['login_required'];
    if (document.querySelector('.error-404')) return ['page_not_found'];
    if (document.querySelector('[type="password"]')) return ['login_required'];
    return null;
}
```

### 7.3 Response Logging Architecture (Function Level)

**Purpose**: This diagram shows how response logging is implemented at the infrastructure level in the router. Use this when investigating logging issues, understanding why certain actions aren't logged, or implementing new logging features.

```mermaid
sequenceDiagram
    participant R as widget-router.js
    participant H as Handler  
    participant L as ActionLogger
    participant Relay as widget-relay.js
    participant WP as WordPress
    
    activate R
    Note over R: handleMessage(message, sender, sendResponse)
    R->>R: Store originalSendResponse = sendResponse
    
    R->>R: Create wrappedSendResponse = (response) => {<br/>// Log the response<br/>const responseStatus = response?.success ? 'success' : 'error'<br/>const action = message.action || message.type<br/>const error = response?.error || ''<br/><br/>ActionLogger.log(<br/>CATEGORIES.WORDPRESS_ACTION,<br/>`${status}: ${action}${error ? ' - ' + error : ''}`,<br/>{status: responseStatus, error, requestId})<br/><br/>// Send original<br/>originalSendResponse(response)<br/>}
    
    R->>H: handler.handle(message, sender, wrappedSendResponse, routerContext)
    deactivate R
    
    activate H
    Note over H: Process the request
    
    alt Handler Success
        H->>H: Complete operation successfully
        H->>R: wrappedSendResponse({success: true, data: {...}})
        activate R
        R->>L: ActionLogger.log('WORDPRESS_ACTION',<br/>'SUCCESS: SIP_UPDATE_MOCKUPS',<br/>{status: 'success', requestId: 'req_123'})
        R->>Relay: originalSendResponse({success: true, data: {...}})
        deactivate R
        activate Relay
        Relay->>WP: window.postMessage({<br/>type: 'SIP_EXTENSION_RESPONSE',<br/>success: true,<br/>requestId: 'req_123'})
        deactivate Relay
        
    else Handler Error  
        H->>H: Encounter error
        H->>R: wrappedSendResponse({success: false, error: 'Page not found'})
        activate R
        R->>L: ActionLogger.log('WORDPRESS_ACTION',<br/>'ERROR: SIP_UPDATE_MOCKUPS - Page not found',<br/>{status: 'error', error: 'Page not found'})
        R->>Relay: originalSendResponse({success: false, error: 'Page not found'})
        deactivate R
        
    else Handler Timeout
        Note over H: Handler crashes or never calls wrappedSendResponse
        Note over L: Only "Received: SIP_UPDATE_MOCKUPS" log exists
        Note over Relay: Chrome closes message port after ~5 minutes
        Note over WP: WordPress sees request timeout
    end
    deactivate H
```

**Why Infrastructure Level**: 
- DRY principle - implement once, not in every handler
- Guaranteed coverage - can't forget to log
- Evolution-friendly - change format in one place

### 7.4 Content Security Policy (CSP) Compliance

**Required Patterns**:
```javascript
// ❌ CSP Violation - Inline handler
element.innerHTML = '<button onclick="doThing()">Click</button>';

// ✓ CSP Compliant - Programmatic handler
const button = document.createElement('button');
button.textContent = 'Click';
button.addEventListener('click', doThing);
element.appendChild(button);

// ❌ CSP Violation - Inline styles
element.innerHTML = '<div style="color: red">Text</div>';

// ✓ CSP Compliant - CSS classes
element.innerHTML = '<div class="error-text">Text</div>';
```

**Why CSP Matters**: WordPress and many sites enforce CSP to prevent XSS. Extension must work everywhere.

### 7.5 Public API Naming Standards

**Critical Pattern**: All UI functions MUST be under `SiPWidget.UI` namespace

```javascript
// ❌ WRONG - Will cause ReferenceError
showWidget();  
toggleWidget();

// ✓ CORRECT - Explicit namespace
SiPWidget.UI.showWidget();
SiPWidget.UI.toggleWidget();

// Future commands follow same pattern:
SiPWidget.UI.refreshWidget();
SiPWidget.UI.resizeWidget();
```

**Why**: Prevents race conditions where function is called before module loads. Makes API discoverable and extensible.

### 7.5 URL Parameter Mockup Update Flow (Chrome.runtime Workaround)

**Purpose**: This diagram shows how mockup updates work on Printify pages where chrome.runtime is blocked. The extension uses URL parameters to pass data to the content script, which then automates the UI interaction.

```mermaid
sequenceDiagram
    participant WP as WordPress
    participant BG as Background (Router)
    participant MUH as mockup-update-handler.js
    participant Chrome as Chrome API
    participant PT as Printify Tab
    participant CS as mockup-library-actions.js
    
    activate WP
    WP->>BG: postMessage({<br/>type: 'SIP_UPDATE_PRODUCT_MOCKUPS',<br/>data: {mockupIds, productId, shopId}})
    deactivate WP
    
    activate BG
    BG->>MUH: handle(message, sender, sendResponse)
    deactivate BG
    
    activate MUH
    Note over MUH: Extract mockup data
    MUH->>MUH: const mockupIds = message.data.mockupIds<br/>// [{id: 'mockup_123_102752_1', is_default: true}]
    
    MUH->>MUH: extractSceneNames(mockupIds)
    Note over MUH: Map scene IDs to names<br/>102752 → 'Front'<br/>102753 → 'Right'<br/>102754 → 'Back'<br/>102755 → 'Left'
    
    MUH->>MUH: const sceneNames = ['Front', 'Back']<br/>const url = `https://printify.com/app/mockup-library/<br/>shops/${shopId}/products/${productId}<br/>?sip-action=update&scenes=${sceneNames.join(',')}`
    
    MUH->>Chrome: chrome.tabs.create({<br/>url: mockupUrl,<br/>active: true})
    Chrome-->>MUH: {id: tabId}
    
    MUH->>MUH: setTimeout(() => {<br/>sendResponse({success: true})<br/>}, 10000) // 10 second timeout
    deactivate MUH
    
    Chrome->>PT: Navigate to URL with parameters
    
    activate CS
    Note over CS: Content script loads
    CS->>CS: checkUrlParameters()
    CS->>CS: const urlParams = new URLSearchParams(window.location.search)<br/>const action = urlParams.get('sip-action') // 'update'<br/>const scenes = urlParams.get('scenes') // 'Front,Back'
    
    CS->>CS: action.data('URL parameters detected', {<br/>scenes: ['Front', 'Back'],<br/>url: window.location.href})
    
    CS->>CS: waitForPageReady()
    Note over CS: Wait for mockup elements
    
    CS->>CS: executeSceneSelection(['Front', 'Back'])
    
    loop For each scene
        CS->>CS: findSceneButton(sceneLabel)
        CS->>PT: button.click() // Select scene
        CS->>CS: await delay(700ms)
        CS->>CS: getSelectAllCheckbox()
        CS->>PT: checkbox.click() // Select all in scene
        CS->>CS: await delay(500ms)
    end
    
    CS->>CS: findSaveButton()
    CS->>PT: saveButton.click()
    CS->>CS: action.info('Automated mockup selection completed', {<br/>scenes: sceneLabels,<br/>status: 'success'})
    deactivate CS
```

**Scene ID Mapping** (hardcoded in mockup-update-handler.js):
```javascript
const sceneIdToName = {
    '102752': 'Front',
    '102753': 'Right', 
    '102754': 'Back',
    '102755': 'Left'
};
```

**Why URL Parameters**: Printify blocks chrome.runtime in content scripts, preventing traditional message passing. URL parameters provide a one-way data channel that doesn't require chrome.runtime.

### 7.6 Error Capture System Architecture

**Purpose**: This diagram shows how the extension captures and handles errors globally. The error-capture.js script sets up handlers for uncaught errors and unhandled promise rejections.

```mermaid
sequenceDiagram
    participant Page as Web Page
    participant EC as error-capture.js
    participant AL as ActionLogger
    participant WE as widget-error.js
    participant BG as Background (Router)
    
    alt Window Error Event
        Page->>EC: window.onerror(message, source, lineno, colno, error)
        activate EC
        EC->>EC: captureError('window.onerror', {<br/>message, source, lineno, colno,<br/>stack: error?.stack})
        
        EC->>AL: ActionLogger.log('ERROR',<br/>`Uncaught error: ${message}`,<br/>{source, line: lineno, column: colno, stack})
        
        alt Chrome.runtime available
            EC->>WE: formatError(error || {message})
            WE-->>EC: formattedError
            EC->>BG: chrome.runtime.sendMessage({<br/>type: 'widget',<br/>action: 'logError',<br/>error: formattedError})
        else Chrome.runtime blocked (Printify)
            EC->>EC: console.error('[SiP Error Capture]', details)
        end
        deactivate EC
    
    else Unhandled Promise Rejection
        Page->>EC: unhandledrejection event
        activate EC
        EC->>EC: event.preventDefault() // Prevent default console error
        EC->>EC: captureError('unhandledrejection', {<br/>reason: event.reason,<br/>promise: event.promise})
        
        EC->>AL: ActionLogger.log('ERROR',<br/>'Unhandled promise rejection',<br/>{reason, stack})
        deactivate EC
    
    else Caught Error in Code
        Page->>WE: formatError(error)
        activate WE
        WE->>WE: Check if already formatted
        WE->>WE: standardizeError(error)
        WE-->>Page: {<br/>message: string,<br/>stack: string,<br/>details: {...},<br/>timestamp: ISO string,<br/>context: 'content_script'<br/>}
        deactivate WE
    end
```

**Global Error Handlers**:
```javascript
// Captures all uncaught errors
window.onerror = function(message, source, lineno, colno, error) {
    captureError('window.onerror', {...});
    return true; // Prevent default browser error handling
};

// Captures unhandled promise rejections
window.addEventListener('unhandledrejection', function(event) {
    event.preventDefault();
    captureError('unhandledrejection', {...});
});
```

### 7.7 Action Logging Helper Architecture

**Purpose**: This diagram shows how the action-log-helper.js provides convenient shortcuts for logging throughout the extension. It wraps the ActionLogger with category-specific methods.

```mermaid
sequenceDiagram
    participant Code as Extension Code
    participant Helper as action-log-helper.js
    participant AL as ActionLogger
    participant Storage as Chrome Storage
    
    Note over Helper: Global shortcuts created on load
    Helper->>Helper: window.action = {<br/>log(), info(), error(),<br/>warn(), data(), api(), navigation()<br/>}
    
    alt Direct Log Call
        Code->>Helper: action.log('CUSTOM_CATEGORY', 'Message', {details})
        Helper->>AL: SiPWidget.ActionLogger.log('CUSTOM_CATEGORY', 'Message', {details})
    
    else Info Log
        Code->>Helper: action.info('User clicked button', {buttonId: 'save'})
        activate Helper
        Helper->>Helper: const category = SiPWidget?.ActionLogger?.CATEGORIES?.USER_ACTION || 'USER_ACTION'
        Helper->>AL: SiPWidget.ActionLogger.log('USER_ACTION', 'User clicked button', {buttonId: 'save'})
        deactivate Helper
    
    else Error Log
        Code->>Helper: action.error('Failed to save', {error: 'Network error'})
        Helper->>AL: SiPWidget.ActionLogger.log('ERROR', 'Failed to save', {error: 'Network error'})
    
    else Data Fetch Log
        Code->>Helper: action.data('Fetched mockups', {count: 10})
        Helper->>AL: SiPWidget.ActionLogger.log('DATA_FETCH', 'Fetched mockups', {count: 10})
    end
    
    activate AL
    AL->>AL: const log = {<br/>timestamp: new Date().toISOString(),<br/>category,<br/>message,<br/>details,<br/>url: window.location.href<br/>}
    
    AL->>AL: logs.push(log)<br/>if (logs.length > 1000) logs.shift()
    
    AL->>Storage: chrome.storage.local.set({<br/>sipActionLogs: logs<br/>})
    deactivate AL
```

**Helper Method Mapping**:
```javascript
window.action = {
    info: (msg, details) => log('USER_ACTION', msg, details),
    error: (msg, details) => log('ERROR', msg, details),
    warn: (msg, details) => log('WARNING', msg, details),
    data: (msg, details) => log('DATA_FETCH', msg, details),
    api: (msg, details) => log('API_CALL', msg, details),
    navigation: (msg, details) => log('NAVIGATION', msg, details)
};
```

**Why Helper**: Reduces verbosity, ensures consistent categorization, and provides fallback when ActionLogger isn't available.

## 8. Development Quick Reference

### File Structure with Key Functions
```
extension/
├── manifest.json              # Extension configuration
├── background.js              # importScripts() loader for service worker:
│                              # Loads: widget-error.js, action-logger.js,
│                              # mockup-fetch-handler.js, mockup-update-handler.js,
│                              # widget-data-handler.js, printify-data-handler.js,
│                              # wordpress-handler.js, widget-router.js
├── core-scripts/
│   ├── widget-router.js      # handleMessage(), navigateTab(), pauseOperation()
│   ├── widget-relay.js       # handlePostMessage(), window.addEventListener()
│   ├── widget-error.js       # formatError(), standardizeError()
│   ├── action-logger.js      # ActionLogger.log(), storeLog(), getActionLogs()
│   ├── action-log-helper.js  # action.info(), action.error(), action.warn()
│   └── error-capture.js      # window.onerror, unhandledrejection handlers
├── action-scripts/
│   ├── extension-detector.js # announceExtension(), checkPageContext()
│   ├── widget-tabs-actions.js # createWidget(), handleButtonClick(), updateUI()
│   ├── printify-tab-actions.js # observeDOM(), detectPageChanges()
│   └── mockup-library-actions.js # checkUrlParameters(), executeSceneSelection()
└── handler-scripts/
    ├── widget-data-handler.js # handle() with navigate/showWidget/updateState
    ├── printify-data-handler.js # handle() with fetchMockups/updateStatus
    ├── wordpress-handler.js   # handle() routes SIP_* to internal format
    ├── mockup-fetch-handler.js # handle() navigates and captures mockup data
    └── mockup-update-handler.js # handle() opens URL with scene parameters
```

### Common Issues

**Widget not visible**: 
- Widget must start with `sip-visible` class
- Position must be in viewport: `x: window.innerWidth - 340, y: 20`
- Check `#sip-floating-widget` exists in DOM

**Messages not routing**: 
- External format requires: `type: 'SIP_*'` and `source: 'sip-printify-manager'`
- Internal format requires: `type: 'widget|printify|wordpress'` and `action: 'specificAction'`
- On Printify: chrome.runtime blocked, messages won't work at all

**Printify functionality limited**:
- chrome.runtime.sendMessage() blocked - use URL parameters instead
- Widget has reduced functionality on Printify pages
- Mockup updates work via URL params: `?sip-action=update&scenes=Front,Back`

**Manifest corruption**: 
- Run `file manifest.json` - should show "ASCII text" not "UTF-8 Unicode (with BOM)"
- Validate with `node validate-manifest.js`

### Testing Checklist with Function Verification
- [ ] Run `node validate-manifest.js` to check manifest integrity
- [ ] Check chrome://extensions for ANY errors or warnings  
- [ ] Click "service worker" link and verify all importScripts() loaded
- [ ] Verify no BOM characters: `file manifest.json` shows "ASCII text"
- [ ] Check handleMessage() receives all messages in service worker console
- [ ] Verify handlePostMessage() security checks in content script console
- [ ] Look for paired "Received"/"SUCCESS" logs from wrapSendResponse()
- [ ] Test pauseOperation()/resumeOperation() with login pages
- [ ] Verify createWidget() positions widget in viewport
- [ ] Test createTabPair() creates bidirectional entries in storage
- [ ] Confirm announceExtension() runs on page load