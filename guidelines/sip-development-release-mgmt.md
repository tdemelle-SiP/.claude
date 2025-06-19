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
- **File Browser Component**: Cross-platform directory selector (part of SiP Core platform tools)

## Repository Management

### Overview
The release manager uses a flexible repository registration system that allows management of repositories located anywhere on the file system. This replaces the previous auto-detection system that was limited to the WordPress plugins directory.

### Key Features
- **Manual Repository Addition**: Users explicitly add repositories via UI
- **Flexible Locations**: Supports repositories outside WordPress directory
- **Multiple Types**: Handles both WordPress plugins and browser extensions
- **Persistent Storage**: Repository paths stored in WordPress options
- **Cross-Platform**: Works on Windows, Mac, and Linux

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

### Repository Validation
Minimal validation ensures only essential requirements:
1. **Git Repository**: Directory must contain `.git` folder
2. **Main File**: 
   - Plugins: PHP file with valid WordPress plugin header
   - Extensions: `manifest.json` file
3. **Permissions**: Read/write access to directory
4. **Clear Error Messages**: Specific feedback on validation failures

### UI Elements
- **Add Repository Button**: Located above the release table, right-aligned with title
- **Repository Path Column**: Shows truncated path with full path on hover
- **Edit Path**: Click path to update repository location
- **Remove Repository**: Option to remove from management

## Release Process Workflow

### Pre-Release Checklist
The system automatically checks:
1. Current branch (must be on `develop`)
2. Uncommitted changes (working directory must be clean)
3. Git identity configuration
4. Local/remote branch synchronization

### 16-Step Release Process
The PowerShell script executes these steps:

1. **Safety Checks**: Verify Git branch and uncommitted changes
2. **Update Version**: Update version in main plugin file
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
```php
// Main plugin file header
/**
 * Version: 2.3.0
 */

// Central repository README.md
### sip-plugins-core
- Version: 2.3.0
- File: sip-plugins-core-2.3.0.zip
- Last updated: 2024-03-15 14:30:00
```

## Git Workflow

### Branch Strategy
- **develop**: Active development branch
- **master**: Stable release branch
- Tags: `v2.3.0` format for releases

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
- **Temp Directory**: Uses the WordPress uploads structure for temporary files
- **Compression**: Uses store method (no compression) for faster processing

### Process Flow
1. PowerShell creates a temporary directory structure
2. Copies plugin files (excluding .git, logs, etc.)
3. Calls PHP function to create ZIP using 7-Zip
4. Cleans up temporary files

## Implementation Details

### AJAX Actions
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
            sip_check_uncommitted_changes();
            break;
        case 'check_branch_changes':
            sip_check_branch_changes();
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
- **Wrong Branch**: Must be on `develop` branch
- **Git Identity**: Auto-configured if missing

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

## Implementation Plan: Repository Management System

### Overview
This plan details the steps to transition from the current auto-detection system (limited to WordPress plugins directory) to a flexible repository management system that supports both plugins and extensions located anywhere on the file system.

**CRITICAL**: All implementation MUST strictly follow SiP coding standards and patterns:
- Use SiP AJAX patterns (no custom solutions)
- Follow SiP file structure conventions
- Use SiP Core utilities and components
- Implement using established SiP patterns only
- NO alternative implementations for established structures

### Current State
- Release manager uses `get_plugins()` which only detects plugins in `wp-content/plugins/`
- No support for browser extensions
- No support for repositories outside WordPress directory
- Hardcoded plugin detection in `get_sip_plugins()` method

### Target State
- Manual repository registration via UI (add/remove only, no in-place updates)
- Support for plugins and extensions anywhere on file system
- Persistent storage of repository paths in WordPress options
- Cross-platform file browser for directory selection using SiP Core component
- Handle missing/moved repositories with reconnection capability
- Unified release process for plugins and extensions

### Implementation Steps

#### Step 1: Database Storage Implementation (Following SiP Standards)
**File**: `sip-development-tools/includes/repository-manager.php` (new)

**MUST follow SiP class naming and structure patterns**

