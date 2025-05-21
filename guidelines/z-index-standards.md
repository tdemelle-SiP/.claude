# Z-Index Standards for SiP Plugins

Our z-index system follows a hierarchical structure with main categories and sub/super variations. This provides a clear organization while allowing flexibility within each category.

## Z-Index Scale

| Group | Variable | Value | Purpose |
|-------|----------|-------|---------|
| **Negative** | --z-negative | -1 | Elements behind content |
| **Base** | --z-base-sub | 1 | Below standard content |
| | --z-base | 10 | Standard content |
| | --z-base-super | 50 | Above standard content |
| **Table Header** | --z-table-header-sub | 75 | Below table headers |
| | --z-table-header | 80 | Table headers |
| | --z-table-header-super | 85 | Above table headers |
| **Plugin Header** | --z-plugin-header-sub | 90 | Below plugin headers |
| | --z-plugin-header | 100 | Plugin headers, navigation |
| | --z-plugin-header-super | 200 | Dropdowns, above plugin headers |
| **Overlay** | --z-overlay-sub | 900 | Below overlays |
| | --z-overlay | 1000 | Page overlays, backdrops |
| | --z-overlay-super | 1500 | Above standard overlays |
| **Modal** | --z-modal-sub | 1900 | Below modals |
| | --z-modal | 2000 | Modal windows, dialogs |
| | --z-modal-super | 2500 | Above standard modals |
| **Toast** | --z-toast-sub | 2900 | Below toast messages |
| | --z-toast | 3000 | Toast notifications |
| | --z-toast-super | 3500 | Important notifications |
| **Spinner** | --z-spinner-sub | 3900 | Below spinners |
| | --z-spinner | 4000 | Loading spinners |
| | --z-spinner-super | 4500 | Critical spinners |
| **Top** | --z-top-sub | 8000 | High priority elements |
| | --z-top | 9000 | Very high priority |
| | --z-top-super | 9999 | Absolute highest (rare) |

## Usage Guidelines

1. Always use the appropriate z-index variable for the element's purpose
2. Use the standard (middle) value when possible
3. Use -sub and -super variants only when elements need to be specifically ordered within a layer
4. For new elements, determine which layer they belong to and use that layer's variable
5. Document any special cases with comments in the code

## Common Use Cases

| Element Type | Recommended Variable |
|--------------|---------------------|
| Plugin Headers | --z-plugin-header |
| Navigation Menus | --z-plugin-header |
| Dropdown Menus | --z-plugin-header-super |
| Table Headers | --z-table-header |
| Page Overlays | --z-overlay |
| Modal Backdrops | --z-overlay or --z-overlay-super |
| Modal Windows | --z-modal |
| Toast Messages | --z-toast |
| Loading Spinners | --z-spinner |

## Related Documents

- [CSS Guidelines](css-guidelines.md)
- [UI Components](ui-components.md)
- [SiP Plugin Architecture](plugin-architecture.md)