# CodeMirror Integration

This feature builds on the [SiP Plugins Platform](./sip-core-platform.md) architecture.

Code editor implementation in SiP plugins using CodeMirror v5.65.13.

## Overview

CodeMirror is included in the SiP Plugins Core platform and is automatically available to all SiP plugins. The core platform includes:
- CodeMirror core (v5.65.13)
- Code folding addons
- Common syntax modes (XML, JavaScript, CSS, HTMLMixed)

## Using CodeMirror in Your Plugin

Since CodeMirror is already loaded by the SiP Core platform, you don't need to enqueue it separately. Simply ensure the platform is loaded:

```php
// In your plugin's enqueue_admin_scripts()
// The platform loader already includes CodeMirror
sip_core_load_platform();

// All CodeMirror resources are now loaded!
// No additional enqueuing needed
```

### Available Resources

The following CodeMirror resources are automatically available:

**Core:**
- `codemirror` - Main CodeMirror script and styles

**Addons:**
- `codemirror-addon-foldcode` - Code folding functionality
- `codemirror-addon-foldgutter` - Fold gutter UI
- `codemirror-addon-brace-fold` - Brace folding
- `codemirror-addon-comment-fold` - Comment folding

**Syntax Modes:**
- `codemirror-mode-xml` - XML syntax
- `codemirror-mode-javascript` - JavaScript syntax
- `codemirror-mode-css` - CSS syntax
- `codemirror-mode-htmlmixed` - HTML mixed mode

## Migration from Plugin-Bundled to Platform CodeMirror

If your plugin previously bundled CodeMirror locally or loaded it from CDN, follow these steps:

1. **Remove all CodeMirror enqueue calls** from your plugin
2. **Delete any local CodeMirror files** from your plugin's assets
3. **Ensure `sip_core_load_platform()` is called** - this loads CodeMirror automatically
4. **Update handle names** if you used custom handles (now use standard handles listed above)

### Important Notes

1. **No Double Loading**: Do NOT enqueue CodeMirror again in your plugin - it's already loaded
2. **Handle Names**: Use the standard handle names (e.g., 'codemirror', 'codemirror-mode-javascript')
3. **Version**: The platform provides v5.65.13 - ensure your code is compatible
4. **Dependencies**: All modes depend on 'codemirror', htmlmixed depends on xml, javascript, and css modes

## Implementation

### Basic Editor Initialization

```javascript
// JSON Editor
const jsonEditor = CodeMirror(document.getElementById('json-editor-bottom-editor'), {
    mode: 'application/json',
    lineNumbers: true,
    lineWrapping: true,
    dragDrop: false,
    viewportMargin: Infinity,
    foldGutter: true,
    gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
    extraKeys: {
        "Ctrl-Q": function(cm) {
            cm.foldCode(cm.getCursor());
        }
    }
});

// HTML Editor
const descriptionEditor = CodeMirror(document.getElementById('json-editor-top-editor'), {
    mode: 'htmlmixed',
    lineNumbers: true,
    lineWrapping: true,
    dragDrop: false,
    viewportMargin: Infinity,
    foldGutter: true,
    gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"]
});
```

### Event Handling

```javascript
// Single change handler for both editors
jsonEditor.on('change', handleEditorChange);
descriptionEditor.on('change', handleEditorChange);

function handleEditorChange() {
    jsonEditorIsDirty = true;
    const state = JSON.parse(localStorage.getItem('sip-core')) || {};
    if (!state['sip-printify-manager']) state['sip-printify-manager'] = {};
    state['sip-printify-manager']['template-json-editor'].isDirty = true;
    localStorage.setItem('sip-core', JSON.stringify(state));
    pushButton.addClass('has-changes');
    debouncedUpdateContent();
}
```

### Debouncing Updates

```javascript
const debounce = (func, wait) => {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
};

const debouncedUpdateContent = debounce(updateEditorState, 300);
```

## Editor Operations

### Getting/Setting Values

```javascript
// Get value
const content = jsonEditor.getValue();

// Set value
jsonEditor.setValue(JSON.stringify(data, null, 2));

// Clear content
jsonEditor.setValue('');
```

### Refreshing Editor

```javascript
// Important after changing visibility or container size
descriptionEditor.refresh();
jsonEditor.refresh();
```

### Focus Management

```javascript
// Set focus
jsonEditor.focus();

// Set cursor position
jsonEditor.setCursor(0, 0);
```

## Configuration Options

### Mode Options
- `application/json` - JSON syntax highlighting
- `htmlmixed` - HTML/CSS/JS mixed mode
- `javascript` - JavaScript syntax
- `css` - CSS syntax
- `xml` - XML syntax

### Standard Options
```javascript
{
    lineNumbers: true,          // Show line numbers
    lineWrapping: true,         // Wrap long lines
    dragDrop: false,           // Disable drag/drop
    viewportMargin: Infinity,   // Render all lines
    foldGutter: true,          // Enable code folding
    gutters: [                 // Gutter areas
        "CodeMirror-linenumbers", 
        "CodeMirror-foldgutter"
    ]
}
```

## JSON Editor Implementation

