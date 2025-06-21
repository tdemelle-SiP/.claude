# Release, Versioning, and Git Process

## Overview

The SiP plugin suite uses an automated release system that handles version updates, Git operations, and package creation. The system supports both WordPress plugins and browser extensions through a flexible repository management interface. The process follows a specific Git workflow with `develop` and `master` branches, automated versioning, and centralized release distribution.

## System Architecture

### Components
- **SiP Development Tools Admin UI**: Web interface for managing repositories and triggering releases
- **Repository Manager**: Flexible system for adding and managing both plugin and extension repositories
- **PHP Backend** (`release-functions.php`): Handles AJAX requests and launches PowerShell script
- **PowerShell Script** (`release-plugin.ps1` / `release-extension.ps1`): Executes release process
- **JavaScript Frontend** (`release-actions.js`): Real-time status monitoring and UI updates
- **Repository Manager Module** (`repository-manager.js`): Handles client-side repository management

## Repository Management

### Overview
The release manager uses a flexible repository registration system that allows management of repositories located anywhere on the file system. This replaces the previous auto-detection system that was limited to the WordPress plugins directory.

### Key Features
- **Manual Repository Addition**: Users explicitly add repositories via UI using text input
- **Flexible Locations**: Supports repositories anywhere on the file system
- **Multiple Types**: Handles both WordPress plugins and browser extensions
- **Persistent Storage**: Repository paths stored in WordPress options
- **Cross-Platform**: Works on Windows, Mac, and Linux
- **Path-Based Operations**: All Git and file operations use actual repository paths from Repository Manager

### Repository Storage Structure
Repository information is stored in WordPress options following SiP data storage standards:

```php
// Option name: sip_development_tools_repositories
[
    [
        'path' => 'C:/Users/tdeme/Local Sites/.../plugins/sip-plugins-core',
        'type' => 'plugin',
        'name' => 'SiP Plugins Core',
        'slug' => 'sip-plugins-core',
        'main_file' => 'sip-plugins-core.php',
        'version' => '2.3.0'
    ],
    [
        'path' => 'C:/Users/tdeme/Repositories/sip-printify-manager-extension',
        'type' => 'extension',
        'name' => 'SiP Printify Manager Extension',
        'slug' => 'sip-printify-manager-extension',
        'main_file' => 'manifest.json',
        'version' => '1.0.0'
    ]
]
```

Note: The `get_release_repositories()` method adds computed fields like `release_date` from the central repository README for display purposes.

### Repository Validation
Minimal validation ensures only essential requirements:
1. **Git Repository**: Directory must contain `.git` folder
2. **Main File**: 
   - Plugins: PHP file with valid WordPress plugin header
   - Extensions: `manifest.json` file
3. **Permissions**: Read/write access to directory
4. **Clear Error Messages**: Specific feedback on validation failures

### UI Elements
- **Add Repository Button**: Located in release table header, shows modal dialog with text input
- **Repository Table**: No longer shows repository path column (removed for cleaner UI)
- **Remove Repository**: × button in actions column to remove from management
- **Table Refresh**: Automatic refresh via AJAX when repositories are added/removed

### Disconnected Repository Handling
When a repository cannot be found at its stored path:

1. **Visual Indicators**:
   - Row appears greyed out
   - Path column shows "Repository not found" message
   - Version and status information unavailable

2. **Available Actions**:
   - **Delete**: Removes the repository entry permanently
   - **Reconnect**: Opens file browser to select new location
     - Uses same validation as adding new repository
     - If validation fails or user cancels, row remains disconnected
     - Useful when repository moved or drive temporarily unmounted

3. **Automatic Recovery**:
   - System checks repository availability on each page load
   - When missing repository becomes available again (e.g., drive remounted), full functionality automatically restored
   - No manual intervention required if repository returns to original location

## Branch Status Checking

### Overview
The branch status system checks Git repository state for all registered repositories, regardless of their location on the file system.

