# SiP Printify Manager Browser Extension - Streamlined Documentation

**Repository**: https://github.com/tdemelle-SiP/sip-printify-manager-extension

## 1. Overview

The SiP Printify Manager browser extension bridges the gap between WordPress and Printify.com, enabling automated workflows and data access not available through Printify's public API.

**Core Problem**: WordPress plugins cannot directly access Printify's internal APIs or page data.

**Solution**: A Chrome extension that acts as a privileged intermediary, capturing data and executing operations on behalf of the WordPress plugin.

**Critical Limitation**: Printify blocks `chrome.runtime` access in content scripts, preventing traditional extension messaging. The extension uses URL parameters for mockup updates and has limited functionality on Printify pages.

## 2. Architecture

### Diagram Notation Guide

**Box Types**:
- `[User action]` - User events (clicks, navigations)
- `[JS does something<br/>-functionName-<br/>file.js]` - Code execution with function name and file
- `[(Storage Type<br/>-key-)]` - Storage with actual key names (cylinder shape for persistence)

**Connection Labels**:
- `-->|methodName|` - Function calls or API methods
- `-->|chrome.storage.set|` - Chrome API calls
- `-->|window.postMessage|` - Browser APIs
- `-.->|onChange|` - Event-driven connections

### 2.1 Master System Architecture

This diagram shows the complete extension architecture with key functions:

```mermaid
graph TB
    subgraph "WordPress Context"
        subgraph "User Events"
            UserAction[User clicks action button]
        end
        
        subgraph "Code Flow"
            WP[PHP renders page<br/>-sip_printify_manager_page-<br/>sip-printify-manager.php]
            BEM[JS sends message<br/>-sendMessageToExtension-<br/>browser-extension.js]
        end
    end
    
    subgraph "Extension - Content Scripts"
        subgraph "WordPress Pages"
            RelayListen[JS listens postMessage<br/>-window.addEventListener-<br/>widget-relay.js]
            RelayHandle[JS validates & forwards<br/>-handlePostMessage-<br/>widget-relay.js]
            RelaySend[JS sends to router<br/>-chrome.runtime.sendMessage-<br/>widget-relay.js]
            Detector[JS announces presence<br/>-announceExtension-<br/>extension-detector.js]
            Widget1[JS creates widget UI<br/>-createWidget-<br/>widget-tabs-actions.js]
            WidgetUpdate1[JS updates terminal<br/>-updateOperationStatus-<br/>widget-tabs-actions.js]
        end
        
        subgraph "Printify Pages"
            Widget2[JS creates widget UI<br/>-createWidget-<br/>widget-tabs-actions.js]
            WidgetUpdate2[JS updates terminal<br/>-updateOperationStatus-<br/>widget-tabs-actions.js]
            Monitor[JS monitors page<br/>-observeDOM-<br/>printify-tab-actions.js]
            Mockup[JS reads URL params<br/>-checkUrlParameters-<br/>mockup-library-actions.js]
            AutoSelect[JS automates selection<br/>-executeSceneSelection-<br/>mockup-library-actions.js]
        end
        
        subgraph "Shared Scripts"
            Error[JS formats errors<br/>-formatError-<br/>widget-error.js]
            ErrorCap[JS captures errors<br/>-window.onerror-<br/>error-capture.js]
            Logger[JS logs actions<br/>-ActionLogger.log-<br/>action-logger.js]
            OpStart[JS detect op start<br/>-isOperationStart-<br/>action-logger.js]
            OpEnd[JS detect op end<br/>-isOperationEnd-<br/>action-logger.js]
            UpdateDisplay[JS updates widget<br/>-updateWidgetDisplay-<br/>action-logger.js]
            LogHelper[JS log shortcuts<br/>-action.info/error/warn-<br/>action-log-helper.js]
            DiagBtn[JS handle diagnostic<br/>-handleDiagnostic-<br/>widget-tabs-actions.js]
            RunDiag[JS run diagnostic<br/>-runPrintifyDiagnostic-<br/>widget-tabs-actions.js]
            MonBtn[JS handle monitor<br/>-handleMonitor-<br/>widget-tabs-actions.js]
            StartMon[JS start monitor<br/>-startInteractionMonitor-<br/>widget-tabs-actions.js]
            StopMon[JS stop monitor<br/>-stopInteractionMonitor-<br/>widget-tabs-actions.js]
        end
    end
    
    subgraph "Extension - Background Service Worker"
        BG[JS loads modules<br/>-importScripts-<br/>background.js]
        
        subgraph "Router Functions"
            RouterMsg[JS receives messages<br/>-handleMessage-<br/>widget-router.js]
            RouterVal[JS validates message<br/>-validateMessage-<br/>widget-router.js]
            RouterWrap[JS wraps response<br/>-wrapSendResponse-<br/>widget-router.js]
            RouterRoute[JS routes by type<br/>-routeToHandler-<br/>widget-router.js]
            RouterPause[JS pauses operation<br/>-pauseOperation-<br/>widget-router.js]
            RouterResume[JS resumes operation<br/>-resumeOperation-<br/>widget-router.js]
        end
        
        subgraph "Handler Functions"
            WHHandle[JS widget handler<br/>-handle-<br/>widget-data-handler.js]
            PHHandle[JS printify handler<br/>-handle-<br/>printify-data-handler.js]
            WPHRoute[JS routes wordpress<br/>-handle-<br/>wordpress-handler.js]
            MFHandle[JS mockup fetch<br/>-handle-<br/>mockup-fetch-handler.js]
            MUHandle[JS mockup update<br/>-handle-<br/>mockup-update-handler.js]
            ReportStatus[JS reports progress<br/>-reportStatus-<br/>handlers]
        end
        
        subgraph "Chrome API Functions"
            NavTab[JS navigates tabs<br/>-navigateTab-<br/>widget-router.js]
            CreateTab[JS creates tab<br/>-chrome.tabs.create-<br/>widget-router.js]
            QueryTab[JS queries tabs<br/>-chrome.tabs.query-<br/>widget-router.js]
            SetStore[JS saves state<br/>-chrome.storage.set-<br/>widget-router.js]
            GetStore[JS loads state<br/>-chrome.storage.get-<br/>widget-router.js]
            InjectScript[JS injects scripts<br/>-chrome.scripting.executeScript-<br/>widget-router.js]
        end
        
        subgraph "Helper Functions"
            TestConn[JS test connection<br/>-testWordPressConnection-<br/>widget-router.js]
            CheckPlugin[JS check plugin<br/>-checkWordPressPluginStatus-<br/>widget-router.js]
            ExtractScene[JS extract scenes<br/>-extractSceneNames-<br/>mockup-update-handler.js]
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
    
    %% Progress reporting
    MFHandle -->|calls| ReportStatus
    MUHandle -->|calls| ReportStatus
    ReportStatus -->|chrome.storage.local.set| StateStore
    
    %% Diagnostic and monitoring flows
    Widget1 -->|button click| DiagBtn
    Widget2 -->|button click| DiagBtn
    DiagBtn -->|calls| RunDiag
    RunDiag -->|logs to| Logger
    Widget1 -->|button click| MonBtn
    Widget2 -->|button click| MonBtn
    MonBtn -->|calls| StartMon
    MonBtn -->|calls| StopMon
    StartMon -->|logs to| Logger
    StopMon -->|logs to| Logger
    
    %% Operation detection flow
    Logger -->|checks| OpStart
    Logger -->|checks| OpEnd
    OpStart -->|returns boolean| Logger
    OpEnd -->|returns boolean| Logger
    
    %% Widget display updates
    Logger -->|calls| UpdateDisplay
    UpdateDisplay -->|updates| Widget1
    UpdateDisplay -->|updates| Widget2
    
    %% Operation status updates via router
    StateStore -.->|onChange sipOperationStatus| Router
    Router -->|sendMessage updateOperationStatus| WidgetUpdate1
    Router -->|sendMessage updateOperationStatus| WidgetUpdate2
    
    %% Configuration
    GetStore -->|chrome.storage.sync.get| ConfigStore
    
    style RouterMsg fill:#f9f,stroke:#333,stroke-width:4px
    style RelayHandle fill:#bbf,stroke:#333,stroke-width:2px
    style UpdateDisplay fill:#9f9,stroke:#333,stroke-width:2px
```