```php
<?php
/**
 * Repository Manager Class
 * 
 * Manages repository registration for SiP Development Tools
 * Following SiP coding standards and patterns
 */

// Prevent direct access
if (!defined('ABSPATH')) exit;

class SiP_Repository_Manager {
    private static $option_name = 'sip_development_tools_repositories';
    
    /**
     * Get all registered repositories with status check
     * @return array Repository configurations with status
     */
    public static function get_repositories() {
        $repositories = get_option(self::$option_name, array());
        
        // Check status of each repository
        foreach ($repositories as &$repo) {
            $repo['status'] = self::check_repository_status($repo['path']);
        }
        
        return $repositories;
    }
    
    /**
     * Check if repository path exists and is valid
     * @param string $path Repository path
     * @return string Status: 'active', 'missing', or 'invalid'
     */
    private static function check_repository_status($path) {
        if (!is_dir($path)) {
            return 'missing';
        }
        if (!is_dir($path . '/.git')) {
            return 'invalid';
        }
        return 'active';
    }
    
    /**
     * Add a new repository (NO UPDATE METHOD - add/remove only)
     * @param string $path Repository path
     * @return array Result with success status and message
     */
    public static function add_repository($path) {
        $repositories = get_option(self::$option_name, array());
        
        // Validate repository
        $validation = self::validate_repository($path);
        if ($validation !== true) {
            return array(
                'success' => false,
                'message' => $validation
            );
        }
        
        // Check for duplicates
        foreach ($repositories as $existing) {
            if ($existing['path'] === $path) {
                return array(
                    'success' => false,
                    'message' => 'Repository already registered'
                );
            }
        }
        
        // Extract repository information
        $repository = self::extract_repository_info($path);
        
        $repositories[] = $repository;
        update_option(self::$option_name, $repositories);
        
        return array(
            'success' => true,
            'message' => 'Repository added successfully',
            'repository' => $repository
        );
    }
    
    /**
     * Remove repository by ID
     * @param string $id Repository ID (path-based)
     * @return array Result with success status and message
     */
    public static function remove_repository($id) {
        $repositories = get_option(self::$option_name, array());
        $found = false;
        
        foreach ($repositories as $index => $repo) {
            if (md5($repo['path']) === $id) {
                array_splice($repositories, $index, 1);
                $found = true;
                break;
            }
        }
        
        if (!$found) {
            return array(
                'success' => false,
                'message' => 'Repository not found'
            );
        }
        
        update_option(self::$option_name, $repositories);
        
        return array(
            'success' => true,
            'message' => 'Repository removed successfully'
        );
    }
    
    /**
     * Reconnect a missing repository to a new path
     * @param string $old_id Original repository ID
     * @param string $new_path New repository path
     * @return array Result with success status and message
     */
    public static function reconnect_repository($old_id, $new_path) {
        // First remove the old entry
        $remove_result = self::remove_repository($old_id);
        if (!$remove_result['success']) {
            return $remove_result;
        }
        
        // Then add the new path
        return self::add_repository($new_path);
    }
    
    /**
     * Validate repository path
     * @param string $path Repository path to validate
     * @return bool|string True if valid, error message if not
     */
    public static function validate_repository($path) {
        // Check if path exists
        if (!is_dir($path)) {
            return 'Repository path does not exist';
        }
        
        // Check for .git directory
        if (!is_dir($path . '/.git')) {
            return 'Not a git repository (no .git directory found)';
        }
        
        // Determine type and validate accordingly
        $type = self::detect_repository_type($path);
        
        if ($type === 'plugin') {
            // Look for PHP file with plugin header
            $plugin_file_found = false;
            $files = glob($path . '/*.php');
            foreach ($files as $file) {
                $content = file_get_contents($file, false, null, 0, 8192);
                if (strpos($content, 'Plugin Name:') !== false) {
                    $plugin_file_found = true;
                    break;
                }
            }
            if (!$plugin_file_found) {
                return 'No valid WordPress plugin file found';
            }
        } elseif ($type === 'extension') {
            // Check for manifest.json
            if (!file_exists($path . '/manifest.json')) {
                return 'No manifest.json file found';
            }
        } else {
            return 'Unable to determine repository type';
        }
        
        return true;
    }
    
    /**
     * Detect repository type based on files
     * @param string $path Repository path
     * @return string 'plugin', 'extension', or 'unknown'
     */
    private static function detect_repository_type($path) {
        // Check for manifest.json (extension)
        if (file_exists($path . '/manifest.json')) {
            return 'extension';
        }
        
        // Check for WordPress plugin header
        $files = glob($path . '/*.php');
        foreach ($files as $file) {
            $content = file_get_contents($file, false, null, 0, 8192);
            if (strpos($content, 'Plugin Name:') !== false) {
                return 'plugin';
            }
        }
        
        return 'unknown';
    }
    
    /**
     * Extract repository information from path
     * @param string $path Repository path
     * @return array Repository configuration
     */
    private static function extract_repository_info($path) {
        $type = self::detect_repository_type($path);
        $repository = array(
            'path' => $path,
            'type' => $type,
            'slug' => basename($path)
        );
        
        if ($type === 'plugin') {
            // Find main plugin file
            $files = glob($path . '/*.php');
            foreach ($files as $file) {
                $content = file_get_contents($file, false, null, 0, 8192);
                if (strpos($content, 'Plugin Name:') !== false) {
                    $repository['main_file'] = basename($file);
                    $plugin_data = get_plugin_data($file);
                    $repository['name'] = $plugin_data['Name'];
                    $repository['version'] = $plugin_data['Version'];
                    break;
                }
            }
        } elseif ($type === 'extension') {
            $repository['main_file'] = 'manifest.json';
            $manifest = json_decode(file_get_contents($path . '/manifest.json'), true);
            $repository['name'] = $manifest['name'];
            $repository['version'] = $manifest['version'];
        }
        
        return $repository;
    }
    
    /**
     * Get repository details including git status
     * @param array $repository Repository configuration
     * @return array Repository with additional status information
     */
    public static function get_repository_status($repository) {
        // Add git status information
        $repository['branch'] = self::get_current_branch($repository['path']);
        $repository['has_changes'] = self::has_uncommitted_changes($repository['path']);
        $repository['ahead_behind'] = self::get_ahead_behind_status($repository['path']);
        
        return $repository;
    }
    
    // Git helper methods would go here...
}
```

