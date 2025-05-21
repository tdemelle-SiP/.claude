# UI Components for SiP Plugins

## Component Design Principles

1. **Consistency**: Components should have a consistent look and feel across all SiP plugins
2. **Accessibility**: All components should be accessible and follow WCAG guidelines
3. **Responsive**: Components should work across different screen sizes
4. **Performance**: Components should be optimized for performance

## Core Components

### Headers

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

### Buttons

Use the standard button classes:

```html
<button class="button">Default Button</button>
<button class="button button-primary">Primary Button</button>
<button class="button button-secondary">Secondary Button</button>
```

### Progress Dialog

Progress dialogs are used for long-running operations:

```html
<div class="sip-dialog progress-dialog">
  <div class="progress-bar">
    <div class="progress-fill" style="width: 50%;"></div>
  </div>
  <div class="status-log">
    <!-- Status messages -->
  </div>
</div>
```

### Toast Notifications

Toast notifications are used for temporary messages:

```html
<div id="toast-container">
  <div class="toast">Your message here</div>
</div>
```

## Component Stacking

SiP plugins use a standardized z-index system to ensure proper stacking of UI components. When creating new components, refer to the [Z-Index Standards](z-index-standards.md) document to determine appropriate z-index values.

## Style Customization

All components use CSS variables for theming and can be customized by modifying these variables:

```css
:root {
  --primary-color: #0E5274;
  --secondary-color: #aed5ea;
  /* ... */
}
```

## JavaScript Behavior

Use the SiP Core JavaScript utilities for component behaviors:

```javascript
// Example: Show a toast notification
SiP.Core.utilities.showToast('Operation completed successfully');

// Example: Show a progress dialog
SiP.Core.utilities.showProgressDialog('Processing', 'Please wait...');
```

## Related Documents

- [CSS Guidelines](css-guidelines.md)
- [Z-Index Standards](z-index-standards.md)
- [SiP Plugin Architecture](plugin-architecture.md)