**Reading the Master Diagram**:
- **Box Format**: `[Language action<br/>-functionName-<br/>file.js]` shows what the code does, which function, and which file
- **Solid arrows (→)**: Active message/data flow with labels showing method calls
- **Dashed arrows (--->)**: Configuration or dependency relationships
- **Dotted arrows (-.->)**: Event-driven updates (storage onChange) or usage dependencies
- **Storage Format**: `[(Storage Type<br/>-key name-)]` shows actual storage keys
- **Subgraphs**: Execution contexts with different Chrome API capabilities

**Key Architecture Points**:
- **Router is the hub**: ALL runtime messages flow through handleMessage() in widget-router.js
- **Content scripts are limited**: Can only use chrome.runtime.sendMessage and chrome.storage
- **Background has full access**: Service worker context with all Chrome APIs
- **Function visibility**: Every function that touches data is shown with its file location
- **One-way message flow**: WordPress → Relay → Router → Handler → Response
- **Printify limitation**: chrome.runtime blocked, mockup updates use URL parameters instead [NEEDS FIX]
- **Two display update paths**: Storage-driven for stateful operations, direct updates for instant feedback
- **Operation hierarchy**: ActionLogger detects operation start/end patterns to provide visual structure

### Understanding the Diagram Hierarchy

The Master System Architecture diagram above provides a complete view of the extension system, showing all major components and their relationships. However, to truly understand the implementation and validate that code matches architecture, we need function-level detail for specific flows.

The following detail diagrams expand specific aspects of the master architecture to show:
- **Every function that touches data** in that particular flow
- **The exact function names** from the code
- **The specific operations** each function performs
- **Error handling paths** that might not be visible at the high level

Each detail diagram serves developers who need to:
- Trace a specific flow (e.g., "Why isn't my WordPress command working?")
- Implement changes to that flow (e.g., "Where do I add validation for tab operations?")
- Understand the complete chain of operations (e.g., "What happens between click and response?")

### 2.2 Complete Message Flow (Function Level)