**Action**: Include this file in `sip-development-tools.php`:
```php
require_once plugin_dir_path(__FILE__) . 'includes/repository-manager.php';
```

#### Step 2: AJAX Handlers for Repository Management
**File**: `sip-development-tools/includes/release-functions.php` (update)

Add new AJAX action handlers:
```php
// Add to existing AJAX setup
add_action('wp_ajax_sip_repository_action', 'sip_handle_repository_action');

/**
 * Handle repository management actions
 */
function sip_handle_repository_action() {
    // Verify nonce
    if (!isset($_POST['nonce']) || !wp_verify_nonce($_POST['nonce'], 'sip_admin_nonce')) {
        SiP_AJAX_Response::error('Invalid nonce');
        return;
    }
    
    $action = isset($_POST['repository_action']) ? sanitize_text_field($_POST['repository_action']) : '';
    
    switch ($action) {
        case 'add':
            sip_add_repository();
            break;
        case 'update':
            sip_update_repository();
            break;
        case 'remove':
            sip_remove_repository();
            break;
        case 'validate':
            sip_validate_repository();
            break;
        case 'browse':
            sip_browse_directories();
            break;
        default:
            SiP_AJAX_Response::error('Invalid repository action');
    }
}

/**
 * Add a new repository
 */
function sip_add_repository() {
    $path = isset($_POST['path']) ? sanitize_text_field($_POST['path']) : '';
    $type = isset($_POST['type']) ? sanitize_text_field($_POST['type']) : 'plugin';
    
    $repository = array(
        'path' => $path,
        'type' => $type
    );
    
    // Validate and enrich repository data
    $validated = SiP_Repository_Manager::validate_repository($repository);
    
    if (is_array($validated) && !isset($validated['path'])) {
        // Validation returned errors
        SiP_AJAX_Response::error('Validation failed', array('errors' => $validated));
        return;
    }
    
    // Add repository
    if (SiP_Repository_Manager::add_repository($validated)) {
        SiP_AJAX_Response::success('Repository added successfully', array(
            'repository' => $validated
        ));
    } else {
        SiP_AJAX_Response::error('Failed to add repository');
    }
}

// Similar implementations for update, remove, validate...
```

#### Step 3: JavaScript Module for Repository Management
**File**: `sip-development-tools/assets/js/modules/repository-manager.js` (new)

