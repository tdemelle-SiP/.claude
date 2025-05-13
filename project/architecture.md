# SiP Plugin Suite Architecture

## Core Plugin Structure

The SiP Plugins Core acts as a foundation and framework for all Stuff is Parts plugins. Its architecture follows these key principles:

### 1. Centralized Plugin Management

- Provides a unified admin dashboard under "SiP Plugins" menu
- Manages plugin dependencies and cross-plugin relationships
- Handles activation/deactivation of dependent plugins

### 2. Component Architecture

- **Core Libraries**:
  - `ajax.js`: Standardized AJAX request/response handling
  - `utilities.js`: Common utility functions used across plugins
  - `state.js`: Client-side state management
  
- **UI Components**:
  - Standardized headers via `sip_render_standard_header()`
  - Common CSS/styling system
  - Progress dialog system

### 3. Update System

- Custom plugin updater connecting to Stuff is Parts server
- Centralized version checking via `init_plugin_updater()`
- Plugin self-registration pattern for update checks

## Inter-Plugin Communication

- Plugins register themselves with core via `SiP_Plugin_Framework::init_plugin()`
- Each plugin maintains its own admin page but shares common UI patterns
- JavaScript modules can communicate through core-provided state system

## File Organization

```
sip-plugins-core/
├── assets/                # Frontend assets
│   ├── css/               # Stylesheets
│   ├── js/                # JavaScript modules
│   │   ├── core/          # Core functionality
│   │   └── modules/       # Feature-specific modules
│   └── images/            # Logos and icons
├── includes/              # PHP includes
│   ├── ui-components.php  # UI rendering functions
│   ├── ajax-handler.php   # AJAX processing
│   └── plugin-updater.php # Update system
└── sip-plugin-framework.php # Framework for other plugins
```

## Plugin Integration Pattern

Other SiP plugins follow this integration pattern:

1. Include the framework: `require_once WP_PLUGIN_DIR . '/sip-plugins-core/sip-plugin-framework.php'`
2. Initialize via: `SiP_Plugin_Framework::init_plugin($name, __FILE__, $class_name)`
3. Implement a static `render_dashboard()` method in their main class