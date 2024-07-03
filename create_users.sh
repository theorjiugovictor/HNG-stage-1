#!/bin/bash

# Log file
LOG_FILE="/var/log/user_management.log"
# Secure file to store usernames and passwords
SECURE_FILE="/var/secure/user_passwords.csv"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Ensure log and secure file directories exist
mkdir -p /var/log
mkdir -p /var/secure

# Ensure secure file has the correct permissions
touch $SECURE_FILE
chmod 600 $SECURE_FILE

# Embedded user details
user_details=(
    "light;sudo,dev,www-data"
    "idimma;sudo"
    "mayowa;dev,www-data"
)

# Read user details array
for user_detail in "${user_details[@]}"; do
    IFS=";" read -r username groups <<< "$user_detail"
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

    # Create user and personal group
    useradd -m "$username"
    if [ $? -ne 0 ]; then
        log_message "Failed to create user $username"
        continue
    fi

    # Create personal group
    groupadd "$username"
    usermod -g "$username" "$username"

    # Generate random password
    password=$(openssl rand -base64 12)
    echo "$username:$password" | chpasswd

    # Log the password to secure file
    echo "$username,$password" >> $SECURE_FILE

    # Add user to additional groups
    if [ -n "$groups" ]; then
        IFS=',' read -ra group_array <<< "$groups"
        for group in "${group_array[@]}"; do
            group=$(echo "$group" | xargs)
            # Check if group exists, if not create it
            if ! getent group "$group" &>/dev/null; then
                groupadd "$group"
                log_message "Group $group created"
            fi
            usermod -aG "$group" "$username"
        done
    fi

    # Set appropriate permissions and ownership
    chown -R "$username:$username" "/home/$username"
    chmod 700 "/home/$username"

    log_message "User $username created and added to groups: $groups"
done

log_message "User creation script completed"