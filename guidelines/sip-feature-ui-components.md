# SiP Feature - UI Components

This guide documents the UI components and browser storage patterns used in SiP plugins.

## Component Design Principles

1. **Consistency**: Components should have a consistent look and feel across all SiP plugins
2. **Accessibility**: All components should be accessible and follow WCAG guidelines
3. **Responsive**: Components should work across different screen sizes
4. **Performance**: Components should be optimized for performance

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

## Checkbox Selection Patterns

The SiP Plugin Suite implements comprehensive checkbox selection patterns for hierarchical data tables.

### Checkbox Types

#### 1. Row Selection Checkboxes
Used for selecting entire table rows, managed by DataTables Select extension:

```javascript
select: {
    style: "multi",
    selector: "td.col-select",
    headerCheckbox: true
}
```

#### 2. Data Element Checkboxes
For selecting specific data elements within rows (e.g., image selections):

```html
<input type="checkbox" class="creation-table-image-select sip-checkbox" data-image-index="0">
```

#### 3. Group Selection Checkboxes
For selecting all related items in a group:

```html
<input type="checkbox" class="child-product-group-select sip-checkbox">
```

### Selection Hierarchy

The selection system supports three levels:

1. **Header Level**: Selects all items in a column or all rows
2. **Group Level**: Selects all items within a specific group
3. **Item Level**: Individual item selection

```
Header Checkbox (all rows/columns)
├── Group Checkbox 1 (all items in group 1)
│   ├── Item Checkbox 1.1
│   ├── Item Checkbox 1.2
│   └── Item Checkbox 1.3
└── Group Checkbox 2 (all items in group 2)
    ├── Item Checkbox 2.1
    └── Item Checkbox 2.2
```

### Indeterminate States

Checkboxes display three states:
- **Unchecked**: No items selected
- **Checked**: All items selected
- **Indeterminate**: Some items selected

#### Implementing Indeterminate Logic

```javascript
function updateGroupCheckboxState($groupCheckbox, $itemCheckboxes) {
    const totalCount = $itemCheckboxes.length;
    const checkedCount = $itemCheckboxes.filter(':checked').length;
    
    if (checkedCount === 0) {
        $groupCheckbox.prop({
            'checked': false,
            'indeterminate': false
        });
    } else if (checkedCount === totalCount) {
        $groupCheckbox.prop({
            'checked': true,
            'indeterminate': false
        });
    } else {
        $groupCheckbox.prop({
            'checked': false,
            'indeterminate': true
        });
    }
}
```

### Implementation Patterns

#### Row Selection Pattern

```javascript
// Select/deselect rows
table.rows(selector)[isChecked ? 'select' : 'deselect']();

// Listen for selection changes
$('#table').on('select.dt deselect.dt', function(e, dt, type, indexes) {
    updateGroupCheckboxStates();
});
```

#### Column Selection Pattern

```javascript
// Select all checkboxes in a column
$(`.image-cell[data-image-index="${columnIndex}"] input.checkbox-class`)
    .prop('checked', isChecked);

// Listen for individual changes
$(document).on('change', '.image-cell input.checkbox-class', function() {
    const columnIndex = $(this).closest('.image-cell').data('image-index');
    updateColumnHeaderState(columnIndex);
});
```

#### Group Selection Pattern

```javascript
// Group checkbox handler
$(document).on('click', '.group-checkbox', function() {
    const groupId = $(this).data('group-id');
    const isChecked = this.checked;
    
    // Clear indeterminate state
    $(this).prop('indeterminate', false);
    
    // Update all items in the group
    $(`.item[data-group-id="${groupId}"]`).each(function() {
        // Update via appropriate method
    });
});
```

### Cross-Module Communication

When checkbox handlers exist in different modules:

```javascript
// Triggering Module
$(document).trigger('sip:checkboxStateChanged', [checkboxId, newState]);

// Listening Module
$(document).on('sip:checkboxStateChanged', function(e, checkboxId, newState) {
    updateRelatedCheckboxes(checkboxId, newState);
});
```

#### Module Loading Order Considerations

```javascript
// Option 1: Check if function exists
if (typeof SiP.OtherModule?.updateFunction === 'function') {
    SiP.OtherModule.updateFunction();
}

// Option 2: Use custom events (preferred)
$(document).trigger('sip:imageCheckboxStateChanged', [imageIndex]);

// Option 3: Defer updates
setTimeout(function() {
    // Update logic here
    $(document).trigger('sip:updateComplete');
}, 10);
```

