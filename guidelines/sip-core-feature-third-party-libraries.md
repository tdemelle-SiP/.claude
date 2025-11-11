# Third-Party Library Integration

This guide explains how to properly integrate third-party JavaScript and CSS libraries into the SiP Plugins Core platform.

## Overview

Third-party libraries extend the functionality of SiP plugins by providing specialized features like data tables (DataTables) and image galleries (PhotoSwipe). These libraries must be integrated consistently to ensure proper dependency management, security, and WordPress.org compliance.

## Integration Standards

### PRIMARY RULE: All Libraries Must Be Stored Locally

**This is mandatory for WordPress.org compliance.** All JavaScript and CSS libraries must be bundled with the plugin and served from the plugin's directory.

#### Why Local Storage is Required:

1. **WordPress.org Compliance** - The official plugin repository requires all assets to be included
2. **Security** - Prevents code injection from compromised CDNs
3. **Privacy** - No user data is exposed to third-party servers
4. **GDPR Compliance** - No additional privacy notices needed
5. **Reliability** - No external dependencies that could fail
6. **Offline Capability** - Works in development/staging environments without internet

### Storage Location

All third-party libraries must be stored in:
```
/assets/lib/[library-name]/
```

Include all necessary files:
- Minified JavaScript files (`.min.js`)
- Minified CSS files (`.min.css`)
- Required assets (fonts, images, sprites)
- Source maps if available (`.map`)

### No CDN Usage

CDN loading is **not permitted** for any JavaScript or CSS libraries. This includes:
- ❌ cdnjs.cloudflare.com
- ❌ cdn.jsdelivr.net
- ❌ unpkg.com
- ❌ Any other external CDN

The only exception in WordPress.org guidelines is for font services (Google Fonts, etc.), though even these are discouraged for privacy reasons.

### File Structure

```
sip-plugins-core/
└── assets/
    └── lib/
        ├── photoswipe/
        │   ├── photoswipe.umd.min.js
        │   ├── photoswipe-lightbox.umd.min.js
        │   ├── photoswipe.css
        │   └── photoswipe-custom.css
        ├── datatables/
        │   ├── datatables.min.js
        │   ├── datatables.min.css
        │   ├── datatables.select.min.js
        │   ├── select.dataTables.min.css
        │   ├── datatables.rowGroup.min.js
        │   └── rowGroup.dataTables.min.css
        └── codemirror/
            ├── codemirror.min.js
            ├── codemirror.min.css
            ├── addon/fold/
            │   └── [fold addons]
            └── mode/
                └── [syntax modes]
```

## Implementation Steps

### 1. Add Library Files

For local storage:
```bash
# Create directory
mkdir -p assets/lib/library-name

# Add library files
# - Download minified versions
# - Include source maps if available
# - Include required CSS/images
```

### 2. Register in Platform Loader

Add to `sip_core_load_platform()` function in `sip-plugins-core.php`:

```php
// All libraries must be stored locally
wp_enqueue_style('library-name-css', 
    plugin_dir_url(__FILE__) . 'assets/lib/library-name/library.min.css', 
    [], // dependencies
    '1.0.0' // version
);

wp_enqueue_script('library-name-js', 
    plugin_dir_url(__FILE__) . 'assets/lib/library-name/library.min.js', 
    ['jquery'], // dependencies
    '1.0.0', // version
    true // in footer
);
```

### 3. Create Module Wrapper (if needed)

For complex libraries, create a wrapper module in `/assets/js/modules/`:

```javascript
// library-name.js
SiP.Core.libraryName = (function($) {
    const debug = SiP.Core.debug || console;
    
    debug.log('▶ library-name.js Loading...');
    
    // Private methods
    function initialize(options) {
        // Library initialization code
    }
    
    // Public API
    return {
        init: initialize,
        // other public methods
    };
    
})(jQuery);
```

### 4. Handle Special Requirements

Some libraries need special handling:

```php
// For ES6 modules (like PhotoSwipe)
add_filter('script_loader_tag', function($tag, $handle, $src) {
    $module_scripts = ['photoswipe', 'photoswipe-lightbox'];
    if (in_array($handle, $module_scripts)) {
        $tag = str_replace('<script ', '<script type="module" ', $tag);
    }
    return $tag;
}, 10, 3);
```

