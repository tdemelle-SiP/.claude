# SiP Plugin Suite Documentation Map

This document serves as a central reference point and navigation guide for the SiP Plugin Suite codebase. It organizes all documentation in the .claude directory and provides context for understanding the architecture, conventions, and functionality of the plugin suite.

## Introduction for Claude

>Your mission is twofold: (1) work on the specific code that is the focus of the session, and (2) maintain this document as a map of the overall SiP Plugin Suite codebase. Use this document to orient yourself to where the specific code being worked on resides within the larger framework. Ensure that new code conforms to the patterns described here. If it doesn't, either reconsider the approach to the immediate code task or extend/clarify this documentation to maintain alignment between the map and the terrain.
>
>This document serves as a critical bridge between human and AI collaborators, preserving context that would otherwise be lost between sessions. Documentation updates should correlate with versioning logic: minor changes (1.2.6 → 1.2.7) may require no updates, structural refactors (1.2.7 → 1.3.0) should be reflected here, and substantial additions (1.3.0 → 2.0.0) require significant documentation updates. For significant architectural decisions, include a dated entry in the appropriate section to create a lightweight architectural decision record.
>
>Update this document when:
- Making architectural changes affecting multiple components
- Establishing new coding patterns or conventions
- Changing development environment requirements
- Identifying recurring issues that require specific handling approaches

Do NOT update for routine code changes, bug fixes, or implementation details that don't affect overall structure.


## Key Documentation Files

| File | Description |
|------|-------------|
| [SiP Code Standards Overiew](./sip_code_standards_overview.md) | Introductory overview explaining patterns, utilities, and conventions used in SiP plugins |
| [SiP Plugin Suite Hierarchy](./sip_plugin_suite_hierarchy.md) | The full file hierarchy of the sip plugin suite plugins |
| [SiP Plugin Ajax Architecture](./sip_plugin_ajax_architecture.md) | Documentation for the centralized AJAX handling system used by all SiP plugins
| [Sip Plugin File Structure](./sip_plugin_file_structure.md) | This document outlines the patterns, utilities, and naming conventions that should be followed when implementing SiP (Stuff is Parts) plugins

## Architecture Overview

The SiP Plugin Suite consists of a core plugin (`sip-plugins-core`) that provides centralized functionality, and several feature-specific plugins that leverage this shared infrastructure. This modular approach allows for:

1. Consistent code patterns across plugins
2. Centralized AJAX handling
3. Shared UI components and utilities
4. Standardized error handling

### Core Components

- **AJAX Handler**: Centralizes all AJAX communication via a routing system
- **UI Utilities**: Provides spinners, toast notifications, and dialog boxes
- **Progress Dialog**: Handles batch operations with visual feedback
- **Response Format**: Standardizes all AJAX responses for consistent handling

### Plugin Integration

Each SiP plugin follows a consistent structure and integrates with the core by:

1. Including the core framework
2. Providing an AJAX shell for routing
3. Using standardized function and file naming conventions
4. Leveraging shared utilities for UI and data handling
5. Using the standard SiP Plugin Header
   - Use `sip_render_standard_header()` for consistent headers
   - Include navigation links to parent pages
   - Use right area for context-specific actions

### Update Mechanism
Self-registration for update checks via central update server at updates.stuffisparts.com
  - Core plugin must use `register_core_plugin_for_updates()` method to register itself

## Common Issues and Solutions

### FormData Creation

Always use the `SiP.Core.ajax.createStandardFormData()` utility to ensure consistent parameter structure. This utility automatically adds:

- The 'action' parameter (set to 'sip_handle_ajax_request')
- The 'plugin' identifier
- The 'action_type' parameter
- The nonce for security validation

   - Use `SiP_AJAX_Response` class for standardized responses
   - Include success flag, data, and message in all responses

XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX BELOW NEEDS TO BE REWRITTEN AFTER DOCUMENTATION RE-ORG XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

## Plugin Checklist

Before deploying or updating SiP plugins, use the comprehensive [integration checklist](./sip_plugin_standards.md#plugin-integration-checklist) to verify that all standards are properly implemented.

## Customizing and Extending

When creating new functionality:

1. Follow the established directory structure
2. Use the proper naming conventions for files and functions
3. Register with the central AJAX handler
4. Implement consistent error handling
5. Utilize existing UI components and utilities

## Development Guidelines

See the [guidelines](./guidelines/) directory for detailed development practices including:

- Code style and formatting
- Error handling best practices
- Performance considerations
- Security guidelines

## Environment Setup

The [environment](./environment/) directory contains documentation about setting up development environments for the SiP Plugin Suite.

## Project Management

The [project](./project/) directory contains documentation related to project management, roadmaps, and release planning.

## Best Practices Quick Reference

1. **AJAX Requests**: Always use `SiP.Core.utilities.createFormData()` and `SiP.Core.ajax.handleAjaxAction()`
2. **AJAX Responses**: Always use `SiP_AJAX_Response::success()` or `SiP_AJAX_Response::error()`
3. **Event Handling**: Follow the module pattern with proper event attachment
4. **UI Components**: Use the standardized SiP Core utilities for spinners, toasts, and dialogs
5. **Error Handling**: Implement consistent error handling with appropriate messages
6. **File Organization**: Maintain the established directory structure and file naming conventions

By following these standards and utilizing the resources in this documentation, you can maintain consistency across the SiP Plugin Suite and ensure a seamless development experience.