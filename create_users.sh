#!/bin/bash

# Log file
LOG_FILE="/var/log/user_management.log"
# Secure file to store usernames and passwords
SECURE_FILE="/var/secure/user_passwords.csv"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Check if argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <user_file>"
    exit 1
fi

# Check if user file exists
if [ ! -f "$1" ]; then
    echo "User file not found: $1"
    exit 1
fi

# Ensure log and secure file directories exist
mkdir -p /var/log
mkdir -p /var/secure

# Ensure log file has the correct permissions
touch "$LOG_FILE"
chmod 640 "$LOG_FILE"

# Ensure secure file has the correct permissions
touch "$SECURE_FILE"
chmod 600 "$SECURE_FILE"

# Read user file line by line
while IFS=";" read -r username groups; do
    # Remove leading/trailing whitespaces
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Skip empty lines
    [ -z "$username" ] && continue

    # Check if user already exists
    if id "$username" &>/dev/null; then
        log_message "User $username already exists"
        continue
    fi

    # Create personal group for the user
    if ! getent group "$username" &>/dev/null; then
        groupadd "$username"
        if [ $? -ne 0 ]; then
            log_message "Failed to create group $username"
            continue
        fi
    fi

    # Create user with personal group
    useradd -m -g "$username" "$username"
    if [ $? -ne 0 ]; then
        log_message "Failed to create user $username"
        continue
    else
        log_message "User $username created"
    fi

    # Generate random password
    password=$(openssl rand -base64 12)
    echo "$username:$password" | chpasswd

    # Log the password to secure file
    echo "$username,$password" >> "$SECURE_FILE"

    # Add user to additional groups
    if [ -n "$groups" ]; then
        IFS=',' read -ra group_array <<< "$groups"
        for group in "${group_array[@]}"; do
            group=$(echo "$group" | xargs)
            # Check if group exists, if not create it
            if ! getent group "$group" &>/dev/null; then
                groupadd "$group"
                if [ $? -ne 0 ]; then
                    log_message "Failed to create group $group"
                    continue
                else
                    log_message "Group $group created"
                fi
            fi
            usermod -aG "$group" "$username"
        done
    fi

    # Set appropriate permissions and ownership
    chown -R "$username:$username" "/home/$username"
    chmod 700 "/home/$username"

    log_message "User $username added to groups: $groups"
done < "$1"

log_message "User creation script completed"