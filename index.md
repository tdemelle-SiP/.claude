# SiP Plugin Suite Documentation Map

This document serves as a central reference point and navigation guide for the SiP Plugin Suite codebase. It organizes all documentation in the .claude directory and provides context for understanding the architecture, conventions, and functionality of the plugin suite.

## 🚨 REQUIRED READING - START HERE 🚨

**BEFORE doing ANY work on the SiP Plugin Suite, you MUST read:**

### **[📋 Coding Guidelines](./Coding_Guidelines_Snapshot.txt)** 

**This document defines HOW to work within the SiP ecosystem and contains critical behavioral standards that prevent destructive coding patterns. Failure to follow these guidelines results in broken functionality, wasted time, and technical debt.**

**Key areas covered:**
- **Planning requirements** - When and how to code
- **Work methodology** - How to understand and modify existing code
- **Quality standards** - What constitutes acceptable code changes
- **Review processes** - How to verify work meets standards

**These guidelines are not suggestions - they are requirements that must be followed rigorously.**

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

## Getting Started with SiP Plugins

New to SiP Plugin development? Follow this path to get up to speed quickly:

1. **Understand the Platform** → Start with [SiP Plugins Platform](./guidelines/sip-plugins-platform.md)
   - Learn the key principles and architecture
   - Understand how plugins interact with the core platform

2. **Create Your First Plugin** → Follow [Creating a New Plugin](./guidelines/sip-plugin-creation.md)
   - Set up proper file structure
   - Register with SiP Core framework
   - Implement basic functionality

3. **Add AJAX Capabilities** → Read [AJAX Implementation](./guidelines/sip-plugin-ajax.md)
   - Set up standardized AJAX handling
   - Implement proper error handling
   - Follow request-response patterns

4. **Implement User Interface** → Check [Implementing Dashboards](./guidelines/sip-plugin-dashboards.md)
   - Create standardized admin UI
   - Add data management interfaces

5. **Test and Debug** → Review [Testing & Debugging](./guidelines/sip-development-testing.md) and [Debug Logging](./guidelines/sip-development-debug-logging.md)
   - Set up debug logging
   - Implement testing workflows
   - Troubleshoot common issues

6. **Release Your Plugin** → Use [Release Management](./guidelines/sip-development-release-mgmt.md)
   - Follow versioning standards
   - Deploy using the automated system

## Architecture Overview

The SiP Plugin Suite consists of two main components:

### SiP Plugins Core
A foundational plugin providing centralized functionality that all other SiP plugins leverage:

1. **AJAX System**: Centralized request routing and standardized response formatting
2. **UI Utilities**: Shared components (spinners, toasts, dialogs)
3. **Plugin Framework**: Registration system and shared menu management
4. **Update Mechanism**: Centralized update system with dependency validation
5. **Dependency Management**: Automated version requirements and compatibility checking
6. **Libraries**: CodeMirror editor and PhotoSwipe lightbox

### SiP Development Tools
Development and deployment utilities for the plugin suite:

1. **Release Management**: Automated versioning, Git workflow, and deployment
2. **Development Helpers**: Code generation and testing utilities
3. **System Diagnostics**: Environment verification and troubleshooting

## Task-Oriented Guides

The documentation is organized into four main categories:

1. **Core Documentation** - Development standards and best practices
2. **Plugin Development (sip-plugin-*)** - Guides for creating new plugins using SiP Core patterns
3. **Feature Implementation (sip-feature-*)** - Guides for implementing specific SiP Core features
4. **Development Tools (sip-development-*)** - Using the SiP Development Tools plugin for workflow automation

Each guide presents standards and conventions in the context where they're used.

## Visual Documentation Map

