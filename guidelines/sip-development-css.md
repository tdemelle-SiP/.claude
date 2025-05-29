# SiP Plugin Suite CSS Standards

This document defines the CSS coding standards for the SiP Plugin Suite. These standards ensure consistency, maintainability, and scalability across all plugins in the suite.

## Table of Contents
1. [Core Principles](#core-principles)
2. [File Organization](#file-organization)
3. [Hierarchical Structure](#hierarchical-structure)
4. [Naming Conventions](#naming-conventions)
5. [Selector Strategy](#selector-strategy)
6. [CSS Variables](#css-variables)
7. [Specificity Management](#specificity-management)
8. [Z-Index Management](#z-index-management)
9. [Component Architecture](#component-architecture)
10. [DataTables Standards](#datatables-standards)
11. [Responsive Design](#responsive-design)
12. [Comments and Documentation](#comments-and-documentation)
13. [Legacy Code Migration](#legacy-code-migration)
14. [Best Practices Summary](#best-practices-summary)

## Core Principles

### 1. Predictability Over Cleverness
Write CSS that is immediately understandable. Avoid complex selectors or clever tricks that require documentation to understand.

### 2. Consistency Over Personal Preference
Follow these standards even if you prefer a different approach. Consistency across the codebase is more valuable than individual optimization.

### 3. Maintainability Over Brevity
Write CSS that is easy to modify and extend. Verbose but clear code is better than compact but cryptic code.

### 4. Progressive Enhancement
Start with a solid base that works everywhere, then enhance for modern browsers.

## File Organization

### Directory Structure
```
assets/
├── css/
│   ├── modules/           # Component-specific styles
│   │   ├── variables.css  # CSS custom properties
│   │   ├── base.css       # Base/reset styles
│   │   ├── layout.css     # Layout components
│   │   ├── tables.css     # Table components
│   │   └── [component].css
│   ├── admin.css          # Main admin stylesheet (imports modules)
│   └── public.css         # Main public stylesheet (if needed)
```

### File Loading Order
1. **variables.css** - CSS custom properties and configuration
2. **base.css** - Resets, typography, common elements
3. **layout.css** - Page structure and containers
4. Component files in dependency order
5. Page-specific overrides (if necessary)

### Import Strategy
```css
/* admin.css */
@import url('modules/variables.css');
@import url('modules/base.css');
@import url('modules/layout.css');
@import url('modules/tables.css');
/* Component imports in dependency order */
```

## Hierarchical Structure

CSS should follow a logical hierarchy from general to specific:

```css
/*==============================================================================
1. SHARED STYLES - Apply to all instances
==============================================================================*/
/* Base component styles that apply everywhere */

/*==============================================================================
2. CONTEXTUAL STYLES - Apply to specific contexts
==============================================================================*/
/* Styles for components in specific containers or states */

/*==============================================================================
3. COMPONENT-SPECIFIC STYLES - Individual component overrides
==============================================================================*/
/* Unique styles for specific component instances */
```

### Example: Table Styling Hierarchy
```css
/* 1. SHARED DASHBOARD STYLES */
.sip-pm-dashboard { /* All dashboards */ }

/* 2. SHARED TABLE STYLES */
.sip-pm-table { /* All tables */ }
.sip-pm-table__header { /* All table headers */ }
.sip-pm-table__cell { /* All table cells */ }

/* 3. SHARED COLUMN STYLES */
.sip-pm-table__cell--checkbox { /* All checkbox columns */ }
.sip-pm-table__cell--title { /* All title columns */ }

/* 4. SPECIFIC TABLE STYLES */
.sip-pm-product-table { /* Product table specific */ }
.sip-pm-template-table { /* Template table specific */ }
.sip-pm-image-table { /* Image table specific */ }

/* 5. SPECIAL CASES */
.sip-pm-product-table__cell--status { /* Product table status column */ }
```

## Naming Conventions

### BEM Methodology with Plugin Prefix
All classes must use BEM (Block Element Modifier) with the plugin prefix:

```css
/* Block */
.sip-pm-table { }

/* Element (separated by double underscore) */
.sip-pm-table__header { }
.sip-pm-table__cell { }

/* Modifier (separated by double hyphen) */
.sip-pm-table--bordered { }
.sip-pm-table__cell--checkbox { }

/* State (use is- prefix) */
.sip-pm-table.is-loading { }
.sip-pm-table__row.is-selected { }
```

### Prefix Requirements
- **sip-** - All SiP suite classes
- **sip-pm-** - SiP Printify Manager specific
- **sip-core-** - SiP Core plugin specific
- **sip-dev-** - SiP Development Tools specific

### Naming Patterns
```css
/* Components */
.sip-pm-[component] { }              /* table, modal, form */

/* Sub-components */
.sip-pm-[component]__[element] { }   /* table__header, modal__content */

/* Variants */
.sip-pm-[component]--[variant] { }   /* table--striped, modal--large */

/* States */
.sip-pm-[component].is-[state] { }   /* is-active, is-disabled, is-loading */

/* Utilities */
.sip-pm-u-[utility] { }              /* u-hidden, u-text-center */
```

## Dynamic Class Generation

### String Normalization for CSS Classes
When generating CSS classes dynamically from data (e.g., status values), use the standard normalization utility:

```javascript
// Use SiP.Core.utilities.normalizeForClass()
const statusClass = SiP.Core.utilities.normalizeForClass('Uploaded - Unpublished', 'status-');
// Returns: 'status-uploaded-unpublished'
```

### Normalization Rules
The `normalizeForClass()` utility applies these transformations in order:
1. Convert to lowercase
2. Replace " - " with single dash (prevents triple dashes)
3. Replace remaining spaces with dashes
4. Replace underscores with dashes
5. Collapse multiple consecutive dashes
6. Remove non-alphanumeric characters (except dashes)
7. Remove leading/trailing dashes

### Common Dynamic Classes
```css
/* Status-based classes */
.status-work-in-progress { }
.status-uploaded-unpublished { }
.status-uploaded-published { }
.status-archived { }

/* Type-based classes */
.type-parent { }
.type-child { }
.type-single { }

/* Template relationship classes */
.template-blueprint { }
.template-parent { }
.template-child { }
```

### Implementation Pattern
```javascript
// ❌ Bad - Inconsistent normalization
const statusClass = 'status-' + status.toLowerCase().replace(/\s+/g, '-');

// ✅ Good - Use standard utility
const statusClass = SiP.Core.utilities.normalizeForClass(status, 'status-');

// ✅ Also Good - For data attributes
const statusId = SiP.Core.utilities.normalizeForClass(status);
element.setAttribute('data-status', statusId);
```

## Selector Strategy

### Use Classes, Not IDs
```css
/* ❌ Bad - ID selector */
#product-table { }

/* ✅ Good - Class selector */
.sip-pm-product-table { }
```

### Avoid nth-child for Semantic Elements
```css
/* ❌ Bad - Position-dependent */
.sip-pm-table td:nth-child(3) {
    text-align: left;
}

/* ✅ Good - Semantic class */
.sip-pm-table__cell--title {
    text-align: left;
}

/* ✅ Also Good - Data attribute */
.sip-pm-table__cell[data-column="title"] {
    text-align: left;
}
```

### Data Attributes for Dynamic Content
```css
/* Use data attributes for dynamic styling */
.sip-pm-table__row[data-status="active"] { }
.sip-pm-table__cell[data-column="price"] { }
.sip-pm-product[data-variant="true"] { }
```

### Maximum Nesting Depth: 3 Levels
```css
/* ❌ Bad - Too specific */
.sip-pm-dashboard .sip-pm-table tbody tr td.title-column span {
    color: red;
}

/* ✅ Good - Direct selection */
.sip-pm-table__title-text {
    color: red;
}
```

## CSS Variables

### Variable Naming Convention
```css
:root {
    /* Plugin-specific namespace */
    --sip-pm-[category]-[property]: value;
    
    /* Examples */
    --sip-pm-color-primary: #0073aa;
    --sip-pm-spacing-small: 5px;
    --sip-pm-table-header-height: 40px;
}
```

### Variable Categories
```css
:root {
    /* Colors */
    --sip-pm-color-primary: #0073aa;
    --sip-pm-color-success: #4CAF50;
    --sip-pm-color-error: #dc3232;
    
    /* Typography */
    --sip-pm-font-size-small: 12px;
    --sip-pm-font-size-base: 14px;
    --sip-pm-font-weight-bold: 700;
    
    /* Spacing */
    --sip-pm-spacing-xs: 2px;
    --sip-pm-spacing-sm: 5px;
    --sip-pm-spacing-md: 10px;
    
    /* Layout */
    --sip-pm-sidebar-width: 300px;
    --sip-pm-header-height: 60px;
    
    /* Components */
    --sip-pm-table-border-width: 1px;
    --sip-pm-table-border-color: #ddd;
    
    /* Z-index Scale - See Z-Index Management section for complete scale */
}
```

### Component-Specific Variables
```css
/* Define at component level for scoped customization */
.sip-pm-product-table {
    --table-header-bg: var(--sip-pm-color-primary);
    --table-row-height: 40px;
    --table-column-gap: 10px;
}
```

## Specificity Management

### Specificity Hierarchy (Low to High)
1. Type selectors: `table { }`
2. Class selectors: `.sip-pm-table { }`
3. Multiple classes: `.sip-pm-table.is-loading { }`
4. Attribute selectors: `[data-status="active"] { }`
5. Never use: ID selectors, inline styles, !important

### Avoiding !important
```css
/* ❌ Bad - Using !important */
.sip-pm-table__header {
    background: blue !important;
}

/* ✅ Good - Increase specificity naturally */
.sip-pm-dashboard .sip-pm-table__header {
    background: blue;
}

/* ✅ Better - Use CSS variables */
.sip-pm-table--custom {
    --table-header-bg: blue;
}
```

### Specificity Guidelines
- One class selector for base styles
- Two class selectors for variants
- Three class selectors maximum for edge cases (minimize nesting)
- Never use ID selectors for styling
- Reserve !important for utility classes only
- Avoid `!important` where possible - increase specificity naturally instead

## Z-Index Management

Our z-index system follows a hierarchical structure with main categories and sub/super variations. This provides clear organization while allowing flexibility within each category.

### Z-Index Scale

```css
:root {
    /* Negative layer */
    --sip-pm-z-negative: -1;          /* Elements behind content */
    
    /* Base layer */
    --sip-pm-z-base-sub: 1;           /* Below standard content */
    --sip-pm-z-base: 10;              /* Standard content */
    --sip-pm-z-base-super: 50;        /* Above standard content */
    
    /* Table header layer */
    --sip-pm-z-table-header-sub: 75;  /* Below table headers */
    --sip-pm-z-table-header: 80;      /* Table headers */
    --sip-pm-z-table-header-super: 85;/* Above table headers */
    
    /* Plugin header layer */
    --sip-pm-z-plugin-header-sub: 90; /* Below plugin headers */
    --sip-pm-z-plugin-header: 100;    /* Plugin headers, navigation */
    --sip-pm-z-plugin-header-super: 200; /* Dropdowns, above plugin headers */
    
    /* Overlay layer */
    --sip-pm-z-overlay-sub: 900;      /* Below overlays */
    --sip-pm-z-overlay: 1000;         /* Page overlays, backdrops */
    --sip-pm-z-overlay-super: 1500;   /* Above standard overlays */
    
    /* Modal layer */
    --sip-pm-z-modal-sub: 1900;       /* Below modals */
    --sip-pm-z-modal: 2000;           /* Modal windows, dialogs */
    --sip-pm-z-modal-super: 2500;     /* Above standard modals */
    
    /* Toast layer */
    --sip-pm-z-toast-sub: 2900;       /* Below toast messages */
    --sip-pm-z-toast: 3000;           /* Toast notifications */
    --sip-pm-z-toast-super: 3500;     /* Important notifications */
    
    /* Spinner layer */
    --sip-pm-z-spinner-sub: 3900;     /* Below spinners */
    --sip-pm-z-spinner: 4000;         /* Loading spinners */
    --sip-pm-z-spinner-super: 4500;   /* Critical spinners */
    
    /* Top layer */
    --sip-pm-z-top-sub: 8000;         /* High priority elements */
    --sip-pm-z-top: 9000;             /* Very high priority */
    --sip-pm-z-top-super: 9999;       /* Absolute highest (rare) */
}
```

### Z-Index Usage Guidelines

1. **Use appropriate variables**: Always use the z-index variable that matches your element's purpose
2. **Standard values first**: Use the standard (middle) value when possible
3. **Sub/super for ordering**: Use -sub and -super variants only when elements need specific ordering within a layer
4. **Document special cases**: Add comments for any unusual z-index usage
5. **Never use arbitrary values**: Always use the defined variables

### Common Z-Index Use Cases

| Element Type | Recommended Variable |
|--------------|---------------------|
| Regular content | `--sip-pm-z-base` |
| Sticky table headers | `--sip-pm-z-table-header` |
| Plugin navigation | `--sip-pm-z-plugin-header` |
| Dropdown menus | `--sip-pm-z-plugin-header-super` |
| Modal backdrops | `--sip-pm-z-overlay` |
| Modal dialogs | `--sip-pm-z-modal` |
| Toast notifications | `--sip-pm-z-toast` |
| Loading indicators | `--sip-pm-z-spinner` |
| PhotoSwipe gallery | `--sip-pm-z-modal-super` |
| Tooltips | `--sip-pm-z-overlay-super` |

### Implementation Example

```css
/* Sticky table header */
.sip-pm-table__header {
    position: sticky;
    top: 0;
    z-index: var(--sip-pm-z-table-header);
}

/* Dropdown menu that needs to appear above header */
.sip-pm-dropdown {
    position: absolute;
    z-index: var(--sip-pm-z-plugin-header-super);
}

/* Modal with backdrop */
.sip-pm-modal-backdrop {
    position: fixed;
    z-index: var(--sip-pm-z-overlay);
}

.sip-pm-modal {
    position: fixed;
    z-index: var(--sip-pm-z-modal);
}
```

## Unified Component Styles

### Checkbox Styles
All checkboxes across the SiP Plugin Suite should use unified styles for consistency:

```css
/* Base checkbox reset and styling */
input[type="checkbox"],
.sip-checkbox {
    -webkit-appearance: none;
    -moz-appearance: none;
    appearance: none;
    width: 1rem;
    height: 1rem;
    min-width: 1rem;
    min-height: 1rem;
    border: 1px solid #7e8993;
    border-radius: 3px;
    background-color: #fff;
    margin: 0;
    padding: 0;
    vertical-align: middle;
    position: relative;
    cursor: pointer;
    transition: border-color 0.1s ease-in-out;
    box-sizing: border-box;
    display: inline-block;
}

/* States and pseudo-elements */
/* See sip-feature-ui-components.md#checkbox-selection-patterns for complete implementation */
```

## Component Architecture

### Component Structure
```css
/*==============================================================================
COMPONENT: Table
==============================================================================*/

/* 1. Component Variables */
.sip-pm-table {
    --table-border-color: var(--sip-pm-color-border);
    --table-header-height: 40px;
}

/* 2. Component Base */
.sip-pm-table {
    width: 100%;
    border-collapse: collapse;
}

/* 3. Component Elements */
.sip-pm-table__header { }
.sip-pm-table__body { }
.sip-pm-table__row { }
.sip-pm-table__cell { }

/* 4. Component Modifiers */
.sip-pm-table--bordered { }
.sip-pm-table--striped { }

/* 5. Component States */
.sip-pm-table.is-loading { }
.sip-pm-table__row.is-selected { }

/* 6. Component Responsive */
@media (max-width: 768px) {
    .sip-pm-table { }
}
```

### Composite Components
```css
/* Parent defines layout */
.sip-pm-data-grid {
    display: grid;
    gap: var(--sip-pm-spacing-md);
}

/* Children handle their own internal styles */
.sip-pm-data-grid__table {
    /* Position and size only */
    grid-area: main;
}

/* Table component maintains its own styles */
.sip-pm-data-grid .sip-pm-table {
    /* No overrides needed - table styles itself */
}
```

## DataTables Standards

For styling DataTables, we have comprehensive standards that ensure consistency across all table implementations, especially when dealing with multiple row types.

See the [DataTables Styling Standard](datatables-styling-standard.md) for complete implementation details.

### Core DataTables Principles

1. **Unified Base Styling**: All row types should share the same base styles
2. **DataTables Native Methods**: Use DataTables' built-in features and conventions
3. **Minimal Overrides**: Special cases should be handled with minimal CSS overrides
4. **Centralized Styles**: All table styling should be consolidated in dedicated CSS files
5. **Consistent Data Formatting**: Data should be formatted consistently before being passed to DataTables

### Table Structure Standard

```html
<table id="[module]-table" class="display sip-pm-datatable">
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

### DataTables CSS Architecture

```css
/*==============================================================================
DATATABLE BASE STYLES
==============================================================================*/

/* Base table setup */
.sip-pm-datatable {
    width: 100%;
    table-layout: fixed; /* Ensures consistent column widths */
}

/* Base cell styling - applies to ALL cells */
.sip-pm-datatable td,
.sip-pm-datatable th {
    /* Layout */
    padding: var(--sip-pm-cell-padding-y) var(--sip-pm-cell-padding-x);
    box-sizing: border-box;
    
    /* Typography */
    font-size: var(--sip-pm-font-size-base);
    
    /* Borders */
    border: 1px solid var(--sip-pm-table-border-color);
    
    /* Content overflow - default behavior */
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

/* Special row types inherit base styles automatically */
.sip-pm-datatable tr.group td,
.sip-pm-datatable tr.summary-row td {
    /* Only override what's different */
    background-color: var(--sip-pm-color-gray-light);
    font-weight: 600;
}
```

### JavaScript Standards for DataTables

```javascript
const tableConfig = {
    // Disable auto width to respect our CSS
    autoWidth: false,
    
    // Use fixed columns
    columns: [
        { 
            data: 'column1',
            className: 'sip-pm-table__cell--title',
            render: function(data, type, row) {
                // Always return consistent HTML structure
                return '<span class="sip-pm-table__cell-content">' + escapeHtml(data) + '</span>';
            }
        },
        // ... more columns
    ]
};
```

### Dashboard Table Organization

Table styles should be organized in clear sections:

```css
/*==============================================================================
SHARED TABLE STYLES
==============================================================================*/
/* Common DataTables overrides, base table styling, shared utilities */

/*==============================================================================
TEMPLATE TABLE
==============================================================================*/
/* All styles specific to .sip-pm-template-table */

/*==============================================================================
PRODUCT TABLE
==============================================================================*/
/* All styles specific to .sip-pm-product-table */

/*==============================================================================
CREATION TABLE
==============================================================================*/
/* All styles specific to .sip-pm-creation-table */

/*==============================================================================
IMAGE TABLE
==============================================================================*/
/* All styles specific to .sip-pm-image-table */
```

## Responsive Design

### Mobile-First Approach
```css
/* Base styles (mobile) */
.sip-pm-table {
    font-size: 14px;
}

/* Tablet and up */
@media (min-width: 768px) {
    .sip-pm-table {
        font-size: 16px;
    }
}

/* Desktop and up */
@media (min-width: 1024px) {
    .sip-pm-table {
        font-size: 18px;
    }
}
```

### Breakpoint Variables
```css
:root {
    --sip-pm-breakpoint-sm: 576px;
    --sip-pm-breakpoint-md: 768px;
    --sip-pm-breakpoint-lg: 1024px;
    --sip-pm-breakpoint-xl: 1280px;
}
```

### Container Queries (Future-Proof)
```css
/* Component-level responsive design */
@container (min-width: 400px) {
    .sip-pm-table__cell {
        padding: 10px;
    }
}
```

### Media Query Organization

Place media queries at the end of each component's style section:

```css
/* Component styles */
.sip-pm-component {
    width: 100%;
    padding: var(--sip-pm-spacing-md);
}

/* Responsive adjustments */
@media (max-width: 768px) {
    .sip-pm-component {
        width: 100%;
        padding: var(--sip-pm-spacing-sm);
    }
}
```

## Comments and Documentation

### Section Headers

Use consistent comment blocks to organize major sections:

```css
/*==============================================================================
SECTION NAME
==============================================================================*/

/*------------------------------------------------------------------------------
1. Sub-section
------------------------------------------------------------------------------*/
```

### Inline Comments

```css
/* Brief explanation for non-obvious code */
.sip-pm-table--complex {
    /* Compensate for border in width calculation */
    width: calc(100% - 2px);
}
```

### TODO Comments

```css
/* TODO: Refactor when migrating to CSS Grid */
.sip-pm-legacy-layout {
    float: left;
}
```

## Legacy Code Migration

### Migration Strategy
1. **Phase 1**: Add new BEM classes alongside old classes
2. **Phase 2**: Update JavaScript to use new classes
3. **Phase 3**: Remove old classes from CSS
4. **Phase 4**: Remove old classes from HTML/PHP

### Temporary Mapping
```css
/* During migration, map old to new */
.product-table { @extend .sip-pm-product-table; }
.title-column { @extend .sip-pm-table__cell--title; }

/* Or duplicate temporarily */
.product-table,
.sip-pm-product-table {
    /* Shared styles */
}
```

### Migration Checklist
- [ ] Identify all legacy selectors
- [ ] Create BEM equivalents with proper prefix
- [ ] Add data attributes where nth-child is used
- [ ] Update HTML/PHP templates
- [ ] Update JavaScript selectors
- [ ] Remove legacy CSS
- [ ] Test thoroughly

## Dashboard Element Organization

For complex dashboards with multiple tables, organize styles hierarchically:

```css
/*==============================================================================
SHARED DASHBOARD STYLES
==============================================================================*/
/* Common styles for all dashboard elements */

/*==============================================================================
TEMPLATE TABLE
==============================================================================*/
/* All styles specific to template table */

/*==============================================================================
PRODUCT TABLE  
==============================================================================*/
/* All styles specific to product table */

/*==============================================================================
CREATION TABLE
==============================================================================*/
/* All styles specific to creation table */
```

This organization:
- Allows easy location of specific component styles
- Enables simple debugging by commenting out sections
- Maintains clear boundaries between components
- Keeps shared styles accessible to all elements

## Best Practices Summary

### DO:
- ✅ Use semantic class names that describe purpose
- ✅ Follow BEM methodology with plugin prefixes
- ✅ Use CSS variables for all values
- ✅ Organize CSS hierarchically from general to specific
- ✅ Keep specificity low and avoid !important
- ✅ Use data attributes for dynamic styling
- ✅ Write comments for complex sections
- ✅ Test in multiple browsers
- ✅ Group related properties together
- ✅ Use shorthand properties where appropriate
- ✅ Specify proper fallbacks for variables
- ✅ Place media queries at component end
- ✅ Follow mobile-first responsive approach

### DON'T:
- ❌ Use ID selectors for styling
- ❌ Use nth-child for semantic elements (except for column widths)
- ❌ Nest selectors more than 3 levels deep
- ❌ Use !important except in utilities
- ❌ Hard-code values that should be variables
- ❌ Mix naming conventions (camelCase, snake_case)
- ❌ Write position-dependent CSS
- ❌ Forget responsive design
- ❌ Use arbitrary z-index values
- ❌ Mix CSS organization patterns
- ❌ Leave undocumented hacks or workarounds

## DataTables Styling Standards

For DataTables implementations across SiP plugins, we follow specific standards to ensure consistency, especially when dealing with multiple row types.

### DataTables Structure Standard

#### HTML Structure
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

#### Row Types
1. **Standard Rows**: Regular data rows managed by DataTables
2. **Group Header Rows**: Created by rowGroup.startRender (class: `dtrg-group`)
3. **Summary Rows**: Custom injected rows (class: `[type]-summary-row`)
4. **Variant Rows**: Sub-rows within groups (class: `variant-row`)

### DataTables CSS Architecture

```css
/* Base DataTables overrides */
.sip-pm-datatable {
    width: 100%;
    table-layout: fixed; /* Ensures consistent column widths */
}

/* Base cell styling - applies to ALL cells */
.sip-pm-datatable td,
.sip-pm-datatable th {
    /* Use base styles from component architecture */
    padding: var(--sip-pm-spacing-sm);
    border: 1px solid var(--sip-pm-table-border-color);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

/* Special row types inherit base styles */
.sip-pm-datatable tr.dtrg-group td,
.sip-pm-datatable tr.summary-row td {
    /* Only override what's different */
    background-color: var(--sip-pm-color-surface-raised);
    font-weight: var(--sip-pm-font-weight-semibold);
}
```

### DataTables JavaScript Standards

```javascript
const tableConfig = {
    // Disable auto width to respect our CSS
    autoWidth: false,
    
    // Use fixed columns with consistent classes
    columns: [
        { 
            data: 'column1',
            className: 'sip-pm-table__cell--column1',
            render: function(data, type, row) {
                // Always return consistent HTML structure
                return '<span class="sip-pm-table__text">' + escapeHtml(data) + '</span>';
            }
        }
    ],
    
    // Consistent row callbacks
    createdRow: function(row, data, dataIndex) {
        // Add BEM classes based on data
        if (data.status) {
            $(row).addClass('sip-pm-table__row--' + data.status);
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
        column3: formatTags(rawData.column3)
    };
}

// Strip HTML consistently
function formatDescription(desc) {
    const cleanText = $('<div>').html(desc || '-').text();
    return '<span class="sip-pm-table__description">' + cleanText + '</span>';
}
```

### Column-Specific Patterns

```css
/* Use data attributes for semantic column styling */
.sip-pm-table__cell[data-column="title"] {
    text-align: left;
    font-weight: var(--sip-pm-font-weight-semibold);
}

.sip-pm-table__cell[data-column="status"] {
    text-align: center;
}

.sip-pm-table__cell[data-column="actions"] {
    text-align: center;
    white-space: nowrap;
}

/* Truncating columns */
.sip-pm-table__cell--truncate {
    max-width: 200px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

/* Multi-line cells */
.sip-pm-table__cell--wrap {
    white-space: normal;
    min-height: var(--sip-pm-table-row-height);
}
```

### DataTables Implementation Checklist

When implementing a DataTable:

1. **Structure**
   - [ ] Use consistent HTML structure with proper classes
   - [ ] Include `display sip-datatable` classes
   - [ ] Add data attributes for semantic styling

2. **Styling**
   - [ ] Extend base table component styles
   - [ ] Use BEM classes for all custom elements
   - [ ] Avoid nth-child for semantic elements
   - [ ] Ensure all row types use same column structure

3. **JavaScript**
   - [ ] Disable autoWidth
   - [ ] Format all data consistently before adding
   - [ ] Use render functions for consistent HTML
   - [ ] Add proper classes in createdRow callback

4. **Testing**
   - [ ] Verify column alignment across all row types
   - [ ] Test with empty data sets
   - [ ] Check responsive behavior
   - [ ] Validate accessibility

## Implementation Example

Here's a complete example following all standards:

```css
/*==============================================================================
COMPONENT: Product Table
Following SiP CSS Standards
==============================================================================*/

/* Component Variables */
.sip-pm-product-table {
    --table-header-bg: var(--sip-pm-color-primary);
    --table-row-height: 40px;
    --table-cell-padding: var(--sip-pm-spacing-sm);
}

/* Component Base */
.sip-pm-product-table {
    width: 100%;
    border-collapse: collapse;
    background: var(--sip-pm-color-white);
}

/* Component Elements */
.sip-pm-product-table__header {
    background: var(--table-header-bg);
    height: var(--table-row-height);
}

.sip-pm-product-table__cell {
    padding: var(--table-cell-padding);
    border: 1px solid var(--sip-pm-color-border);
}

/* Semantic Column Types */
.sip-pm-product-table__cell[data-column="title"] {
    text-align: left;
    font-weight: var(--sip-pm-font-weight-bold);
}

.sip-pm-product-table__cell[data-column="price"] {
    text-align: right;
    font-family: monospace;
}

/* Component States */
.sip-pm-product-table.is-loading {
    opacity: 0.5;
    pointer-events: none;
}

.sip-pm-product-table__row.is-selected {
    background: var(--sip-pm-color-selection);
}

/* Responsive */
@media (max-width: 768px) {
    .sip-pm-product-table__cell {
        padding: var(--sip-pm-spacing-xs);
        font-size: var(--sip-pm-font-size-small);
    }
}
```

## File Naming Conventions

### CSS Files
- Use lowercase with hyphens: `table-styles.css`, `modal-dialog.css`
- Module files: `modules/[component-name].css`
- Feature-specific: `features/[feature-name].css`
- Avoid generic names: Use `product-table.css` not `table.css`

### Import Order
1. Variables and configuration
2. Base/reset styles
3. Layout components
4. UI components
5. Feature-specific styles
6. Page-specific overrides
7. Utility classes

## Performance Considerations

### Selector Performance
- Prefer class selectors over complex selectors
- Avoid universal selectors (*)
- Minimize descendant selectors
- Use child selectors (>) when possible

### CSS Optimization
- Combine similar rules
- Use CSS variables for repeated values
- Minimize redundant declarations
- Consider critical CSS for above-fold content

## Related Documentation

- [UI Components](sip-feature-ui-components.md) - Component library including checkbox patterns
- [DataTables](sip-feature-datatables.md) - DataTables implementation guide
- [Plugin Architecture](sip-plugin-platform.md) - Overall plugin structure

This standards document should be reviewed and updated as the codebase evolves and new patterns emerge. Last updated: 2024