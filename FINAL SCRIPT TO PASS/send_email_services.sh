#!/bin/bash

# Dummy recipient email address
recipient="ninjagoblok0@gmail.com"

# Directory containing CSV files for inactive services
inactive_dir="/opt/services/inactive"

# Check if there are CSV files present for inactive services
if ls ${inactive_dir}/services_inactive_*.csv 1> /dev/null 2>&1; then
    # Initialize email body
    body=$(echo -e "Hi,\n\nPlease start the following services immediately:\n")

    # Loop through each CSV file for inactive services
    for file in ${inactive_dir}/services_inactive_*.csv; do
        filename=$(basename "$file")
        while IFS=, read -r unit description status _; do
            if [[ "$status" == "inactive" || "$status" == "failed" ]]; then
                body+="\nService Name: ${unit}\nDescription: ${description}\n"
            fi
        done < "$file"
    done

    body+="\n---------------------------------------------------------\nDo Not Reply, this is an Automated Email.\n\nThank you."

    # Email subject
    subject="[FAILED] ALMALINUX SERVICES"

    # Sending email
    echo -e "${body}" | mailx -s "${subject}" "${recipient}" >/dev/null 2>&1

    echo "Email sent to ${recipient} with inactive services information."
else
    echo "No CSV files found for inactive services."
fi

