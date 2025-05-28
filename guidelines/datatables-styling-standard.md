# DataTables Styling Standard for SiP Plugins

## Overview

This document establishes a consistent standard for styling DataTables across all SiP plugins, with special attention to handling multiple row types (header, summary, variant, etc.) in a unified manner.

## Core Principles

1. **Unified Base Styling**: All row types should share the same base styles
2. **DataTables Native Methods**: Use DataTables' built-in features and conventions
3. **Minimal Overrides**: Special cases should be handled with minimal CSS overrides
4. **Centralized Styles**: All table styling should be consolidated in dedicated CSS files
5. **Consistent Data Formatting**: Data should be formatted consistently before being passed to DataTables

## Table Structure Standard

### HTML Structure
```html
<table id="[module]-table" class="display sip-datatable">
  <thead>
    <tr>
      <th>Column 1</th>
      <th>Column 2</th>
      <!-- ... -->
    </tr>
  </thead>
  <tbody>
    <!-- DataTables will populate this -->
  </tbody>
</table>
```

### Row Types
1. **Standard Rows**: Regular data rows managed by DataTables
2. **Group Header Rows**: Created by rowGroup.startRender (class: `group`)
3. **Summary Rows**: Custom injected rows (class: `[type]-summary-row`)
4. **Variant Rows**: Sub-rows within groups (class: `variant-row`)

## CSS Architecture

### File Organization
```
assets/css/modules/
├── tables.css           # Base table styles
├── datatables-core.css  # DataTables overrides
└── [module]-table.css   # Module-specific styles
```

### Base Table Styling
```css
/*==============================================================================
DATATABLE BASE STYLES
==============================================================================*/

/* Base table setup */
.sip-datatable {
    width: 100%;
    table-layout: fixed; /* Ensures consistent column widths */
}

/* Base cell styling - applies to ALL cells */
.sip-datatable td,
.sip-datatable th {
    /* Layout */
    padding: var(--cell-padding-y) var(--cell-padding-x);
    box-sizing: border-box;
    
    /* Typography */
    font-size: var(--font-md);
    
    /* Borders */
    border: 1px solid var(--table-border);
    
    /* Content overflow - default behavior */
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

/* Column-specific widths using nth-child for consistency */
.sip-datatable th:nth-child(1),
.sip-datatable td:nth-child(1) { 
    width: var(--col-1-width); 
}
/* ... repeat for each column ... */
```

### Handling Special Row Types
```css
/* Summary rows inherit base styles automatically */
.sip-datatable tr.group td,
.sip-datatable tr.summary-row td {
    /* Only override what's different */
    background-color: var(--summary-bg);
    font-weight: 600;
}

/* Variant rows */
.sip-datatable tr.variant-row td {
    /* Minimal overrides */
    padding-left: var(--variant-indent);
}
```

## JavaScript Standards

### DataTable Initialization
```javascript
const tableConfig = {
    // Disable auto width to respect our CSS
    autoWidth: false,
    
    // Use fixed columns
    columns: [
        { 
            data: 'column1',
            className: 'column-1',
            render: function(data, type, row) {
                // Always return consistent HTML structure
                return '<span class="cell-content">' + escapeHtml(data) + '</span>';
            }
        },
        // ... more columns
    ],
    
    // Row grouping
    rowGroup: {
        startRender: function(rows, group) {
            // Return consistent HTML matching other rows
            return $('<tr class="group">')
                .append('<td>' + content + '</td>')
                // ... append all columns
                .prop('outerHTML');
        }
    }
};
```

### Data Formatting Standards
```javascript
// Before passing to DataTables, ensure consistent data format
function formatRowData(rawData) {
    return {
        column1: escapeHtml(rawData.column1 || ''),
        column2: formatDescription(rawData.column2),
        column3: formatTags(rawData.column3),
        // ... etc
    };
}

// Consistent formatters for common data types
function formatDescription(desc) {
    // Strip HTML and return plain text
    return $('<div>').html(desc || '').text();
}

function formatTags(tags) {
    // Ensure consistent array handling
    return Array.isArray(tags) ? tags.join(', ') : (tags || '');
}
```

## Column Type Standards

### Text Columns
```css
.sip-datatable .text-column {
    text-align: left;
    padding-left: var(--text-indent);
}
```

### Truncating Columns
```css
.sip-datatable .truncate-column {
    max-width: var(--truncate-max-width);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}
```

### Action Columns
```css
.sip-datatable .action-column {
    text-align: center;
    width: var(--action-width);
}
```

## Implementation Checklist

When implementing a DataTable:

1. **Structure**
   - [ ] Use consistent HTML structure
   - [ ] Add appropriate classes (`display sip-datatable`)
   - [ ] Include all required columns in thead

2. **Styling**
   - [ ] Use base styles from tables.css
   - [ ] Override only what's necessary in module CSS
   - [ ] Use nth-child for column widths
   - [ ] Ensure all row types use same column structure

3. **JavaScript**
   - [ ] Disable autoWidth
   - [ ] Format all data consistently before adding to table
   - [ ] Use render functions for consistent HTML output
   - [ ] Handle all row types with same column count

4. **Testing**
   - [ ] Verify column alignment across all row types
   - [ ] Test truncation behavior
   - [ ] Check responsive behavior
   - [ ] Validate with different data sets

## Common Patterns

### Multi-line Cell Content
When cell content might wrap:
```css
.sip-datatable .wrap-column {
    white-space: normal;
    min-height: var(--row-height);
}
```

### Image Cells
For cells containing images:
```css
.sip-datatable .image-column {
    text-align: center;
    padding: var(--image-padding);
}

.sip-datatable .image-column img {
    max-width: var(--thumbnail-size);
    max-height: var(--thumbnail-size);
    vertical-align: middle;
}
```

### Status Indicators
```css
.sip-datatable .status-column {
    text-align: center;
    font-weight: 600;
}
```

## Migration Guide

To migrate existing tables to this standard:

1. **Audit Current Implementation**
   - Identify all row types
   - Document column structure
   - Note special styling requirements

2. **Standardize Data**
   - Update data formatting functions
   - Ensure consistent HTML structure
   - Remove inline styles

3. **Update CSS**
   - Apply base classes
   - Move to nth-child selectors
   - Consolidate duplicate rules

4. **Test Thoroughly**
   - Check all row types align
   - Verify special features still work
   - Test edge cases

## Related Documents

- [CSS Guidelines](css-guidelines.md)
- [JavaScript Standards](javascript-standards.md)
- [UI Components](ui-components.md)