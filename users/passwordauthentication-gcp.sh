#!/bin/bash

# Script to modify PasswordAuthentication setting in cloud image SSH config
# This script specifically checks for and modifies /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

# Exit on error
set -e

# Check if script is run with sudo privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with sudo privileges" >&2
    echo "Please run: sudo $0" >&2
    exit 1
fi

CLOUD_CONFIG="/etc/ssh/sshd_config.d/60-cloudimg-settings.conf"

# Check if the cloud config file exists
if [ ! -f "$CLOUD_CONFIG" ]; then
    echo "Notice: $CLOUD_CONFIG does not exist on this system."
    echo "This script is intended for Ubuntu cloud images that contain this file."
    exit 0
fi

echo "Found cloud image SSH configuration file: $CLOUD_CONFIG"

# Create a backup of the original file
BACKUP_FILE="${CLOUD_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
cp "$CLOUD_CONFIG" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

# Check if the file contains PasswordAuthentication no
if grep -q "PasswordAuthentication no" "$CLOUD_CONFIG"; then
    echo "Found 'PasswordAuthentication no' in the file. Changing to 'PasswordAuthentication yes'..."
    
    # Replace the setting
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' "$CLOUD_CONFIG"
    
    # Verify the change
    if grep -q "PasswordAuthentication yes" "$CLOUD_CONFIG"; then
        echo "Successfully updated the configuration."
    else
        echo "Error: Failed to update the configuration." >&2
        echo "Please check $CLOUD_CONFIG manually." >&2
        exit 1
    fi
else
    echo "The file does not contain 'PasswordAuthentication no'."
    
    # Check if it already has the setting we want
    if grep -q "PasswordAuthentication yes" "$CLOUD_CONFIG"; then
        echo "The file already contains 'PasswordAuthentication yes'. No changes needed."
    else
        echo "Adding 'PasswordAuthentication yes' to the file..."
        echo "PasswordAuthentication yes" >> "$CLOUD_CONFIG"
        echo "Setting added successfully."
    fi
fi

# Restart SSH service to apply changes
echo "Restarting SSH service to apply changes..."

# Check which service manager is in use
if command -v systemctl >/dev/null 2>&1; then
    systemctl restart ssh.service || systemctl restart sshd.service
    echo "SSH service restarted successfully."
elif command -v service >/dev/null 2>&1; then
    service ssh restart || service sshd restart
    echo "SSH service restarted successfully."
else
    echo "Warning: Could not restart SSH service automatically."
    echo "Please restart the SSH service manually to apply changes:"
    echo "sudo systemctl restart ssh.service"
    echo "or"
    echo "sudo service ssh restart"
fi

echo
echo "Configuration complete!"
echo "Password authentication is now enabled in the cloud image configuration."

exit 0