### Implementation Details
- **No Plugin Directory Assumptions**: Uses Repository Manager paths instead of `WP_PLUGIN_DIR`
- **Universal Support**: Works for both plugins and extensions in any location
- **Repository-Based Queries**: All functions accept repository path as parameter
- **Clean Architecture**: No `get_plugins()` calls or WordPress plugin scanning

### Key Functions
```php
// Check branch changes for all repositories
function sip_check_branch_changes() {
    $repositories = SiP_Repository_Manager::get_repositories();
    foreach ($repositories as $repo) {
        if ($repo['status'] === 'active') {
            $results[$repo['slug']] = sip_get_branch_changes($repo['path'], $repo['slug']);
        }
    }
}

// Get branch changes using repository path
function sip_get_branch_changes($repo_path, $repo_slug) {
    // Uses $repo_path directly for all Git commands
    // No assumptions about plugin directory structure
}
```

## Release Process Workflow

### Pre-Release Checklist
The system automatically checks:
1. Current branch (must be on `develop`)
2. Uncommitted changes (working directory must be clean)
3. Git identity configuration
4. Local/remote branch synchronization

### Branch Check and Recovery
**Why**: Git workflow requires releases from `develop` branch to maintain separation between stable (`master`) and development code. Manual branch switching is error-prone and interrupts workflow.

```javascript
// Branch check triggers modal if not on develop
checkCurrentBranch(pluginSlug).then(response => {
    if (response.data.current_branch !== 'develop') {
        showBranchSwitchModal(response.data.current_branch, (proceed) => {
            if (proceed) {
                switchToDevelopBranch(pluginSlug).then(() => {
                    startReleaseProcess(pluginSlug, ...);
                });
            }
        });
    }
});
```

### 16-Step Release Process
The PowerShell script executes these steps for both plugins and extensions:

1. **Safety Checks**: Verify Git branch and uncommitted changes
2. **Update Version**: Update version in main plugin file (or manifest.json for extensions)
3. **Update Dependencies**: Automatically set core dependency requirements for child plugins
4. **Commit Changes**: Commit to `develop` branch
5. **Push Develop**: Push `develop` to GitHub
6. **Merge to Master**: Checkout and merge `develop` into `master`
7. **Create Tag**: Create Git tag for release version
8. **Push Master**: Push `master` and tags to GitHub
9. **Verify Central Dir**: Check central repository exists
10. **Ensure Directories**: Create `previous_releases` folder
11. **Archive Old ZIPs**: Move existing ZIPs to previous releases
12. **Build Package**: Create clean release ZIP using 7-Zip via PHP
13. **Update README**: Create/update central repository README
14. **Commit Central**: Commit changes to central repository
15. **Push Central**: Push central repository to GitHub
16. **Return to Develop**: Checkout `develop` branch

## Version Numbering

### Format
- Follows semantic versioning: `MAJOR.MINOR.PATCH` (e.g., `2.3.0`)
- Must be numeric with exactly three components

### Version Locations

#### WordPress Plugins
```php
// Main plugin file header
/**
 * Version: 2.3.0
 */
```

#### Browser Extensions
```json
// manifest.json
{
  "version": "1.0.0"  // Note: No 'v' prefix in manifest
}
```

#### Central Repository README.md
```markdown
### sip-plugins-core
- Version: 2.3.0
- File: sip-plugins-core-2.3.0.zip
- Last updated: 2024-03-15 14:30:00

### sip-printify-manager-extension
- Version: 1.0.0
- File: extensions/sip-printify-manager-extension-v1.0.0.zip
- Last updated: 2024-03-15 14:35:00
```

## Git Workflow

### Branch Strategy
- **develop**: Active development branch (required for releases)
- **master**: Stable release branch
- Tags: `v2.3.0` format for releases