This sequence diagram shows the exact function calls for a typical operation:

```mermaid
sequenceDiagram
    participant WP as WordPress
    participant Relay as widget-relay.js
    participant Router as widget-router.js  
    participant Handler as mockup-update-handler.js
    participant Chrome as Chrome APIs
    participant Logger as ActionLogger
    participant Widget as widget-tabs-actions.js
    
    WP->>Relay: postMessage({type: 'SIP_UPDATE_MOCKUPS'})
    activate Relay
    Note over Relay: handlePostMessage(event)
    Relay->>Relay: validateOrigin(event.origin)
    Relay->>Relay: checkSource(data.source)
    
    Relay->>Router: chrome.runtime.sendMessage(originalMessage)
    deactivate Relay
    
    activate Router
    Note over Router: handleMessage(message, sender, sendResponse)
    Router->>Router: validateMessage(message)
    Router->>Router: detectWordPressMessage(SIP_ prefix)
    Router->>Logger: ActionLogger.log('WORDPRESS_ACTION', 'Received: SIP_UPDATE_MOCKUPS')
    
    Router->>Router: convertToInternal({type: 'wordpress', action: 'SIP_UPDATE_MOCKUPS'})
    Router->>Router: importHandlers()
    Router->>Router: wrapSendResponse(sendResponse)
    Router->>Router: getHandler('wordpress')
    
    Router->>Handler: handle(message, sender, wrappedResponse, routerContext)
    deactivate Router
    
    activate Handler
    Handler->>Handler: validateMockupData(message.data)
    Handler->>Handler: reportStatus('Updating Mockups', 'Opening library', 25)
    Handler->>Chrome: chrome.storage.local.set({sipOperationStatus: {...}})
    
    Note over Widget: Storage onChange listener
    Chrome->>Widget: sipOperationStatus changed
    Widget->>Widget: updateOperationStatus(status)
    Note over Widget: Shows PROCESSING state with progress
    
    Handler->>Chrome: routerContext.navigateTab(url, 'printify', tabId)
    activate Chrome
    Chrome->>Chrome: getPairedTab(tabId)
    Chrome->>Chrome: chrome.tabs.create({url: url})
    Chrome-->>Handler: {success: true, tabId: 123, action: 'created-pair'}
    deactivate Chrome
    
    alt Success Path
        Handler->>Handler: waitForPageReady(tabId)
        Handler->>Handler: reportStatus('Update Complete', 'Success', 100, details)
        Handler->>Chrome: chrome.storage.local.set({sipOperationStatus: {...}})
        Chrome->>Widget: sipOperationStatus changed
        Widget->>Widget: updateOperationStatus shows completion
        
        Handler->>Chrome: setTimeout(() => set state: 'idle', 2000)
        Note over Widget: After 2s, returns to READY state
        
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

### 2.3 Widget Terminal Display Architecture

The widget includes a retro terminal-style display (black background, colored text) that shows real-time action messages and operation progress. See visual mockups at `C:\Users\tdeme\Documents\VSCode_Images_Repo\WidgetWindowDesign01-03.png`.

```mermaid
graph TD
    subgraph "Display Update Flows"
        subgraph "Operation Progress Flow"
            Handler[Handler calls<br/>-reportStatus-] -->|chrome.storage.set| OpStatus[(sipOperationStatus)]
            OpStatus -.->|onChange| Widget1[widget-tabs-actions.js<br/>-updateOperationStatus-]
            Widget1 --> Terminal1[Terminal Display<br/>PROCESSING state]
        end
        
        subgraph "One-off Message Flow"
            Action[Action occurs] --> Logger[ActionLogger.log()]
            Logger --> UpdateDisp[updateWidgetDisplay()]
            UpdateDisp --> Terminal2[Terminal Display<br/>Transient message]
        end
    end
    
    subgraph "Terminal Display States"
        Ready[READY State<br/>- Bottom: READY<br/>- Center: ... dots<br/>- Top: Empty/dimmed]
        
        Processing[PROCESSING State<br/>- Bottom: PROCESSING...<br/>- Center: Progress bar + task<br/>- Top: Operation name]
        
        Transient[Transient Message<br/>- Bottom: READY (unchanged)<br/>- Center: Action message<br/>- Top: Status type]
    end
    
    subgraph "Color Coding"
        StatusColors[Status Header Colors<br/>INFO: #cccccc (grey)<br/>SUCCESS: #00ff00 (green)<br/>ERROR: #ff3333 (red)<br/>WARNING: #ffaa00 (orange)]
        
        MessageColors[Action Message Colors<br/>WordPress on WP: #00ccff (bright blue)<br/>WordPress on Printify: #0088cc (dim blue)<br/>Printify on Printify: #00ff00 (bright green)<br/>Printify on WP: #00cc00 (dim green)]
    end
    
    Terminal1 --> Processing
    Terminal2 --> Transient
    OpStatus -->|state: 'idle'| Ready
```

**Terminal Display Components**:
1. **Status Header** (top): Shows message status (INFO, SUCCESS, ERROR, WARNING) with appropriate colors
2. **Message Area** (center): Shows either dots (...), action messages, or progress bar with task
3. **Status Line** (bottom): Shows READY or PROCESSING...

**Message Dimming**: Messages and headers dim to 50% opacity after 5 seconds but remain visible until replaced.

### 2.4 Storage Architecture Detail (Function Level)

```mermaid
graph LR
    subgraph "Storage Functions"
        subgraph "Configuration"
            InitConfig[JS loads config<br/>-initializeConfig-<br/>widget-router.js]
            LoadConfig[JS reads storage<br/>-loadConfiguration-<br/>widget-router.js]
            UpdateConfig[JS saves config<br/>-updateConfig-<br/>widget-router.js]
        end
        
        subgraph "Tab Pairing"
            LoadPairs[JS loads pairs<br/>-loadTabPairs-<br/>widget-router.js]
            SavePairs[JS saves pairs<br/>-saveTabPairs-<br/>widget-router.js]
            CreatePair[JS creates pair<br/>-createTabPair-<br/>widget-router.js]
            RemovePair[JS removes pair<br/>-removeTabPair-<br/>widget-router.js]
            GetPaired[JS gets pair<br/>-getPairedTab-<br/>widget-router.js]
        end
        
        subgraph "Action Logging"  
            StoreLog[JS stores log<br/>-storeLog-<br/>action-logger.js]
            GetLogs[JS retrieves logs<br/>-getActionLogs-<br/>action-logger.js]
            ClearLogs[JS clears logs<br/>-clearActionLogs-<br/>action-logger.js]
            TrackOp[JS tracks operations<br/>-operationStack-<br/>action-logger.js]
        end
        
        subgraph "Widget State"
            SaveWidget[JS saves state<br/>-saveWidgetState-<br/>widget-router.js]
            LoadWidget[JS loads state<br/>-loadWidgetState-<br/>widget-router.js]
        end
        
        subgraph "Operation Status"
            ReportOp[JS reports status<br/>-reportStatus-<br/>handlers]
            UpdateOp[JS listens for changes<br/>-updateOperationStatus-<br/>widget-tabs-actions.js]
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
    Logger -->|updates| TrackOp
    TrackOp -->|maintains| TimingsCache
    
    %% Widget state flow
    SaveWidget -->|chrome.storage.local.set| WidgetState
    LoadWidget -->|chrome.storage.local.get| WidgetState
    WidgetState -.->|onChange event| LoadWidget
    
    %% Operation status flow
    ReportOp -->|chrome.storage.local.set| OpStatus
    OpStatus -.->|onChange event| UpdateOp
```

### 2.5 Tab Pairing System Detail (Function Level)

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

## 3. Architectural Rationale

### 3.1 Why This Architecture?

**Chrome Extension Constraints**:
1. **Security boundaries**: Web pages cannot access Chrome APIs
2. **Message passing rules**: Content scripts cannot intercept messages between other content scripts
3. **Context isolation**: Background scripts have no DOM access

**Core Design Principles**:

1. **Push-Driven Architecture**: Extension announces presence; WordPress never polls
   - Reduces message traffic, ensures accurate state
   - Fresh detection on every page load

2. **"Dumb Pipe" Principle**: Extension captures raw data; WordPress processes it
   - Keeps extension simple, business logic centralized
   - Handlers return raw API responses

3. **Central Router Pattern**: All messages flow through one hub
   - Chrome funnels all runtime messages to background script
   - Content scripts cannot intercept each other's messages

4. **Infrastructure-Level Logging**: Response logging at router, not handlers
   - Cross-cutting concern, guaranteed coverage
   - Router wraps sendResponse for logging before passing to handlers

5. **Fresh Detection Model**: Extension state never persisted between page loads
   - Eliminates false positives, ensures accurate detection
   - Extension must announce on every page load

6. **Dual Display Update Paths**: Two systems update the terminal display
   - Operation progress via hub messaging (handlers → storage → router → widget)
   - One-off messages via direct function calls (logger → updateWidgetDisplay)

### 3.2 Why Dual Display Update Paths?

The widget terminal display receives updates through two distinct paths because:

1. **Stateful Operations Need Hub Coordination**: Multi-step operations like mockup updates require centralized message routing
   - Handlers run in service worker context without DOM access
   - Router ensures messages only go to paired tabs that exist
   - Progress updates are coordinated through the hub architecture

2. **Instant Feedback Needs Direct Updates**: User interactions and transient events need immediate visual feedback
   - Navigation clicks should show instant response
   - Error messages need immediate display
   - API responses arrive outside operation context

3. **Operation Hierarchy Requires Context**: Visual structure helps users understand complex workflows
   - Operation start/end detection provides indentation
   - Parent operations group related child actions
   - Visual markers (🔻/🔺) clarify operation boundaries

### 3.3 Component Purposes

| Component | Purpose | Constraint/Requirement |
|-----------|---------|------------------------|
| **widget-relay.js** | Bridge between postMessage and chrome.runtime | WordPress can only use postMessage |
| **widget-router.js** | Central message hub and Chrome API executor | Chrome sends all messages to background |
| **background.js** | Module loader for service worker | Manifest V3 requires importScripts |
| **Handlers** | Separate business logic from infrastructure | Easier testing, single responsibility |
| **Action Scripts** | Detect page events and user interactions | Content scripts have limited API access |
| **widget-error.js** | Standardize error responses | Consistent error format for WordPress |
| **action-logger.js** | Structured action history + widget display updates | Log extension actions and update terminal for one-off messages |
| **widget-tabs-actions.js** | Widget UI and terminal display management | Shows operation progress and transient messages |
| **Tab Pairing** | Reuse existing tabs | Users expect "Go to Printify" to reuse tabs |
| **Response Logging** | Visible operation outcomes | Timeout/failures need to be traceable |

## 4. Implementation Guide

### 4.1 Architectural Constraints

**Router MUST be the background script**:
- Chrome doesn't allow content scripts to intercept runtime messages between other content scripts
- ALL chrome.runtime.sendMessage() calls go directly to the background script
- This is why we achieve "ALL messages flow through router"

**Extension announces presence on each page load**:
- Fresh detection eliminates false positives from uninstalled extensions
- WordPress receives accurate extension state for each session
- Enables reliable "Install Extension" button visibility

**WordPress manages mockup detection**:
- Checks filesystem for mockups when rendering blueprint rows
- Initiates fetch after confirming extension readiness
- Maintains filesystem as single source of truth

**Service Worker Context**:
- No DOM access in background scripts
- Must use `SiPWidget.ActionLogger` not `window.action` in handlers
- Check for window existence: `const isServiceWorker = typeof window === 'undefined'`

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

**Operation Status (Storage)**:
```javascript
{
    operation: 'Updating Mockups',     // Operation name shown in header
    task: 'Opening mockup library',    // Current task shown in message area
    progress: 25,                      // Progress percentage (0-100)
    details: 'Multi-line\ndetails',    // Detailed info for completion
    cancellable: false,                // Future: show cancel button
    state: 'active' | 'idle' | 'paused' | 'resuming',
    message: 'Operation in progress',  // Alternative message field
    timestamp: Date.now()
}
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

**Service Worker Usage**: In handlers and background scripts, use `SiPWidget.ActionLogger.log()` directly as `window.action` is not available.

### 4.4 Terminal Display Implementation

**Display States**:
1. **READY**: Default state showing dots, one-off messages appear here
2. **PROCESSING**: Active operation with progress bar
3. **Transient Messages**: Brief messages that don't change state

**Color Coding Implementation**:
```javascript
// Status header colors (in updateOperationStatus)
let statusColor = '#cccccc'; // Default light grey for info
if (status === 'success') {
    statusColor = '#00ff00'; // Green for success
} else if (status === 'error' || status === 'failure') {
    statusColor = '#ff3333'; // Red for error
} else if (status === 'warning') {
    statusColor = '#ffaa00'; // Orange for warning
}

// Action message colors (in updateWidgetDisplay)
const isOnWordPress = window.location.href.includes('/wp-admin/');
const isOnPrintify = window.location.href.includes('printify.com');

let actionColor = '#00ff00'; // Default green
if (siteType === 'WordPress Site') {
    actionColor = isOnWordPress ? '#00ccff' : '#0088cc';
} else if (siteType === 'Printify Site') {
    actionColor = isOnPrintify ? '#00ff00' : '#00cc00';
}
```

**Message Dimming**:
```javascript
// Set timer to dim message after 5 seconds
messageDimTimer = setTimeout(() => {
    if (messageDiv && messageDiv.parentNode) {
        messageDiv.style.opacity = '0.5';
    }
}, 5000);
```

### 4.5 Mockup Scene Mapping

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

**Hard-coded Mapping**: Printify's internal scene IDs are stable but not exposed in their UI. The mapping was determined by inspecting the mockup library page.

### 4.6 Chrome Architecture Constraints

**Service Worker (Background) Constraints**:
```javascript
// NO DOM access - this will fail in background.js:
// window.location  ❌
// document.querySelector  ❌

// Must check for window existence:
const isServiceWorker = typeof window === 'undefined';
const globalScope = isServiceWorker ? self : window;
```

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
chrome.runtime.sendMessage()  ❌  // Blocked by Printify [NEEDS FIX]
chrome.runtime.onMessage  ❌  // Blocked by Printify [NEEDS FIX]
chrome.runtime.getURL()  ❌  // Blocked by Printify [NEEDS FIX]
chrome.runtime.getManifest()  ❌  // Blocked by Printify [NEEDS FIX]
```

**Message Channel Constraints**:
```javascript
// Content scripts CANNOT intercept other content script messages
// This will NEVER receive messages from other content scripts:
chrome.runtime.onMessage.addListener((message, sender) => {
    // Only receives from background script
});
```

### 4.7 Critical Patterns

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

**Progress Reporting Pattern**:
```javascript
// In handlers (service worker context)
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

// After completion, return to idle
setTimeout(() => {
    chrome.storage.local.set({ 
        sipOperationStatus: { state: 'idle', timestamp: Date.now() } 
    });
}, 2000);
```

### 4.8 Adding New Features

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
    sipOperationStatus: {      // Set by handlers and pause/resume operations
        // For active operations:
        operation: string,     // Operation name
        task: string,          // Current task
        progress: number,      // 0-100
        details: string,       // Completion details
        cancellable: boolean,  // Show cancel button
        state: 'active' | 'idle',
        message: string,       // Alternative message
        timestamp: number,
        
        // For paused operations:
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
    },
    messageDimTimer: number,  // Timer ID for dimming messages
    // ActionLogger state (in action-logger.js)
    operationStack: [],       // Tracks nested operations for hierarchy
    activeOperations: Map,    // Maps operation IDs to operation data
    sipActionTimings: Map     // Performance timing data
}
```

### 5.1 Extension Detection & Installation Flow (Function Level)

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
    Note over BEM: WordPress handles mockup checking<br/>when blueprint rows draw
```

**Programmatic Injection**: Content scripts don't auto-inject into already-open tabs after installation. Users expect immediate functionality without reload.

**100ms Delay**: Ensures all scripts are fully loaded before announcing presence.

**No State Persistence**: Fresh detection eliminates false positives from uninstalled extensions.

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

```mermaid
flowchart LR
    subgraph "WordPress Context"
        WP[JS builds message<br/>-sendMessageToExtension-<br/>browser-extension-manager.js]
        WPMsg["{
            type: 'SIP_UPDATE_PRODUCT_MOCKUPS',
            source: 'sip-printify-manager',
            requestId: 'req_123',
            data: { productId: 456 }
        }"]
    end
    
    subgraph "Relay Functions"
        R1[JS receives event<br/>-handlePostMessage-<br/>widget-relay.js]
        R2[JS validates origin<br/>-event.origin check-<br/>widget-relay.js]
        R3[JS validates source<br/>-data.source check-<br/>widget-relay.js]
        R4[JS forwards message<br/>-chrome.runtime.sendMessage-<br/>widget-relay.js]
    end
    
    subgraph "Router Functions"
        RO1[JS receives message<br/>-handleMessage-<br/>widget-router.js]
        RO2[JS detects WordPress<br/>-checks SIP_ prefix-<br/>widget-router.js]
        RO3[JS converts format<br/>-type: 'wordpress'-<br/>widget-router.js]
        RO4[JS logs received<br/>-ActionLogger.log-<br/>action-logger.js]
        RO5[JS gets handler<br/>-getHandlerByType-<br/>widget-router.js]
        RO6[JS calls handler<br/>-handler.handle-<br/>widget-router.js]
    end
    
    subgraph "Handler Processing"
        H1[JS routes command<br/>-wordpress-handler.handle-<br/>wordpress-handler.js]
        H2[JS converts to internal<br/>-mapWordPressAction-<br/>wordpress-handler.js]
        H3[JS delegates to handler<br/>-PrintifyDataHandler.handle-<br/>printify-data-handler.js]
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
    R3 -->|forwards| R4
    R4 -->|chrome.runtime| RO1
    RO1 -->|checks| RO2
    RO2 -->|converts| RO3
    RO3 -->|logs| RO4
    RO4 -->|routes| RO5
    RO5 -->|calls| RO6
    RO6 -->|invokes| H1
    H1 -->|maps| H2
    H2 -->|creates| HandlerMsg
    H2 -->|delegates| H3
```

**Transform Reason**: Router converts WordPress messages (SIP_* prefix) to internal format for handler routing. No relay wrapping needed - messages are forwarded directly.

## 7. Key Features

### 7.1 Tab Pairing System
- Maintains bidirectional pairing between WordPress and Printify tabs
- Reuses existing tabs instead of creating new ones
- Automatically cleans up when tabs close

### 7.2 Widget Terminal Display

The widget features a retro terminal-style display that shows real-time action messages and operation progress.

**Three Display Modes**:
1. **READY State**
   - Shows "READY" at bottom
   - Shows "..." dots in center (or transient messages)
   - Header empty or shows previous status (dimmed)

2. **PROCESSING State**
   - Shows "PROCESSING..." at bottom
   - Shows progress bar with percentage
   - Shows current task message in action color
   - Shows operation name in header

3. **Transient Messages**
   - One-off messages that appear without changing state
   - Replace dots temporarily in READY state
   - Do NOT trigger progress bar or hide READY status

**Message Flow**:
- **Operation Progress**: Handlers → reportStatus() → storage → updateOperationStatus() → terminal
- **One-off Messages**: Actions → ActionLogger.log() → updateWidgetDisplay() → terminal

**Visual Design**:
- Black background (#000000)
- Green text (#00ff00) as default
- Monospace font (Consolas, Monaco, Courier New)
- Messages dim to 50% opacity after 5 seconds
- Progress bar fills from 0% to 100%

### 7.3 Pause/Resume Error Recovery (Function Level)

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

**Pause/Resume Reason**: Operations fail on login pages, 404s, permission errors. Users can fix issues without losing progress.

**Error Detection**:
```javascript
function detectPageIssue() {
    if (window.location.href.includes('/login')) return ['login_required'];
    if (document.querySelector('.error-404')) return ['page_not_found'];
    if (document.querySelector('[type="password"]')) return ['login_required'];
    return null;
}
```

### 7.4 Response Logging Architecture (Function Level)

```mermaid
sequenceDiagram
    participant R as widget-router.js
    participant H as Handler  
    participant L as ActionLogger
    participant W as widget-tabs-actions.js
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
        
        Note over L: In content script context
        L->>L: updateWidgetDisplay() called
        L->>W: Updates terminal with success message
        
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

**Infrastructure Level Reason**: 
- DRY principle - implement once, not in every handler
- Guaranteed coverage - can't forget to log
- Evolution-friendly - change format in one place

### 7.5 Content Security Policy (CSP) Compliance

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

**CSP Importance**: WordPress and many sites enforce CSP to prevent XSS. Extension must work everywhere.

### 7.6 Public API Naming Standards

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

**Namespace Reason**: Prevents race conditions where function is called before module loads. Makes API discoverable and extensible.

### 7.7 URL Parameter Mockup Update Flow (Chrome.runtime Workaround) [NEEDS FIX]

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

**URL Parameter Reason**: Printify blocks chrome.runtime in content scripts, preventing traditional message passing. URL parameters provide a one-way data channel that doesn't require chrome.runtime. [NEEDS FIX]

### 7.8 Error Capture System Architecture

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
        else Chrome.runtime blocked (Printify) [NEEDS FIX]
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

### 7.9 Action Logging Helper Architecture

```mermaid
sequenceDiagram
    participant Code as Extension Code
    participant Helper as action-log-helper.js
    participant AL as ActionLogger
    participant WD as updateWidgetDisplay()
    participant Widget as Terminal Display
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
    
    Note over AL: In content script context only
    AL->>WD: updateWidgetDisplay(category, action, details, siteType)
    activate WD
    WD->>WD: Apply color coding based on site/context
    WD->>Widget: Update terminal display with message
    deactivate WD
    
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

**Helper Benefit**: Reduces verbosity, ensures consistent categorization, and provides fallback when ActionLogger isn't available.

### 7.10 Diagnostic and Monitoring Tools

These features were added to help users understand and debug Printify page interactions. The diagnostic tool analyzes DOM structure and the monitor tracks user interactions with API calls.

**Tool Purpose**: Users were repeatedly encountering issues with DOM structure changes on Printify pages. Rather than manually running console scripts each time, these tools are now integrated into the widget interface for easy access.

```mermaid
graph LR
    subgraph "Widget Interface"
        DiagButton[Diagnostic Button<br/>id='sip-diagnostic-btn']
        MonButton[Monitor Button<br/>id='sip-monitor-btn']
    end
    
    subgraph "Diagnostic Flow"
        HandleDiag[JS handle click<br/>-handleDiagnostic-<br/>widget-tabs-actions.js]
        RunDiag[JS analyze page<br/>-runPrintifyDiagnostic-<br/>widget-tabs-actions.js]
        DiagResult[Diagnostic Result<br/>{pageType, data, interactive}]
    end
    
    subgraph "Monitor Flow"
        HandleMon[JS handle toggle<br/>-handleMonitor-<br/>widget-tabs-actions.js]
        StartMon[JS start tracking<br/>-startInteractionMonitor-<br/>widget-tabs-actions.js]
        StopMon[JS stop tracking<br/>-stopInteractionMonitor-<br/>widget-tabs-actions.js]
        MonitorData[Monitor Data<br/>{clicks, apiCalls, stateChanges}]
    end
    
    subgraph "Output"
        Logger[ActionLogger<br/>-log-<br/>action-logger.js]
        Toast[Toast Messages<br/>-showToast-<br/>widget-tabs-actions.js]
        Terminal[Terminal Display<br/>Shows diagnostic status]
    end
    
    DiagButton -->|click| HandleDiag
    HandleDiag -->|calls| RunDiag
    RunDiag -->|returns| DiagResult
    DiagResult -->|logged to| Logger
    HandleDiag -->|updates| Terminal
    HandleDiag -->|shows| Toast
    
    MonButton -->|click| HandleMon
    HandleMon -->|starts/stops| StartMon
    HandleMon -->|starts/stops| StopMon
    StartMon -->|captures| MonitorData
    MonitorData -->|logged to| Logger
    HandleMon -->|shows| Toast
```

**Diagnostic Tool Features**:
- Detects page type (mockup-library, product-editor, etc.)
- Counts interactive elements (buttons, forms, images)
- Identifies data-testid attributes
- Page-specific analysis (e.g., mockup grids on library pages)

**Monitor Tool Features**:
- Tracks all click events with element details
- Intercepts fetch() calls to capture API requests/responses
- Monitors checkbox state changes
- Logs mockup selection changes with IDs

**Integration Benefits**:
1. No need to open console and paste scripts
2. Results automatically logged to action logger
3. Visual feedback in widget interface
4. Toggle monitoring on/off as needed
5. Captures data that manual inspection might miss

### 7.11 Enhanced Action Log Message Examples

The ActionLogger now provides visual hierarchy for operations:

**Operation Start Detection**:
```javascript
// These patterns trigger operation start markers (🔻)
"Starting mockup update for Product ABC"
"Received: SIP_UPDATE_PRODUCT_MOCKUPS"
"Mockup automation started for Winter Hoodie (4 mockups to sync)"
```

**Operation End Detection**:
```javascript
// These patterns trigger operation end markers (🔺)
"Mockup update completed successfully"
"Connection verified with https://example.com"
"Fetch Complete"
```

**Example Terminal Display with Hierarchy**:
```
🔻 Starting mockup update for Winter Hoodie
│  Navigating to mockup library page
│  Created new printify tab: printify.com/app/products/123
│  Mockup automation started for Winter Hoodie (4 mockups to sync)
│  Synchronizing mockups: Adding 2, removing 1
│  Saving mockup changes
🔺 Mockup update completed successfully

🔻 Received: SIP_FETCH_MOCKUPS
│  Opening product editor for fetch operation
│  Reused printify tab, navigated to: printify.com/app/editor
│  Blueprint: 145, Status: active, Provider: Monster Digital
🔺 Fetch Complete - Mockup data retrieved successfully
```

**Message Enhancement Examples**:
```javascript
// Navigation messages now include specific URLs
"Switched to existing printify tab: printify.com/app/products/123"
"Created new wordpress tab: example.com/wp-admin/admin.php"

// Connection test messages include target
"Connection verified with https://example.com/wp-json"
"Connection failed to https://example.com: Invalid API key"

// Mockup operations include product names and counts
"Mockup update completed for Winter Hoodie (4 mockups)"
"Synchronizing mockups for Summer Tee: Adding 3, removing 2"
```

## 8. Development Quick Reference

### File Structure with Key Functions

```mermaid
graph TB
    subgraph "Extension Root"
        Manifest[manifest.json<br/>Extension configuration]
        Background[background.js<br/>-importScripts-<br/>Loads all modules]
    end
    
    subgraph "Core Scripts"
        Router[widget-router.js<br/>-handleMessage-<br/>-navigateTab-<br/>-pauseOperation-]
        Relay[widget-relay.js<br/>-handlePostMessage-<br/>-window.addEventListener-]
        Error[widget-error.js<br/>-formatError-<br/>-standardizeError-]
        Logger[action-logger.js<br/>-ActionLogger.log-<br/>-updateWidgetDisplay-<br/>-storeLog-<br/>-getActionLogs-]
        LogHelper[action-log-helper.js<br/>-action.info-<br/>-action.error-<br/>-action.warn-]
        ErrorCap[error-capture.js<br/>-window.onerror-<br/>-unhandledrejection handlers-]
    end
    
    subgraph "Action Scripts"
        Detector[extension-detector.js<br/>-announceExtension-<br/>-checkPageContext-]
        WidgetActions[widget-tabs-actions.js<br/>-createWidget-<br/>-updateOperationStatus-<br/>-handleButtonClick-<br/>-handleDiagnostic-<br/>-runPrintifyDiagnostic-<br/>-handleMonitor-<br/>-startInteractionMonitor-<br/>-stopInteractionMonitor-]
        PrintifyActions[printify-tab-actions.js<br/>-observeDOM-<br/>-detectPageChanges-]
        MockupActions[mockup-library-actions.js<br/>-checkUrlParameters-<br/>-executeSceneSelection-]
    end
    
    subgraph "Handler Scripts"
        WidgetHandler[widget-data-handler.js<br/>-handle-<br/>navigate/showWidget/updateState]
        PrintifyHandler[printify-data-handler.js<br/>-handle-<br/>fetchMockups/updateStatus]
        WordPressHandler[wordpress-handler.js<br/>-handle-<br/>routes SIP_* to internal]
        MockupFetch[mockup-fetch-handler.js<br/>-handle-<br/>-reportStatus-<br/>navigates and captures]
        MockupUpdate[mockup-update-handler.js<br/>-handle-<br/>-reportStatus-<br/>opens URL with params]
    end
    
    Background -->|loads| Router
    Background -->|loads| Error
    Background -->|loads| Logger
    Background -->|loads| WidgetHandler
    Background -->|loads| PrintifyHandler
    Background -->|loads| WordPressHandler
    Background -->|loads| MockupFetch
    Background -->|loads| MockupUpdate
```

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

### Terminal Display Testing
- [ ] READY state shows green "..." dots
- [ ] One-off messages appear without hiding READY status
- [ ] PROCESSING state shows progress bar and hides dots
- [ ] Progress updates from 0% to 100%
- [ ] Messages dim to 50% opacity after 5 seconds
- [ ] New messages reset opacity to 100%
- [ ] WordPress messages are blue (context-aware brightness)
- [ ] Printify messages are green (context-aware brightness)
- [ ] Status headers use correct colors (INFO=grey, SUCCESS=green, ERROR=red, WARNING=orange)
- [ ] Completion shows detailed message at 100%
- [ ] Terminal returns to READY after operation completes

## 9. Key Implementation Notes

### Two Separate Progress Systems
- **WordPress Plugin**: Tracks batch progress across multiple operations
- **Extension Widget**: Tracks individual operation progress
- These work together but are completely distinct

### Message Persistence
- Messages stay visible (dimmed) until replaced
- No setTimeout to hide messages - only to dim them
- User can always see the last action that occurred

### State Management
- Only handlers should set `sipOperationStatus`
- One-off messages should never change terminal state
- State changes only through storage updates, not direct manipulation

### Service Worker Safe Logging
- Use `SiPWidget.ActionLogger.log()` in handlers
- Use `window.action` helpers in content scripts
- Check for window existence before using DOM features