#!/bin/bash

source_dir="/home/gauri/Desktop/Assignment2"
destination_dir="/home/gauri/Desktop/Assignment2/central"
dashboard_file="dashboard.txt"

# Function to check if a file is being copied
is_copying() {
    local file="$1"
    lsof "$file" >/dev/null 2>&1
}

# Function to check if a file is completely copied
is_completely_copied() {
    local source_file="$1"
    local destination_file="$destination_dir/$(basename "$source_file")"
    
    # Check if the source file exists and is not being copied
    if [ -f "$destination_file" ] && ! is_copying "$destination_file"; then
        # Compare file sizes
        local source_size=$(stat -c "%s" "$source_file" 2>/dev/null)
        local dest_size=$(stat -c "%s" "$destination_file" 2>/dev/null)
        
        if [ -n "$source_size" ] && [ -n "$dest_size" ]; then
            [ "$source_size" -eq "$dest_size" ]
        else
            false
        fi
    else
        false
    fi
}

# Function to check the progress of file copying
file_copy_progress() {
    local source_file="$1"
    local destination_file="$destination_dir/$(basename "$source_file")"
    
    # Get the size of the source file
    local source_size=$(stat -c "%s" "$source_file" 2>/dev/null)
    
    if [ -z "$source_size" ]; then
        echo "0"
        return
    fi
    
    # Get the size of the destination file (copied so far)
    local dest_size=$(stat -c "%s" "$destination_file" 2>/dev/null || echo "0")
    
    # Calculate the progress percentage
    local progress=$(( (dest_size * 100) / source_size ))
    echo "$progress"
}

# Function to check if a file is corrupt
is_corrupt() {
    local filename=$(basename "$1")
    local expected_lines=$(echo "$filename" | awk -F_ '{print $1}')
    local actual_lines=$(wc -l < "$1")

    if [ "$expected_lines" -eq "$actual_lines" ]; then
        echo "Not corrupt"
    else
        echo "Corrupt"
    fi
}

# Function to update the dashboard
update_dashboard() {
    local file="$1"
    local file_status="$2"
    local corrupt_status="$3"
    local incoming_percentage="$4"
    local progress="$5"
    
    printf "| %-30s | %-15s | %-25s | %-13s | %-13s |\n" "$file" "$file_status" "$corrupt_status" "$incoming_percentage%" 
}

# Continuous loop to update the dashboard
while true; do
    # Clear the screen and move the cursor to the beginning of the dashboard
    tput clear
    tput cup 0 0

    # Print the header
    echo "-------------------------------------------------------------------------"
    echo "| Filename                      | File Status   | Corrupt Status    | Incoming (%) |"
    echo "-------------------------------------------------------------------------"

    # Loop through files in the source directory
    for file in "$source_dir"/*.txt; do
        filename=$(basename "$file")
        file_status="pending"
        corrupt_status="N/A"
        incoming_percentage="N/A"
        progress="N/A"

        # Check if file is completely copied
        if is_completely_copied "$file"; then
            file_status="processed"
            
            # Check if file is corrupt
            corrupt_status=$(is_corrupt "$file")
            
            # If file is being checked for corruption, mark it as in progress
            if [ "$corrupt_status" == "N/A" ]; then
                corrupt_status="In Progress"
                update_dashboard "$filename" "$file_status" "$corrupt_status" "$incoming_percentage" "$progress"
                # Simulate corruption check
                sleep 5
                # Update corrupt status after checking
                corrupt_status=$(is_corrupt "$file")
            fi
        else
            # Check if file is being copied
            if is_copying "$file"; then
                file_status="incoming"
                incoming_percentage=$(file_copy_progress "$file")
            fi
        fi

        # Update dashboard for the current file
        update_dashboard "$filename" "$file_status" "$corrupt_status" "$incoming_percentage" "$progress"
    done

    # Print the footer
    echo "-------------------------------------------------------------------------"

    # Delay before next iteration
    sleep 5
done

