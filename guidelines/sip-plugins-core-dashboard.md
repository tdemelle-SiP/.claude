# SiP Plugins Core Dashboard

This guide documents the SiP Plugins Core dashboard functionality, including the unified installer management system for both WordPress plugins and browser extensions.

## Overview

The SiP Plugins Core dashboard provides centralized management for all SiP plugins and browser extensions, displaying:
- Available installers (plugins and extensions) from the stuffisparts update server
- Installation status for each item
- Version information and update availability
- Installation, activation, and management controls

## Architecture

### Unified Installer System

The dashboard uses a unified architecture to manage both plugins and extensions:

```javascript
// Module-level storage
let availableInstallers = {};  // Data from update server
let installedPlugins = {};     // From WordPress PHP
let activePlugins = [];        // Active plugin list

// Unified installed items tracking
window.sipInstalledItems = {
    'sip-plugin/sip-plugin.php': {
        type: 'plugin',
        version: '1.0.0',
        active: true,
        data: { /* WordPress plugin data */ }
    },
    'sip-extension-slug': {
        type: 'extension',
        version: '1.0.0',
        isInstalled: true,
        name: 'Extension Name'
    }
};
```

### Why This Architecture?

**Unified Data Management**: Both plugins and extensions are "installers" that enhance the SiP ecosystem. Managing them with the same patterns reduces complexity and ensures consistent behavior.

**Single Source of Truth**: The update server provides available items, while `sipInstalledItems` tracks what's actually installed, regardless of source (WordPress or browser).

**Push-Based Updates**: Extensions announce themselves via postMessage when ready, triggering immediate UI updates without polling.

## Key Components

### 1. Data Loading (`loadInstallersTables`)

Fetches available plugins and extensions from the update server in a single AJAX call:

```javascript
function loadInstallersTables() {
    const formData = SiP.Core.utilities.createFormData(
        'sip-plugins-core',
        'plugin_management',
        'get_available_installers'
    );
    
    SiP.Core.ajax.handleAjaxAction('sip-plugins-core', 'plugin_management', formData)
        .then(response => {
            availableInstallers = response.data;  // Store both plugins and extensions
            renderInstallersTables(availableInstallers);
        });
}
```

### 2. Unified Rendering (`renderInstallersTables`)

Renders both tables using the same data structure:

```javascript
function renderInstallersTables(installers) {
    if (installers.plugins) {
        renderPluginsTable(installers.plugins);
    }
    if (installers.extensions) {
        renderExtensionsTable(installers.extensions);
    }
}
```

### 3. Extension Detection

Extensions announce themselves when loaded on the dashboard page:

```javascript
// In extension-detector.js
window.postMessage({
    type: 'SIP_EXTENSION_DETECTED',
    extension: {
        slug: 'sip-printify-manager-extension',
        name: 'SiP Printify Manager Extension',
        version: chrome.runtime.getManifest().version,
        isInstalled: true
    }
}, window.location.origin);
```

The dashboard listens for these announcements and updates the UI:

```javascript
function setupExtensionDetection() {
    window.addEventListener('message', function(event) {
        if (event.data && event.data.type === 'SIP_EXTENSION_DETECTED') {
            const extension = event.data.extension;
            
            // Update unified storage
            window.sipInstalledItems[extension.slug] = {
                type: 'extension',
                version: extension.version,
                isInstalled: true,
                name: extension.name
            };
            
            // Refresh tables to show new status
            refreshInstallersTables();
        }
    });
}
```

### 4. Status Checking

Installation status is checked against the unified storage:

```javascript
// For plugins
const installedItem = window.sipInstalledItems[expectedPluginFile];
const isInstalled = !!installedItem;
const isActive = isInstalled && installedItem.active;

// For extensions
function checkIfExtensionInstalled(slug) {
    const installedItem = window.sipInstalledItems[slug];
    return installedItem && installedItem.type === 'extension' && installedItem.isInstalled;
}
```

## Operations

### Plugin Operations

All plugin operations update the unified storage:

```javascript
// Installation adds to sipInstalledItems
window.sipInstalledItems[pluginFile] = {
    type: 'plugin',
    version: response.data.version,
    active: false,
    data: { /* plugin data */ }
};

// Activation updates the active flag
window.sipInstalledItems[pluginFile].active = true;
```

### Extension Operations

Extensions are not managed by WordPress, so operations are limited to:
- Chrome Web Store installation (via button click)
- Manual installation wizard (for development/testing)
- Automatic detection when present

## Server-Side Support

### AJAX Handler

The PHP handler provides both plugins and extensions:

```php
function sip_core_get_available_installers() {
    $plugins_basic = SiP_Plugins_Core::get_available_plugins_list();
    $extensions_basic = SiP_Plugins_Core::get_available_extensions_list();
    
    // Enhance data for frontend
    $plugins = /* format plugins */;
    $extensions = /* format extensions */;
    
    SiP_AJAX_Response::success(
        'sip-plugins-core',
        'plugin_management',
        'get_available_installers',
        ['plugins' => $plugins, 'extensions' => $extensions],
        'Successfully retrieved available plugins and extensions'
    );
}
```

## UI Patterns

### Table Structure

Both plugins and extensions use similar table structures:
- Name (with dashboard link for active plugins)
- Version (installed version or install button)
- Status (Active/Inactive/Not Installed)
- Actions (context-appropriate buttons)

### Status Display

- **Plugins**: Text status (Active/Inactive/Not Installed)
- **Extensions**: Icon + text (✓ Installed / Not Installed)

### Action Buttons

- **Plugins**: Install, Activate, Deactivate, Update, Delete
- **Extensions**: Install (Chrome Store), Manual Install

## Best Practices

1. **Consistent Naming**: Use "installers" when referring to both plugins and extensions
2. **Unified Storage**: Always update `sipInstalledItems` for state changes
3. **Single Refresh**: Use `refreshInstallersTables()` to update both tables
4. **Extension Detection**: Extensions must announce on each page load (no persistence)

## Integration with Other Systems

- **Update System**: Version comparison for update notifications
- **Release Management**: Automated deployment for both types
- **Debug Logging**: Consistent logging for troubleshooting
- **UI Components**: Uses standard SiP Core utilities (spinners, toasts, etc.)