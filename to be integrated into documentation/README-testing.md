# SiP Plugin Release Testing Tools

This directory contains tools for testing and debugging the SiP plugin release process. These tools can help identify and resolve issues with the release script, particularly with the ZIP creation process that has been causing delays.

## Available Testing Tools

1. **test-release-script.ps1** - PowerShell script to test the release-plugin.ps1 script directly
2. **test-zip-creation.php** - PHP script to test the ZIP creation functionality in isolation
3. **debug-zip-creation.php** - Enhanced ZIP creation functions with detailed logging

## Testing the Release Process

### Using test-release-script.ps1

This PowerShell script allows you to run the release-plugin.ps1 script directly from PowerShell, without going through the WordPress admin interface. This makes it easier to debug and test the release process.

#### Usage

1. Open PowerShell
2. Navigate to the work directory:
   ```powershell
   cd "C:\Users\tdeme\Local Sites\faux-stained-glass-panes\app\public\wp-content\plugins\sip-development-tools\work"
   ```
3. Run the script with parameters:
   ```powershell
   .\test-release-script.ps1 -PluginSlug "sip-plugins-core" -NewVersion "2.5.7" -SkipGitChecks $true -TestMode $true
   ```
4. Review the output to see what command would be executed
5. Run without TestMode to actually execute the release process:
   ```powershell
   .\test-release-script.ps1 -PluginSlug "sip-plugins-core" -NewVersion "2.5.7" -SkipGitChecks $true
   ```

#### Parameters

- **PluginSlug** (required): The plugin slug (e.g., "sip-plugins-core")
- **NewVersion** (required): The new version number (e.g., "2.5.7")
- **MainFile**: The main plugin file (defaults to "{PluginSlug}.php")
- **SkipGitChecks**: Skip Git branch and uncommitted changes checks (default: $false)
- **SkipGitPush**: Skip pushing to GitHub (default: $false)
- **DebugZipCreation**: Add extra debugging for ZIP creation (default: $false)
- **LogLevel**: Log level (MINIMAL, NORMAL, VERBOSE) (default: "VERBOSE")
- **TestMode**: Run in test mode without making permanent changes (default: $false)

### Using test-zip-creation.php

This PHP script allows you to test the ZIP creation functionality in isolation, without running the entire release process. This is useful for diagnosing performance issues with the ZIP creation process.

#### Usage

1. From a web browser:
   ```
   http://localhost/wp-content/plugins/sip-development-tools/work/test-zip-creation.php?plugin=sip-plugins-core&version=2.5.7&compression=5
   ```

2. From the command line:
   ```
   php test-zip-creation.php sip-plugins-core 2.5.7 true 5
   ```

#### Parameters

- **plugin**: The plugin slug (e.g., "sip-plugins-core")
- **version**: The version number (e.g., "2.5.7")
- **debug**: Enable debug mode (true/false)
- **compression**: Compression level (1-9, where 1 is fastest and 9 is smallest)

## Diagnosing ZIP Creation Issues

The ZIP creation process in the release script has been observed to take a long time (over 5 minutes) for even small plugins. Here are some potential causes and solutions:

### Potential Causes

1. **High Compression Level**: The default compression level is set to 9 (maximum), which can be very slow for minimal size benefit.
2. **Path Issues**: If there are spaces or special characters in file paths, the 7-Zip command might be struggling.
3. **Plugin Folder Structure**: The script tries to create a nested folder structure that might be causing issues.
4. **Command Execution**: The way the command is executed might be causing delays or timeouts.

### Solutions

1. **Reduce Compression Level**: Use the test-zip-creation.php script with a lower compression level (e.g., 5) to see if it improves performance.
2. **Debug ZIP Creation**: Enable debug mode to get detailed logs of the ZIP creation process.
3. **Check Paths**: Ensure there are no spaces or special characters in file paths.
4. **Modify Command Execution**: The debug-zip-creation.php file includes an improved command execution method with timeout handling.

## Interpreting Debug Logs

When running with debug mode enabled, detailed logs will be created in the work directory. These logs include:

- Timestamps for each step
- Elapsed time measurements
- Command execution details
- File paths and directory contents
- Error messages and warnings

Look for long gaps between timestamps to identify where the process is getting stuck.

## Modifying the Release Process

If you identify issues with the release process, you can modify the following files:

1. **release-plugin.ps1**: The main PowerShell script that handles the release process
2. **release-functions.php**: Contains the PHP functions for creating ZIP files
3. **debug-zip-creation.php**: Contains enhanced ZIP creation functions with better performance

The most common issue is the ZIP creation process taking too long. This can be fixed by:

1. Reducing the compression level from 9 to 5
2. Improving the command execution method
3. Simplifying the folder structure creation

## Example: Testing ZIP Creation with Different Compression Levels

To test how compression level affects ZIP creation time:

```powershell
# Run the PHP script with different compression levels
php test-zip-creation.php sip-plugins-core 2.5.7 true 1
php test-zip-creation.php sip-plugins-core 2.5.7 true 5
php test-zip-creation.php sip-plugins-core 2.5.7 true 9
```

Compare the ZIP creation times and file sizes to find the optimal balance between speed and size.