```javascript
var SiP = SiP || {};
SiP.DevTools = SiP.DevTools || {};

SiP.DevTools.repositoryManager = (function($) {
    const PLUGIN_ID = 'sip-development-tools';
    
    function init() {
        attachEventListeners();
        
        // Register success handler
        SiP.Core.ajax.registerSuccessHandler(PLUGIN_ID, 'repository_action', handleRepositoryResponse);
    }
    
    function attachEventListeners() {
        // Add repository button
        $(document).on('click', '#add-repository', handleAddRepository);
        
        // Repository path click (edit)
        $(document).on('click', '.repository-path', handleEditPath);
        
        // Remove repository
        $(document).on('click', '.remove-repository', handleRemoveRepository);
        
        // Type toggle for add dialog
        $(document).on('change', '#repository-type', handleTypeChange);
    }
    
    function handleAddRepository(e) {
        e.preventDefault();
        
        // Show file browser or input dialog
        showRepositoryDialog('add');
    }
    
    function showRepositoryDialog(mode, repository) {
        // Create modal dialog
        var dialogHtml = `
            <div id="repository-dialog" class="sip-modal">
                <div class="sip-modal-content">
                    <div class="sip-modal-header">
                        <span class="sip-modal-close">&times;</span>
                        <h2>${mode === 'add' ? 'Add Repository' : 'Edit Repository'}</h2>
                    </div>
                    <div class="sip-modal-body">
                        <div class="form-field">
                            <label for="repository-type">Type:</label>
                            <select id="repository-type" ${mode === 'edit' ? 'disabled' : ''}>
                                <option value="plugin">WordPress Plugin</option>
                                <option value="extension">Browser Extension</option>
                            </select>
                        </div>
                        <div class="form-field">
                            <label for="repository-path">Path:</label>
                            <div class="path-input-group">
                                <input type="text" id="repository-path" 
                                       value="${repository ? repository.path : ''}" 
                                       placeholder="C:/path/to/repository">
                                <button id="browse-path" class="button">Browse...</button>
                            </div>
                        </div>
                        <div id="validation-messages" class="notice notice-error" style="display:none;"></div>
                    </div>
                    <div class="sip-modal-footer">
                        <button id="save-repository" class="button button-primary">Save</button>
                        <button id="cancel-repository" class="button">Cancel</button>
                    </div>
                </div>
            </div>
        `;
        
        // Add dialog to page
        $('body').append(dialogHtml);
        $('#repository-dialog').show();
        
        // Attach dialog event handlers
        attachDialogHandlers(mode, repository);
    }
    
    function attachDialogHandlers(mode, repository) {
        // Browse button
        $('#browse-path').on('click', function(e) {
            e.preventDefault();
            browseForRepository();
        });
        
        // Save button
        $('#save-repository').on('click', function(e) {
            e.preventDefault();
            saveRepository(mode, repository);
        });
        
        // Cancel/close
        $('#cancel-repository, .sip-modal-close').on('click', function(e) {
            e.preventDefault();
            $('#repository-dialog').remove();
        });
        
        // Path change validation
        $('#repository-path').on('change', validatePath);
    }
    
    function browseForRepository() {
        // Use SiP Core file browser when available
        // For now, fallback to manual input
        var currentPath = $('#repository-path').val();
        
        SiP.Core.ajax.post({
            plugin_id: PLUGIN_ID,
            ajax_action: 'repository_action',
            repository_action: 'browse',
            current_path: currentPath
        }, function(response) {
            if (response.path) {
                $('#repository-path').val(response.path).trigger('change');
            }
        });
    }
    
    function validatePath() {
        var path = $('#repository-path').val();
        var type = $('#repository-type').val();
        
        if (!path) return;
        
        SiP.Core.ajax.post({
            plugin_id: PLUGIN_ID,
            ajax_action: 'repository_action',
            repository_action: 'validate',
            path: path,
            type: type
        }, function(response) {
            if (response.errors) {
                showValidationErrors(response.errors);
            } else {
                hideValidationErrors();
            }
        });
    }
    
    function saveRepository(mode, originalRepository) {
        var path = $('#repository-path').val();
        var type = $('#repository-type').val();
        
        var data = {
            plugin_id: PLUGIN_ID,
            ajax_action: 'repository_action',
            repository_action: mode,
            path: path,
            type: type
        };
        
        if (mode === 'update' && originalRepository) {
            data.index = originalRepository.index;
        }
        
        SiP.Core.ajax.post(data, function(response) {
            if (response.success) {
                $('#repository-dialog').remove();
                // Reload the release management table
                location.reload();
            }
        });
    }
    
    function handleRepositoryResponse(response, requestData) {
        // Handle various repository action responses
        console.log('Repository action response:', response);
    }
    
    return {
        init: init
    };
})(jQuery);

// Initialize when ready
jQuery(document).ready(function() {
    SiP.DevTools.repositoryManager.init();
});
```

