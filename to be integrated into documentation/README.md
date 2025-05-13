# SiP Plugin Suite Documentation

## Overview

The SiP (Stuff is Parts) Plugin Suite is a framework for creating and managing a collection of WordPress plugins. It consists of a core plugin (SiP Plugins Core) and individual SiP plugins that integrate with this core.

# Structure

## SiP Plugins Core

The core plugin provides the following functionality:

- Creates a main menu item in the WordPress admin for all SiP plugins.
- Manages the activation and deactivation of SiP plugins.
- Provides a framework for SiP plugins to register themselves.

### Key Components

- `SiP_Plugins_Core` class: Manages the core functionality.
- `add_menu_pages()`: Creates the main SiP Plugins menu.
- `deactivate_core()`: Deactivates all SiP plugins when the core is deactivated.

## Setting Up a New SiP Plugin

To create a new plugin that works with the SiP suite:

1. Create a folder in the plugins directory and name your plugin `sip-plugin-name`
1. Create a new PHP file for your plugin (e.g., `sip-my-plugin.php`).
2. Use the following template:

```php
<?php
/*
Plugin Name: SiP My Plugin
Description: Description of your plugin
Version: 1.0
Author: Your Name
*/

if (!defined('ABSPATH')) exit; // Exit if accessed directly

class SiP_My_Plugin {
    private static $instance = null;

    private function __construct() {
        add_action('plugins_loaded', array($this, 'init'));
    }

    public static function get_instance() {
        if (null === self::$instance) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function init() {
        if (function_exists('sip_plugins_core')) {
            add_action('admin_menu', array($this, 'register_submenu'), 20);
        }
    }

    public function register_submenu() {
        add_submenu_page(
            'sip-plugins',
            'My Plugin',
            'My Plugin',
            'manage_options',
            'sip-my-plugin',
            array($this, 'render_admin_page')
        );
    }

    public static function render_admin_page() {
        echo '<div class="wrap">';
        echo '<h1>My Plugin</h1>';
        echo '<p>This is the admin page for My Plugin.</p>';
        echo '</div>';
    }

    // Add your plugin's functionality here
}

function sip_my_plugin() {
    return SiP_My_Plugin::get_instance();
}

sip_my_plugin();
```

3. Customize the plugin name, description, and functionality as needed.
4. Ensure your plugin file starts with `sip-` for proper integration.

## Activation and Deactivation

- When any SiP plugin is activated, it will automatically activate the SiP Plugins Core if it's not already active.
- When the SiP Plugins Core is deactivated, it will deactivate all other SiP plugins.

## Best Practices

1. Always check if the core plugin is active before adding your plugin's functionality.
2. Use the provided hooks and methods for integration with the core.
3. Follow WordPress coding standards and best practices in your plugin development.

## Troubleshooting

If you encounter issues:

1. Ensure all SiP plugins follow the naming convention (starting with `sip-`).
2. Check that the SiP Plugins Core is installed and activated.
3. Verify that your plugin is properly hooked into the `plugins_loaded` action.
4. Review the WordPress debug log for any error messages.

The manager is responsible for creating the icon in the wp-admin sidebar and the top level SiP Plugins Suite page as described below. Although each individual sip plugin will have the capacity to install the manager by itself, only the first installed sip plugin will actually install it and only the last remaining sip plugin will uninstall it when it is deactivated and deleted.

When the first installed sip plugin suite plugin is activated, the sip suite manager adds a new tab with a custom icon to the wordpress admin side bar.

When the SiP Plugins tab in the sidebar is rolled over, there is a flyout that shows two entries
	-SiP Plugins (driven by the manager)
	-<The installed sip plugin>

Selecting "SiP plugins" from the flyout will bring up an admin page showing
	A list of all the available sip-plugins and appropriate actions that can be taken including "Install, activate, dashboard, deactivate, remove"

Clicking a plugin's dashboard link in the SiP Plugins tab will bring up it's specific plugin controls and settings page.