# SiP Plugin Suite Documentation Map

This document serves as a central reference point and navigation guide for the SiP Plugin Suite codebase. It organizes all documentation in the .claude directory and provides context for understanding the architecture, conventions, and functionality of the plugin suite.

## Key Documentation Files

| File | Description |
|------|-------------|
| [SiP Plugin Standards](./sip_plugin_standards.md) | Comprehensive guide to patterns, utilities, and conventions used in SiP plugins |
| [Project Overview](./project-overview.md) | High-level overview of the SiP Plugin Suite |
| [Printify-WooCommerce Error Fix](./printify-woocommerce-error-fix.md) | Documentation of the AJAX routing issue and its solution |
| [Documentation](./documentation.md) | General documentation guidelines and structure |

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

## Common Issues and Solutions

### AJAX Response Routing

One of the most critical aspects of the system is proper AJAX response routing. Issues can occur when:

- Non-standard response formats are used (wp_send_json instead of SiP_AJAX_Response)
- Missing plugin or action_type identifiers in responses
- Redundant parameter additions in JavaScript 

The [Printify-WooCommerce Error Fix](./printify-woocommerce-error-fix.md) document details a specific instance of this issue and its resolution.

### FormData Creation

Always use the `SiP.Core.utilities.createFormData()` utility to ensure consistent parameter structure. This utility automatically adds:

- The 'action' parameter (set to 'sip_handle_ajax_request')
- The 'plugin' identifier
- The 'action_type' parameter
- The nonce for security validation

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