#!/bin/bash

# Get current user's desktop path
DESKTOP_PATH=$(xdg-user-dir DESKTOP)

# Get system information
START_TIME=$(date)
IPV4_ADDRESS=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)
PKG_MANAGERS=$(command -v apt-get >/dev/null 2>&1 && echo "apt-get") 
INSTALLED_ITEMS=$(dpkg-query -f '${binary:Package}\n' -W | wc -l)
AVAILABLE_UPDATES=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | awk '{print $1, $2}')
NUM_AVAILABLE_UPDATES=$(echo "$AVAILABLE_UPDATES" | wc -l)
# Create CSV file and write header
REPORT_FILE="${DESKTOP_PATH}/software_report_$(date +%Y-%m-%d_%H-%M-%S).csv"
echo -e "LinuxCheck&Update v1.01\n
         PingBackHome 2023(c)\n
         +-----------------------------------+\n
         Start time: $START_TIME\n
         IPv4 address: $IPV4_ADDRESS\n
         Hostname: $HOSTNAME\n
         Package managers in use: $PKG_MANAGERS\n
         Installed items found: $INSTALLED_ITEMS\n
         Available updates found: $NUM_AVAILABLE_UPDATES
         +-----------------------------------+\n\n" > "$REPORT_FILE"

# Get the longest item in the table
max_name_length=0
max_version_length=0
while read -r line; do
    name=$(echo "$line" | awk -F/ '{print $1}')
    version=$(echo "$line" | awk -F/ '{print $2}')
    if [[ ${#name} -gt $max_name_length ]]; then
        max_name_length=${#name}
    fi
    if [[ ${#version} -gt $max_version_length ]]; then
        max_version_length=${#version}
    fi
done <<< "$AVAILABLE_UPDATES"

# Create table header
printf "+%s+-%s+\n" "$(printf '%*s\n' "$((max_name_length + 2))" "" | tr ' ' '-')" "$(printf '%*s\n' "$((max_version_length + 2))" "" | tr ' ' '-')" >> "$REPORT_FILE"
printf "| %-$(($max_name_length+1))s| %-$(($max_version_length+1))s|\n" "Package Name" "Version" >> "$REPORT_FILE"
printf "+%s+-%s+\n" "$(printf '%*s\n' "$((max_name_length + 2))" "" | tr ' ' '-')" "$(printf '%*s\n' "$((max_version_length + 2))" "" | tr ' ' '-')" >> "$REPORT_FILE"

# Loop through available updates and add rows to the table
while read -r line; do
    name=$(echo "$line" | awk -F/ '{print $1}')
    version=$(echo "$line" | awk -F/ '{print $2}')
    printf "| %-$(($max_name_length+1))s| %-$(($max_version_length+1))s|\n" "$name" "$version" >> "$REPORT_FILE"
    printf "+%s+-%s+\n" "$(printf '%*s\n' "$((max_name_length + 2))" "" | tr ' ' '-')" "$(printf '%*s\n' "$((max_version_length + 2))" "" | tr ' ' '-')" >> "$REPORT_FILE"
done <<< "$AVAILABLE_UPDATES"

# Print table in terminal
cat "$REPORT_FILE"

# Ask user if they want to update and upgrade
read -p "Do you want to update and upgrade the software? (yes/no): " answer

# Update and upgrade if user said yes
if [ "$answer" == "yes" ]; then
    # Update and upgrade software
    echo "Updating and upgrading software..."
    sudo apt-get update && sudo apt-get upgrade -y

    # Check if update and upgrade were successful
    if [ $? -eq 0 ]; then
        status="success"
    else
        status="failure"
    fi

    # Append note to report file
    echo -e "User response: $answer;\n Update and upgrade status: $status" >> "$REPORT_FILE"

    echo "Software update and upgrade complete."
else
    echo "No updates were performed."
fi

