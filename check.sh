#!/bin/bash

# Get current user's desktop path
DESKTOP_PATH=$(xdg-user-dir DESKTOP)

# Get system information
START_TIME=$(date)
IPV4_ADDRESS=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)
PKG_MANAGERS=$(command -v apt-get >/dev/null 2>&1 && echo "apt-get") # add other package managers as needed
INSTALLED_ITEMS=$(dpkg-query -f '${binary:Package}\n' -W | wc -l)
AVAILABLE_UPDATES=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | awk '{print $1, $2}')
NUM_AVAILABLE_UPDATES=$(echo "$AVAILABLE_UPDATES" | wc -l)
# Create CSV file and write header
REPORT_FILE="${DESKTOP_PATH}/software_report_$(date +%Y-%m-%d_%H-%M-%S).csv"
echo -e "SoftLibChecker v1.01\n
         PingBackHome(c)\n
         -------------------------------------\n\n
         Start time: $START_TIME\n
         IPv4 address: $IPV4_ADDRESS\n
         Hostname: $HOSTNAME\n
         Package managers in use: $PKG_MANAGERS\n
         Installed items found: $INSTALLED_ITEMS\n
         Available updates found: $NUM_AVAILABLE_UPDATES" > "$REPORT_FILE"

# Create table header

printf "+--------------------------+---------------+\n"
printf "|      Package Name        |  Version      |\n"
printf "+--------------------------+---------------+\n"

# Loop through available updates and add rows to the table
while read -r line; do
    name=$(echo "$line" | awk -F/ '{print $1}')
    version=$(echo "$line" | awk -F/ '{print $2}')
    printf "| %-24s| %-14s|\n" "$name" "$version"
done <<< "$AVAILABLE_UPDATES"

# Add a row separator
printf "+--------------------------+---------------+\n" >> "$REPORT_FILE"