```
┌─────────────────────────────────────┐
│       SiP Plugin Suite Platform      │
│       [sip-plugins-platform.md]      │
└───────────────────┬─────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────▼──────────┐    ┌───────▼──────────┐
│  Plugin Creation  │    │  Feature Modules │
│  & Development    │    │  Implementation  │
└───────┬──────────┘    └───────┬──────────┘
        │                       │
┌───────▼──────────┐    ┌───────▼──────────┐
│ Creating Plugin   │    │  UI Components   │
│ [sip-plugin-      │    │  [sip-feature-   │
│  creation.md]     │    │   ui-components] │
└───────┬──────────┘    └───────┬──────────┘
        │                       │
┌───────▼──────────┐    ┌───────▼──────────┐    ┌─────────────────┐
│ AJAX Implementation│    │  DataTables      │    │ Development Tools│
│ [sip-plugin-ajax.md]│    │  [sip-feature-   │    │ & Workflow      │
└───────┬──────────┘    │   datatables.md] │    └───────┬─────────┘
        │                └───────┬──────────┘            │
┌───────▼──────────┐    ┌───────▼──────────┐    ┌───────▼─────────┐
│ Admin Dashboards  │    │  Progress Dialog │    │ Debug Logging   │
│ [sip-plugin-      │    │  [sip-feature-   │    │ [sip-development-│
│  dashboards.md]   │    │   progress-      │    │  debug-logging] │
└───────┬──────────┘    │   dialog.md]     │    └───────┬─────────┘
        │                └───────┬──────────┘            │
┌───────▼──────────┐    ┌───────▼──────────┐    ┌───────▼─────────┐
│ Data Storage      │    │  Other Features  │    │ Testing &       │
│ [sip-plugin-      │    │  • CodeMirror    │    │ Troubleshooting │
│  data-storage.md] │    │  • PhotoSwipe    │    │ [sip-development-│
└──────────────────┘    │  • Modals        │    │  testing.md]    │
                        └──────────────────┘    └───────┬─────────┘
                                                        │
                                                ┌───────▼─────────┐
                                                │ Release Mgmt    │
                                                │ [sip-development-│
                                                │  release-mgmt]  │
                                                └─────────────────┘
```

### Plugin Development (sip-plugin-*)
Guides for creating new plugins using the SiP Core plugin framework and patterns.

| Guide | Description | Status |
|-------|-------------|--------|
| [Creating a New Plugin](./guidelines/sip-plugin-creation.md) | Step-by-step guide to creating a SiP plugin from scratch | ✅ Complete |
| [AJAX Implementation](./guidelines/sip-plugin-ajax.md) | Complete AJAX guide including error handling | ✅ Complete |
| [Implementing Dashboards](./guidelines/sip-plugin-dashboards.md) | Creating admin dashboards and interfaces | ✅ Complete |
| [Data Storage & File Handling](./guidelines/sip-plugin-data-storage.md) | All data storage patterns and file handling | ✅ Complete |
| Plugin Development Workflow | See workflow section below | ✅ In Index |

### Feature Implementation (sip-feature-*)
Guides for implementing specific SiP Core features in your plugins.

| Guide | Description | Status |
|-------|-------------|--------|
| [Progress Dialog](./guidelines/sip-feature-progress-dialog.md) | Batch operations and progress feedback | ✅ Complete |
| [DataTables](./guidelines/sip-feature-datatables.md) | Server-side data tables | ✅ Complete |
| [Table Management](./guidelines/sip-table-management.md) | Table visibility and lifecycle management | ✅ Complete |
| [UI Components](./guidelines/sip-feature-ui-components.md) | Core UI utilities and localStorage for UI state | ✅ Complete |
| [Modals](./guidelines/sip-feature-modals.md) | Modal dialogs and toast notifications | ✅ Complete |
| [CodeMirror](./guidelines/sip-feature-codemirror.md) | Code editor integration | ✅ Complete |
| [PhotoSwipe](./guidelines/sip-feature-photoswipe.md) | Image lightbox functionality | ✅ Complete |

### Development Tools (sip-development-*)
Guides for using the SiP Development Tools plugin for automated workflows.

