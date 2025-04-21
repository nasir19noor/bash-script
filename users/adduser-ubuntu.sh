#!/bin/bash

# Ubuntu-Optimized User Creation Script
# This script adds a new user to Ubuntu systems with all necessary information

# Exit immediately if a command exits with a non-zero status
set -e

# Check if script is run with sudo privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with sudo privileges" >&2
    echo "Please run: sudo $0" >&2
    exit 1
fi

# Function to get input with validation
get_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    local value=""
    
    while [ -z "$value" ]; do
        read -p "$prompt [${default:-(no default)}]: " value
        value=${value:-$default}
        if [ -z "$value" ]; then
            echo "Value cannot be empty if no default is provided."
        fi
    done
    
    eval "$var_name=\"$value\""
}

# Collect user information
echo "=== Ubuntu User Creation Wizard ==="
echo "Please provide the following information:"
echo

get_input "Username" username
get_input "Full Name" full_name
get_input "Home Directory" home_dir "/home/$username"

# For Ubuntu, default shell is /bin/bash
shell="/bin/bash"

# Ask for password or generate one
read -p "Do you want to set a password now? (y/n) [y]: " set_password
set_password=${set_password:-y}

if [[ "$set_password" =~ ^[Yy]$ ]]; then
    password_set=false
    while [ "$password_set" = false ]; do
        read -s -p "Enter password: " password
        echo
        read -s -p "Confirm password: " password_confirm
        echo
        
        if [ "$password" = "$password_confirm" ]; then
            password_set=true
        else
            echo "Passwords do not match. Please try again."
        fi
    done
else
    # Generate a random password
    password=$(< /dev/urandom tr -dc 'A-Za-z0-9!@#$%^&*' | head -c12)
    echo "Generated password: $password"
    echo "Please make note of this password."
fi

# Common Ubuntu groups
echo "Common Ubuntu groups:"
echo "  adm: System monitoring tasks"
echo "  cdrom: CD-ROM access"
echo "  lpadmin: Printer administration"
echo "  plugdev: Removable device access"
echo "  sambashare: File sharing"
echo "  docker: Docker access (if installed)"

read -p "Enter additional groups (comma-separated, leave empty for none): " additional_groups

# Ask if user should be an administrator
read -p "Should this user be an administrator (sudo access)? (y/n) [n]: " is_admin
is_admin=${is_admin:-n}

# Confirm information
echo
echo "=== User Information Summary ==="
echo "Username: $username"
echo "Full Name: $full_name"
echo "Home Directory: $home_dir"
echo "Shell: $shell"
echo "Additional Groups: ${additional_groups:-None}"
echo "Administrator: ${is_admin}"
echo

read -p "Create user with these settings? (y/n) [y]: " confirm
confirm=${confirm:-y}

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "User creation cancelled."
    exit 0
fi

# Create the user
echo "Creating user $username..."

# Add user to system
adduser --home "$home_dir" --shell "$shell" --gecos "$full_name" --disabled-password "$username"

# Set password
echo "$username:$password" | chpasswd

# Add to additional groups
if [ -n "$additional_groups" ]; then
    for group in ${additional_groups//,/ }; do
        if getent group "$group" > /dev/null; then
            usermod -aG "$group" "$username"
            echo "Added $username to group $group."
        else
            echo "Warning: Group $group does not exist. Skipping."
        fi
    done
fi

# Add to sudo group if requested
if [[ "$is_admin" =~ ^[Yy]$ ]]; then
    usermod -aG sudo "$username"
    echo "Added $username to sudo group for administrator privileges."
fi

# Set up .profile and .bashrc
if [ -d "/etc/skel" ]; then
    # Copy any missing default files from /etc/skel
    for file in /etc/skel/.*; do
        base_file=$(basename "$file")
        if [[ "$base_file" != "." && "$base_file" != ".." && ! -e "$home_dir/$base_file" ]]; then
            cp -a "$file" "$home_dir/$base_file"
            chown "$username:$username" "$home_dir/$base_file"
        fi
    done
fi

# Ensure proper ownership of home directory
chown -R "$username:$username" "$home_dir"

# Show success message
echo
echo "=== Success ==="
echo "User $username has been created successfully on this Ubuntu system!"
echo "Home directory: $home_dir"
if [[ "$set_password" =~ ^[Yy]$ ]]; then
    echo "Password: [As entered]"
else
    echo "Password: $password"
fi

echo
echo "The user can change their password after logging in with:"
echo "passwd"
echo

exit 0