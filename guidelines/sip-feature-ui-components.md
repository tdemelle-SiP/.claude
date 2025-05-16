# SiP Feature - UI Components

This guide documents the UI components and browser storage patterns used in SiP plugins.

## UI State Management with Local Storage

SiP plugins use localStorage to persist UI state across sessions. All state is stored under a `sip-core` namespace.

### Storage Structure

```javascript
{
  "sip-core": {
    "sip-printify-manager": {
      "images-table": {},
      "products-table": {},
      "templates-table": {},
      "creations-table": {},
      "main-window": {}
    }
  }
}
```

### Common UI State Patterns

#### Table UI States
```javascript
{
  actionDropdown: 'add_image_to_new_product',
  search: { search: '' },
  displayStart: 0,
  order: [[2, 'desc'], [4, 'asc']],
  columns: {
    3: { search: 'all' },
    6: { search: 'all' }
  }
}
```

#### Window States
```javascript
{
  scrollPosition: 0,
  expandedSections: ['section1', 'section2'],
  selectedTab: 'images'
}
```

### Implementation Functions

#### Initialize Local Storage
```javascript
function initializeLocalStorage() {
    const coreState = JSON.parse(localStorage.getItem('sip-core')) || {};
    if (!coreState['sip-printify-manager']) {
        coreState['sip-printify-manager'] = {
            'images-table': {},
            'products-table': {},
            'templates-table': {},
            'creations-table': {},
            'main-window': { scrollPosition: 0 }
        };
    }
    localStorage.setItem('sip-core', JSON.stringify(coreState));
}
```

#### Track UI State
```javascript
function trackTableUi() {
    const state = JSON.parse(localStorage.getItem('sip-core')) || {};
    const pluginKey = 'sip-printify-manager';
    const tableKey = 'images-table';
    
    if (!state[pluginKey]) state[pluginKey] = {};
    
    state[pluginKey][tableKey] = {
        actionDropdown: $('#image_action').val() || '',
        expandedRows: Array.from($('.expanded-row')).map(el => el.id)
    };
    
    localStorage.setItem('sip-core', JSON.stringify(state));
}
```

#### Refresh UI from State
```javascript
function refreshTableUi() {
    const state = JSON.parse(localStorage.getItem('sip-core'))?.['sip-printify-manager']?.['images-table'] || {};
    const defaultState = {
        actionDropdown: '',
        expandedRows: []
    };
    
    const finalState = { ...defaultState, ...state };
    
    // Apply state to UI
    $('#image_action').val(finalState.actionDropdown);
    finalState.expandedRows.forEach(rowId => {
        $(`#${rowId}`).addClass('expanded-row');
    });
}
```

### Event Listeners

Track UI changes with debounced event listeners:

```javascript
// Track scroll position
$(window).on('scroll', _.debounce(trackMainWindowUi, 200));

// Track dropdown changes
$('#image_action').on('change', trackTableUi);

// Track tab switches
$('.nav-tab').on('click', function() {
    trackSelectedTab($(this).data('tab'));
});
```

### DataTables State Management

DataTables has its own state management that integrates with localStorage:

```javascript
$('#image-table').DataTable({
    stateSave: true,
    stateDuration: -1, // Forever
    
    stateLoadCallback: function(settings) {
        let savedState = localStorage.getItem("Image_DataTables_" + settings.sInstance);
        return savedState ? JSON.parse(savedState) : {};
    },
    
    stateSaveCallback: function(settings, data) {
        localStorage.setItem("Image_DataTables_" + settings.sInstance, JSON.stringify(data));
    }
});
```

## Toast Notifications

SiP Core provides a unified toast system for user feedback.

### Basic Usage
```javascript
// Success message (green)
SiP.Core.utilities.toast.show('Operation completed successfully', 3000);

// Error message (red)
SiP.Core.utilities.toast.show('Error: Invalid input', 5000, true);

// With HTML content
SiP.Core.utilities.toast.show('<strong>Success:</strong> Files uploaded', 3000);
```

### Toast Options
- **Duration**: Time in milliseconds (default: 3000)
- **Error Style**: Red background for errors (third parameter)
- **HTML Content**: Supports basic HTML formatting

## Spinner

Display loading indicators during async operations.

### Basic Usage
```javascript
// Show spinner with message
const spinner = SiP.Core.utilities.spinner.show('Loading products...');

