# SiP Plugins Core Dashboard

This guide documents the SiP Plugins Core dashboard functionality, including the unified installer management system for both WordPress plugins and browser extensions.

## Required Reading

Before implementing changes to the dashboard, you should understand:

1. **[AJAX Implementation](./sip-plugin-ajax.md)** - For `SiP.Core.ajax` patterns and error handling
2. **[Data Storage](./sip-plugin-data-storage.md)** - For `SiP.Core.storage` API and storage types
3. **[UI Components](./sip-feature-ui-components.md)** - For spinner, toast notifications, and modal patterns
4. **[Plugin Architecture](./sip-plugin-architecture.md)** - For overall plugin structure and conventions

## Overview

The SiP Plugins Core dashboard provides centralized management for all SiP plugins and browser extensions, displaying:
- Available installers (plugins and extensions) from the stuffisparts update server
- Installation status for each item
- Version information and update availability
- Installation, activation, and management controls

## Architecture

### Page Load Flow

When the dashboard loads, it follows this sequence:

1. **Show spinner** - User sees loading state immediately
2. **Purge stored data** - Clear any cached installer data
3. **Fetch installer data** - Get entire README from update server
4. **Parse installer data** - Extract plugins and extensions into unified structure
5. **Query installation status** - Check WordPress for plugins, request extension announcements
6. **Render tables** - Display both tables with current status
7. **Store data** - Save using SiP data storage conventions

### Unified Data Structure

All installer data is stored in a single `installationsTablesData` structure:

```javascript
installationsTablesData = {
    "plugins": {
        "sip-plugin-slug": {
            "name": "SiP Plugin Name",
            "version": "1.0.0",  // Latest available version
            "download_url": "https://updates.stuffisparts.com/...",
            "installed": true,
            "active": true,
            "installed_version": "0.9.0"  // Currently installed version
        }
    },
    "extensions": {
        "sip-extension-slug": {
            "name": "SiP Extension Name", 
            "version": "1.0.0",  // Latest available version
            "download_url": "https://updates.stuffisparts.com/...",
            "chrome_store_url": "https://chrome.google.com/webstore/...",
            "installed": true,
            "installed_version": "1.0.0"  // Currently installed version
        }
    }
}
```

### Why This Architecture?

**Single Source of Truth**: One data structure contains all information needed to render both tables - available items from the update server plus their installation status.

**Fresh State on Load**: Every page load rebuilds state from primary sources, ensuring accurate information without stale cached data.

**Request-Based Extension Detection**: Extensions only announce when requested, eliminating race conditions and timing issues.

**Proper Storage**: Uses SiP data storage conventions instead of module-level variables, enabling proper state management.

## Key Components

### 1. Loading Installer Data (`loadInstallersTables`)

Fetches and processes all installer data on page load:

```javascript
function loadInstallersTables() {
    // Show spinner (see [UI Components](./sip-feature-ui-components.md#spinner-and-overlay))
    SiP.Core.utilities.spinner.show();
    
    // Purge stored data
    SiP.Core.storage.session.remove('installationsTablesData');
    
    // Create request for all installer data (see [AJAX Guide](./sip-plugin-ajax.md))
    const formData = SiP.Core.utilities.createFormData(
        'sip-plugins-core',
        'plugin_management',
        'get_installers_data'  // New action that returns parsed README
    );
    
    SiP.Core.ajax.handleAjaxAction('sip-plugins-core', 'plugin_management', formData)
        .then(response => {
            // response.data contains parsed plugins and extensions
            installationsTablesData = response.data;
            
            // Append WordPress plugin installation status
            appendPluginStatus(installationsTablesData);
            
            // Request extension announcements
            requestExtensionStatus();
            
            // Wait for extension responses, then render
            setTimeout(() => {
                renderInstallersTables(installationsTablesData);
                SiP.Core.storage.session.set('installationsTablesData', installationsTablesData);
                SiP.Core.utilities.spinner.hide();
            }, 500);
        })
        .catch(error => {
            // Error handling (see [AJAX Error Handling](./sip-plugin-ajax.md#error-handling))
            SiP.Core.utilities.spinner.hide();
            SiP.Core.utilities.toast.show('Failed to load installer data', 'error');
        });
}
```

### 2. Extension Detection

Extensions respond to requests rather than announcing automatically:

```javascript
function requestExtensionStatus() {
    // Broadcast request for extensions to announce
    window.postMessage({
        type: 'SIP_REQUEST_EXTENSION_STATUS'
    }, window.location.origin);
}

// Listen for extension responses
window.addEventListener('message', function(event) {
    if (event.origin !== window.location.origin) return;
    
    if (event.data?.type === 'SIP_EXTENSION_DETECTED') {
        const ext = event.data.extension;
        
        // Update the unified data structure
        if (installationsTablesData.extensions[ext.slug]) {
            installationsTablesData.extensions[ext.slug].installed = true;
            installationsTablesData.extensions[ext.slug].installed_version = ext.version;
        }
    }
});
```

### 3. Rendering Tables (`renderInstallersTables`)

Renders both tables from the unified data:

```javascript
function renderInstallersTables(data) {
    if (data.plugins) {
        renderTable('plugin', data.plugins, '#sip-plugins-table');
    }
    
    if (data.extensions) {
        renderTable('extension', data.extensions, '#sip-extensions-table');
    }
}

function renderTable(type, items, tableId) {
    const $tbody = $(tableId + ' tbody');
    $tbody.empty();
    
    // Convert to array and sort
    const itemsArray = Object.entries(items).map(([slug, item]) => ({
        ...item,
        slug: slug,
        type: type
    }));
    
    // Sort: installed first, then by name
    itemsArray.sort((a, b) => {
        if (a.installed && !b.installed) return -1;
        if (!a.installed && b.installed) return 1;
        return a.name.localeCompare(b.name);
    });
    
    // Render rows
    itemsArray.forEach(item => {
        const $row = createInstallerRow(item);
        $tbody.append($row);
    });
    
    $(tableId).show();
}
```