### Branch Switching Recovery
```php
// sip_switch_to_develop() implementation
function sip_switch_to_develop() {
    // Check for uncommitted changes
    $status_output = shell_exec('git status --porcelain 2>&1');
    if (!empty(trim($status_output))) {
        SiP_AJAX_Response::error(..., 'Cannot switch branches - you have uncommitted changes.');
    }
    
    // Switch to develop branch
    shell_exec('git checkout develop 2>&1');
    
    // Pull latest changes
    $pull_output = shell_exec('git pull origin develop 2>&1');
    
    // Set upstream if needed
    if (strpos($pull_output, 'no tracking information') !== false) {
        shell_exec('git branch --set-upstream-to=origin/develop develop 2>&1');
    }
}
```

### Release Git Flow
```bash
# Start on develop branch
git checkout develop

# Version bump and commit
git add main-file.php
git commit -m "Bump version to 2.3.0"
git push origin develop

# Merge to master
git checkout master
git merge develop
git tag -a "v2.3.0" -m "Version 2.3.0"
git push origin master --tags

# Return to develop
git checkout develop
```

### Git Identity
Default identity if not configured:
- Name: `SiP Development Tools`
- Email: `support@stuffisparts.com`

## ZIP Creation Process

### Overview
The release process creates ZIP files using 7-Zip through a PHP function that can be called from the PowerShell script without requiring WordPress context.

### Key Points
- **7-Zip Requirement**: The system requires 7-Zip to be installed at `C:\Program Files\7-Zip\7z.exe`
- **WordPress Independence**: The `sip_create_zip_archive()` function works without WordPress loaded
- **ABSPATH Calculation**: Dynamically calculates ABSPATH from script location to support repositories anywhere on the filesystem
- **Temp Directory**: Uses temporary directory structure for building packages
- **Compression**: Uses store method (no compression) for faster processing

### ABSPATH Calculation
**Why**: Repository Manager allows repositories anywhere on filesystem, but PHP ZIP creation function requires WordPress constants. Script location provides reliable reference point for calculation.

```php
// PowerShell script generates PHP code that calculates ABSPATH
$scriptDir = '$($MyInvocation.MyCommand.Path.Replace('\', '/'))';  
$parts = explode('/', $scriptDir);
$abspath = implode('/', array_slice($parts, 0, -5)) . '/';
define('ABSPATH', $abspath);
```

### Process Flow
1. PowerShell creates a temporary directory structure
2. Copies plugin files (excluding .git, logs, etc.)
3. Calls PHP function to create ZIP using 7-Zip
4. Cleans up temporary files

## Implementation Details

### AJAX Actions

#### Release Actions
```php
// Main release action handler
function sip_handle_release_action() {
    $release_action = $_POST['release_action'];
    
    switch ($release_action) {
        case 'create_release':
            sip_create_release();
            break;
        case 'check_release_status':
            sip_check_release_status();
            break;
        case 'check_uncommitted_changes':
            sip_check_uncommitted_changes();  // Uses Repository Manager
            break;
        case 'check_branch_changes':
            sip_check_branch_changes();  // Uses Repository Manager
            break;
        case 'commit_changes':
            sip_commit_changes();  // Uses Repository Manager
            break;
        case 'get_plugin_data':
            sip_get_plugin_data();  // Uses Repository Manager
            break;
        case 'check_current_branch':
            sip_check_current_branch();  // Check repository branch
            break;
        case 'switch_to_develop':
            sip_switch_to_develop();  // Switch to develop and pull latest
            break;
    }
}
```

#### Repository Actions
```php
// Repository management handler
function sip_handle_repository_action() {
    $action = $_POST['repository_action'];
    
    switch ($action) {
        case 'validate_repository':
            sip_ajax_validate_repository();
            break;
        case 'add_repository':
            sip_ajax_add_repository();
            break;
        case 'remove_repository':
            sip_ajax_remove_repository();
            break;
        case 'reconnect_repository':
            sip_ajax_reconnect_repository();
            break;
        case 'get_repository_table_rows':
            sip_ajax_get_repository_table_rows();
            break;
    }
}
```

