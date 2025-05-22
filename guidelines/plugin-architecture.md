# SiP Plugin Architecture

## Overview

SiP plugins follow a standardized architecture to ensure consistency, maintainability, and interoperability between plugins. The architecture is centered around the Core plugin, which provides shared functionality, and individual feature plugins that extend this functionality.

## Directory Structure

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

## Core Plugin

The SiP Plugins Core provides:

1. **Platform Services**: Common utilities, AJAX handling, updater
2. **UI Framework**: Standardized UI components and styles  
3. **Plugin Management**: Registration, activation, deactivation
4. **Plugin Updates**: Centralized update mechanism with dependency validation
5. **Dependency Management**: Automated dependency checking and version requirements

### CSS Architecture

#### Standardized Variables

SiP plugins share a common set of CSS variables for consistency, defined in the core plugin. These include:

- Color variables
- Spacing variables
- [Z-index variables](z-index-standards.md)

Always use these standardized variables rather than hardcoded values.

## Feature Plugins

Feature plugins extend the core functionality with specific features:

1. **Registration**: Register with the core plugin using `SiP_Plugin_Framework::init_plugin()`
2. **Dependency Declaration**: Must include `Requires Plugins: sip-plugins-core` header
3. **Version Compatibility**: Check minimum core version before initialization
4. **Standardized UI**: Follow the UI guidelines and use shared components
5. **Update Mechanism**: Use the core update system with automatic dependency validation

## Dependency Management

### Overview

SiP plugins use WordPress's native dependency system combined with automated version management to ensure compatibility and prevent breaking changes.

### Plugin Headers

All child plugins must include:

```php
/*
Plugin Name: SiP Your Plugin Name
Description: Brief description
Version: 1.0.0
Author: Stuff is Parts, LLC
Requires Plugins: sip-plugins-core
*/
```

### Version Compatibility

Child plugins check core version compatibility on initialization:

```php
// Check for minimum core version compatibility
$required_core_version = '2.8.9';
$core_plugin_data = get_plugin_data(WP_PLUGIN_DIR . '/sip-plugins-core/sip-plugins-core.php', false, false);
$current_core_version = $core_plugin_data['Version'] ?? '0.0.0';

if (version_compare($current_core_version, $required_core_version, '<')) {
    // Show admin notice and prevent initialization
    return;
}
```

### Automated Dependency Updates

The release system automatically:

1. **Detects current core version** during child plugin releases
2. **Updates dependency requirements** in plugin headers (e.g., `sip-plugins-core (2.8.9+)`)
3. **Validates dependencies** during direct updates
4. **Prevents incompatible updates** through API validation

### Update System Protection

Both WordPress native updates and SiP direct updates respect dependencies:

- **WordPress Updates**: Protected by `Requires Plugins` headers
- **Direct Updates**: Protected by server-side dependency validation
- **API Integration**: Update server provides dependency information

## JavaScript Architecture

The JavaScript architecture follows a modular pattern:

```
SiP.Core              # Core namespace
├── debug             # Debugging utilities
├── utilities         # Shared utilities
├── ajax              # AJAX handling
└── state             # State management

SiP.PluginName        # Plugin-specific namespace
├── init              # Initialization
└── modules           # Feature modules
```

## Data Flow

1. **User Interaction**: User interacts with the UI
2. **Event Handling**: JavaScript captures the event
3. **AJAX Request**: Data is sent to the server via AJAX
4. **Server Processing**: PHP processes the request
5. **Response**: Server sends a response
6. **UI Update**: JavaScript updates the UI

## Best Practices

1. **Separation of Concerns**: Separate logic, presentation, and data
2. **Dependency Management**: Use the core for shared dependencies
3. **Error Handling**: Consistent error handling and reporting
4. **Performance**: Optimize for performance
5. **Documentation**: Document code and architecture decisions

## Related Documents

- [CSS Guidelines](css-guidelines.md)
- [UI Components](ui-components.md)
- [Z-Index Standards](z-index-standards.md)