# CSS Guidelines for SiP Plugins

## Principles

1. **Consistency**: Follow established patterns and naming conventions
2. **Modularity**: Keep styles modular and reusable
3. **Readability**: Write clean, well-documented CSS
4. **Performance**: Minimize specificity and optimize selectors

## File Structure

CSS files should be organized in a logical structure:

```
assets/css/
├── variables.css         # Shared variables
├── sip_plugins_core.css  # Core styles
├── ui.css                # UI component styles
├── modals.css            # Modal and dialog styles
├── header.css            # Header styles
└── modules/              # Feature-specific modules
    ├── feature-1.css
    ├── feature-2.css
    └── ...
```

## CSS Variables

Always use CSS variables for consistent values:

```css
:root {
  /* Color System */
  --primary-color: #0E5274;
  --secondary-color: #aed5ea;
  
  /* Spacing */
  --spacing-xs: 2px;
  --spacing-sm: 5px;
  
  /* Font Sizes */
  --font-sm: 10px;
  --font-md: 11px;
}
```

### Z-Index Management

For z-index management, we use a standardized system across all SiP plugins. This ensures consistency and prevents z-index conflicts.

See the [Z-Index Standards](z-index-standards.md) document for detailed information on our z-index system.

Key principles:
- Always use CSS variables for z-index values
- Follow the established layer hierarchy
- Document any special cases

## Naming Conventions

Use descriptive, hyphen-separated class names:

```css
/* Good */
.product-item-container { }
.product-item-title { }

/* Avoid */
.productItemContainer { }
.product_item_title { }
```

## Comments

Use comment blocks to organize sections:

```css
/*==============================================================================
SECTION NAME
==============================================================================*/

/*------------------------------------------------------------------------------
1. Sub-section
------------------------------------------------------------------------------*/
```

## Media Queries

Place media queries at the end of each component's style section:

```css
.component {
  width: 100%;
}

@media (max-width: 768px) {
  .component {
    width: 50%;
  }
}
```

## Best Practices

1. Avoid `!important` where possible
2. Minimize nesting (max 3 levels)
3. Use shorthand properties
4. Group related properties together
5. Keep selectors as simple as possible
6. Specify proper fallbacks for variables

## Related Documents

- [Z-Index Standards](z-index-standards.md)
- [UI Components](ui-components.md)
- [SiP Plugin Architecture](plugin-architecture.md)