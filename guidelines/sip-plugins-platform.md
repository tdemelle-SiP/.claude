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
| Utilities | `SiP.Core.utilities` | Common utility functions |

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

- **DataTables**: Available via jQuery plugin interface
- **PhotoSwipe**: Available via the core PhotoSwipe wrapper

## Using Core Features in Child Plugins

### JavaScript Usage

In child plugin JavaScript files, core features are directly accessible through the global namespace. Learn more about utilizing SiP Core debug logging in the [Debug Logging Guide](./sip-development-debug-logging.md):

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

To get started creating your own SiP plugin, see the [Plugin Creation Guide](./sip-plugin-creation.md).