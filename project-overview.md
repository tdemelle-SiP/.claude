# SiP Plugin Suite - Project Overview

## Core Architecture Concepts

1. **Plugin Framework Pattern**
   - Core plugin (sip-plugins-core) serves as foundation for all SiP plugins
   - Plugin framework (`SiP_Plugin_Framework` class) handles standardized plugin initialization
   - Plugins register themselves with the core via `init_plugin($name, $file, $class_name)`

2. **JavaScript Module System**
   - Namespace hierarchy: `SiP.Core.*` for framework, `SiP.PluginName.*` for plugins
   - Core provides utilities, AJAX handling, and state management
   - Modules use revealing module pattern with explicit initialization

3. **Update Mechanism**
   - Custom update server at updates.stuffisparts.com
   - Self-registration pattern for update checks via `register_core_plugin_for_updates()`
   - WordPress transients used for caching plugin information

## Non-obvious Patterns & Decisions

1. **AJAX System Design**
   - Uses a single AJAX endpoint with action routing
   - Standardized response format via `SiP_AJAX_Response` class
   - Spinner suppression for background polling operations

2. **UI Philosophy**
   - Standardized headers provide consistent navigation
   - Plugin pages maintain their own UI but share framework components
   - WordPress admin UI elements are intentionally hidden in SiP plugin pages

3. **Error Handling Approach**
   - Minimal error handling to expose structural issues
   - Errors should bubble up rather than be masked
   - Focus on fixing root causes rather than symptoms

## Development Environment

- **Windows 11 with WSL2** running on machine named "Odin"
- **Screenshot folder**: `/mnt/c/users/tdeme/Documents/VSCode_images_Repo/`
- **Local WordPress** development with multiple plugins in workspace

## Code Style Considerations

- Single method for functionality (no legacy support within methods)
- Clean, minimal implementations without unnecessary abstraction
- CSS organized by component type (header.css, modals.css, etc.)
- Data-driven development (avoid speculation-based changes)