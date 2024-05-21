#!/bin/bash

# Define recipient email
recipient="ninjagoblok0@gmail.com"

# Define hostname and IP address
hostname_ip="192.168.211.129"

# Define directory containing critical CSV files
critical_dir="/opt/filesystem/critical"

# Check if there are critical CSV files present
if ls "${critical_dir}"/filesystem_*.csv 1> /dev/null 2>&1; then
    # Initialize email body
    body="Hi,\n\nPlease address the following filesystems immediately.\n\n"
    body+="Hostname IP address: ${hostname_ip}\n\n"

    # Loop through each critical CSV file
    while IFS= read -r file; do
        filename=$(basename "$file")
        filesystem_no=$(echo "$filename" | cut -d'_' -f2 | cut -d'.' -f1)
        filesystem_info=$(tail -n 1 "$file")

        directory=$(echo "$filesystem_info" | cut -d',' -f3)
        disk_used_percentage=$(echo "$filesystem_info" | cut -d',' -f7)

        # Check if the directory and disk usage percentage match the criteria
        if [ "$directory" = "/run/media/admin/AlmaLinux-9-2-x86_64-dvd" ] && [ "$disk_used_percentage" = "100%" ]; then
            body+="Directory: ${directory}\n"
            body+="Disk Used Percentage: ${disk_used_percentage}\n\n"
        fi
    done < <(find "${critical_dir}" -type f -name "filesystem_*.csv")

    if [ -z "$body" ]; then
        echo "No critical filesystems found matching the specified criteria."
    else
        body+="Do Not Reply, this is an Automated Email.\n\nThank you."

        # Prepare email subject
        subject="[CRITICAL] ALMALINUX SERVER FILESYSTEM"

        # Send email using 'echo' command
        echo -e "${body}" | mailx -s "${subject}" "${recipient}"

        # Log the email sending for record-keeping
        echo "Email sent to ${recipient} with critical filesystem information."
    fi
else
    echo "No critical filesystem CSV files found."
fi

