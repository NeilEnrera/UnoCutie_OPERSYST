#!/bin/bash

# Script to send the latest filesystem utilization JSON file to AlmaLinux Server 2 without requiring a password for SSH

# Print a message indicating the action
echo "Sending the latest filesystem utilization JSON file to AlmaLinux Server 2."

# Set variables
source_directory="/tmp"  # Source directory where JSON files are stored
output_logfile="/opt/filesystem/services_$(date '+%Y%m%d%H%M%S').log"  # Log file to capture script output

# Find the latest filesystem JSON file
json_filename=$(ls -t "$source_directory"/services_*.json 2>/dev/null | head -1)  # Get the latest JSON file

if [ -z "$json_filename" ]; then
    # If no JSON file found, exit script with an error message
    echo "$(date): No filesystem JSON file found in $source_directory"
    exit 1
fi

# Remote server details
ssh_user="admin"  # SSH username
ssh_host="192.168.211.129"  # IP address of the remote server
remote_opt_directory="/opt/services"  # Directory on the remote server to transfer the file

# Use SSH password for authentication (not recommended for security reasons)
ssh_password="Opersyst_2023"  # Password for SSH authentication

# Check if remote directory exists, if not create it
sshpass -p "$ssh_password" ssh "$ssh_user@$ssh_host" "[ -d \"$remote_opt_directory\" ] || mkdir -p \"$remote_opt_directory\""

# Use SCP to transfer the file without requiring a password
echo "$(date): Running SCP command to transfer $json_filename to server 2"
sshpass -p "$ssh_password" scp "$json_filename" "$ssh_user@$ssh_host:$remote_opt_directory"

# Check if SCP command was successful
if [ $? -eq 0 ]; then
    # If transfer successful, delete the file from the source directory
    echo "$(date): Deleting the file $json_filename from the source directory"
    rm "$json_filename"
    echo "$(date): Done transferring $json_filename"
else
    # If SCP command failed, print an error message
    echo "$(date): Error transferring $json_filename"
fi

# Print the location of the log file
echo "Log file is saved to $output_logfile"

