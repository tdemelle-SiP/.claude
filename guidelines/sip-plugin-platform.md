# SiP Plugins Platform Guide

## Overview

The SiP Plugins Platform is a centralized architecture for all SiP plugins that provides automatic loading of core features, utilities, and dependencies. This guide explains how the platform works and how to use it effectively in child plugins.

## Key Principles

1. **Central Loading**: All core scripts are loaded by the platform automatically
2. **Zero Duplication**: Child plugins never load core scripts themselves
3. **Direct Feature Access**: Child plugins access core features directly through the global namespace
4. **Dependency Management**: Core features have proper dependencies defined and loading order

## Platform Architecture

The SiP Plugins Platform follows a layered architecture:

1. **Core Layer**: Fundamental utilities (debug, ajax, state, utilities)
2. **Module Layer**: Feature modules built on the core (progress-dialog, header-debug-toggle, etc.)
3. **Child Plugin Layer**: Plugin-specific functionality that uses core and module features

### Plugin Architecture Relationships

```
┌─────────────────────────────────────────────────────────────────────┐
│                        WordPress Environment                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    SiP Plugins Core                          │  │
│  │                                                              │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │                    Core Layer                          │ │  │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐│ │  │
│  │  │  │  Debug   │  │   AJAX   │  │  State   │  │ Utils  ││ │  │
│  │  │  └──────────┘  └──────────┘  └──────────┘  └────────┘│ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  │                             ▲                                │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │                   Module Layer                         │ │  │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │ │  │
│  │  │  │  Progress   │  │   Header    │  │  PhotoSwipe │   │ │  │
│  │  │  │   Dialog    │  │Debug Toggle │  │  Lightbox   │   │ │  │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘   │ │  │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │ │  │
│  │  │  │  Network    │  │   Direct    │  │ DataTables  │   │ │  │
│  │  │  │   Filter    │  │  Updater    │  │  Wrapper    │   │ │  │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘   │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                ▲                                    │
│  ┌──────────────────────┐     ▲     ┌─────────────────────────┐  │
│  │  SiP Printify Mgr    │◄────┼────►│  SiP Product Gallery    │  │
│  │  ┌────────────────┐  │     ▲     │  ┌───────────────────┐  │  │
│  │  │ Product Tables │  │     ▲     │  │ Gallery Display   │  │  │
│  │  │ Image Manager  │  │     ▲     │  │ Cart Integration  │  │  │
│  │  │ Template Mgmt  │  │     ▲     │  └───────────────────┘  │  │
│  │  └────────────────┘  │     ▲     └─────────────────────────┘  │
│  └──────────────────────┘     ▲                                   │
│                               ▲                                    │
│  ┌──────────────────────┐     ▲     ┌─────────────────────────┐  │
│  │  SiP Development     │◄────┴────►│  Other SiP Plugins      │  │
│  │      Tools           │           │                         │  │
│  └──────────────────────┘           └─────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

Legend:
━━━━ Platform boundary
──── Module dependency
◄──► Plugin communication (via Core)
  ▲  Inherits from Core
```

### Plugin Architecture Relationships (Mermaid)

```mermaid
graph TB
    subgraph WordPress["WordPress Environment"]
        subgraph Core["SiP Plugins Core"]
            subgraph CoreLayer["Core Layer"]
                Debug[Debug]
                AJAX[AJAX]
                State[State]
                Utils[Utils]
            end
            
            subgraph ModuleLayer["Module Layer"]
                Progress[Progress Dialog]
                HeaderDebug[Header Debug Toggle]
                PhotoSwipe[PhotoSwipe Lightbox]
                Network[Network Filter]
                DirectUpdate[Direct Updater]
                DataTables[DataTables Wrapper]
            end
            
            CoreLayer --> ModuleLayer
        end
        
        subgraph Plugins["Child Plugins"]
            PrintifyMgr["SiP Printify Manager<br/>• Product Tables<br/>• Image Manager<br/>• Template Mgmt"]
            Gallery["SiP Product Gallery<br/>• Gallery Display<br/>• Cart Integration"]
            DevTools["SiP Development Tools"]
            Others["Other SiP Plugins"]
        end
        
        Core --> PrintifyMgr
        Core --> Gallery
        Core --> DevTools
        Core --> Others
        
        PrintifyMgr -.->|Via Core| Gallery
        PrintifyMgr -.->|Via Core| DevTools
        Gallery -.->|Via Core| DevTools
    end
    
    style Core fill:#e6f3ff
    style CoreLayer fill:#cce7ff
    style ModuleLayer fill:#b3daff
    style PrintifyMgr fill:#fff0e6
    style Gallery fill:#fff0e6
    style DevTools fill:#fff0e6
```