### JavaScript Monitoring
```javascript
// Check release status every 2 seconds
function startStatusPolling(logFileName) {
    statusPollingInterval = setInterval(function() {
        checkReleaseStatus(logFileName, function(hasNewContent, currentLogEntry) {
            // Update UI with progress
        });
    }, 2000);
}

// Modal dialog for branch switching
function showBranchSwitchModal(currentBranch, callback) {
    // Creates SiP-standard modal dialog
    // Offers to switch to develop branch
    // Handles user response via callback
}
```

### PowerShell Execution
```php
// Background execution (default)
$command = "start /B cmd /c \"cd /d " . escapeshellarg($plugin_dir) . 
          " && powershell -ExecutionPolicy Bypass -File \"$ps_script\" " .
          "-NewVersion \"$new_version\" -PluginSlug \"$plugin_slug\" " .
          "-MainFile \"$main_file\" -LogLevel \"$log_level\" >> \"$log_file_path\" 2>&1\"";
pclose(popen($command, 'r'));

// Foreground execution (POWERSHELL log level)
exec($command, $output, $return_var);
```

## Error Handling

### Pre-Release Errors
- **Uncommitted Changes**: Must commit or stash before release
- **Wrong Branch**: Shows modal offering to switch to `develop` branch
- **Git Identity**: Auto-configured if missing
- **Repository Not Found**: Clear error when repository path invalid

### Release Process Errors
- **Version Update Failed**: Check file permissions
- **Git Push Failed**: Check authentication/network
- **Tag Creation Failed**: Verify tag doesn't exist
- **Central Repo Issues**: Ensure directory exists

### Recovery
- PowerShell script logs all operations
- Process can be cancelled via UI
- Failed releases don't affect working directory

## Central Repository

### Structure
```
sip-plugin-suite-zips/
├── README.md               # Auto-updated plugin & extension manifest
├── sip-plugins-core-2.3.0.zip
├── sip-printify-manager-3.1.0.zip
├── extensions/             # Browser extensions directory
│   └── sip-printify-manager-extension-v1.0.0.zip
└── previous_releases/
    ├── sip-plugins-core-2.2.0.zip
    └── sip-printify-manager-3.0.0.zip
```

### README.md Format
```markdown
# SiP Plugin & Extension Releases

This directory contains the latest releases of all SiP plugins and extensions.

Last updated: 2024-03-15 14:30:00

## Available Plugins

### sip-plugins-core
- Version: 2.3.0
- File: sip-plugins-core-2.3.0.zip
- Last updated: 2024-03-15 14:30:00

### sip-printify-manager
- Version: 3.1.0
- File: sip-printify-manager-3.1.0.zip
- Last updated: 2024-03-14 10:15:00

## Available Extensions

### sip-printify-manager-extension
- Version: 1.0.0
- File: extensions/sip-printify-manager-extension-v1.0.0.zip
- Chrome Web Store ID: ikgbhdaibkmehpeipbcooebkgpfegdbg
- Last updated: 2024-03-15 14:35:00
```

### Update Server Integration
The README.md is automatically uploaded to `https://updates.stuffisparts.com/` after each release, allowing other systems to check for available updates.

## Logging

### Log Levels
- **MINIMAL**: Only critical steps
- **NORMAL**: Standard progress (default)
- **VERBOSE**: Detailed debug information
- **POWERSHELL**: Foreground execution with full output

### Log Location
```
sip-development-tools/logs/
└── release_sip-plugins-core_2.3.0_1710512400.log
```

### Log Format
```
[2024-03-15 14:30:00] [INFO] Starting release process for sip-plugins-core version 2.3.0
[2024-03-15 14:30:01] [SUCCESS] Version updated in main file
[2024-03-15 14:30:02] [INFO] Pushing develop branch to GitHub...
[2024-03-15 14:30:05] [SUCCESS] Develop branch pushed to GitHub
```

## UI Features

### Branch Status Display
- **Master←Develop**: Shows commits between branches
- **Local↔Remote**: Shows ahead/behind status
- **Uncommitted**: Shows modified files

