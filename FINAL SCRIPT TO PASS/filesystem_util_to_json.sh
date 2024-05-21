#!/bin/bash

# This script collects filesystem utilization information and saves it into a single JSON file.

# Define a function to construct a JSON object for each filesystem.
construct_json_object() {
    cat <<EOF
{
  "filesystem_utilization": [
    {
      "filesystem_no": "$1",
      "filesystem": "$2",
      "disk_size": "$3",
      "disk_used": "$4",
      "disk_available": "$5",
      "disk_used_pct": "$6",
      "directory": "$7"
    }
  ]
}
EOF
}

# Use the df -k command to get filesystem utilization information in kilobytes and store it in a variable.
# The output of df -k has six columns: the filesystem name, disk size, disk used, disk available, disk used percentage, and directory.
filesystem_data=$(df -k)

# Define the JSON file name with the current date and time in the format of YYYYMMDD_HHMMSS.
json_filename="/tmp/filesystem_$(date '+%Y%m%d_%H%M%S').json"

# Initialize a counter variable for the filesystem number.
filesystem_no=1

# Start the JSON structure with an opening bracket.
echo "[" > "$json_filename"

# Loop through each line of the output of df -k and read the values of each column into variables.
while read -r filesystem filesystem_size filesystem_used filesystem_available filesystem_used_pct directory; do
    # Skip the first line of the output, which is the header line.
    if [[ "$filesystem" == "Filesystem" ]]; then
        continue
    fi

    # Call the function to construct a JSON object for the current filesystem and store it in a variable.
    json_object=$(construct_json_object "$filesystem_no" "$filesystem" "$filesystem_size" "$filesystem_used" "$filesystem_available" "$filesystem_used_pct" "$directory")

    # Append the JSON object to the JSON file.
    echo "$json_object," >> "$json_filename"

    # Increment the filesystem number counter by one.
    ((filesystem_no++))

done <<< "$filesystem_data"

# Remove the trailing comma from the last JSON object.
truncate -s -2 "$json_filename"

# End the JSON structure with a closing bracket.
echo "]" >> "$json_filename"

# Display a message indicating the script execution is successful and the JSON file name.
echo "Script executed successfully. JSON file saved as: $json_filename"