### Dependency Flow

All child plugins depend on the Core plugin, which provides:
- Shared JavaScript and CSS assets
- Common PHP utilities and classes
- Centralized storage management
- Update mechanisms

### Directory Structure

```
sip-plugins-core/            # Core plugin with shared functionality
├── assets/                  # Shared assets
│   ├── css/                 # CSS files
│   │   ├── variables.css    # CSS variables
│   │   └── ...
│   ├── js/                  # JavaScript files
│   │   ├── core/            # Core JS modules
│   │   └── modules/         # Feature modules
│   └── images/              # Shared images
├── includes/                # PHP includes
└── sip-plugins-core.php     # Main plugin file

sip-plugin-name/             # Feature plugin
├── assets/                  # Plugin-specific assets
│   ├── css/
│   │   └── modules/         # CSS modules
│   └── js/
│       └── modules/         # JS modules
├── includes/                # PHP includes
├── views/                   # HTML templates
└── sip-plugin-name.php      # Main plugin file
```

### How Scripts Load

The platform uses a central loader function `sip_core_load_platform()` that:

1. Loads all core JavaScript files in the correct dependency order
2. Attaches necessary WordPress data through localization
3. Sets up third-party libraries (DataTables, PhotoSwipe)
4. Runs early in the admin lifecycle to ensure availability

## Available Core Features

The following core features are always available to child plugins. For details on specific core features, see the guides for [AJAX handling](./sip-plugin-ajax.md), [DataTables integration](./sip-feature-datatables.md), and [Progress Dialog](./sip-feature-progress-dialog.md):

### Core Utilities

| Feature | Global Variable | Description |
|---------|----------------|-------------|
| Debug | `SiP.Core.debug` | Centralized debug logging system |
| AJAX | `SiP.Core.ajax` | Standardized AJAX handling |
| State | `SiP.Core.state` | Client-side state management |
| Utilities | `SiP.Core.utilities` | Common utility functions including string normalization, HTML escaping, and UI helpers |

### Module Features

| Feature | Global Variable | Description |
|---------|----------------|-------------|
| Progress Dialog | `SiP.Core.progressDialog` | Standardized progress indicators |
| Header Debug Toggle | `SiP.Core.headerDebugToggle` | Debug mode toggle in admin UI |
| Network Filter Helper | `SiP.Core.networkFilterHelper` | Network request filtering utilities |
| Direct Updater | `SiP.Core.directUpdater` | Plugin update utilities |
| PhotoSwipe Lightbox | `SiP.Core.photoswipeLightbox` | Image lightbox functionality |

### Server-Side Features

| Feature | PHP Function | Description |
|---------|--------------|-------------|
| Storage Manager | `sip_plugin_storage()` | Centralized storage management for folders and database tables |
| Plugin Framework | `SiP_Plugin_Framework::init_plugin()` | Plugin initialization and menu registration |
| AJAX Response | `SiP_AJAX_Response` | Standardized AJAX response formatting |

### Third-Party Libraries

All third-party libraries are automatically loaded by the platform and available globally:

| Library | Version | Access | Purpose |
|---------|---------|--------|---------|
| **PhotoSwipe** | 5.4.4 | Via module wrapper | Image lightbox galleries |
| **DataTables** | 2.2.1 | jQuery plugin (`$.fn.DataTable`) | Advanced table functionality |
| **jsTree** | 3.3.16 | jQuery plugin (`$.fn.jstree`) | File/directory browser |
| **CodeMirror** | 5.65.13 | Global `CodeMirror` object | Code editor with syntax highlighting |

See [Third-Party Library Integration](./sip-feature-third-party-libraries.md) for implementation details.

## Using Core Features in Child Plugins

