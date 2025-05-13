# Patch for release-plugin.ps1

This file contains the changes needed to fix the issue with the README.md upload in the release-plugin.ps1 script. The issue is that the `$toolsDir` variable is not properly defined when trying to get the API key from the .env file.

## Fix for README.md Upload Issue

In the release-plugin.ps1 file, find the section that handles uploading the README.md file to the update server (around line 1000-1100). It should look something like this:

```powershell
# Upload README.md to update server
Write-LogEntry "Uploading README.md to update server..." "INFO"

# Get API key from .env file
$envFilePath = Join-Path -Path $toolsDir -ChildPath ".env"
$apiKey = Get-ApiKey -KeyName "SIP_UPDATE_API_KEY" -EnvFilePath $envFilePath

if (-not $apiKey) {
    Write-LogEntry "API key not found in .env file. Using default key." "WARNING"
    $apiKey = "SiP-Update-API-Key-2025" # Fallback to default key
}

# Use curl to upload the README.md file
$curlArgs = @(
    "-k",  # Skip SSL verification
    "-X", "POST",
    "-H", "X-API-Key: $apiKey",
    "-F", "action=update_readme",
    "-F", "readme_file=@$readmePath",
    "https://updates.stuffisparts.com/update-api.php"
)

try {
    $result = & curl.exe @curlArgs
    
    # Parse the JSON response
    try {
        $response = $result | ConvertFrom-Json
        if ($response.success) {
            Write-LogEntry "README.md uploaded successfully to update server" "SUCCESS"
        } else {
            Write-LogEntry "Failed to upload README.md: $($response.error)" "ERROR"
        }
    } catch {
        Write-LogEntry "Error parsing response: $_" "ERROR"
        Write-LogEntry "Raw response: $result" "ERROR"
    }
} catch {
    Write-LogEntry "Error uploading README.md: $_" "ERROR"
}
```

Replace it with the following code:

```powershell
# Upload README.md to update server
Write-LogEntry "Uploading README.md to update server..." "INFO"

# Define the tools directory properly
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$toolsDir = $scriptPath  # The script itself is in the tools directory

# Get API key from .env file
$envFilePath = Join-Path -Path $toolsDir -ChildPath ".env"
Write-LogEntry "Looking for .env file at: $envFilePath" "INFO" -Level "LOW"

if (Test-Path $envFilePath) {
    $apiKey = Get-ApiKey -KeyName "SIP_UPDATE_API_KEY" -EnvFilePath $envFilePath
    
    if (-not $apiKey) {
        Write-LogEntry "API key not found in .env file. Using default key." "WARNING"
        $apiKey = "SiP-Update-API-Key-2025" # Fallback to default key
    } else {
        Write-LogEntry "API key found in .env file" "INFO" -Level "LOW"
    }
} else {
    Write-LogEntry ".env file not found at: $envFilePath. Using default key." "WARNING"
    $apiKey = "SiP-Update-API-Key-2025" # Fallback to default key
}

# Verify the README.md file exists
if (-not (Test-Path $readmePath)) {
    Write-LogEntry "README.md file not found at: $readmePath" "ERROR"
    return
}

# Use curl to upload the README.md file
$curlArgs = @(
    "-k",  # Skip SSL verification
    "-X", "POST",
    "-H", "X-API-Key: $apiKey",
    "-F", "action=update_readme",
    "-F", "readme_file=@$readmePath",
    "https://updates.stuffisparts.com/update-api.php"
)

try {
    Write-LogEntry "Executing curl command to upload README.md..." "INFO" -Level "LOW"
    $result = & curl.exe @curlArgs
    
    # Parse the JSON response
    try {
        $response = $result | ConvertFrom-Json
        if ($response.success) {
            Write-LogEntry "README.md uploaded successfully to update server" "SUCCESS"
        } else {
            Write-LogEntry "Failed to upload README.md: $($response.error)" "ERROR"
        }
    } catch {
        Write-LogEntry "Error parsing response: $_" "ERROR"
        Write-LogEntry "Raw response: $result" "ERROR"
    }
} catch {
    Write-LogEntry "Error uploading README.md: $_" "ERROR"
}
```

## Fix for ZIP Creation Performance Issue

The ZIP creation process is taking a long time because it's using the maximum compression level (9). To improve performance, you can modify the compression level to 5, which provides a good balance between compression ratio and speed.

In the release-plugin.ps1 file, find the section that creates the PHP script for ZIP creation (around line 1100-1200). Look for the line that sets the compression level:

```powershell
$command = '"' . $seven_zip_path . '" a -tzip -r -mx=9 "' . $output_zip . '" "' . $plugin_folder . '"';
```

Change it to:

```powershell
$command = '"' . $seven_zip_path . '" a -tzip -r -mx=5 "' . $output_zip . '" "' . $plugin_folder . '"';
```

Do this for both instances of this line in the PHP script (there should be two - one for when the plugin folder exists and one for when it doesn't).

## Additional Improvements

1. **Add Timeout Handling**: The ZIP creation process might be hanging because there's no timeout handling. You can add a timeout to the PHP script to prevent it from hanging indefinitely.

2. **Improve Error Reporting**: Add more detailed error reporting to help diagnose issues with the ZIP creation process.

3. **Use the Improved ZIP Creation Function**: Replace the `sip_create_zip_archive` function in release-functions.php with the improved version provided in improved-zip-creation.php.

4. **Test with Different Compression Levels**: Use the test-zip-creation.php script to test different compression levels and find the optimal balance between speed and size.

## Testing the Changes

After making these changes, you can test them using the test-release-script.ps1 script:

```powershell
.\test-release-script.ps1 -PluginSlug "sip-plugins-core" -NewVersion "2.5.7" -SkipGitChecks $true -DebugZipCreation $true
```

This will run the release process with the changes and provide detailed logging to help diagnose any issues.
