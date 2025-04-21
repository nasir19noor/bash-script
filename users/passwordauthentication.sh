#!/bin/bash

# Script to add PasswordAuthentication yes to sshd_config
# This script requires root privileges to modify system files

# Exit on error
set -e

# Check if script is run with sudo privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with sudo privileges" >&2
    echo "Please run: sudo $0" >&2
    exit 1
fi

SSH_CONFIG="/etc/ssh/sshd_config"

# Check if the sshd_config file exists
if [ ! -f "$SSH_CONFIG" ]; then
    echo "Error: $SSH_CONFIG does not exist." >&2
    exit 1
fi

echo "Checking current SSH configuration..."

# Create a backup of the original file
BACKUP_FILE="${SSH_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
cp "$SSH_CONFIG" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

# Check if PasswordAuthentication is already in the file
if grep -q "^PasswordAuthentication" "$SSH_CONFIG"; then
    # Replace existing line
    echo "Updating existing PasswordAuthentication setting..."
    sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' "$SSH_CONFIG"
else
    # Check if the line exists but is commented out
    if grep -q "^#PasswordAuthentication" "$SSH_CONFIG"; then
        echo "Uncommenting and setting PasswordAuthentication to yes..."
        sed -i 's/^#PasswordAuthentication.*$/PasswordAuthentication yes/' "$SSH_CONFIG"
    else
        # Add the line if it doesn't exist
        echo "Adding PasswordAuthentication yes to $SSH_CONFIG..."
        echo "PasswordAuthentication yes" >> "$SSH_CONFIG"
    fi
fi

echo "Verifying change..."
if grep -q "^PasswordAuthentication yes" "$SSH_CONFIG"; then
    echo "Success: PasswordAuthentication is set to yes."
    
    # Restart SSH service to apply changes
    echo "Restarting SSH service to apply changes..."
    
    # Check which service manager is in use
    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart ssh.service || systemctl restart sshd.service
    elif command -v service >/dev/null 2>&1; then
        service ssh restart || service sshd restart
    else
        echo "Warning: Could not restart SSH service automatically."
        echo "Please restart the SSH service manually to apply changes."
    fi
    
    echo "Configuration complete!"
else
    echo "Error: Failed to update SSH configuration." >&2
    echo "Please check $SSH_CONFIG manually." >&2
    exit 1
fi

exit 0