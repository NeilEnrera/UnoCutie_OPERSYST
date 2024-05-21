#!/bin/bash

# Function to check and adjust permissions for /opt directory
check_opt_permissions() {
  # Check if /opt directory is writable
  if [ ! -w "/opt" ]; then
    echo "Error: Insufficient permissions to write to /opt directory."
    echo "Attempting to adjust permissions..."
    # Attempt to change permissions using sudo
    sudo chmod o+w /opt || { echo "Error: Failed to adjust permissions for /opt directory."; exit 1; }
    echo "Permissions adjusted successfully."
  fi
}

# Call the function to check and adjust permissions for /opt directory
check_opt_permissions

# Define the source directory
source_directory="/opt/services"

# Create directories if they do not exist
mkdir -p /opt/services/active /opt/services/inactive

# Find the latest JSON file in the source directory
JSON_FILE=$(find "$source_directory" -maxdepth 1 -type f -name 'services_*.json' -printf '%T@ %p\n' | sort -n | tail -1 | cut -d ' ' -f 2-)

if [ -z "$JSON_FILE" ]; then
    echo "$(date): No services JSON file found in $source_directory"
    exit 1
fi

echo "Latest JSON file found: $JSON_FILE"

# Check if the JSON file exists and is readable  
if [[ ! -f "${JSON_FILE}" || ! -r "${JSON_FILE}" ]]; then
  echo "JSON File not Found"
  exit 1
fi

DATE=$(date '+%Y%m%d_%H%M%S')

# Process the JSON file with jq and perform the required actions for 'active' services
jq -r '.services_state_running[] | "\n\tname: \(.service["service-name"])\n\tdescription: \(.service.description)"' "$JSON_FILE" > "/opt/services/active/services_active_${DATE}.txt"

# Process the JSON file with jq and perform the required actions for 'inactive' and 'failed' services
jq -r '.services_state_running[] | "\(.service["service-name"]),\(.service.description),\(.service.status),\(.service.sub_status)"' "$JSON_FILE" > "/opt/services/inactive/services_inactive_${DATE}.csv"

# Append failed services to the inactive file
jq -r '.services_state_failed[] | "\(.service["service-name"]),\(.service.description),\(.service.status),\(.service.sub_status)"' "$JSON_FILE" >> "/opt/services/inactive/services_inactive_${DATE}.csv"

echo "Script executed successfully."

# Delete files older than 7 days in /opt/services/active and /opt/services/inactive
find /opt/services/active -type f -mtime +7 -delete
find /opt/services/inactive -type f -mtime +7 -delete

# Delete JSON files older than 15 days in /opt/json_archives/
find /opt/json_archives/ -name '*.json' -type f -mtime +15 -delete

echo "Old files deleted successfully."

