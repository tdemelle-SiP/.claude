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
8. [Component Architecture](#component-architecture)
9. [Responsive Design](#responsive-design)
10. [Legacy Code Migration](#legacy-code-migration)

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
    
    /* Z-index Scale */
    --sip-pm-z-base: 1;
    --sip-pm-z-dropdown: 100;
    --sip-pm-z-sticky: 200;
    --sip-pm-z-modal: 300;
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
- Three class selectors maximum for edge cases
- Never use ID selectors for styling
- Reserve !important for utility classes only

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

### DON'T:
- ❌ Use ID selectors for styling
- ❌ Use nth-child for semantic elements
- ❌ Nest selectors more than 3 levels deep
- ❌ Use !important except in utilities
- ❌ Hard-code values that should be variables
- ❌ Mix naming conventions
- ❌ Write position-dependent CSS
- ❌ Forget responsive design

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

This standards document should be reviewed and updated as the codebase evolves and new patterns emerge.