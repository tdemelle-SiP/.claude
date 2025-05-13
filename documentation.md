# SiP Plugin Suite Documentation

> **For Claude Assistant**: Your mission is twofold: (1) work on the specific code that is the focus of the session, and (2) maintain this document as a map of the overall SiP Plugin Suite codebase. Use this document to orient yourself to where the specific code being worked on resides within the larger framework. Ensure that new code conforms to the patterns described here. If it doesn't, either reconsider the approach to the immediate code task or extend/clarify this documentation to maintain alignment between the map and the terrain.
>
> This document serves as a critical bridge between human and AI collaborators, preserving context that would otherwise be lost between sessions. Documentation updates should correlate with versioning logic: minor changes (1.2.6 → 1.2.7) may require no updates, structural refactors (1.2.7 → 1.3.0) should be reflected here, and substantial additions (1.3.0 → 2.0.0) require significant documentation updates. For significant architectural decisions, include a dated entry in the appropriate section to create a lightweight architectural decision record.

> **Maintainers**: This documentation is maintained by both human developers and AI assistants (Claude). All contributors should follow the guidelines in the Maintenance section to ensure this document remains concise and valuable.

> **Purpose**: This document contains **only information that is not easily deducible from the code**. It serves as a high-level orientation map for developers and AI assistants working with this codebase. Benefits include: reduced onboarding time for new developers (human or AI), consistency across code changes, and preservation of institutional knowledge about design decisions that aren't explicitly stated in comments.

## Core Architecture

- **Plugin Framework Pattern**: Core plugin serves as foundation; plugins register via `SiP_Plugin_Framework::init_plugin($name, $file, $class_name)`
- **JS Module System**: Namespace hierarchy (`SiP.Core.*` for framework, `SiP.PluginName.*` for plugins)
- **Update Mechanism**: Self-registration for update checks via central update server at updates.stuffisparts.com
  - Core plugin must use `register_core_plugin_for_updates()` method to register itself
  - Each plugin requires proper version information to detect updates

## Key Design Decisions

- **AJAX System**: Single endpoint with action routing; standardized via `SiP_AJAX_Response`; spinner suppression for background polling
  - Spinner state should be stored at beginning of request to prevent flashing during background polling
  - Response format standardized through `handleSuccessResponse()` in ajax.js
  - See detailed architecture in `project/ajax-architecture.md`
- **UI Philosophy**: Standardized headers for consistent navigation; WordPress admin UI elements intentionally hidden
  - Logo should appear left of title in header (not above)
  - Header is sticky to remain visible when scrolling
  - Third-party plugin dialogs (Elementor, etc.) actively suppressed to prevent interference
- **Error Handling**: Minimal error handling to expose structural issues; errors should bubble up rather than be masked
- **Collaboration Model**: Changes always discussed before implementing; errors reverted promptly
  - See detailed guidelines in `guidelines/collaboration.md`

## Environment

- **Development**: Windows 11 with WSL2 on machine "Odin"
- **Screenshot Directory**: `/mnt/c/users/tdeme/Documents/VSCode_images_Repo/`
- **Terminal Operations**: Special considerations for WSL environment
  - See detailed guidance in `environment/terminal-operations.md`

## Coding Approach

- Single method for functionality (no legacy support within methods)
- Clean, minimal implementations without unnecessary abstraction
- Data-driven development (avoid speculation-based changes)
- CSS approach prioritizes external stylesheets over inline styles

## Common Issues & Solutions

- **Spinner Flashing**: WooCommerce monitor's periodic AJAX calls can cause spinner to briefly appear
  - Solution: Store spinner state at beginning of request via `const shouldShowSpinner`
- **Third-Party Dialogs**: Elementor and others inject dialogs on SiP plugin pages
  - Solution: Hide via CSS selectors and JavaScript interval (see sip-plugin-framework.php)
- **Logo Positioning**: Logo must be left of title in main dashboard
  - Solution: Maintain correct HTML structure in `render_main_page()`

## Maintenance Guidelines

Update this document when:
- Making architectural changes affecting multiple components
- Establishing new coding patterns or conventions
- Changing development environment requirements
- Identifying recurring issues that require specific handling approaches

Do NOT update for routine code changes, bug fixes, or implementation details that don't affect overall structure.

---

## Suggested Future Additions
- Business requirements and user workflows
- Deployment information and release process
- Performance considerations and optimization strategies
- Security measures and permissions model
- Integration points with WooCommerce and third-party services