### Visual Indicators
```javascript
// Red button for plugins with changes
if (hasChangesForRelease) {
    $createReleaseButton.css({
        'background-color': '#d63638',
        'border-color': '#d63638',
        'color': 'white'
    });
}

// Modal dialogs for user interaction
// - Branch switch modal with monospace branch names
// - Uncommitted changes modal with file list
// - Progress tracking during operations
```

### Progress Tracking
- Real-time log updates
- Step duration display
- Total elapsed time
- Success/error messages

## Usage

### Basic Release
1. Navigate to SiP Dev Tools → Release Plugins
2. Enter new version number (e.g., `2.3.0`)
3. Select log level (default: NORMAL)
4. Click "Create Release"
5. Monitor progress in real-time

### Cancel Release
- Click "Cancel Release" during process
- System attempts to terminate PowerShell script
- Log file preserved for debugging

### View Logs
- Click "View Log File" after completion
- Access via `sip-development-tools/logs/`

## Configuration

### Environment Variables
```powershell
# Skip branch check
$env:SKIP_BRANCH_CHECK = "true"

# Enable Git trace (VERBOSE mode)
$env:GIT_TRACE = 1
$env:GIT_CURL_VERBOSE = 1
```

### Timeout Settings
```php
// PHP execution limits
ini_set('memory_limit', '256M');
ini_set('max_execution_time', 30);

// PowerShell timeouts
$timeoutSeconds = 60;  // Git push operations
$timeoutSeconds = 30;  // Git checkout/merge
$timeoutSeconds = 20;  // Git add/commit
```

## Troubleshooting

### Common Issues

1. **Stuck on "Processing..."**
   - Check PowerShell execution policy
   - Verify Git authentication
   - Check network connectivity

2. **"Not on develop branch" Error**
   - Click "Switch to Develop & Continue" in the modal dialog
   - Or manually switch:
     ```bash
     git checkout develop
     git pull origin develop
     ```

3. **Authentication Failures**
   - Configure Git credentials
   - Use SSH keys or credential store

4. **Central Repository Missing**
   - Ensure `sip-plugin-suite-zips` exists
   - Check directory permissions

### Debug Commands
```bash
# Check Git identity
git config user.name
git config user.email

# View branch status
git branch -vv
git status

# Test Git connectivity
git ls-remote origin

# Check PowerShell
powershell -Command "Get-ExecutionPolicy"
```

## Security Considerations

1. **File Permissions**: Ensure write access to:
   - Plugin directories
   - Log directory
   - Central repository

2. **Git Authentication**: 
   - Never store credentials in code
   - Use Git credential manager
   - Consider SSH keys

3. **Process Security**:
   - Scripts run with web server permissions
   - Validate all inputs
   - Sanitize version numbers

## Best Practices

1. **Before Release**:
   - Pull latest changes
   - Test plugin functionality
   - Review changelog

2. **Version Planning**:
   - MAJOR: Breaking changes
   - MINOR: New features
   - PATCH: Bug fixes

3. **Release Notes**:
   - Update README/changelog
   - Document breaking changes
   - Include migration guides

4. **Post-Release**:
   - Verify ZIP integrity
   - Test auto-update system
   - Monitor error logs

## Code Standards Compliance

When implementing release management features, ensure compliance with SiP standards:

1. **User Notifications**: Use `SiP.Core.utilities.toast` instead of `alert()`
   - ✅ Toast notifications for user feedback
   - ❌ Browser alerts (poor UX and styling)

2. **Modal Dialogs**: Use SiP modal patterns
   - ✅ Custom sip-modal class structure
   - ✅ jQuery UI dialogs with sip-dialog class
   - ❌ Native browser confirm/prompt dialogs

3. **Error Handling**: Provide clear, actionable error messages
   - ✅ Specific error context and recovery steps
   - ✅ Modal dialogs for user choices
   - ❌ Generic error messages