## Current Third-Party Libraries

All libraries are stored locally as per WordPress.org requirements.

**Total size of all third-party libraries: ~464KB**

This includes:

### PhotoSwipe (v5.4.4)
- **Storage**: `/assets/lib/photoswipe/`
- **Purpose**: Image lightbox galleries
- **Files**: 
  - `photoswipe.umd.min.js`
  - `photoswipe-lightbox.umd.min.js`
  - `photoswipe.css`
  - `photoswipe-custom.css`
- **Special**: Requires `type="module"` attribute
- **Size**: ~84KB total

### DataTables (v2.2.1)
- **Storage**: `/assets/lib/datatables/`
- **Purpose**: Advanced table functionality
- **Files**:
  - `datatables.min.js` (core)
  - `datatables.min.css` (core styles)
  - `datatables.select.min.js` (Select extension v3.0.0)
  - `select.dataTables.min.css` (Select styles)
  - `datatables.rowGroup.min.js` (RowGroup extension v1.5.1)
  - `rowGroup.dataTables.min.css` (RowGroup styles)
- **Dependencies**: jQuery
- **Size**: ~150KB total

### CodeMirror (v5.65.13)
- **Storage**: `/assets/lib/codemirror/`
- **Purpose**: Code editor with syntax highlighting
- **Files**:
  - `codemirror.min.js` (core)
  - `codemirror.min.css` (core styles)
  - `addon/fold/` (code folding addons)
  - `mode/` (syntax highlighting for XML, JS, CSS, HTML)
- **Dependencies**: jQuery
- **Size**: ~230KB total
- **Documentation**: See [CodeMirror Integration Guide](./sip-core-feature-codemirror.md)

## Best Practices

### 1. Version Management
- Always specify exact versions
- Document version updates in code comments
- Test thoroughly when updating versions

### 2. Dependency Declaration
```php
// Good - explicit dependencies
wp_enqueue_script('my-module',
    $url,
    ['jquery', 'library-name-js'], // Depends on library
    $version,
    true
);

// Bad - missing dependency
wp_enqueue_script('my-module', $url, ['jquery'], $version, true);
```

### 3. Conditional Loading
Only load libraries on pages that need them:

```php
public function enqueue_admin_scripts($hook) {
    // Load platform (includes core libraries)
    sip_core_load_platform();
    
    // Page-specific libraries
    if ($hook === 'specific_page_hook') {
        wp_enqueue_script('special-library');
    }
}
```

### 4. CSS Customization
Override library styles using SiP CSS variables:

```css
/* Example: datatables.css */
.dataTables_wrapper .dataTables_filter input {
    border-color: var(--sip-color-border);
}

.dataTables_wrapper .dataTables_paginate .paginate_button.current {
    background-color: var(--sip-color-primary);
    color: var(--sip-color-bg-white);
}
```

### 5. Module Pattern
Wrap complex libraries in SiP module pattern:

```javascript
SiP.Core.libraryWrapper = (function($) {
    // Private state
    let instance = null;
    
    // Initialize library
    function init(options) {
        instance = new LibraryConstructor(options);
        return instance;
    }
    
    // Destroy and cleanup
    function destroy() {
        if (instance) {
            instance.destroy();
            instance = null;
        }
    }
    
    return { init, destroy };
})(jQuery);
```

## Adding New Libraries

### Evaluation Criteria
1. **License**: Must be compatible with commercial use (MIT, Apache, BSD)
2. **Size**: Consider impact on page load
3. **Dependencies**: Minimize additional dependencies
4. **Maintenance**: Active development and community
5. **Alternatives**: Evaluate multiple options

### Integration Checklist
- [ ] Evaluate library and license
- [ ] Download or identify CDN source
- [ ] Add files to `/assets/lib/` if storing locally
- [ ] Register in `sip_core_load_platform()`
- [ ] Create wrapper module if needed
- [ ] Add CSS customizations
- [ ] Document in this guide
- [ ] Test on all SiP plugin pages

## Troubleshooting

### Common Issues

1. **Library not loading**
   - Check handle names for typos
   - Verify dependencies are correct
   - Check browser console for 404 errors