| Guide | Description | Status |
|-------|-------------|--------|
| [Release Management](./guidelines/sip-development-release-mgmt.md) | Versioning, Git workflow, and automated deployment | ✅ Complete |
| [Testing & Debugging](./guidelines/sip-development-testing.md) | Testing strategies and debugging | ✅ Complete |
| [Debug Logging](./guidelines/sip-development-debug-logging.md) | Implementing and using debug logging | ✅ Complete |

### Development Standards
Standards and best practices for SiP plugin development.

| Guide | Description | Status |
|-------|-------------|--------|
| [CSS Standards](./guidelines/sip-css-standards.md) | CSS architecture, naming conventions, and best practices | ✅ Complete |

### Plugin-Specific Architecture
Detailed architecture guides for specific SiP plugins with complex systems.

| Guide | Description | Status |
|-------|-------------|--------|
| [SiP Printify Manager Architecture](./guidelines/sip-printify-manager-architecture.md) | Complete architecture, data flows, and parent-child product relationships | ✅ Complete |


## Core Components and Utilities

The SiP Plugins Core provides these key components (detailed in implementation guides):

### AJAX System
- Centralized routing through `ajax-handler.php`
- Flexible response routing based on PHP response fields
- Standardized responses via `SiP_AJAX_Response` class
- Client-side handling via `SiP.Core.ajax`
- Cross-table operation support
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
- **Module Consolidation**: Related functionality grouped in single module files (2025-01-21)
- **Dependency Management**: Automated version requirements and compatibility validation (2025-05-22)

## Existing Documentation

These files contain reference information and detailed specifications:

| Document | Description | Status |
|----------|-------------|--------|
| **[Coding Guidelines](./Coding_Guidelines_Snapshot.txt)** | **Behavioral standards and work process requirements** | **✅ Critical** |
| [SiP Plugin Ajax Architecture](./sip_plugin_ajax_architecture.md) | AJAX system architecture details | ✅ Exists |
| [SiP Code Standards Overview](./sip_code_standards_overview.md) | General coding principles | ✅ Exists |
| [SiP Plugin File Structure](./sip_plugin_file_structure.md) | File organization and naming | ✅ Exists |
| [SiP Plugin Suite Hierarchy](./sip_plugin_suite_hierarchy.md) | Complete file hierarchy | ✅ Exists |

## To Be Integrated

Legacy documentation that needs to be reorganized into the task-oriented structure:

| Document | Integration Target | Status |
|----------|-------------------|--------|
| [Progress Dialog Step by Step](./to be integrated into documentation/!Progress-Dialog Step by Step.md) | Progress Dialog guide | ✅ Integrated |
| [Plugin Setup Guide](./to be integrated into documentation/sip-plugin-setup-guide.md) | Creating New Plugin guide | ✅ Integrated |

## Plugin Development Workflow

The SiP Plugin Suite documentation is organized to guide you through the complete plugin development process. Here's how the documentation categories work together:

### Step-by-Step Development Process

1. **Create the Plugin Foundation** (sip-plugin-* guides)
   - Start with [Creating a New Plugin](./guidelines/sip-plugin-creation.md)
   - Set up proper file structure and initialization
   - Register with SiP Core framework

2. **Build Core Functionality** (sip-plugin-* guides)
   - Implement [AJAX handlers](./guidelines/sip-plugin-ajax.md) for server communication
   - Create [admin dashboards](./guidelines/sip-plugin-dashboards.md) for user interfaces
   - Set up [data storage](./guidelines/sip-plugin-data-storage.md) patterns

3. **Add SiP Core Features** (sip-feature-* guides)
   Choose from available features as needed:
   - [Progress Dialog](./guidelines/sip-feature-progress-dialog.md) for batch operations
   - [DataTables](./guidelines/sip-feature-datatables.md) for data display
   - [UI Components](./guidelines/sip-feature-ui-components.md) for consistent interfaces
   - [Modals](./guidelines/sip-feature-modals.md) for dialogs and notifications
   - [CodeMirror](./guidelines/sip-feature-codemirror.md) for code editing
   - [PhotoSwipe](./guidelines/sip-feature-photoswipe.md) for image galleries

