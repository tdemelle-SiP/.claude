# SiP Printify Manager Extension – Integrated Documentation {#top}

---

### TABLE OF CONTENTS

- [1. Three‑Layer Framework](#three-layer-framework)
- [2. Overview](#overview)
- [3. Architecture](#architecture)
  - [3.1A UI & Content Scripts](#area-ui-content-scripts)
  - [3.1B Tab Management & Integration](#area-tab-management)
  - [3.1C Background Router & Messaging](#area-router-messaging)
  - [3.1D Storage & Logging](#area-storage-logging)
- [4. Development Guide](#development-guide)
- [5. Author Checklist](#author-checklist)

---

## 1. THREE‑LAYER FRAMEWORK {#three-layer-framework}

Every subsequent section follows SiP’s standard three‑layer model (**WHAT | HOW | WHY**).

### LAYER OVERVIEW {#layer-overview-table}

| Layer    | Purpose                        | Typical Content                 | Mandatory?             |
| -------- | ------------------------------ | ------------------------------- | ---------------------- |
| **WHAT** | Architecture & data‑flow       | Mermaid diagram or outline      | Optional (recommended) |
| **HOW**  | Implementation detail          | Code, mapping tables, sequences | **Yes**                |
| **WHY**  | Design rationale & constraints | ≤ 2 short paragraphs            | **Yes**                |


---

## 2. OVERVIEW {#overview}

### WHAT

The extension links three contexts to automate Printify product management without direct access to the public API:

1. **Browser‑Extension Context** – content scripts, widget UI, relay, and background router.
2. **WordPress Tab Context** – WordPress admin page with relay for extension communication.
3. **Printify Tab Context** – Printify.com page plus internal XHR that content scripts intercept, scrape and pass to the router.

The full‑system diagram in section 4.0 visualises these contexts, data flows, and storage/logging backbones. Features are documented inside their respective Major Areas in section 3 (Architecture).

### WHY

Printify’s public API omits mock‑up images and some product attributes needed for SiP’s automated template creation. The browser extension bridges that gap by harvesting data directly from the live Printify site while staying in sync with the WordPress plugin via in‑page messaging. Keeping the three contexts distinct preserves security boundaries and minimises maintenance risk: each block can evolve independently while the relay and router enforce a stable contract.

---

## 3. ARCHITECTURE {#architecture}

### 3.0 Full‑System Overview (WHAT)

```mermaid
graph LR
  subgraph "Browser Extension Context"
    CS[Content Scripts] --> WUI[Widget UI]
    CS --> Relay
    Relay --> Router((Service Worker Router))
    Router <-. tab pairs, config .-> Storage[(chrome.storage)]
    CS <-. widget state, config .-> Storage
    WUI <-. widget state, config .-> Storage
    Handlers <-. operation status .-> Storage
    Router --> Handlers[Message Handlers]
    Router --> CS
    Router --> WUI
    Storage -. logs .-> Logger[(Action Log)]
  end

  subgraph "WordPress Tab Context"
    WPPage[WordPress Admin Page]
    WPRelay[wordpress-relay.js] --> WPPage
    WPRelay --> Relay
    WPPage -. REST/XHR .-> WPAPI[(SiP Plugin REST API)]
  end

  subgraph "Printify Tab Context"
    PrintifyPage[Printify.com Page]
    InternalAPI[(Printify Internal API XHR)]
    MICS[Manifest Injected Content Scripts]
    DIS[Dynamically Injected Scripts]
    PrintifyPage --> InternalAPI
    InternalAPI -. intercept .-> DIS
    PrintifyPage -. URL params .-> MICS
    MICS -. DOM manipulation .-> PrintifyPage
    DIS -. API data .-> Router
    Router -. URL params .-> PrintifyPage
    Router -. inject scripts .-> DIS
  end
  
  %% Style definitions for main components
  classDef routerStyle fill:#e8f4f8,stroke:#5a8ca8,stroke-width:2px,color:#1a4a5c
  classDef contentStyle fill:#f3e8f8,stroke:#7d5a8a,stroke-width:2px,color:#3d1a4a
  classDef storageStyle fill:#f8f3e8,stroke:#8a7d5a,stroke-width:2px,color:#4a3d1a
  classDef uiStyle fill:#e8f8e8,stroke:#5a8a5a,stroke-width:2px,color:#1a4a1a
  classDef handlerStyle fill:#f8e8e8,stroke:#8a5a5a,stroke-width:2px,color:#4a1a1a
  
  %% Apply styles to nodes
  class Router routerStyle
  class CS contentStyle
  class Storage storageStyle
  class WUI uiStyle
  class Handlers handlerStyle
```

#### WHY


The overview highlights three execution contexts and their interactions:

• **Browser Extension Context** – injected scripts, relay, and background router that coordinate actions.  
• **WordPress Tab Context** – WordPress admin page communicates with extension via relay, and may call the SiP WordPress plugin's REST API for store data.  
• **Printify Tab Context** – the live page, its internal XHR calls, URL‑parameter commands, and DOM that scripts inspect.

Content Scripts declared in manifest.json cannot use chrome.runtime on Printify. However, the router can dynamically inject scripts to intercept API responses and relay data back.

WordPress plugin uses REST for back‑end tasks, separate from the browser extension.

Host permissions are limited to printify.com and wp-admin domains to minimize Chrome Web Store review friction while maintaining necessary access.


### 3.1 Major Areas

| ID | Major Area                    | Maps to Diagram Node                                      |
| -- | ----------------------------- | --------------------------------------------------------- |
| A  | UI & Content Scripts          | `Content Scripts`, `Widget UI`                            |
| B  | Tab Management & Integration  | `wordpress-relay.js`, `Printify.com Page`, Tab Pairing    |
| C  | Background Router & Messaging | `Service Worker Router`                                   |
| D  | Storage & Logging             | `chrome.storage`, `Action Log`                            |

Each area will become its own subsection (**WHAT | HOW | WHY**) containing relevant Key Features.

### 3.1A UI & Content Scripts {#area-ui-content-scripts}

> **Bundle definition**  `manifest.json` contains **two** `content_scripts` blocks:
>
> 1. **Printify bundle** – Core scripts (`widget-error.js`, `action-logger.js`, `error-capture.js`) plus action scripts for Printify pages.
> 2. **WordPress bundle** – Core scripts plus `wordpress-relay.js` and widget actions for WP admin pages.

#### WHAT

```mermaid
graph TD
  subgraph "Content Scripts System"
    subgraph "Load Order"
      Error[widget-error.js] -->|1| Logger[action-logger.js]
      Logger -->|2| Capture[error-capture.js]
      Capture -->|3| Actions[Action Scripts]
    end
    
    subgraph "Runtime Components"
      CS[Content Scripts]
      WUI[Widget UI]
      CS --> WUI
      
      WUI --> Terminal[Terminal<br/>500 lines]
      WUI --> Modal[VanillaModal]
      WUI --> State[State Manager]
      State -.->|debounced| Storage[(chrome.storage)]
    end
    
    Actions --> CS
    Logger --> Terminal
    
    Router((Router)) -.->|messages| CS
    CS -.->|inject on| WPPage[WordPress Pages]
    CS -.->|inject on| PPPage[Printify Pages]
  end
  
  Terminal -->|auto-hide| Timer[30s timer]
  Modal -->|save position| Storage
  
  %% Apply styles
  classDef contentStyle fill:#f3e8f8,stroke:#7d5a8a,stroke-width:2px,color:#3d1a4a
  classDef uiStyle fill:#e8f8e8,stroke:#5a8a5a,stroke-width:2px,color:#1a4a1a
  classDef routerStyle fill:#e8f4f8,stroke:#5a8ca8,stroke-width:2px,color:#1a4a5c
  
  class CS contentStyle
  class WUI uiStyle
  class Router routerStyle
```

The content scripts system provides error handling, logging, and a floating widget UI that persists state and provides real-time feedback across WordPress and Printify pages.



#### HOW

**Component Implementations**

| WHAT Component | Implementation | File:Line | Key Details |
|----------------|----------------|-----------|-------------|
| widget-error.js | Global error handler | widget-error.js:1 | Sets up `window.SiPWidget.showError()` |
| action-logger.js | Logging system | action-logger.js:1 | Maintains `sipActionLogs` array |
| error-capture.js | Error interceptor | error-capture.js:1 | Hooks `window.onerror` and unhandled rejections |
| Widget UI | Main UI controller | widget-tabs-actions.js:1 | Creates floating widget interface |
| VanillaModal | Modal class | widget-tabs-actions.js:12 | Draggable/resizable dialogs |
| Terminal | Log display | widget-tabs-actions.js:450 | Circular buffer implementation |
| State Manager | `saveState()`, `loadState()` | widget-tabs-actions.js:380 | Debounced persistence |

**Constants & Configuration**

<details>
<summary>View constants</summary>

```javascript
// Widget positioning
const WIDGET_Z_INDEX = 2147483000;  // Above all page content

// Terminal settings  
const TERMINAL_MAX_LINES = 500;     // Circular buffer size
const AUTO_HIDE_MS = 30000;         // 30 second auto-hide

// State persistence
const SAVE_DEBOUNCE_MS = 1000;      // 1 second debounce
```

</details>

**Message Handlers**

| Message | Handler Function | Action |
|---------|-----------------|--------|
| `SIP_SHOW_WIDGET` | `showWidget()` | Makes widget visible |
| `SIP_HIDE_WIDGET` | `hideWidget()` | Hides widget |
| `SIP_TERMINAL_APPEND` | `updateTerminal()` | Adds log entry |
| `SIP_OPERATION_STATUS` | `updateOperationStatus()` | Updates progress display |

#### WHY

A consistent floating widget keeps all extension actions in one place, avoiding separate browser‑action pop‑ups. Injecting via `content_scripts` guarantees that the UI appears automatically on every relevant domain. The terminal gives real‑time feedback critical for long‑running batch operations; capping lines avoids memory leaks.

---

### 3.1B Tab Management & Integration {#area-tab-management}

#### WHAT

```mermaid
graph TD
  subgraph "Service Worker (Background)"
    Router((Service Worker Router))
    TPM[Tab Pair Manager]
    Nav[navigateTab]
    Store[(sipTabPairs)]
    
    Router --> Nav
    Nav --> TPM
    TPM <--> Store
    Nav --> |create/update| ChromeTabs[chrome.tabs API]
  end
  
  subgraph "WordPress Tab"
    WP[WordPress Page]
    WPR[wordpress-relay.js]
    WP -->|postMessage| WPR
  end
  
  subgraph "Printify Tab" 
    PP[Printify Page]
    MICS[Manifest Scripts<br/>URL param reader]
    DIS[Dynamic Scripts<br/>API interceptor]
    PP --> MICS
    MICS -.->|DOM actions| PP
    DIS -.->|capture data| API[Printify API]
  end
  
  WPR -->|chrome.runtime| Router
  Router -->|URL params| PP
  Router -->|executeScript| DIS
  DIS -->|postMessage| Router
  
  TPM -.->|"123↔456"| Pairs[Tab Pairs]
  Pairs -.-> WP
  Pairs -.-> PP
  
  Store -->|onRemoved| Cleanup[Auto-cleanup]
  
  %% Style the Router node
  classDef routerStyle fill:#e8f4f8,stroke:#5a8ca8,stroke-width:2px,color:#1a4a5c
  class Router routerStyle
```

The Tab Management system maintains bidirectional pairing between WordPress and Printify tabs, enabling coordinated actions across both contexts while respecting browser security boundaries.

#### HOW

**Component Locations**

| WHAT Component | Implementation | File:Line |
|----------------|----------------|-----------|
| navigateTab | `async function navigateTab(url, tabType, currentTabId)` | widget-router.js:366 |
| Tab Pair Manager | `tabPairs` Map + helper functions | widget-router.js:42-104 |
| sipTabPairs storage | `chrome.storage.local` key | Persisted as `{tabId: pairedId}` |
| wordpress-relay.js | Content script relay | wordpress-relay.js:1-133 |
| Manifest Scripts | `content_scripts` block | manifest.json:27-60 |
| Dynamic Scripts | `chrome.scripting.executeScript()` | mockup-fetch-handler.js:263 |

**Data Formats**

<details>
<summary>View data structures</summary>

```javascript
// Tab pairs storage structure
sipTabPairs: {
  "123": 456,  // WordPress tab 123 ↔ Printify tab 456
  "456": 123   // Bidirectional for O(1) lookup
}

// URL parameters for Printify automation
?sip-action=update&scenes=Front,Back&primaryScene=Front

// Message format through relay
{
  type: "SIP_UPDATE_PRODUCT_MOCKUPS",
  source: "sip-printify-manager",
  data: { productId: "123", scenes: ["Front", "Back"] }
}
```

</details>

**Script Injection Worlds**

- **ISOLATED world**: Can use `chrome.runtime` API, sets up message relay
- **MAIN world**: Can access page's JavaScript context and intercept API calls

**Message Flows**

```mermaid
graph LR
  subgraph "Tab Pairing Flow"
    WP1[WordPress Tab] -->|SIP_WP_ROUTE_TO_PRINTIFY| R1((Router))
    R1 --> TPM1{Tab Paired?}
    TPM1 -->|Yes| Update[chrome.tabs.update<br/>existing tab]
    TPM1 -->|No| Create[chrome.tabs.create<br/>new tab]
    Create --> Pair[createTabPair<br/>store mapping]
    Update --> PP1[Printify Tab]
    Pair --> PP1
  end
```

```mermaid
graph LR
  subgraph "Mockup Selection Flow"
    WP2[WordPress] -->|SIP_UPDATE_PRODUCT_MOCKUPS| R2((Router))
    R2 -->|Navigate with params| URL[URL: ?sip-action=update<br/>&scenes=Front,Back]
    URL --> PP2[Printify Page loads]
    PP2 --> Script[mockup-library-actions.js]
    Script --> Read[Read URL params]
    Read --> Select[Select mockups<br/>by scene]
    Select --> Save[Click save button]
  end
```

#### WHY

Tab pairing solves the fundamental challenge of coordinating actions across security-isolated contexts. Without direct API access, the extension must orchestrate browser tabs to automate Printify operations while maintaining state consistency. The bidirectional pairing ensures that each WordPress session maintains its own Printify workspace, preventing cross-contamination in multi-store setups.

The dual communication approach—URL parameters for one-way automation and dynamic script injection for data extraction—works around chrome.runtime restrictions on third-party sites. This architecture respects browser security models while enabling the complex interactions required for mockup management. Tab reuse through pairing reduces resource consumption and provides a smoother user experience than constantly opening new tabs.

**Deep-dive: Extension Detection**

```mermaid
graph LR
    WP[WordPress Plugin UI] -->|checkStatus| BEM[Browser Extension Manager]
    BEM -->|postMessage| Relay[wordpress-relay.js]
    Relay -->|chrome.runtime.sendMessage| Router((Router))
    Router -->|route to handler| Handler[WordPress Handler]
    Handler -->|SIP_EXTENSION_DETECTED| Router
    Router -->|response| Relay
    Relay -->|window.postMessage| BEM
    BEM -->|jQuery trigger| Event[extensionDetected event]
    
    style Router fill:#e8f4f8,stroke:#5a8ca8,stroke-width:2px,color:#1a4a5c
```

The extension detection pattern uses:
- Two‑stage widget display – content scripts always injected, widget revealed only on `SIP_SHOW_WIDGET`
- Message identification via `source` string (`sip‑printify-extension`)
- Validation chain – origin → source → structure
- Stateless detection – request/response each time; no proactive announcements
- Edge‑case handling – missing `source`, cross‑origin messages, self‑responses

---

### 3.1C Background Router & Messaging {#area-router-messaging}

#### WHAT

```mermaid
graph TD
  WPPage["WordPress Page"] --> WPRelay[wordpress-relay.js]
  WPRelay --> Router((Service Worker Router))
  
  Router --> CS[Content Scripts]
  Router --> Logger[(Action Log)]
  Router -. URL navigation .-> PrintifyPage[Printify Page]
  
  PrintifyPage --> Actions[Action Scripts]
  Actions -. reads .-> URLParams[URL Parameters]
  
  %% Apply styles to match main architecture
  classDef routerStyle fill:#e8f4f8,stroke:#5a8ca8,stroke-width:2px,color:#1a4a5c
  classDef contentStyle fill:#f3e8f8,stroke:#7d5a8a,stroke-width:2px,color:#3d1a4a
  
  class Router routerStyle
  class CS contentStyle
```

WordPress messages pass through wordpress-relay.js to reach the **Service‑Worker Router**. Printify pages operate in isolation due to chrome.runtime restrictions, using URL parameters as the sole communication method. The Router navigates to Printify pages with specific parameters that action scripts read and execute.

#### HOW

| Component               | Responsibility                                                                         | Key Files            |
| ----------------------- | -------------------------------------------------------------------------------------- | -------------------- |
| Service‑Worker Router   | Central switchboard; validates messages; calls handlers; persists logs                 | `widget-router.js`   |
| wordpress‑relay.js      | In‑page relay that validates WP messages and forwards to Router                        | `wordpress-relay.js` |
| Action Scripts          | Handle page-specific actions (mockup selection, product details)                       | `*-actions.js` files |
| Message Handlers        | Process messages by type and execute appropriate actions                               | `*-handler.js` files |

**Message Lifecycle**

**WordPress → Router:**
1. WordPress plugin posts message to window → wordpress-relay.js
2. Relay validates and formats object `{source:'sip', type:'SIP_*', payload}`
3. Relay calls `chrome.runtime.sendMessage` → Router
4. Router dispatches to appropriate handler

**Router → Printify (URL Parameters):**
1. Router navigates to Printify URL with parameters (e.g., `?sip-action=update&scenes=Front,Back`)
2. Printify action scripts read URL parameters on page load
3. Scripts execute requested actions (mockup selection, etc.)
4. No response path - chrome.runtime is blocked for manifest content scripts

**Router → Printify (Data Fetching):**
1. Router navigates to Printify mockup library page
2. Router dynamically injects scripts via `chrome.scripting.executeScript`:
   - Relay script in ISOLATED world (can use chrome.runtime)
   - Interceptor script in MAIN world (captures API responses)
3. Interceptor captures Printify API responses (e.g., `generated-mockup-maps`)
4. Data flows back: Interceptor → postMessage → Relay → chrome.runtime → Router

Key constants:

```javascript
export const MSG_PREFIX = 'SIP_';
export const AUTO_HIDE_MS = 30000; // widget auto-hide timeout
export const TERMINAL_MAX_LINES = 500; // max log entries in UI
```

**Message Type Catalog**

| Type | Direction | Handler | Purpose |
|------|-----------|---------|---------|
| **WordPress Commands** |
| `SIP_REQUEST_EXTENSION_STATUS` | WP → Extension | `wordpress-handler.js` | Check if extension is active |
| `SIP_EXTENSION_DETECTED` | Extension → WP | (response) | Confirms extension presence |
| `SIP_SHOW_WIDGET` | WP → Extension | `widget-data-handler.js` | Display floating widget |
| `SIP_HIDE_WIDGET` | WP → Extension | `widget-data-handler.js` | Hide floating widget |
| `SIP_UPDATE_PRODUCT_MOCKUPS` | WP → Extension | `mockup-update-handler.js` | Batch update mockups |
| `SIP_FETCH_MOCKUPS` | WP → Extension | `mockup-fetch-handler.js` | Fetch mockup data via intercept |
| `SIP_TEST_CONNECTION` | WP → Extension | `wordpress-handler.js` | Test config & connection |
| `SIP_WP_ROUTE_TO_PRINTIFY` | WP → Extension | `wordpress-handler.js` | Navigate to Printify tab |
| **Internal Actions** |
| `SIP_TERMINAL_APPEND` | Internal | `widget-data-handler.js` | Add line to terminal |
| `SIP_TERMINAL_CLEAR` | Internal | `widget-data-handler.js` | Clear terminal content |
| `SIP_TERMINAL_SET_STATE` | Internal | `widget-data-handler.js` | Update terminal state |
| `SIP_SCENE_MAP` | Router → WP | (broadcast) | Available scenes update |
| `SIP_TAB_PAIRED` | Internal | `widget-tabs-actions.js` | Tabs linked successfully |
| `SIP_TAB_REMOVED` | Internal | `widget-tabs-actions.js` | Tab closed, cleanup pair |
| `SIP_OPERATION_PAUSED` | Internal | `action-queue.js` | User paused batch |
| `SIP_OPERATION_RESUMED` | Internal | `action-queue.js` | User resumed batch |
| `SIP_OPERATION_STATUS` | Internal | `widget-data-handler.js` | Update progress display |
| `SIP_STORAGE_UPDATE` | Internal | `widget-data-handler.js` | Sync storage changes |
| `SIP_LOG_ACTION` | Internal | `action-logger.js` | Record action to log |
| `SIP_ERROR_CAPTURED` | Internal | `error-capture.js` | Global error occurred |
| **Printify Data Events** |
| `MOCKUP_API_RESPONSE` | Printify → Router | `mockup-fetch-handler.js` | Intercepted API data |

**Handler Files**

| Handler | Responsibility | Message Types |
|---------|---------------|---------------|
| `mockup-fetch-handler.js` | Fetches mockup data from Printify pages | `SIP_FETCH_MOCKUPS` |
| `mockup-update-handler.js` | Updates mockup selections on products | `SIP_UPDATE_PRODUCT_MOCKUPS` |
| `widget-data-handler.js` | Controls widget UI and terminal | `SIP_SHOW_WIDGET`, `SIP_TERMINAL_*` |
| `printify-data-handler.js` | Processes mockup data fetched from Printify | `SIP_FETCH_MOCKUPS` responses |
| `wordpress-handler.js` | Processes WordPress plugin commands | `SIP_REQUEST_EXTENSION_STATUS`, `SIP_NAVIGATE` |

**Router Internal Systems**

| System | Purpose | Key Functions |
|--------|---------|---------------|
| Config Manager | Extension setup & API keys | `initializeConfig()`, `loadConfiguration()`, `updateConfig()` |
| Chrome API Layer | Wrapped Chrome APIs with error handling | `createTab()`, `queryTabs()`, `sendTabMessage()`, `updateTab()`, `removeTab()` |
| Operation Control | Pause/resume for user intervention | `pauseOperation()`, `resumeOperation()` |
| Message Validation | Single-point validation | `handleMessage()` validates all incoming messages |

**Configuration Management**

The Router manages extension configuration with fallback layers:

```javascript
async function initializeConfig() {
  // 1. Try pre-configured settings first
  const preConfig = await fetch(chrome.runtime.getURL('assets/config.json'))
    .then(r => r.json())
    .catch(() => null);
    
  if (preConfig?.configured) {
    return preConfig;
  }
  
  // 2. Fall back to chrome.storage.sync
  const stored = await chrome.storage.sync.get(['wordpressUrl', 'apiKey']);
  
  // 3. Update badge based on config status
  if (stored.wordpressUrl && stored.apiKey) {
    chrome.action.setBadgeText({ text: '✓' });
    chrome.action.setBadgeBackgroundColor({ color: '#4CAF50' });
  }
  
  return stored;
}
```

**Chrome API Wrapper Pattern**

All Chrome APIs are wrapped for consistent error handling:

```javascript
async function createTab(params) {
  try {
    const tab = await chrome.tabs.create(params);
    return { 
      success: true, 
      data: { tabId: tab.id, tab: tab } 
    };
  } catch (error) {
    return { 
      success: false, 
      error: error.message, 
      code: 'TAB_CREATION_FAILED' 
    };
  }
}
```

**Operation Pause/Resume**

For operations requiring user intervention:

```javascript
async function pauseOperation(tabId, issue, instructions) {
  operationState.paused = true;
  operationState.pausedOperation = { tabId, issue, instructions };
  
  // Focus the problematic tab
  await chrome.tabs.update(tabId, { active: true });
  
  // Update UI with pause instructions
  await chrome.storage.local.set({
    sipOperationStatus: {
      state: 'paused',
      issue: issue,
      instructions: instructions,
      showResumeButton: true
    }
  });
  
  // Return promise that resolves when resumed
  return new Promise((resolve) => {
    operationState.pausedCallback = resolve;
  });
}
```

**Message Validation Flow**

All messages pass through comprehensive validation:

1. **Structure Check**: Message must have `type` field
2. **Source Validation**: WordPress messages verified by source and origin
3. **Handler Routing**: Message type mapped to specific handler
4. **Response Wrapping**: Success/error responses formatted consistently

#### WHY

A single service‑worker router gives one chokepoint for security and observability: every action is validated, logged, and tracked. The router pattern enables clean separation between message sources and handlers, making the extension maintainable as features grow. Enforcing consistent message naming helps debug issues and prevents collisions with other extensions.

---

### 3.1D Storage & Logging {#area-storage-logging}

#### WHAT

```mermaid
graph TD
  Router((Service Worker Router)) --> Logger[action-logger.js]
  Logger --> ActionLog[(Action Log)]
  ErrorCap[error-capture.js] --> Logger
  Storage[(chrome.storage.local)] -. persists .-> ActionLog
  
  %% Apply styles to match main architecture
  classDef routerStyle fill:#e8f4f8,stroke:#5a8ca8,stroke-width:2px,color:#1a4a5c
  classDef storageStyle fill:#f8f3e8,stroke:#8a7d5a,stroke-width:2px,color:#4a3d1a
  
  class Router routerStyle
  class Storage storageStyle
```

All logs—errors or normal actions—flow through `action-logger.js` into a single array **sipActionLogs** stored in `chrome.storage.local`.

#### HOW

| Component              | Responsibility                                                                                     | Key Files                      |
| ---------------------- | -------------------------------------------------------------------------------------------------- | ------------------------------ |
| action-logger.js       | Maintains `sipActionLogs` array; caps at **500** entries; creates hierarchical log entries         | `action-logger.js`             |
| error-capture.js       | Hooks `window.onerror` & promise rejections; forwards to action logger                             | `error-capture.js`             |
| widget-error.js        | Global error handling and error display infrastructure                                             | `widget-error.js`              |

**Data Schema (current implementation)**

```jsonc
{
  "timestamp": 1713012345678,
  "type": "SIP_API_CALL",
  "tabId": 38,
  "category": "navigation",   // one of: wp-action, navigation, api-call, error, etc.
  "payload": { "endpoint": "/v1/products" }
}
```

Stored under key `"sipActionLogs"` as an array. The logger prunes the array to the last **500** entries to keep below Chrome’s 5 MB quota.

**Storage Keys**

*All keys live in chrome.storage unless noted otherwise.*

| Key | Scope | Purpose | Schema | Size/Quota |
|-----|-------|---------|--------|------------|
| `sipActionLogs` | local | Action & error logging | Array of log entries (see above) | Capped at 500 entries |
| `sipStore` | local | Extension state persistence | `{widgetState, tabPairs, operationStatus}` | Max 1MB total |
| `sipQueue` | session | Paused operation queue | Array of pending messages | Cleared on resume |
| `sipWidgetState` | local | Widget UI persistence | `{isVisible, position, terminalContent, terminalState}` | ~1KB |
| `sipTabPairs` | local | WP↔Printify tab mapping | `{[wpTabId]: printifyTabId}` bidirectional | ~500B |
| `sipOperationStatus` | local | Current operation tracking | `{operation, task, progress, state, timestamp}` | ~2KB |
| `fetchStatus_*` | local | Temporary fetch results | `{status, data, timestamp}` per operation | ~50KB each |
| `wordpressUrl` | sync | Cross-device WP URL | String URL | ~100B |
| `apiKey` | sync | Cross-device auth | 32-char string | ~50B |

**Storage Access Patterns**

```javascript
// Local storage (device-specific)
chrome.storage.local.get(['sipStore', 'sipActionLogs'], (result) => {
  const state = result.sipStore || {};
  const logs = result.sipActionLogs || [];
});

// Session storage (tab-specific, cleared on close)
chrome.storage.session.get(['sipQueue'], (result) => {
  const queue = result.sipQueue || [];
});

// Sync storage (cross-device)
chrome.storage.sync.get(['wordpressUrl', 'apiKey'], (result) => {
  const config = { url: result.wordpressUrl, key: result.apiKey };
});
```

**State Management Functions**

Widget components manage their own state persistence:

| Function | Purpose | Storage Key | Scope |
|----------|---------|-------------|-------|
| `saveState()` | Debounced widget state saving | `sipWidgetState` | Widget position, visibility, terminal content |
| `loadState()` | Restore widget on page load | `sipWidgetState` | Called on content script initialization |
| `autoConfigureForWordPress()` | Auto-detect WP URL | `wordpressUrl` | WordPress admin pages only |

**Auto-Configuration**

On WordPress admin pages, the extension automatically captures the site URL:

```javascript
function autoConfigureForWordPress() {
  if (window.location.pathname.includes('/wp-admin/')) {
    const baseUrl = `${window.location.protocol}//${window.location.hostname}`;
    
    // Check if already configured
    chrome.storage.sync.get(['wordpressUrl'], (items) => {
      if (!items.wordpressUrl || items.wordpressUrl !== baseUrl) {
        chrome.storage.sync.set({ 
          wordpressUrl: baseUrl 
        }, () => {
          console.log('Auto-configured WordPress URL:', baseUrl);
        });
      }
    });
  }
}
```

**State Persistence Pattern**

Widget state is saved with debouncing to prevent storage thrashing:

```javascript
let saveTimeout;
function saveState() {
  clearTimeout(saveTimeout);
  saveTimeout = setTimeout(() => {
    const state = {
      isVisible: widgetVisible,
      position: { x: widget.offsetLeft, y: widget.offsetTop },
      terminalContent: terminal.innerHTML,
      terminalState: terminalExpanded,
      timestamp: Date.now()
    };
    
    chrome.storage.local.set({ sipWidgetState: state });
  }, 1000); // 1 second debounce
}
```

#### WHY

A rolling array of the most‑recent 500 events is simple and fast to query while still covering typical batch‑run history. The hierarchical log structure in `action-logger.js` tracks operation start/end times and nesting, making it easy to trace complex workflows. Keeping both functional and error events in the same list gives an immediate chronological view for debugging.

Chrome's storage quotas shape the architecture: `sipStore` is capped at 1MB to leave headroom in the 5MB local quota, while `sipQueue` uses session storage that's automatically cleared on browser restart, preventing stale operations from accumulating. The bidirectional tab mapping in `sipTabPairs` enables instant lookups in either direction without scanning arrays.

---



<a id="storage-schema"></a>
<a id="message-type-reference"></a>

## 4. DEVELOPMENT GUIDE {#development-guide}

### Adding a New Feature

1. **Register message type** in [3.1C message catalog](#area-router-messaging)
   - Add entry to appropriate section (WordPress Commands, Internal Actions, etc.)
   - Follow `SIP_<VERB>_<NOUN>` naming convention

2. **Add handler** in appropriate handler file
   - Create handler method in relevant `*-handler.js`
   - Register in router's handler map
   - Return `true` for async operations

3. **Emit logs** via action logger
   ```javascript
   // Use the global action object
   action.info('Feature activated', { feature: 'newFeature' });
   action.error('Operation failed', { error: error.message });
   ```

4. **Update documentation**
   - Add feature to relevant section in this file
   - Update message catalog if new messages added
   - Document any new storage keys

---

## 5. AUTHOR CHECKLIST {#author-checklist}

- [ ] Each section follows three-layer framework (WHAT/HOW/WHY)
- [ ] WHAT layer contains architecture diagram or high-level overview
- [ ] HOW layer includes all implementation details from source files
- [ ] WHY layer explains rationale in 2 paragraphs or less
- [ ] All file references verified against actual codebase


[Back to Top](#top)