### JavaScript Usage

In child plugin JavaScript files, core features are directly accessible through the global namespace. Learn more about utilizing SiP Core debug logging in the [Testing, Debugging & Logging Guide](./sip-development-testing-debug.md):

```javascript
// Namespace setup
var SiP = SiP || {};
window.SiP = window.SiP || {};
SiP.YourPlugin = SiP.YourPlugin || {};

// Use core features directly
SiP.YourPlugin.someModule = (function($) {
    // Access core debug directly - no need to check if it exists
    const debug = SiP.Core.debug;
    debug.log('Module initialized!');

    // Use AJAX handling
    function handleSomeAction() {
        const formData = SiP.Core.utilities.createFormData('your-plugin', 'action_type', 'action');
        formData.append('some_data', 'value');
        
        SiP.Core.ajax.handleAjaxAction('your-plugin', 'action_type', formData)
            .then(response => {
                debug.log('Success!', response);
            })
            .catch(error => {
                debug.error('Error:', error);
            });
    }

    // Use utility functions
    function applyStatusStyling(element, status) {
        // Generate consistent CSS class from dynamic data
        const statusClass = SiP.Core.utilities.normalizeForClass(status, 'status-');
        $(element).addClass(statusClass);
        
        // Escape HTML for safe display
        const safeStatus = SiP.Core.utilities.escapeHtml(status);
        $(element).attr('title', safeStatus);
    }

    // Return public methods
    return {
        init: function() {
            debug.log('Module initialized');
            // Additional initialization
        }
    };
})(jQuery);
```

### PHP Usage

In child plugin PHP files:

1. **DO NOT** register or enqueue any core scripts.
2. **DO NOT** check if core features are available - they always are.
3. **DO** only register and enqueue plugin-specific scripts.
4. **DO** register your storage needs with the storage manager.

```php
// Plugin initialization
SiP_Plugin_Framework::init_plugin(
    'Your Plugin Name',
    __FILE__,
    'Your_Plugin_Class'
);

// Register storage configuration on init hook
add_action('init', function() {
    sip_plugin_storage()->register_plugin('your-plugin-slug', array(
    'database' => array(
        'tables' => array(
            // Your table definitions
        )
    ),
    'folders' => array(
        'logs',
        'data',
        // Other folders
    )
));
}, 5); // After storage manager initialization

// Script enqueueing
function enqueue_your_plugin_scripts($hook) {
    if ($hook !== 'your_plugin_page') {
        return;
    }
    
    // DO NOT enqueue core scripts - they're already loaded
    
    // Only enqueue plugin-specific scripts
    wp_enqueue_script(
        'your-plugin-script',
        plugin_dir_url(__FILE__) . 'assets/js/your-script.js',
        array('jquery'), // Only include actual dependencies, no need for core scripts
        filemtime(plugin_dir_path(__FILE__) . 'assets/js/your-script.js'),
        true
    );
}
```

## Important Rules

1. **NEVER** enqueue core scripts in child plugins
2. **ALWAYS** use core features directly - no need to check if they exist
3. **ONLY** enqueue plugin-specific scripts with no unnecessary dependencies
4. **USE** the `SiP.Core` namespace for all core features
5. **MAINTAIN** your plugin's namespace to avoid conflicts
6. **REGISTER** storage needs with `sip_plugin_storage()` - no manual directory creation
7. **AVOID** activation hooks for storage initialization - the storage manager handles it

## Troubleshooting

If core features are not available:

1. Check that SiP Plugins Core is active
2. Verify the page is loaded in the WordPress admin area
3. Check browser console for JavaScript errors
4. Ensure your plugin initializes after the platform is loaded

## Development Guidelines

When extending the platform:

1. Add new core features to the appropriate layer 
2. Update the platform loader to include new scripts
3. Maintain proper dependency chains
4. Document new features in this guide

## Data Flow Architecture

The standard data flow in SiP plugins follows this pattern:

1. **User Interaction**: User interacts with the UI
2. **Event Handling**: JavaScript captures the event
3. **AJAX Request**: Data is sent to the server via standardized AJAX
4. **Server Processing**: PHP processes the request through registered handlers
5. **Response**: Server sends a standardized response
6. **UI Update**: JavaScript updates the UI based on response