4. **Test and Deploy** (sip-development-* guides)
   - Use [Debug Logging](./guidelines/sip-development-debug-logging.md) during development
   - Follow [Testing & Debugging](./guidelines/sip-development-testing.md) practices
   - Deploy using [Release Management](./guidelines/sip-development-release-mgmt.md)

### Workflow Decision Tree

```
Start New Plugin?
    ├─> YES: Use sip-plugin-creation.md
    │    └─> Need AJAX? -> sip-plugin-ajax.md
    │    └─> Need Dashboard? -> sip-plugin-dashboards.md
    │    └─> Need Storage? -> sip-plugin-data-storage.md
    │
    └─> NO: Adding to Existing Plugin?
         └─> Review current structure
         └─> Choose needed features:
              ├─> Batch Operations? -> sip-feature-progress-dialog.md
              ├─> Data Tables? -> sip-feature-datatables.md
              ├─> Modal Dialogs? -> sip-feature-modals.md
              └─> Other UI? -> sip-feature-ui-components.md
```

### Example: Building a Complete Plugin

Here's how you might use the documentation to build a plugin that manages product data:

1. **Foundation**: Use [Creating a New Plugin](./guidelines/sip-plugin-creation.md) to set up `sip-product-manager`
2. **AJAX**: Implement product CRUD operations with [AJAX Implementation](./guidelines/sip-plugin-ajax.md)
3. **Dashboard**: Create product management interface with [Implementing Dashboards](./guidelines/sip-plugin-dashboards.md)
4. **Storage**: Set up database tables with [Data Storage & File Handling](./guidelines/sip-plugin-data-storage.md)
5. **Features**: Add:
   - [DataTables](./guidelines/sip-feature-datatables.md) for product listings
   - [Progress Dialog](./guidelines/sip-feature-progress-dialog.md) for bulk imports
   - [Modals](./guidelines/sip-feature-modals.md) for product editing
6. **Deployment**: Use [Release Management](./guidelines/sip-development-release-mgmt.md) to deploy

## Quick Reference

### Common Tasks
1. **Need to create a new plugin?** → [Creating a New Plugin](./guidelines/sip-plugin-creation.md)
2. **Adding AJAX to your plugin?** → [AJAX Implementation](./guidelines/sip-plugin-ajax.md)
3. **Building a dashboard?** → [Implementing Dashboards](./guidelines/sip-plugin-dashboards.md)
4. **Need progress feedback?** → [Progress Dialog](./guidelines/sip-feature-progress-dialog.md)
5. **Working with data storage?** → [Data Storage & File Handling](./guidelines/sip-plugin-data-storage.md)

### Essential Patterns
1. **AJAX Requests**: Always use `SiP.Core.utilities.createFormData()` and `SiP.Core.ajax.handleAjaxAction()`
2. **AJAX Responses**: Always use `SiP_AJAX_Response::success()` or `SiP_AJAX_Response::error()`
3. **Response Routing**: PHP controls success handler routing via `action_type` field in response
4. **Cross-Table Operations**: Use response routing for operations between different table modules
5. **Event Handling**: Follow the module pattern with proper event attachment
6. **UI Components**: Use the standardized SiP Core utilities
7. **File Organization**: Maintain the established directory structure

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

With all primary documentation complete, focus shifts to implementation verification:

1. **Verify Code Compliance** - Ensure all plugin code follows documented standards
2. **Create Compliance Checklist** - Systematic verification of standards across plugins
3. **Update Non-Conforming Code** - Fix any areas not following standards
4. **Create Code Templates** - Add boilerplate generation to SiP Development Tools
5. **Document Any Gaps** - Add documentation for any discovered patterns

By following this documentation structure, developers can quickly find the information they need in the context where they'll use it, making the SiP Plugin Suite more accessible and maintainable.