**Action**: 
1. Create this new JavaScript file
2. Enqueue it in `sip-development-tools.php`:
```php
wp_enqueue_script(
    'sip-dev-tools-repository-manager', 
    plugin_dir_url(__FILE__) . 'assets/js/modules/repository-manager.js', 
    array('jquery', 'sip-core-ajax'), 
    filemtime(plugin_dir_path(__FILE__) . 'assets/js/modules/repository-manager.js'), 
    true
);
```

#### Step 4: Update UI to Add Repository Management
**File**: `sip-development-tools.php` (update `render_dashboard` method)

Replace the existing plugin table header with:
```php
<!-- Plugin Release Management Section -->
<div class="release-management-header">
    <h2>Plugin Release Management</h2>
    <button id="add-repository" class="button button-primary">Add Repository</button>
</div>
```

Update the table to show repository path:
```php
<th class="column-plugin">Plugin</th>
<th class="column-path">Repository Path</th>
<th class="column-version">Current Version</th>
```

Add repository path column:
```php
<td class="column-path">
    <span class="repository-path" data-index="<?php echo $index; ?>" 
          title="<?php echo esc_attr($repository['path']); ?>">
        <?php echo esc_html($this->truncate_path($repository['path'], 40)); ?>
    </span>
</td>
```

#### Step 5: Update get_sip_plugins to Use Repository Manager
**File**: `sip-development-tools.php` (replace `get_sip_plugins` method)

```php
private function get_sip_plugins() {
    $repositories = SiP_Repository_Manager::get_repositories();
    $sip_plugins = array();
    
    // Get release dates from README.md
    $release_dates = $this->get_release_dates_from_readme();
    
    foreach ($repositories as $index => $repository) {
        // Get current status
        $repository = SiP_Repository_Manager::get_repository_status($repository);
        $repository['index'] = $index;
        
        // Add release date if available
        if (isset($release_dates[$repository['slug']])) {
            $repository['release_date'] = $release_dates[$repository['slug']]['date'];
            // If README version is different, use README version
            if (isset($release_dates[$repository['slug']]['version']) && 
                version_compare($release_dates[$repository['slug']]['version'], $repository['version'], '>=')) {
                $repository['version'] = $release_dates[$repository['slug']]['version'];
            }
        }
        
        $sip_plugins[] = $repository;
    }
    
    return $sip_plugins;
}

/**
 * Truncate path for display
 */
private function truncate_path($path, $max_length = 40) {
    if (strlen($path) <= $max_length) {
        return $path;
    }
    
    // Try to intelligently truncate
    $parts = explode('/', str_replace('\\', '/', $path));
    $filename = array_pop($parts);
    
    if (strlen($filename) >= $max_length - 3) {
        return '...' . substr($filename, -(max_length - 3));
    }
    
    $remaining = $max_length - strlen($filename) - 4; // 4 for '.../'
    $start = substr($path, 0, $remaining);
    
    return $start . '.../' . $filename;
}
```

#### Step 6: Create PowerShell Script for Extensions
**File**: `sip-development-tools/tools/release-extension.ps1` (already created)

This was already implemented in the conversation. The script follows the same pattern as `release-plugin.ps1` but:
- Works with `manifest.json` instead of PHP files
- Creates packages in `extensions/` subdirectory
- Adds 'v' prefix to version tags
- Updates Chrome Web Store ID in README

#### Step 7: Update Release Functions to Support Extensions
**File**: `sip-development-tools/includes/release-functions.php` (update)

Modify `sip_create_release()` to handle both plugins and extensions:
```php
function sip_create_release() {
    // ... existing validation ...
    
    // Get repository details
    $repositories = SiP_Repository_Manager::get_repositories();
    $repository = null;
    
    foreach ($repositories as $repo) {
        if ($repo['slug'] === $plugin_slug) {
            $repository = $repo;
            break;
        }
    }
    
    if (!$repository) {
        SiP_AJAX_Response::error('Repository not found');
        return;
    }
    
    // Determine script to use
    $script_name = $repository['type'] === 'extension' ? 'release-extension.ps1' : 'release-plugin.ps1';
    $ps_script = plugin_dir_path(dirname(__FILE__)) . 'tools/' . $script_name;
    
    // ... rest of the function remains similar ...
}
```