2. **Style conflicts**
   - Use specific selectors
   - Override with SiP CSS variables
   - Load custom CSS after library CSS

3. **JavaScript errors**
   - Check load order (dependencies)
   - Verify library version compatibility
   - Check for global variable conflicts

### Debug Loading
```javascript
// In browser console
console.log('jQuery loaded:', typeof jQuery);
console.log('DataTables loaded:', typeof $.fn.DataTable);
console.log('SiP modules:', Object.keys(SiP.Core));
```

## Examples

### Simple Local Library
```php
// In sip_core_load_platform()
// All libraries must be stored locally for WordPress.org compliance
wp_enqueue_script('moment-js',
    plugin_dir_url(__FILE__) . 'assets/lib/moment/moment.min.js',
    [],
    '2.29.4',
    true
);
```

### Complex Local Library with Module
```php
// In sip_core_load_platform()
wp_enqueue_style('library-css', 
    plugin_dir_url(__FILE__) . 'assets/lib/library/library.min.css',
    [],
    '1.0.0'
);

wp_enqueue_script('library-js',
    plugin_dir_url(__FILE__) . 'assets/lib/library/library.min.js',
    ['jquery'],
    '1.0.0',
    true
);

wp_enqueue_script('sip-library-module',
    plugin_dir_url(__FILE__) . 'assets/js/modules/library-wrapper.js',
    ['jquery', 'library-js', 'sip-core-utilities'],
    filemtime(plugin_dir_path(__FILE__) . 'assets/js/modules/library-wrapper.js'),
    true
);
```

## Migration from CDN to Local

If you have existing CDN-loaded libraries, follow these steps:

### 1. Download Library Files
```bash
# Create directory
mkdir -p assets/lib/library-name

# Download files (example for a typical library)
cd assets/lib/library-name
curl -L -o library.min.js "https://cdn.example.com/library/1.0.0/library.min.js"
curl -L -o library.min.css "https://cdn.example.com/library/1.0.0/library.min.css"
```

### 2. Download Additional Assets
Check the CSS file for references to fonts, images, or other assets:
```bash
# Look for url() references in CSS
grep -o "url([^)]*)" library.min.css
```

Download any referenced assets and update the paths in the CSS file.

### 3. Update Enqueue Calls
Replace CDN URLs with local paths:

```php
// OLD (CDN)
wp_enqueue_script('library-js',
    'https://cdn.example.com/library/1.0.0/library.min.js',
    ['jquery'],
    '1.0.0',
    true
);

// NEW (Local)
wp_enqueue_script('library-js',
    plugin_dir_url(__FILE__) . 'assets/lib/library-name/library.min.js',
    ['jquery'],
    '1.0.0',
    true
);
```

### 4. Test Thoroughly
- Clear browser cache
- Check browser console for 404 errors
- Verify all functionality works correctly
- Test in different browsers

### 5. Update Documentation
- Add the library to this guide
- Update any implementation examples
- Document any special requirements

## Compliance Checklist

Before releasing any plugin:

- [ ] All JavaScript libraries are stored locally
- [ ] All CSS libraries are stored locally
- [ ] No CDN URLs in wp_enqueue_script() calls
- [ ] No CDN URLs in wp_enqueue_style() calls
- [ ] All library assets (images, fonts) are included
- [ ] Version numbers are specified for all libraries
- [ ] Libraries are stored in `/assets/lib/[library-name]/`
- [ ] Documentation is updated

## Version Update Process

When updating a third-party library:

1. **Check for Breaking Changes**
   - Review the library's changelog
   - Check for API changes
   - Test in a development environment

2. **Download New Version**
   ```bash
   cd assets/lib/library-name
   # Backup old version
   mv library.min.js library.min.js.backup
   # Download new version
   curl -L -o library.min.js "https://..."
   ```

3. **Update Version Numbers**
   - Update version in wp_enqueue calls
   - Update version in documentation
   - Update version in plugin header if significant

4. **Test Thoroughly**
   - Test all features that use the library
   - Check browser console for errors
   - Verify backward compatibility

5. **Document the Update**
   - Add to plugin changelog
   - Update this documentation
   - Note any migration steps needed

This approach ensures consistent, maintainable, and WordPress.org compliant integration of third-party libraries across the SiP plugin ecosystem.