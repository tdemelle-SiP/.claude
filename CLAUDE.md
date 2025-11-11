# SIP Printify Manager - Project Structure

This project consists of two related repositories that work together:

## 1. WordPress Plugin (Current Location)
**Path**: `/mnt/c/Users/tdeme/Local Sites/faux-stained-glass-panes/app/public/wp-content/plugins/sip-printify-manager`

The main WordPress plugin that provides Printify API integration, including:
- Mockup management and image generation
- Product synchronization with Printify
- WordPress admin interface
- Data storage and caching

## 2. Chrome Extension Widget
**Path**: `/mnt/c/Users/tdeme/Repositories/sip-printify-manager-extension`

Browser extension that enhances the Printify Manager functionality:
- `manifest.json` - Extension configuration
- `background.js` - Service worker
- `action-scripts/` - Popup and action handlers
- `core-scripts/` - Core functionality
- `handler-scripts/` - Event handlers
- `assets/` - Images and resources

## Working Together
The Chrome extension communicates with the WordPress plugin to provide seamless Printify integration directly in the browser, while the plugin handles server-side operations, data persistence, and WordPress integration.

## Documentation Structure
- `.claude/guidelines/` - Development guidelines and specifications
- `.claude/work/` - Task tracking and work items
- `.claude/index.md` - Main documentation index