#### Step 8: Add CSS for Repository Management UI
**File**: `sip-development-tools/assets/css/release-actions.css` (update)

```css
/* Repository Management Header */
.release-management-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1em;
}

.release-management-header h2 {
    margin: 0;
}

/* Repository Path Column */
.column-path {
    max-width: 300px;
}

.repository-path {
    cursor: pointer;
    text-decoration: underline;
    color: #0073aa;
    display: inline-block;
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.repository-path:hover {
    color: #005a87;
}

/* Repository Dialog */
#repository-dialog .path-input-group {
    display: flex;
    gap: 10px;
}

#repository-dialog #repository-path {
    flex: 1;
}

#repository-dialog .form-field {
    margin-bottom: 15px;
}

#repository-dialog label {
    display: block;
    margin-bottom: 5px;
    font-weight: 600;
}
```

#### Step 9: Migration Script for Existing Installations
**File**: `sip-development-tools/includes/migration.php` (new)

```php
/**
 * Migrate existing plugins to repository manager
 */
function sip_migrate_to_repository_manager() {
    // Check if migration has been run
    if (get_option('sip_repository_migration_complete', false)) {
        return;
    }
    
    // Get existing SiP plugins
    $all_plugins = get_plugins();
    $repositories = array();
    
    foreach ($all_plugins as $plugin_file => $plugin_data) {
        if (strpos($plugin_file, 'sip-') === 0 || strpos($plugin_data['Name'], 'SiP ') === 0) {
            $plugin_slug = dirname($plugin_file);
            if (empty($plugin_slug)) {
                $plugin_slug = basename($plugin_file, '.php');
            }
            
            $repository = array(
                'path' => WP_PLUGIN_DIR . '/' . $plugin_slug,
                'type' => 'plugin',
                'name' => $plugin_data['Name'],
                'slug' => $plugin_slug,
                'main_file' => basename($plugin_file),
                'version' => $plugin_data['Version']
            );
            
            $repositories[] = $repository;
        }
    }
    
    // Save repositories
    if (!empty($repositories)) {
        update_option('sip_development_tools_repositories', $repositories);
    }
    
    // Mark migration complete
    update_option('sip_repository_migration_complete', true);
}

// Run migration on plugin activation or admin init
add_action('admin_init', 'sip_migrate_to_repository_manager');
```

**Action**: 
1. Create this migration file
2. Include it in `sip-development-tools.php`

#### Step 10: SiP Core File Browser Integration
**Note**: This requires coordination with SiP Core team to add a cross-platform file browser component.

**Specification for SiP Core**:
```javascript
// API for file browser component
SiP.Core.fileBrowser = {
    /**
     * Open a directory browser dialog
     * @param {Object} options Browser options
     * @param {string} options.title - Dialog title
     * @param {string} options.startPath - Initial directory path
     * @param {string} options.mode - 'directory' or 'file'
     * @param {Function} options.onSelect - Callback with selected path
     */
    browse: function(options) {
        // Implementation would use native OS file dialogs where possible
        // or provide a server-side directory tree browser
    }
};
```

### Testing Plan

1. **Migration Testing**
   - Verify existing plugins are auto-migrated to repository system
   - Check that all plugin data is preserved

2. **Repository Management**
   - Test adding plugin repositories
   - Test adding extension repositories
   - Verify path validation works correctly
   - Test editing repository paths
   - Test removing repositories

3. **Release Process**
   - Test plugin releases work as before
   - Test extension releases use correct script
   - Verify README updates include extensions
   - Check central repository structure

4. **UI/UX Testing**
   - Verify Add Repository button placement
   - Test modal dialogs work correctly
   - Check path truncation displays properly
   - Test repository path editing

### Rollback Plan

If issues arise:
1. The old `get_sip_plugins()` code is preserved in git history
2. Repository data is stored separately from existing plugin detection
3. Migration can be reversed by clearing the option and removing migration flag

### Future Enhancements

1. **Bulk Import**: Add ability to scan a directory for multiple repositories
2. **Repository Templates**: Pre-configured settings for common repository types
3. **Remote Repositories**: Support for managing repositories on remote servers
4. **Repository Health Checks**: Automated validation of repository state
5. **Integration with CI/CD**: Hooks for automated testing before release