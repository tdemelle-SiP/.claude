# File Browser

This feature builds on the [SiP Plugins Platform](./sip-plugin-platform.md) architecture.

Cross-platform file/directory browser implementation using jsTree.

## Overview

The file browser provides a modal dialog for selecting directories on the server file system. It's built on jsTree and provides secure AJAX-based directory traversal with proper access controls.

## Why This Exists

WordPress plugins often need to interact with the file system beyond the standard WordPress directories. The file browser enables:
- Repository path selection for development tools
- Backup location configuration
- Import/export path selection
- Custom storage location management

## Using the File Browser

The file browser is automatically available when the platform is loaded:

```javascript
// Basic usage
SiP.Core.fileBrowser.browse({
    title: 'Select Directory',
    onSelect: function(path) {
        console.log('Selected:', path);
    }
});
```

### Options

```javascript
SiP.Core.fileBrowser.browse({
    // Dialog title
    title: 'Select Repository Directory',
    
    // Initial directory path (optional)
    startPath: 'C:/Users/username/Documents',
    
    // Root directory to restrict browsing (optional)
    rootPath: '/home/user',
    
    // Callback when directory is selected
    onSelect: function(path) {
        // Handle the selected path
    },
    
    // Callback when dialog is cancelled (optional)
    onCancel: function() {
        // Handle cancellation
    },
    
    // Show files in addition to directories (default: false)
    showFiles: false,
    
    // Dialog dimensions (optional)
    width: '600px',
    height: '400px'
});
```

## Implementation Example

### Adding Repository Path Selection

```javascript
// In your plugin's admin interface
jQuery(document).ready(function($) {
    $('#select-repository-btn').on('click', function(e) {
        e.preventDefault();
        
        // Get current path if any
        const currentPath = $('#repository-path').val();
        
        SiP.Core.fileBrowser.browse({
            title: 'Select Repository Directory',
            startPath: currentPath || '',
            onSelect: function(selectedPath) {
                // Update the input field
                $('#repository-path').val(selectedPath);
                
                // Enable save button
                $('#save-repository-btn').prop('disabled', false);
                
                // Show success message
                SiP.Core.utilities.toast.show('Repository path selected', 3000);
            },
            onCancel: function() {
                SiP.Core.debug.log('Repository selection cancelled');
            }
        });
    });
});
```

### HTML Structure

```html
<div class="repository-selector">
    <label for="repository-path">Repository Path:</label>
    <div class="path-input-group">
        <input type="text" 
               id="repository-path" 
               name="repository_path" 
               readonly 
               placeholder="Click Browse to select...">
        <button type="button" 
                id="select-repository-btn" 
                class="button">
            Browse...
        </button>
    </div>
    <button type="submit" 
            id="save-repository-btn" 
            class="button button-primary" 
            disabled>
        Save Repository
    </button>
</div>
```

## Security Considerations

The file browser includes built-in security measures:

1. **Path Validation**: All paths are validated server-side
2. **Directory Traversal Prevention**: Prevents `../` attacks
3. **Access Control**: Can be restricted to specific root directories
4. **Read-Only**: Only allows directory browsing, no file operations

### Server-Side Validation

Always validate selected paths on the server:

```php
function validate_repository_path($path) {
    // Normalize the path
    $path = wp_normalize_path($path);
    
    // Check if path exists and is readable
    if (!is_dir($path) || !is_readable($path)) {
        return new WP_Error('invalid_path', 'Selected path is not accessible');
    }
    
    // Check for .git directory (for repository validation)
    if (!is_dir($path . '/.git')) {
        return new WP_Error('not_repository', 'Selected path is not a Git repository');
    }
    
    return true;
}
```

## Styling

The file browser uses SiP Core styling with jsTree theme integration:

```css
/* Custom styling for your implementation */
.repository-selector {
    margin: 20px 0;
}

.path-input-group {
    display: flex;
    gap: 10px;
    margin: 10px 0;
}

.path-input-group input {
    flex: 1;
    font-family: monospace;
}
```

## Platform Support

The file browser works across different operating systems:

- **Windows**: Supports drive letters and UNC paths
- **Linux/Mac**: Standard Unix paths
- **Path Normalization**: Automatically handles path separators

## Troubleshooting

### Common Issues

1. **"Access Denied" errors**
   - Ensure the web server has read permissions
   - Check PHP `open_basedir` restrictions

2. **Empty directory listings**
   - Verify directory exists and is readable
   - Check for hidden files (starting with `.`)

3. **Modal not appearing**
   - Ensure platform is loaded: `sip_core_load_platform()`
   - Check browser console for JavaScript errors

### Debug Mode

Enable debug logging to troubleshoot:

```javascript
// Check if file browser is loaded
console.log('File browser available:', typeof SiP.Core.fileBrowser);

// Enable debug logging
SiP.Core.debug.setEnabled(true);
```

## Best Practices

1. **Always validate paths server-side** - Never trust client-side selection alone
2. **Provide clear instructions** - Tell users what type of directory to select
3. **Show current selection** - Display the currently selected path
4. **Handle errors gracefully** - Provide meaningful error messages
5. **Restrict access when possible** - Use `rootPath` to limit browsing scope

## Integration Checklist

- [ ] Call `sip_core_load_platform()` to load file browser
- [ ] Add browse button to UI
- [ ] Implement `onSelect` callback
- [ ] Validate selected path server-side
- [ ] Handle errors and edge cases
- [ ] Test on different operating systems
- [ ] Add appropriate styling