### Data Flow Patterns (ASCII)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           SiP Plugin Data Flow                           │
└─────────────────────────────────────────────────────────────────────────┘

  Browser/Client Side                      Server Side (WordPress/PHP)
 ┌─────────────────┐                     ┌──────────────────────────┐
 │                 │                     │                          │
 │   User Event    │                     │   WordPress Admin        │
 │  (Click/Input)  │                     │                          │
 └────────┬────────┘                     └──────────────────────────┘
          │                                           ▲
          ▼                                           │
 ┌─────────────────┐                                 │
 │  Event Handler  │                                 │
 │   (JS Module)   │                                 │
 └────────┬────────┘                                 │
          │                                          │
          ▼                                          │
 ┌─────────────────┐         AJAX Request           │
 │  SiP.Core.ajax  │─────────────────────────────────┤
 │  handleAction() │         (POST + nonce)          │
 └────────┬────────┘                                 │
          │                                          ▼
          │                              ┌──────────────────────────┐
          │                              │  wp_ajax_sip_* handler   │
          │                              │  (Plugin PHP Handler)    │
          │                              └────────────┬─────────────┘
          │                                           │
          │                                           ▼
          │                              ┌──────────────────────────┐
          │                              │   Process Request        │
          │                              │   - Validate nonce       │
          │                              │   - Check permissions    │
          │                              │   - Execute logic       │
          │                              └────────────┬─────────────┘
          │                                           │
          │                                           ▼
          │                              ┌──────────────────────────┐
          │                              │  Data Layer Access       │
          │                              │  - Database queries     │
          │                              │  - File operations      │
          │                              │  - External APIs        │
          │                              └────────────┬─────────────┘
          │                                           │
          │                                           ▼
          │                              ┌──────────────────────────┐
          │         JSON Response        │  SiP_AJAX_Response      │
          │◄─────────────────────────────┤  wp_send_json_*()      │
          │                              └──────────────────────────┘
          ▼
 ┌─────────────────┐
 │ Promise Handler │
 │  .then/.catch   │
 └────────┬────────┘
          │
          ▼
 ┌─────────────────┐                     ┌──────────────────────────┐
 │   UI Updates    │                     │  Optional: Trigger       │
 │  - DOM changes  │────────────────────►│  - DataTable reload     │
 │  - Toast msgs   │                     │  - State refresh        │
 │  - Spinner hide │                     │  - Event emission       │
 └─────────────────┘                     └──────────────────────────┘
```

### Data Flow Patterns (Mermaid)

```mermaid
flowchart TD
    subgraph Browser["Browser/Client Side"]
        A[User Event<br/>Click/Input] --> B[Event Handler<br/>JS Module]
        B --> C[SiP.Core.ajax<br/>handleAction]
        C -->|AJAX Request<br/>POST + nonce| SERVER
        
        RESPONSE -->|JSON Response| D[Promise Handler<br/>.then/.catch]
        D --> E[UI Updates<br/>DOM changes<br/>Toast messages<br/>Spinner hide]
        E --> F[Optional Triggers<br/>DataTable reload<br/>State refresh<br/>Event emission]
    end
    
    subgraph Server["Server Side WordPress/PHP"]
        SERVER[wp_ajax_sip_* handler<br/>Plugin PHP Handler] --> G[Process Request<br/>- Validate nonce<br/>- Check permissions<br/>- Execute logic]
        G --> H[Data Layer Access<br/>- Database queries<br/>- File operations<br/>- External APIs]
        H --> RESPONSE[SiP_AJAX_Response<br/>wp_send_json_*]
    end
    
    style A fill:#e1f5e1
    style E fill:#e1f5e1
    style SERVER fill:#ffe1e1
    style RESPONSE fill:#ffe1e1