// Hide spinner
SiP.Core.utilities.spinner.hide(spinner);

// Auto-hide after operation
async function loadData() {
    const spinner = SiP.Core.utilities.spinner.show('Loading...');
    try {
        await fetchData();
    } finally {
        SiP.Core.utilities.spinner.hide(spinner);
    }
}
```

## Modals and Dialogs

### jQuery UI Dialog
```javascript
$('#my-dialog').dialog({
    title: 'Confirm Action',
    width: 400,
    height: 'auto',
    modal: true,
    dialogClass: 'sip-dialog',
    buttons: {
        'Confirm': function() {
            // Handle confirm
            $(this).dialog('close');
        },
        'Cancel': function() {
            $(this).dialog('close');
        }
    }
});
```

### Custom Modal Pattern
```javascript
// Show modal
$('#modal-backdrop').fadeIn();
$('#custom-modal').fadeIn();

// Hide modal
$('#modal-backdrop').fadeOut();
$('#custom-modal').fadeOut();

// Close on backdrop click
$('#modal-backdrop').on('click', function() {
    $(this).fadeOut();
    $('#custom-modal').fadeOut();
});
```

## Progress Indicators

### Progress Dialog
See [Progress Dialog Guide](sip-feature-progress-dialog.md) for batch processing with progress tracking.

### Simple Progress Bar
```javascript
// HTML
<div class="progress-bar-container">
    <div class="progress-bar" style="width: 0%"></div>
</div>

// JavaScript
function updateProgress(current, total) {
    const percentage = (current / total) * 100;
    $('.progress-bar').css('width', percentage + '%');
}
```

## Buttons and Controls

### WordPress Button Classes
```html
<!-- Primary button -->
<button class="button button-primary">Save Changes</button>

<!-- Secondary button -->
<button class="button">Cancel</button>

<!-- Large button -->
<button class="button button-large">Import Data</button>

<!-- Small button -->
<button class="button button-small">Add</button>

<!-- Disabled state -->
<button class="button button-primary" disabled>Processing...</button>
```

### Action Dropdown Pattern
```html
<select id="bulk-action" class="action-dropdown">
    <option value="">Select Action</option>
    <option value="delete">Delete Selected</option>
    <option value="export">Export</option>
</select>
<button class="button apply-action">Apply</button>
```

## Form Elements

### Enhanced Select
```javascript
// Add search to select dropdowns
$('.enhanced-select').select2({
    placeholder: 'Select an option',
    allowClear: true,
    width: '100%'
});
```

### Toggle Switches
```html
<label class="toggle-switch">
    <input type="checkbox" class="toggle-input">
    <span class="toggle-slider"></span>
    <span class="toggle-label">Enable Feature</span>
</label>
```

## Responsive Tables

### Collapsible Rows
```javascript
// Toggle row expansion
$('.expand-toggle').on('click', function() {
    const $row = $(this).closest('tr');
    const $detailRow = $row.next('.detail-row');
    
    if ($detailRow.is(':visible')) {
        $detailRow.hide();
        $(this).removeClass('expanded');
    } else {
        $detailRow.show();
        $(this).addClass('expanded');
    }
    
    // Track state
    trackExpandedRows();
});
```

## Session Lifecycle

### Initialization
```javascript
$(document).ready(function() {
    // Initialize localStorage
    initializeLocalStorage();
    
    // Refresh UI from saved state
    refreshAllUiStates();
    
    // Setup event listeners
    attachUiEventListeners();
});
```

### State Persistence
```javascript
// Save state before unload
$(window).on('beforeunload', function() {
    saveAllUiStates();
});

// Periodic state saves for critical data
setInterval(saveAllUiStates, 30000); // Every 30 seconds
```

## Best Practices

1. **Namespace Storage**: Always use the `sip-core` namespace
2. **Default Values**: Provide sensible defaults for all stored values
3. **Debounce Events**: Use debouncing for scroll and resize events
4. **Clean Storage**: Remove obsolete data periodically
5. **Validate State**: Check for corrupt data when loading state
6. **User Privacy**: Don't store sensitive information in localStorage
7. **Cross-Browser**: Test localStorage availability before use