### 4. Refreshing After Status Changes (`refreshInstallersTables`)

When an installer status changes (install, activate, etc.):

```javascript
function refreshInstallersTables() {
    // Get stored data
    const data = SiP.Core.storage.session.get('installationsTablesData');
    
    if (data) {
        // Re-render with current data
        renderInstallersTables(data);
    } else {
        // Fallback: reload everything
        loadInstallersTables();
    }
}

// Example: After plugin activation (see [AJAX Success Handling](./sip-plugin-ajax.md#success-callbacks))
function handlePluginActivation(pluginSlug) {
    // ... activation logic ...
    
    // Update stored data
    const data = SiP.Core.storage.session.get('installationsTablesData');
    if (data && data.plugins[pluginSlug]) {
        data.plugins[pluginSlug].installed = true;
        data.plugins[pluginSlug].active = true;
        SiP.Core.storage.session.set('installationsTablesData', data);
    }
    
    // Refresh tables
    refreshInstallersTables();
    
    // Show success message (see [Toast Notifications](./sip-feature-ui-components.md#toast-notifications))
    SiP.Core.utilities.toast.show('Plugin activated successfully', 'success');
}
```

## Server-Side Support

### New AJAX Handler

The PHP handler fetches and parses the entire README (see [AJAX PHP Implementation](./sip-plugin-ajax.md#php-implementation)):

```php
function sip_core_get_installers_data() {
    // Fetch README from update server
    $response = wp_remote_get('https://updates.stuffisparts.com/update-api.php?action=get_readme');
    $readme = wp_remote_retrieve_body($response);
    
    // Parse plugins and extensions (existing methods in sip-plugins-core.php)
    $plugins = SiP_Plugins_Core::parse_readme_for_plugins($readme);
    $extensions = SiP_Plugins_Core::parse_readme_for_extensions($readme);
    
    // Get installed plugin status
    $installed_plugins = SiP_Plugins_Core::get_fresh_sip_plugins();
    $active_plugins = get_option('active_plugins', array());
    
    // Format for frontend with installation status
    $data = [
        'plugins' => format_plugins_with_status($plugins, $installed_plugins, $active_plugins),
        'extensions' => format_extensions_data($extensions)
    ];
    
    // Return using SiP AJAX standards (see [AJAX Response Format](./sip-plugin-ajax.md#response-format))
    SiP_AJAX_Response::success(
        'sip-plugins-core',
        'plugin_management',
        'get_installers_data',
        $data,
        'Successfully retrieved installer data'
    );
}
```

**Note**: This handler should be added to `includes/core-ajax-shell.php` following the pattern of existing handlers.

## Storage

Uses SiP data storage conventions (see [Data Storage Guide](./sip-plugin-data-storage.md)):

```javascript
// Store installer data (session storage - cleared on browser close)
SiP.Core.storage.session.set('installationsTablesData', data);

// Retrieve installer data
const data = SiP.Core.storage.session.get('installationsTablesData');

// Clear installer data
SiP.Core.storage.session.remove('installationsTablesData');
```

**Notes**: 
- Using session storage ensures data persists across page navigation but is cleared when the browser closes, providing a good balance for dashboard data
- The `SiP.Core.storage` API is implemented in `/assets/js/core/state.js` alongside the state management system

## Extension Behavior

Extensions should conditionally announce based on the current page:

```javascript
// In extension-detector.js
if (window.location.href.includes('page=sip-plugins')) {
    // On dashboard: Only announce when requested
    window.addEventListener('message', function(event) {
        if (event.data?.type === 'SIP_REQUEST_EXTENSION_STATUS') {
            announceExtension();
        }
    });
} else if (window.location.href.includes('page=sip-printify-manager')) {
    // On plugin pages: Announce immediately for functionality
    announceExtension();
}
```

## UI Patterns

### Tables

Both plugins and extensions use the same table structure:
- Name (with dashboard link for active plugins)
- Version (shows update availability)
- Status (Active/Inactive/Not Installed)
- Actions (context-appropriate buttons)

### Status Display

- **Plugins**: Text status (Active/Inactive/Not Installed)
- **Extensions**: Icon + text (✓ Installed / Not Installed)

### Action Buttons

- **Plugins**: Install, Activate, Deactivate, Update, Delete
- **Extensions**: Install (Chrome Store), Manual Install

## Best Practices

1. **Always purge on load**: Ensures fresh state from primary sources
2. **Use the unified data structure**: Don't create separate storage for plugins/extensions
3. **Update stored data**: Modify the stored data when status changes
4. **Request-based detection**: Extensions only announce when asked
5. **Proper storage**: Use SiP storage utilities, not module variables
6. **Follow SiP patterns**: Use established patterns from referenced documentation

## Implementation Files

### JavaScript
- **Location**: `/assets/js/modules/plugin-dashboard.js`
- **Module**: Part of the SiP Core platform loader (see [Platform Guide](./sip-plugin-platform.md))

### PHP
- **AJAX Handler**: `/includes/core-ajax-shell.php`
- **Main Class**: `/sip-plugins-core.php` (contains parse methods)

### HTML/Views
- **Dashboard View**: `/views/dashboard.php`

## Limitations

- **Extension removal**: Cannot detect when user removes extension from browser. User must reload page to see updated status.
- **Timing**: 500ms timeout for extension responses may need adjustment based on performance.