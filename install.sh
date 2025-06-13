#!/bin/bash

# Exit on error
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Make the script executable
chmod +x "$SCRIPT_DIR/conf_checksum"

# Create symlink in /usr/local/bin
ln -sf "$SCRIPT_DIR/conf_checksum" /usr/local/bin/conf_checksum

echo "conf_checksum has been installed successfully!"
echo "You can now use the 'conf_checksum' command from anywhere." 
