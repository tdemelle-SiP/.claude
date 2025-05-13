# Development Environment

## System Setup

- **Operating System**: Windows 11 with WSL2 (Linux 5.15.167.4)
- **Host Machine**: Odin
- **Dev Environment**: Local by Flywheel (WordPress local development)
- **Code Editor**: Visual Studio Code with Claude integration

## Project Location

- **Windows Path**: `C:\Users\tdeme\Local Sites\faux-stained-glass-panes\app\public\wp-content\plugins\sip-plugins-core`
- **WSL Path**: `/mnt/c/Users/tdeme/Local Sites/faux-stained-glass-panes/app/public/wp-content/plugins/sip-plugins-core`
- **Screenshot Directory**: `/mnt/c/users/tdeme/Documents/VSCode_images_Repo/`

## Plugin Configuration

- **WordPress Site**: Faux Stained Glass Panes
- **Core Plugin Version**: 2.7.4
- **Update Server**: https://updates.stuffisparts.com/update-api.php

## Related Plugins

- **sip-printify-manager**: Printify integration
- **sip-woocommerce-monitor**: WooCommerce monitoring functionality
- **sip-development-tools**: Development utilities

## Local Development Tips

1. **Testing Updates**:
   - Increment version in plugin header
   - Update version in remote update server
   - Test update through WordPress plugin page

2. **Debugging**:
   - PHP errors logged to `logs/php-errors.log`
   - JavaScript debug messages in browser console
   - WordPress Debug Bar available in local environment

3. **Performance Optimizations**:
   - Use filemtime() for cache busting on CSS/JS files
   - Load JS in footer where appropriate
   - Enqueue only necessary assets