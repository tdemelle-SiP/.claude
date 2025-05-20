# Modals and Toast Notifications

For dashboard integration examples, see the [Dashboards Guide](./sip-plugin-dashboards.md#step-6-add-modal-dialogs).

Quick reference for dialog and notification patterns in SiP plugins.

## jQuery UI Dialog

### Basic Modal
```javascript
const $dialog = $('<div>Content</div>').dialog({
    modal: true,
    width: 400,
    title: 'Dialog Title',
    dialogClass: 'sip-dialog',
    buttons: {
        'OK': function() { $(this).dialog('close'); },
        'Cancel': function() { $(this).dialog('close'); }
    },
    close: function() { $(this).dialog('destroy').remove(); }
});
```

### Standard Classes
- `sip-dialog` - Base class (required)
- `progress-dialog` - For progress dialogs
- `log-dialog` - For log viewers

## Progress Dialog Pattern

For complete progress dialog implementation, see the [Progress Dialog Guide](./sip-feature-progress-dialog.md).

### Structure
```javascript
const dialogContent = `
    <div class="sip-dialog progress-dialog">
        <div class="initial-message">
            <p>Ready to proceed?</p>
            <div class="dialog-buttons">
                <button class="continue-button">Continue</button>
                <button class="cancel-button">Cancel</button>
            </div>
        </div>
        <div class="progress-content" style="display: none;">
            <div class="progress-bar">
                <div class="progress-fill" style="width: 0%"></div>
            </div>
            <div class="current-step">Starting...</div>
            <div class="status-log"></div>
        </div>
    </div>
`;
```

### Controller Pattern
```javascript
function createProgressDialog() {
    const $dialog = $(dialogContent).dialog({
        modal: false,
        width: 600,
        dialogClass: 'sip-dialog progress-dialog',
        closeOnEscape: false
    });
    
    const controller = {
        onContinue: (callback) => { /* store callback */ },
        onCancel: (callback) => { /* store callback */ },
        startProcess: () => {
            $dialog.find('.initial-message').hide();
            $dialog.find('.progress-content').show();
        },
        updateProgress: (percent) => {
            $dialog.find('.progress-fill').css('width', `${percent}%`);
        },
        updateStatus: (message) => {
            $dialog.find('.current-step').text(message);
            $dialog.find('.status-log').append(`<div>${message}</div>`);
        },
        showError: (message) => {
            $dialog.find('.status-log').append(
                `<div class="error-message">${message}</div>`
            );
        },
        close: () => $dialog.dialog('destroy').remove()
    };
    
    return controller;
}
```

## Toast Notifications

### Basic Usage
```javascript
// Success (3 seconds)
SiP.Core.utilities.toast.show('Operation completed', 3000);

// Error (5 seconds)
SiP.Core.utilities.toast.show('Error: ' + error.message, 5000);

// Info (default duration)
SiP.Core.utilities.toast.show('Processing...');
```

### Implementation Pattern
- Queues messages if multiple are shown
- Displays one at a time
- Located in `SiP.Core.utilities`

## Common Patterns

### Confirmation Dialog
```javascript
const $dialog = $('<div>Are you sure?</div>').dialog({
    modal: true,
    title: 'Confirm',
    dialogClass: 'sip-dialog',
    buttons: {
        'Yes': function() {
            performAction();
            $(this).dialog('close');
        },
        'No': function() {
            $(this).dialog('close');
        }
    }
});
```

### Save Dialog with Options
```javascript
const content = `
    <div class="sip-dialog">
        <p>Save changes?</p>
        <div class="dialog-buttons">
            <button class="push-close">Save & Close</button>
            <div class="button-group">
                <button class="save-button">Save</button>
                <button class="cancel-button">Cancel</button>
            </div>
        </div>
    </div>
`;

const $dialog = $(content).dialog({
    modal: true,
    dialogClass: 'sip-dialog',
    create: function() {
        $(this).find('.save-button').on('click', () => {
            save();
            $dialog.dialog('close');
        });
    }
});
```

## Key CSS

### Dialog Z-Index
```css
:root {
    --z-overlay: 9998;
    --z-spinner: 9999;
    --z-dialog: 10000;
    --z-toast: 10001;
}
```

### Toast Container
```css
#toast-container {
    position: fixed;
    top: 35%;
    left: 50%;
    transform: translate(-50%, -50%);
    z-index: var(--z-toast);
}
```

## Required Actions

### Always Clean Up Dialogs
```javascript
close: function() {
    $(this).dialog('destroy').remove();
}
```

### Use Custom Overlay
```javascript
$('#overlay').show();  // Instead of jQuery UI modal overlay
```

### Error Handling
```javascript
dialog.showError(error.message);
SiP.Core.utilities.toast.show('Error: ' + error.message, 5000);
```

## Checklist

- [ ] Use `sip-dialog` class on all dialogs
- [ ] Clean up with `destroy().remove()` 
- [ ] Use `SiP.Core.utilities.toast.show()` for notifications
- [ ] Progress dialogs follow controller pattern
- [ ] Custom overlay for non-modal dialogs
- [ ] Error messages longer duration (5000ms)
- [ ] Success messages standard duration (3000ms)