### Structure
```html
<div id="json-editor-container">
    <div id="json-editor-top-editor"></div>
    <div id="json-editor-bottom-editor"></div>
    <button id="json-editor-push-btn">Push Changes</button>
</div>
```

### Save Handler
```javascript
async function handleJsonEditorPush() {
    if (!jsonEditorIsDirty) {
        SiP.Core.utilities.toast.show('No changes to save', 2000);
        return;
    }
    
    const description = descriptionEditor.getValue();
    const jsonContent = jsonEditor.getValue();
    
    try {
        const parsedJson = JSON.parse(jsonContent);
        parsedJson.description = description;
        
        const formData = SiP.Core.utilities.createFormData(
            'sip-printify-manager',
            'json_editor_action',
            'save_changes'
        );
        formData.append('content', JSON.stringify(parsedJson));
        
        await SiP.Core.ajax.handleAjaxAction(
            'sip-printify-manager',
            'json_editor_action',
            formData
        );
        
        resetUnsavedChangesFlags();
        SiP.Core.utilities.toast.show('Changes saved', 3000);
        
    } catch (error) {
        SiP.Core.utilities.toast.show('Invalid JSON: ' + error.message, 5000);
    }
}
```

### State Management
```javascript
function resetUnsavedChangesFlags() {
    jsonEditorIsDirty = false;
    const state = JSON.parse(localStorage.getItem('sip-core')) || {};
    if (state['sip-printify-manager']?.['template-json-editor']) {
        state['sip-printify-manager']['template-json-editor'].isDirty = false;
        localStorage.setItem('sip-core', JSON.stringify(state));
    }
    pushButton.removeClass('has-changes');
}
```

## Styling

### CSS Classes
```css
/* Container styling */
.json-editor-wrapper {
    border: 1px solid #ccc;
    border-radius: 3px;
}

/* Button state */
.has-changes {
    background-color: #f0b849;
    color: #000;
}

/* CodeMirror overrides */
.CodeMirror {
    height: 300px;
    font-family: monospace;
}
```

## Best Practices

1. **Always refresh after visibility changes**
```javascript
$('#editor-container').show();
editor.refresh();
```

2. **Debounce change handlers**
```javascript
const debouncedSave = debounce(saveContent, 300);
editor.on('change', debouncedSave);
```

3. **Handle JSON validation**
```javascript
try {
    JSON.parse(editor.getValue());
} catch (e) {
    // Show error
}
```

4. **Clean up on close**
```javascript
// Remove event listeners
editor.off('change', handler);
```

## Troubleshooting

### Common Issues After Migration

1. **"CodeMirror is not defined" error**
   - **Cause**: Your script runs before CodeMirror is loaded
   - **Solution**: Ensure your script depends on 'codemirror' or runs after document ready
   ```javascript
   jQuery(document).ready(function($) {
       // CodeMirror is now available
       const editor = CodeMirror(...);
   });
   ```

2. **Syntax highlighting not working**
   - **Cause**: Mode not loaded or incorrect mode name
   - **Solution**: Check that the required mode is loaded by the platform
   - **Available modes**: xml, javascript, css, htmlmixed

3. **Code folding not working**
   - **Cause**: Fold gutter not properly initialized
   - **Solution**: Ensure you include gutters in configuration:
   ```javascript
   gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"]
   ```

4. **Double loading warning in console**
   - **Cause**: Plugin still enqueuing CodeMirror
   - **Solution**: Remove all wp_enqueue_script/style calls for CodeMirror from your plugin

5. **Styles look different**
   - **Cause**: Custom theme or CSS overrides
   - **Solution**: Platform loads default CodeMirror theme - add custom styles if needed

### Checking Platform Loading

To verify CodeMirror is loaded by the platform:

```javascript
// In browser console
console.log('CodeMirror loaded:', typeof CodeMirror);
console.log('CodeMirror version:', CodeMirror.version);
```

### Adding Additional Modes

If you need syntax modes not included in the platform:

1. **DO NOT** load them from CDN
2. **DO NOT** bundle the entire CodeMirror library
3. **DO** download only the specific mode file to your plugin
4. **DO** enqueue it with 'codemirror' as dependency

Example:
```php
// For Python mode (not in platform)
wp_enqueue_script('my-plugin-codemirror-python',
    plugin_dir_url(__FILE__) . 'assets/js/codemirror-python.min.js',
    ['codemirror'],
    '5.65.13',
    true
);
```

## Checklist

### For New Implementations
- [ ] Call `sip_core_load_platform()` in enqueue_admin_scripts
- [ ] Initialize CodeMirror after document ready
- [ ] Use correct mode names (application/json, htmlmixed, etc.)
- [ ] Add proper gutters configuration for folding
- [ ] Implement change handlers with debouncing
- [ ] Handle JSON validation if applicable
- [ ] Refresh after visibility changes

### For Migration from Plugin-Bundled
- [ ] Remove all CodeMirror wp_enqueue calls
- [ ] Delete local CodeMirror files from plugin
- [ ] Update script dependencies if needed
- [ ] Test all editor functionality
- [ ] Verify no console errors
- [ ] Check syntax highlighting works
- [ ] Confirm code folding works