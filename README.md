# HNG-stage-1
# User Creation Bash Script

This repository contains a Bash script `create_users.sh` that automates the creation of users and groups based on a specified input file. The script ensures secure handling of user passwords, sets up appropriate permissions, and logs all actions.

## Script Overview

The `create_users.sh` script reads a text file containing usernames and group names, where each line is formatted as `user;groups`. It then creates the specified users and groups, sets up home directories, generates random passwords for the users, and logs all actions to `/var/log/user_management.log`. Additionally, it stores the generated passwords securely in `/var/secure/user_passwords.csv`.

## Usage

1. **To Ensure the script is executable**:

   sudo chmod +x create_users.sh
