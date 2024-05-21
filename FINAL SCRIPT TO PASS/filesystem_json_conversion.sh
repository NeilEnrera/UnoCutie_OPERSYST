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

# Function to delete JSON files older than 15 days in the /opt/json_archives/ directory
delete_old_json_files() {
  # Ensure json_archives directory exists
  mkdir -p /opt/json_archives  
  # Find and delete JSON files older than 15 days
  find /opt/json_archives/ -type f -name "*.json" -mtime +15 -exec rm -f {} \;
}

# Call the function to delete old JSON files
delete_old_json_files
if [ $? -eq 0 ]; then
    echo "Old JSON files deleted successfully."
else
    echo "Error: Failed to delete old JSON files."
    exit 1
fi

# Define the source directory
source_directory="/opt/filesystem"

# Find the latest JSON file in the source directory
JSON_FILE=$(find "$source_directory" -maxdepth 1 -type f -name 'filesystem_*.json' -printf '%T@ %p\n' | sort -n | tail -1 | cut -d ' ' -f 2-)

if [ -z "$JSON_FILE" ]; then
    echo "$(date): No filesystem JSON file found in $source_directory"
    exit 1
fi

echo "Latest JSON file found: $JSON_FILE"

# Check if the JSON file exists and is readable
if [[ ! -f "${JSON_FILE}" || ! -r "${JSON_FILE}" ]]; then
  echo "JSON File not Found"
  exit 1
fi

DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M:%S')

# Create the 'normal' and 'critical' directories if they do not exist
mkdir -p /opt/filesystem/{normal,critical}

# Process the JSON file with jq and perform the required actions for 'normal' filesystems
jq -r --arg DATE "$(date '+%Y/%m/%d')" --arg TIME "$(date '+%H-%M-%S')" '.[] | .filesystem_utilization[] | select((.disk_used_pct | sub("%"; "") | tonumber) < 85) | "\(.filesystem_no) normal \(.disk_used_pct) \(.directory) \( $DATE ) \( $TIME )"' "$JSON_FILE" | \
while IFS= read -r LINE; do
    # Extract the fields from the line
    FIELDS=( $(echo "$LINE" | tr ' ' '\n') )
    FILESYSTEM_NO=${FIELDS[0]}
    STATUS=${FIELDS[1]}
    DISK_PERCENTAGE=${FIELDS[2]}
    DIRECTORY=${FIELDS[3]}
    
    # Construct the filename and write the output
    FILENAME="/opt/filesystem/normal/filesystem_${FILESYSTEM_NO}_normal.txt"
    echo "filesystem_no: ${FILESYSTEM_NO}" > "$FILENAME"
    echo "status: ${STATUS}" >> "$FILENAME"
    echo "disk_percentage: ${DISK_PERCENTAGE}" >> "$FILENAME"
    echo "directory: ${DIRECTORY}" >> "$FILENAME"
    echo "date: $(date '+%Y/%m/%d')" >> "$FILENAME"
    echo "time: $(date '+%H-%M-%S')" >> "$FILENAME"
done

# Process the JSON file with jq and perform the required actions for 'critical' filesystems
jq -r --arg DATE "$DATE" --arg TIME "$TIME" '.[] | .filesystem_utilization[] | select((.disk_used_pct | sub("%"; "") | tonumber) >= 85) | "\(.filesystem_no),\(.filesystem),\(.directory),\(.disk_size),\(.disk_used),\(.disk_available),\(.disk_used_pct),CRITICAL,\($DATE),\($TIME)"' "$JSON_FILE" | \
while IFS= read -r LINE; do
    # Extract the fields from the line
    FIELDS=( $(echo "$LINE" | tr ',' '\n') )
    FILESYSTEM_NO=${FIELDS[0]}
    
    # Construct the filename and write the output
    FILENAME="/opt/filesystem/critical/filesystem_${FILESYSTEM_NO}_critical.csv"
    echo "$LINE" > "$FILENAME"
done

# Function to archive processed JSON files
archive_json_files() {
  local archive_dir="/opt/json_archives"
  mkdir -p "${archive_dir}" || { echo "Error: Failed to create directory $archive_dir"; exit 1; }
  mv "$JSON_FILE" "${archive_dir}" || { echo "Error: Failed to move JSON file."; exit 1; }
}

# Call the function to archive the processed JSON file
archive_json_files
if [ $? -eq 0 ]; then
    echo "JSON file archived successfully."
else
    echo "Error: Failed to archive JSON file."
    exit 1
fi

echo "Script executed successfully."