```

### JavaScript Architecture

The JavaScript architecture follows a modular namespace pattern:

#### JavaScript Namespace Structure (ASCII)

```
window.SiP                                 # Global namespace
│
├── Core                                   # Platform-provided core
│   ├── debug                             # Debug logging system
│   │   ├── log()                        # Standard logging
│   │   ├── error()                      # Error logging
│   │   ├── warn()                       # Warning logging
│   │   └── info()                       # Info logging
│   │
│   ├── ajax                              # AJAX handling
│   │   ├── handleAjaxAction()           # Send AJAX requests
│   │   ├── registerSuccessHandler()     # Register handlers
│   │   └── getRegisteredActions()       # List actions
│   │
│   ├── utilities                         # Utility functions
│   │   ├── createFormData()             # Form data helper
│   │   ├── normalizeForClass()          # CSS class generator
│   │   ├── escapeHtml()                 # HTML escaping
│   │   ├── toast.show()                 # Toast notifications
│   │   └── spinner.show/hide()          # Loading spinner
│   │
│   └── state                             # State management
│       ├── get()                        # Get state value
│       ├── set()                        # Set state value
│       └── clear()                      # Clear state
│
├── PrintifyManager                       # Plugin namespace example
│   ├── init()                           # Plugin initialization
│   ├── productActions                   # Product table module
│   │   ├── init()                      # Module init
│   │   ├── handleProductAction()       # Action handler
│   │   └── refreshTable()              # Table refresh
│   │
│   ├── imageActions                     # Image table module
│   └── templateActions                  # Template module
│
└── [OtherPlugins]                       # Other plugin namespaces
```

#### JavaScript Namespace Structure (Mermaid)

```mermaid
graph TD
    Window[window.SiP]
    
    subgraph Core["SiP.Core (Platform Provided)"]
        Debug["debug<br/>• log()<br/>• error()<br/>• warn()<br/>• info()"]
        Ajax["ajax<br/>• handleAjaxAction()<br/>• registerSuccessHandler()<br/>• getRegisteredActions()"]
        Utils["utilities<br/>• createFormData()<br/>• normalizeForClass()<br/>• escapeHtml()<br/>• toast.show()<br/>• spinner.show/hide()"]
        State["state<br/>• get()<br/>• set()<br/>• clear()"]
    end
    
    subgraph Plugins["Plugin Namespaces"]
        PM["SiP.PrintifyManager"]
        PG["SiP.ProductGallery"]
        DT["SiP.DevelopmentTools"]
        
        subgraph PMModules["PrintifyManager Modules"]
            PMInit["init()"]
            PMProduct["productActions<br/>• init()<br/>• handleAction()<br/>• refreshTable()"]
            PMImage["imageActions"]
            PMTemplate["templateActions"]
        end
    end
    
    Window --> Core
    Window --> Plugins
    PM --> PMModules
    
    PMProduct -.->|uses| Debug
    PMProduct -.->|uses| Ajax
    PMProduct -.->|uses| Utils
    
    style Core fill:#e6f3ff
    style Plugins fill:#fff0e6
```

## Best Practices

1. **Separation of Concerns**: Keep logic, presentation, and data separate
2. **Use Core Features**: Always use platform-provided utilities
3. **Consistent Error Handling**: Use standardized error patterns
4. **Performance**: Leverage platform caching and optimization
5. **Documentation**: Document architectural decisions

## Plugin Update System

The SiP platform provides a custom update system that works alongside WordPress's update infrastructure:

### How It Works

1. **Update Detection**: The platform bypasses WordPress's update checks and connects directly to the SiP update server
2. **Dependency Checking**: Before updates, the system verifies that all plugin dependencies are met
3. **Installation Process**: Uses WordPress's `Plugin_Upgrader` class for the actual file installation
4. **Cleanup Handling**: Lets WordPress handle its own upgrade directory cleanup (no pre-emptive deletion)

### Key Implementation Details

```php
// The update process in core-ajax-shell.php
$upgrader = new Plugin_Upgrader(new WP_Ajax_Upgrader_Skin());
$result = $upgrader->install($download_url, array(
    'overwrite_package' => true,
    'clear_destination' => true,
    'abort_if_destination_exists' => false,
    'clear_update_cache' => true
));
```

### Important Notes

- The system uses WordPress's installation machinery for reliability
- File cleanup is handled by WordPress to prevent "file not found" warnings
- Updates check core plugin version requirements before proceeding
- The process provides real-time status updates through AJAX

To get started creating your own SiP plugin, see the [Plugin Creation Guide](./sip-plugin-creation.md).