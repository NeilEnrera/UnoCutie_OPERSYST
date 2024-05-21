#!/bin/bash

# Define the services to monitor
services=($(systemctl list-units --type=service --no-pager | awk '{print $1}'))

# Define the output JSON file
output_file="/tmp/services_$(date '+%Y%m%d_%H%M%S').json"

# Initialize JSON structure
json_data='{
    "services_state_running": [],
    "services_state_dead": [],
    "services_state_failed": [],
    "services_state_exited": []
}'

# Counter for id_number
id_number=1

# Function to add service details to JSON based on status
add_to_json() {
    json_data=$(jq ".$1 += [{\"service\":{\"service-name\":\"$2\",\"description\":\"$3\",\"status\":\"$4\",\"id_number\":$5}}]" <<< "$json_data")
}

# Loop through each service and get its status
for service in "${services[@]}"; do
    status_output=$(systemctl status "$service" 2>/dev/null)
    if [[ $status_output == *"Active: active"* ]]; then
        status="active"
    elif [[ $status_output == *"Inactive: inactive"* ]]; then
        status="inactive"
    elif [[ $status_output == *"Exited: exited"* ]]; then
        status="exited"
    else
        status="failed"
    fi

    # Suppress the error message for systemctl show command
    description=$(systemctl show -p Description --value "$service" 2>/dev/null | sed 's/"/\\"/g')

    case $status in
        active)
            add_to_json "services_state_running" "$service" "$description" "$status" "$id_number"
            ;;
        inactive)
            add_to_json "services_state_dead" "$service" "$description" "$status" "$id_number"
            ;;
        failed)
            add_to_json "services_state_failed" "$service" "$description" "$status" "$id_number"
            ;;
        exited)
            add_to_json "services_state_exited" "$service" "$description" "$status" "$id_number"
            ;;
        *)
            # Handle any other status if needed
            ;;
    esac

    ((id_number++))
done

# Save JSON data to the output file
echo "$json_data" | jq '.' > "$output_file"

# Display success message
echo "Script completed successfully. JSON file saved at: $output_file"