### Checkbox CSS

Unified checkbox styles are defined in the [CSS Development](sip-development-css.md#unified-component-styles). Key aspects:

```css
/* Base checkbox reset */
input[type="checkbox"],
.sip-checkbox {
    -webkit-appearance: none;
    appearance: none;
    width: 1rem;
    height: 1rem;
    border: 1px solid #7e8993;
    border-radius: 3px;
    background-color: #fff;
    cursor: pointer;
}

/* Indeterminate state */
input[type="checkbox"]:indeterminate {
    background-color: #3582c4;
    border-color: #3582c4;
}

input[type="checkbox"]:indeterminate::before {
    content: "";
    position: absolute;
    left: 50%;
    top: 50%;
    width: 10px;
    height: 2px;
    background-color: #fff;
    transform: translate(-50%, -50%);
}
```

### Preventing Sort Interference

For checkboxes in sortable columns:

```javascript
// Make column non-sortable
columnDefs: [{
    orderable: false,
    targets: getColumnIndex('col-with-checkboxes')
}]
```

### Complete Implementation Example

```javascript
// Initialize hierarchical checkbox system
function initCheckboxHierarchy() {
    // Header checkbox - selects all groups and items
    $(document).on('click', '.header-checkbox', function() {
        const isChecked = this.checked;
        $('.group-checkbox, .item-checkbox').prop('checked', isChecked);
        $('.group-checkbox').prop('indeterminate', false);
    });
    
    // Group checkbox - selects all items in group
    $(document).on('click', '.group-checkbox', function() {
        const groupId = $(this).data('group-id');
        const isChecked = this.checked;
        
        $(this).prop('indeterminate', false);
        $(`.item-checkbox[data-group-id="${groupId}"]`).prop('checked', isChecked);
        
        updateHeaderCheckboxState();
    });
    
    // Item checkbox - updates group and header states
    $(document).on('change', '.item-checkbox', function() {
        const groupId = $(this).data('group-id');
        
        updateGroupCheckboxState(groupId);
        updateHeaderCheckboxState();
    });
}

// Update group checkbox based on its items
function updateGroupCheckboxState(groupId) {
    const $groupCheckbox = $(`.group-checkbox[data-group-id="${groupId}"]`);
    const $items = $(`.item-checkbox[data-group-id="${groupId}"]`);
    
    const total = $items.length;
    const checked = $items.filter(':checked').length;
    
    if (checked === 0) {
        $groupCheckbox.prop({ checked: false, indeterminate: false });
    } else if (checked === total) {
        $groupCheckbox.prop({ checked: true, indeterminate: false });
    } else {
        $groupCheckbox.prop({ checked: false, indeterminate: true });
    }
}
```

### Checkbox Best Practices

**DO:**
- ✅ Use semantic classes that describe checkbox purpose
- ✅ Implement proper indeterminate state logic
- ✅ Use event delegation for dynamic content
- ✅ Clear indeterminate state when user clicks
- ✅ Use DataTables API for row selection when available

**DON'T:**
- ❌ Use preventDefault() on checkbox clicks
- ❌ Assume checkbox state immediately after triggering click
- ❌ Mix selection paradigms unnecessarily
- ❌ Create circular dependencies between state updates

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

## Standard Headers

Headers are used consistently across all SiP plugins with the following structure:

```html
<div class="sip-dashboard-wrapper">
  <div class="top-header-section">
    <a href="..." class="back-link">← Back to Dashboards</a>
    <h1 class="header-title">
      <img src="logo.svg" class="inline-image" alt="SiP Logo"> 
      Plugin Name
    </h1>
    <div class="header-right-content">
      <!-- Debug toggle or other controls -->
    </div>
  </div>
  <hr class="header-divider">
</div>
```

For header implementation details, see the [Dashboard Guide](sip-plugin-dashboards.md#step-3-create-the-dashboard-header).

## Best Practices

1. **Namespace Storage**: Always use the `sip-core` namespace
2. **Default Values**: Provide sensible defaults for all stored values
3. **Debounce Events**: Use debouncing for scroll and resize events
4. **Clean Storage**: Remove obsolete data periodically
5. **Validate State**: Check for corrupt data when loading state
6. **User Privacy**: Don't store sensitive information in localStorage
7. **Cross-Browser**: Test localStorage availability before use
8. **Component Stacking**: Use the standardized z-index system (see [CSS Development](sip-development-css.md#z-index-management))