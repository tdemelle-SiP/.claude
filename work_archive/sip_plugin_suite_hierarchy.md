# SIP Plugin Suite File Hierarchy

This document provides a comprehensive overview of the file structure for all SIP plugins.

## SIP Development Tools (v1.4.5)

```
sip-development-tools/
├── assets/
│   ├── css/
│   │   ├── admin.css
│   │   ├── diagnostics.css
│   │   ├── layout.css
│   │   ├── release-actions.css
│   │   └── tabs.css
│   └── js/
│       ├── main.js
│       └── modules/
│           ├── git-actions.js
│           ├── release-actions.js
│           └── system-diagnostics.js
├── changelogs/
│   └── sip-plugins-core-changelog.txt
├── includes/
│   ├── ajax-handler.php
│   ├── development-tools-ajax-shell.php
│   ├── git-functions.php
│   ├── release-functions.php
│   └── system-diagnostics.php
├── info/
│   ├── plugins.json
│   └── sip-plugins-core-description.html
├── logs/
│   ├── index.php
│   └── [various release logs]
├── sip-development-tools.php
├── tools/
│   ├── README.md
│   ├── SiP-GitUtilities.psm1
│   ├── SiP-SystemDiagnostics.psm1
│   ├── env-variables.log
│   ├── release-plugin.ps1
│   └── test-command-execution.ps1
├── utils/
│   └── check-error-logs.php
└── work/
    ├── README-testing.md
    ├── debug-zip-creation.php
    ├── improved-zip-creation.php
    ├── release-plugin-patch.md
    ├── test-git-identity.bat
    ├── test-git-identity.ps1
    ├── test-identity-fix.ps1
    ├── test-release-script.ps1
    ├── test-release.bat
    └── test-zip-creation.php
```

## SIP Plugins Core (v2.8.0)

```
sip-plugins-core/
├── Progress-Dialog Step by Step.md
├── README.md
├── assets/
│   ├── css/
│   │   ├── header.css
│   │   ├── modals.css
│   │   ├── sip_plugins_core.css
│   │   └── ui.css
│   ├── images/
│   │   ├── SiP-Logo-24px.svg
│   │   ├── SiP-LogoBlue44.svg
│   │   └── spinner.webp
│   ├── js/
│   │   ├── core/
│   │   │   ├── ajax.js
│   │   │   ├── state.js
│   │   │   └── utilities.js
│   │   └── modules/
│   │       ├── direct-updater.js
│   │       ├── network-filter-helper.js
│   │       ├── photoswipe-lightbox.js
│   │       └── progress-dialog.js
│   └── lib/
│       ├── codemirror/
│       │   └── cm-resize.js
│       └── photoswipe/
│           ├── photoswipe-custom.css
│           ├── photoswipe-lightbox.umd.min.js
│           ├── photoswipe.css
│           └── photoswipe.umd.min.js
├── docs/
│   └── AJAX-PATTERNS.md
├── includes/
│   ├── ajax-handler.php
│   ├── class-ajax-response.php
│   ├── path-utilities.php
│   ├── plugin-updater.php
│   └── ui-components.php
├── logs/
│   └── php-errors.log
├── sip-plugin-framework.php
├── sip-plugins-core.php
└── work/
    ├── ajax_js_reference.js
    └── test-path-handling.php
```

## SIP Printify Manager (v3.1.3)

```
sip-printify-manager/
├── assets/
│   ├── css/
│   │   └── modules/
│   │       ├── base.css
│   │       ├── catalog-images.css
│   │       ├── json-editor.css
│   │       ├── layout.css
│   │       ├── modals.css
│   │       ├── tables.css
│   │       └── variables.css
│   ├── js/
│   │   ├── core/
│   │   │   └── utilities.js
│   │   ├── main.js
│   │   └── modules/
│   │       ├── catalog-image-index-actions.js
│   │       ├── creation-table-actions.js
│   │       ├── creation-table-setup-actions.js
│   │       ├── image-actions.js
│   │       ├── json-editor-actions.js
│   │       ├── product-actions.js
│   │       ├── shop-actions.js
│   │       ├── sync-products-to-shop-actions.js
│   │       └── template-actions.js
│   ├── photoswipe/
│   │   ├── photoswipe-lightbox.umd.min.js
│   │   ├── photoswipe.css
│   │   └── photoswipe.umd.min.js
│   ├── spinner.webp
│   └── thumbnail-icon.png
├── includes/
│   ├── catalog-image-index-functions.php
│   ├── creation-table-functions.php
│   ├── creation-table-setup-functions.php
│   ├── icon-functions.php
│   ├── image-functions.php
│   ├── json-editor-functions.php
│   ├── printify-ajax-shell.php
│   ├── product-functions.php
│   ├── shop-functions.php
│   ├── sync-products-to-shop-functions.php
│   ├── template-functions.php
│   └── utilities.php
├── sip-printify-manager.php
├── views/
│   └── dashboard-html.php
└── work/
    ├── [documentation files]
    └── [implementation files]
```

## SIP WooCommerce Monitor (v1.1.2)

```
sip-woocommerce-monitor/
├── assets/
│   ├── css/
│   │   ├── admin-bar-toggle.css
│   │   ├── modules/
│   │   │   ├── base.css
│   │   │   ├── popup-window.css
│   │   │   ├── variables.css
│   │   │   └── woocommerce-events.css
│   │   └── product-tables.css
│   └── js/
│       ├── core/
│       │   ├── event-poller.js
│       │   ├── utilities.js
│       │   └── woocommerce-event-utilities.js
│       ├── main.js
│       └── modules/
│           ├── popup-window.js
│           ├── woocommerce-events-actions.js
│           └── woocommerce-products-actions.js
├── includes/
│   ├── event-hooks-functions.php
│   ├── event-logger-functions.php
│   ├── event-query-functions.php
│   ├── product-functions.php
│   ├── settings-functions.php
│   ├── utilities.php
│   ├── woocommerce-functions.php
│   └── woocommerce-monitor-ajax-shell.php
├── sip-woocommerce-monitor.php
└── views/
    ├── dashboard-html.php
    └── popup-window.php
```

## Common Structure Patterns

All SIP plugins follow a consistent organization pattern:

1. **Main plugin file** - Root PHP file with plugin metadata
2. **assets/** - CSS, JS, and media resources
   - css/ - Stylesheets
   - js/ - JavaScript files organized in core and modules
3. **includes/** - PHP functional components
4. **views/** - HTML templates for UI components (when applicable)
5. **work/** - Development files and documentation