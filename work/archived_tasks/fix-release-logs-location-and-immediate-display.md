## Task: Fix Release Script Logs Location and Immediate Display
**Date Started:** 2025-06-22 01:05

### Task Understanding
**What:** 
1. Change log file storage location from uploads directory to plugin's logs directory
2. Make the "View Log File" button appear immediately when release process starts
3. Ensure file path management follows SiP documentation standards
4. Update documentation if needed to reflect logs being in plugin directory

**Why:** 
- Logs are transient and shouldn't be in WordPress data/uploads folder
- Plugin logs folder is more accessible in VS Code workspace
- Users need immediate access to logs when script hangs (not wait 10 minutes)
- Current implementation already had PowerShell syntax errors that need fixing

**Success Criteria:**
- Logs are saved in `/wp-content/plugins/sip-development-tools/logs/`
- Log file URL appears immediately in the release progress modal
- All file path operations use SiP storage API patterns correctly
- PowerShell scripts work without syntax errors
- Documentation updated if needed

### Documentation Review
- [x] Coding Guidelines Snapshot - Read complete procedural framework
- [x] index.md - Understood documentation structure
- [x] sip-plugin-data-storage.md - Reviewed storage API patterns (get_folder_path, get_plugin_url)
- [x] sip-plugin-ajax.md - Reviewed AJAX response patterns
- [x] sip-development-testing-debug.md - Reviewed logging standards

### Files to Modify
1. `/mnt/c/Users/tdeme/Local Sites/faux-stained-glass-panes/app/public/wp-content/plugins/sip-development-tools/includes/release-functions.php`
2. `/mnt/c/Users/tdeme/Local Sites/faux-stained-glass-panes/app/public/wp-content/plugins/sip-development-tools/assets/js/modules/release-actions.js`
3. `/mnt/c/Users/tdeme/Local Sites/faux-stained-glass-panes/app/public/wp-content/plugins/.claude/guidelines/sip-plugin-data-storage.md` (potentially)

### Implementation Plan
1. **Fix PowerShell script syntax errors** (already done):
   - Fixed missing string terminators in here-strings for both release-plugin.ps1 and release-extension.ps1

2. **Modify log storage location**:
   - Create custom storage path function that returns plugin directory logs folder
   - Keep using sip_plugin_storage() API pattern but override the directory
   - Ensure logs directory exists in plugin folder

3. **Fix log URL generation**:
   - Generate correct URL pointing to plugin's logs directory
   - Use WordPress functions correctly to get plugin URL

4. **Make log link appear immediately**:
   - Check JavaScript to ensure log_file_url is displayed as soon as response is received
   - Verify AJAX response includes log_file_url in initial response

5. **Update documentation**:
   - Consider if sip-plugin-data-storage.md needs update about logs location
   - Document that logs are exception to uploads directory pattern

### Questions/Blockers
1. Should we create a special case in the storage API for logs, or just handle it locally in release-functions.php?
2. Is it acceptable to have logs in plugin directory as exception to the documented pattern?
3. The user mentioned logs shouldn't be in WordPress data - should we document this reasoning?

### Current Status
- PowerShell syntax errors have been fixed
- Need to implement proper log directory handling following SiP patterns
- Need to ensure immediate log link display

### Code Analysis Findings
1. **Log file location**: Currently using `sip_plugin_storage()->get_folder_path()` which returns uploads directory
2. **Log URL generation**: Using `sip_plugin_storage()->get_plugin_url()` for URL generation  
3. **JavaScript issue**: In `startReleaseProcess()` function (line ~836), the response contains `log_file_url` but it's not displayed immediately. Only the log_file_name is stored and polling begins.
4. **Log link only appears**: 
   - On error in `handleReleaseError()` function
   - On completion in `handleReleaseComplete()` function
   - But NOT when process starts

### Notes
- User was frustrated with previous attempts that didn't follow SiP standards
- Important to use storage API patterns correctly, not bypass them
- Logs being in plugin folder is user preference, not following current documentation
- Need to display log file URL immediately after receiving initial response