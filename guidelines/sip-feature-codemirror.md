# CodeMirror Integration

This feature builds on the [SiP Plugins Platform](./sip-plugin-platform.md) architecture.

Code editor implementation in SiP plugins using CodeMirror v5.65.13.

## Setup

### Loading CodeMirror Assets

```php
// In enqueue_admin_scripts()

// Core CodeMirror library
wp_enqueue_script('codemirror', 
    'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.13/codemirror.min.js', 
    array('jquery'), 
    '5.65.13', 
    true
);
wp_enqueue_style('codemirror', 
    'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.13/codemirror.min.css', 
    array(), 
    '5.65.13'
);

// Required addons for code folding
$addons = ['foldcode', 'foldgutter', 'brace-fold', 'comment-fold'];
foreach ($addons as $addon) {
    wp_enqueue_script(
        "codemirror-addon-{$addon}", 
        "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.13/addon/fold/{$addon}.min.js", 
        ['codemirror'], 
        '5.65.13', 
        true
    );
}
wp_enqueue_style('codemirror-addon-foldgutter-style', 
    'https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.13/addon/fold/foldgutter.min.css', 
    ['codemirror'], 
    '5.65.13'
);

// Syntax modes
$modes = ['xml', 'javascript', 'css', 'htmlmixed'];
foreach ($modes as $mode) {
    wp_enqueue_script(
        "codemirror-mode-{$mode}",
        "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.13/mode/{$mode}/{$mode}.min.js",
        ['codemirror'],
        '5.65.13',
        true
    );
}
```

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

## Checklist

- [ ] Load CodeMirror core library
- [ ] Load required addons (foldcode, foldgutter)
- [ ] Load appropriate syntax modes
- [ ] Initialize with proper configuration
- [ ] Set up change event handlers
- [ ] Implement debouncing for updates
- [ ] Handle JSON validation if applicable
- [ ] Refresh after visibility changes
- [ ] Track dirty state in localStorage