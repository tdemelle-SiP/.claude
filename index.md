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

## Architecture Overview

The SiP Plugin Suite consists of two main components:

### SiP Plugins Core
A foundational plugin providing centralized functionality that all other SiP plugins leverage:

1. **AJAX System**: Centralized request routing and standardized response formatting
2. **UI Utilities**: Shared components (spinners, toasts, dialogs)
3. **Plugin Framework**: Registration system and shared menu management
4. **Update Mechanism**: Self-registration for updates via central server
5. **Libraries**: CodeMirror editor and PhotoSwipe lightbox

### SiP Development Tools
Development and deployment utilities for the plugin suite:

1. **Release Management**: Automated versioning, Git workflow, and deployment
2. **Development Helpers**: Code generation and testing utilities
3. **System Diagnostics**: Environment verification and troubleshooting

## Task-Oriented Guides

Documentation organized by common developer tasks. Each guide presents standards and conventions in the context where they're used.

### Plugin Development
| Guide | Description | Status |
|-------|-------------|--------|
| [Creating a New Plugin](./guidelines/creating-new-plugin.md) | Step-by-step guide to creating a SiP plugin from scratch | ✅ Created |
| [Implementing AJAX Functionality](./guidelines/ajax-implementation.md) | Complete guide to AJAX, including error handling | 🔲 TODO |
| [Implementing Dashboards](./guidelines/implementing-dashboards.md) | Creating admin dashboards and interfaces | 🔲 TODO |

### Feature Implementation
| Guide | Description | Status |
|-------|-------------|--------|
| [Adding Features to Existing Plugins](./guidelines/adding-features.md) | How to extend plugin functionality following standards | 🔲 TODO |
| [Progress Dialog (Batch Operations)](./guidelines/batch-processing.md) | Using progress dialog for batch processing | 🔲 TODO |
| [DataTables Integration](./guidelines/datatables-integration.md) | Implementing server-side data tables | 🔲 TODO |
| [File Uploads](./guidelines/file-uploads.md) | Handling file uploads via AJAX | 🔲 TODO |
| [UI Components](./guidelines/ui-components.md) | Using core UI utilities (spinners, etc.) | 🔲 TODO |
| [Modals and Toasts](./guidelines/modals-toasts.md) | User notifications and dialogs | 🔲 TODO |
| [CodeMirror Integration](./guidelines/codemirror-integration.md) | Implementing code editor functionality | 🔲 TODO |
| [PhotoSwipe Integration](./guidelines/photoswipe-integration.md) | Implementing image lightbox functionality | 🔲 TODO |

### Development Tools (SiP Development Tools Plugin)
| Guide | Description | Status |
|-------|-------------|--------|
| [Release Process and Git Workflow](./guidelines/release-git-workflow.md) | Complete release process including versioning and Git operations | 🔲 TODO |

### Best Practices
| Guide | Description | Status |
|-------|-------------|--------|
| [Testing and Debugging](./guidelines/testing-debugging.md) | Recommendations for testing and troubleshooting | 🔲 TODO |

## Core Components and Utilities

The SiP Plugins Core provides these key components (detailed in implementation guides):

### AJAX System
- Centralized routing through `ajax-handler.php`
- Standardized responses via `SiP_AJAX_Response` class
- Client-side handling via `SiP.Core.ajax`
- Error handling patterns included

### UI Utilities
- Spinner management: `SiP.Core.utilities.spinner`
- Toast notifications: `SiP.Core.utilities.toast`
- Progress dialog: `SiP.Core.progressDialog`

### Plugin Framework
- Registration: `SiP_Plugin_Framework::init_plugin()`
- Standard headers: `sip_render_standard_header()`
- Shared menu system

### Libraries
- **CodeMirror**: Code editor with syntax highlighting
- **PhotoSwipe**: Lightbox for image galleries

### JavaScript Architecture
- Namespace: `SiP.PluginName.moduleName`
- Module pattern with IIFE
- Standardized AJAX handling

## Existing Documentation

These files contain reference information and detailed specifications:

| Document | Description | Status |
|----------|-------------|--------|
| [SiP Plugin Ajax Architecture](./sip_plugin_ajax_architecture.md) | AJAX system architecture details | ✅ Exists |
| [SiP Code Standards Overview](./sip_code_standards_overview.md) | General coding principles | ✅ Exists |
| [SiP Plugin File Structure](./sip_plugin_file_structure.md) | File organization and naming | ✅ Exists |
| [SiP Plugin Suite Hierarchy](./sip_plugin_suite_hierarchy.md) | Complete file hierarchy | ✅ Exists |

## To Be Integrated

Legacy documentation that needs to be reorganized into the task-oriented structure:

| Document | Integration Target | Status |
|----------|-------------------|--------|
| [Progress Dialog Step by Step](./to be integrated into documentation/!Progress-Dialog Step by Step.md) | Batch Processing guide | 🔲 TODO |
| [Plugin Setup Guide](./to be integrated into documentation/sip-plugin-setup-guide.md) | Creating New Plugin guide | ✅ Integrated |

## Quick Reference

### Common Tasks
1. **Need to create a new plugin?** → [Creating a New Plugin](./guidelines/creating-new-plugin.md)
2. **Adding AJAX to your plugin?** → [Implementing AJAX Functionality](./guidelines/ajax-implementation.md) *[TODO]*
3. **Building a dashboard?** → [Implementing Dashboards](./guidelines/implementing-dashboards.md) *[TODO]*
4. **Adding a new feature?** → [Adding Features to Existing Plugins](./guidelines/adding-features.md) *[TODO]*

### Essential Patterns
1. **AJAX Requests**: Always use `SiP.Core.utilities.createFormData()` and `SiP.Core.ajax.handleAjaxAction()`
2. **AJAX Responses**: Always use `SiP_AJAX_Response::success()` or `SiP_AJAX_Response::error()`
3. **Event Handling**: Follow the module pattern with proper event attachment
4. **UI Components**: Use the standardized SiP Core utilities
5. **File Organization**: Maintain the established directory structure

### Development Environment
- **Operating System**: Windows 11 with WSL2
- **Local Development**: Local by Flywheel
- **Code Editor**: Visual Studio Code with Claude integration
- **Plugin Path**: `/mnt/c/Users/tdeme/Local Sites/faux-stained-glass-panes/app/public/wp-content/plugins/`

## Documentation Maintenance

### When to Update Documentation
1. **Architecture Changes**: Update when changing plugin structure or core functionality
2. **New Patterns**: Document new coding patterns or conventions
3. **API Changes**: Update when modifying public APIs or interfaces
4. **Major Features**: Create guides for significant new functionality

### Documentation Standards
1. **Task-Oriented**: Present standards in the context of actual tasks
2. **Code Examples**: Lead with practical examples, explain standards after
3. **Progressive Complexity**: Start simple, build to advanced topics
4. **Cross-References**: Link between related documents
5. **Status Tracking**: Mark documents as TODO, In Progress, or Complete

## Next Steps

Priority tasks for completing the documentation:

1. Complete [Implementing AJAX Functionality](./guidelines/ajax-implementation.md) guide
2. Complete [Adding Features to Existing Plugins](./guidelines/adding-features.md) guide
3. Complete [Implementing Dashboards](./guidelines/implementing-dashboards.md) guide
4. Create library integration guides (CodeMirror, PhotoSwipe)
5. Consolidate release/version/git workflow documentation

By following this documentation structure, developers can quickly find the information they need in the context where they'll use it, making the SiP Plugin Suite more accessible and maintainable.