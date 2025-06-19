# SiP Printify Manager Extension - Chrome Web Store Implementation Guide

**CRITICAL CONTEXT FOR NEXT CLAUDE:**
- Extension repository created at: `/mnt/c/Users/tdeme/Repositories/sip-printify-manager-extension`
- GitHub repo: https://github.com/tdemelle-SiP/sip-printify-manager-extension
- Extension version reset to 1.0.0 (independent from WordPress plugin v4.3.4)
- Using develop/master branch workflow
- Chrome Web Store API key: [User will provide when ready]

## Current State Summary

### ✅ Completed:
1. Extension repository separated from WordPress plugin
2. Independent versioning (1.0.0) 
3. Git repository with proper branch structure
4. Extension ALREADY announces version on load (no code changes needed)

### 🔄 In Progress: Phase 2 - Data Storage Integration

The extension **already sends version** in its ready announcement:
```javascript
// In widget-relay.js line 70
version: chrome.runtime.getManifest().version
```

WordPress **already captures version** in browser-extension-manager.js:
```javascript  
// Line 112
extensionState.version = data.version;
```

## Implementation Tasks - WHERE TO MAKE CHANGES

### Task 2.1: Update browser-extension-manager.js
**File**: `/wp-content/plugins/sip-printify-manager/assets/js/modules/browser-extension-manager.js`

**Changes needed:**
1. Add SiP Core state management integration (currently uses local object)
2. Add Chrome Web Store installation detection
3. Add update checking against stuffisparts server

**Key code sections to modify:**
- Line 17-23: extensionState object → migrate to SiP.Core.state
- Line 112: Where version is captured → store in SiP state
- Add new function: checkForExtensionUpdates()

### Task 2.2: Create extension-functions.php
**Create new file**: `/wp-content/plugins/sip-printify-manager/includes/extension-functions.php`

**Must include:**
```php
// Register extension storage
sip_plugin_storage()->register_plugin('sip-printify-manager-extension', array(
    'folders' => array('data', 'logs', 'cache')
));

// AJAX handlers for extension operations
function sip_handle_extension_update_check() {
    // Check stuffisparts for latest version
    // Compare with client-provided version
    // Return update status
}
```

### Task 2.3: Update WordPress Plugin Files

**Files to modify:**
1. `/wp-content/plugins/sip-printify-manager/sip-printify-manager.php`
   - Add: require_once 'includes/extension-functions.php';
   - Remove: References to embedded extension

2. `/wp-content/plugins/sip-printify-manager/includes/printify-ajax-shell.php`
   - Add: Extension AJAX action handlers

3. `/wp-content/plugins/sip-printify-manager/views/dashboard-html.php`
   - Update: Installation instructions to Chrome Web Store link
   - Add: Extension version display

### Task 2.4: Stuffisparts Data Structure

**Server data file needs this structure:**
```json
{
  "plugins": { 
    // existing plugins 
  },
  "extensions": {
    "sip-printify-manager-extension": {
      "name": "SiP Printify Manager Extension",
      "version": "1.0.0",
      "chrome_store_id": "[TBD]",
      "chrome_store_url": "https://chrome.google.com/webstore/detail/[TBD]",
      "download_url": "https://stuffisparts.com/downloads/extensions/sip-printify-manager-extension-1.0.0.zip",
      "requires": {
        "sip-printify-manager": "4.3.0"
      }
    }
  }
}
```

## Critical Integration Points

### Version Detection Flow:
1. Extension announces: `SIP_EXTENSION_READY` with version
2. WordPress captures in browser-extension-manager.js
3. Store in SiP.Core.state AND WordPress options
4. Compare against stuffisparts data
5. Show update notification if needed

### Storage Patterns to Follow:
- Client: `sip-core.sip-printify-manager.extension.version`
- Server: `sip_extension_settings` option
- Use SiP_AJAX_Response for all responses

## DO NOT:
- Modify extension code (it already works correctly)
- Create new storage patterns (use existing SiP patterns)
- Skip WordPress options storage (needed for offline checks)

## PROGRESS UPDATE

### ✅ Completed in this session:
1. **Task 2.1: Updated browser-extension-manager.js**
   - Added SiP Core state management registration
   - Extension version now stored in localStorage via SiP.Core.state
   - Added checkForExtensionUpdates() function
   - Added update notification functionality

2. **Task 2.2: Enhanced extension-functions.php**
   - Added sip_register_extension_storage() for SiP storage integration
   - Added sip_handle_extension_update_check() AJAX handler
   - Added sip_get_extension_update_info() to fetch from stuffisparts
   - Added sip_get_extension_install_url() for Chrome Web Store links

### 🔄 Next Immediate Steps:
1. **Add AJAX handler registration in printify-ajax-shell.php**:
   ```php
   case 'extension_action':
       require_once 'extension-functions.php';
       switch ($sip_action) {
           case 'check_for_updates':
               sip_handle_extension_update_check();
               break;
       }
       break;
   ```

2. **Update dashboard to show Chrome Web Store link** instead of local path

3. **Test the integration** with mock stuffisparts data

## CRITICAL NOTES FOR NEXT CLAUDE:
- Extension repository is at: `/mnt/c/Users/tdeme/Repositories/sip-printify-manager-extension`
- Extension version is already announced by extension and captured by WordPress
- State management integration is complete in JS but needs AJAX connection
- DO NOT modify extension code - it already works correctly