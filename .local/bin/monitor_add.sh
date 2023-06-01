#!/usr/bin/env bash

# Set the monitored directory
MONITORED_DIR="/mnt/media/in_progress/"

# Set a counter int
counter=0

# Wait for the monitored directory to become available
while [ ! -d "$MONITORED_DIR" ]; do
    # Check if the counter reached 100
    if [ "$counter" -ge 100 ]; then
        echo "The monitored directory ${MONITORED_DIR} is still not available after 100 attempts. Exiting."
        exit 1
    fi

    echo "Waiting for the monitored directory ${MONITORED_DIR} to become available... (attempt: $((counter + 1)))"
    sleep 5
    counter=$((counter + 1))
done

# Create a function to handle the extraction of .rar files
extract_rar() {
    local rar_file destination_dir extract_attempts
    rar_file="$1"
    destination_dir="$(dirname "$rar_file")"
    extract_attempts=0

    # Loop for extraction attempts
    while [ "$extract_attempts" -lt 5 ]; do
        # Test the rar file
        if unrar t "$rar_file"; then
            # If the rar file is okay, extract it
            unrar x -y "$rar_file" "$destination_dir"
            break
        else
            echo "Error in rar file $rar_file, trying again after sleep... (attempt: $((extract_attempts + 1)))"
            sleep 10
            extract_attempts=$((extract_attempts + 1))
        fi
    done

    if [ "$extract_attempts" -ge 5 ]; then
        echo "Failed to extract $rar_file after 5 attempts. Giving up."
        exit 1
    fi
}

# Monitor the directory for new .rar files and process them
inotifywait -m -r -e close_write --format '%w%f' "$MONITORED_DIR" | while read -r new_file; do
    if [[ "$new_file" =~ \.rar$ ]]; then
        printf "Extracting %s" "$new_file"
        extract_rar "$new_file"
    fi
done
