#!/bin/bash

# Script to convert console.log to debug.log in SiP plugin JavaScript files

# Function to convert a single JS file
convert_file() {
    local file=$1
    echo "Converting: $file"
    
    # Add debug declaration at the top if not already present
    if ! grep -q "const debug = SiP.Core.debug || console;" "$file"; then
        # Find the line after the namespace declarations
        sed -i '/^SiP\..* = SiP\..* || {};$/a\\n// Use debug utility if available, fallback to console if not\nconst debug = SiP.Core.debug || console;' "$file"
    fi
    
    # Replace console.log with debug.log
    sed -i 's/console\.log/debug.log/g' "$file"
    
    # Replace console.error with debug.error
    sed -i 's/console\.error/debug.error/g' "$file"
    
    # Replace console.warn with debug.warn
    sed -i 's/console\.warn/debug.warn/g' "$file"
    
    echo "✓ Converted: $file"
}

# Directory containing JavaScript modules
MODULES_DIR="/mnt/c/Users/tdeme/Local Sites/faux-stained-glass-panes/app/public/wp-content/plugins/sip-printify-manager/assets/js/modules"
CORE_DIR="/mnt/c/Users/tdeme/Local Sites/faux-stained-glass-panes/app/public/wp-content/plugins/sip-printify-manager/assets/js/core"
MAIN_JS="/mnt/c/Users/tdeme/Local Sites/faux-stained-glass-panes/app/public/wp-content/plugins/sip-printify-manager/assets/js/main.js"

echo "Starting debug conversion for SiP Printify Manager..."

# Convert all module files
if [ -d "$MODULES_DIR" ]; then
    for file in "$MODULES_DIR"/*.js; do
        if [ -f "$file" ]; then
            convert_file "$file"
        fi
    done
fi

# Convert core files
if [ -d "$CORE_DIR" ]; then
    for file in "$CORE_DIR"/*.js; do
        if [ -f "$file" ]; then
            convert_file "$file"
        fi
    done
fi

# Convert main.js
if [ -f "$MAIN_JS" ]; then
    convert_file "$MAIN_JS"
fi

echo "Debug conversion complete!"