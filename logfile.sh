#!/bin/bash

# Function to generate a timestamp
generate_timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

# Function to generate log content
generate_log_content() {
  local content_count="$1"
  local pattern="$2"
  local log_content=""

  for ((i = 1; i <= content_count; i++)); do
    log_content+="Some log content line $i\n"
  done

  echo -e "$log_content"
}

# Function to count occurrences of a pattern in a string
count_pattern_occurrences() {
  local input="$1"
  local pattern="$2"
  grep -o -F "$pattern" <<< "$input" | wc -l
}

# Function to copy files concurrently
copy_files_concurrently() {
  local source_dir="$1"
  local destination_dir="$2"

  # Copy files from source to destination
  cp "$source_dir"/*.txt "$destination_dir"

  # Iterate over copied files and copy their content with a sleep duration
  for file in "$destination_dir"/*.txt; do
    if [ -f "$file" ]; then
      # Clear the contents of the destination file
      > "$file"
      
      # Get the filename without the directory path
      filename=$(basename "$file")

      # Copy each line with a sleep duration
      while IFS= read -r line; do
        echo "$line" >> "$file"
        echo "Copied line from $filename to $destination_dir"
        sleep 1
      done < "$file.temp"
      
      # Remove the temporary file
      rm "$file.temp"
      
      echo "Finished copying $filename to $destination_dir"
    fi
  done
}

# Function to check if a file is corrupt
check_corrupt_status() {
  local file="$1"
  local filename=$(basename "$file")
  local expected_lines=$(echo "$filename" | cut -d'_' -f1)
  local actual_lines=$(wc -l < "$file")

  if [ "$expected_lines" -eq "$actual_lines" ]; then
    echo "Not corrupt"
  else
    echo "Corrupt"
  fi
}

# Function to copy lines concurrently
copy_lines_concurrently() {
  local source_dir="$1"
  local destination_dir="$2"
  local processes=()  # Array to store background processes

  # Iterate over files in source directory
  for file in "$source_dir"/*.txt; do
    if [ -f "$file" ]; then
      filename=$(basename "$file")
      
      # Create destination file
      touch "$destination_dir/$filename"

      # Copy each line with a sleep duration
      while IFS= read -r line; do
      sleep 1
        (
          echo "$line" >> "$destination_dir/$filename"
          echo "Copied line from $filename to $destination_dir"
          sleep 3
        ) &
        sleep 1
        processes+=("$!")  # Store the background process ID
      done < "$file"

      # Wait for all background processes to finish for this file
      for pid in "${processes[@]}"; do
        wait "$pid"
      done
      processes=()  # Clear the array for the next file

      # Check corrupt status concurrently
      (
        echo "Checking corrupt status of $filename"
        corrupt_status=$(check_corrupt_status "$destination_dir/$filename")
        echo "$filename: $corrupt_status"
      ) &
    fi
  done
}

# Take user input for pattern
read -p "Enter the pattern: " user_pattern

# Generate log files
for ((file_num = 1; file_num <=3; file_num++)); do
  content_count=$(( ( RANDOM % 200 ) + 501))  # Random content count between 501 and 1000
  filename="${content_count}_${user_pattern}"

  # Generate log content
  log_content=$(generate_log_content "$content_count" "$user_pattern")

  # Count occurrences of the pattern in the log content
  pattern_count=$(count_pattern_occurrences "$log_content" "$user_pattern")

  # Select one file randomly and set its line count differently in the filename
  if (( RANDOM % 10 == 0 )); then
    different_line_count=$(( ( RANDOM % 500 ) + 1001 ))  # Random line count between 1001 and 1500
    filename="${different_line_count}_${user_pattern}_${pattern_count}_${file_num}.txt"
  else
    # Append pattern count to the filename
    filename="${filename}_${pattern_count}_${file_num}.txt"
  fi

  # Write log content to file
  echo -e "$log_content" > "$filename"

  sleep 1  # Delay after generating each file
done

# Directory paths
source_dir="/home/gauri/Desktop/Assignment2"
destination_dir="/home/gauri/Desktop/Assignment2/central"

# Check if source directory exists
if [ ! -d "$source_dir" ]; then
  echo "Source directory not found!"
  exit 1
fi

# Check if destination directory exists, if not create it
if [ ! -d "$destination_dir" ]; then
  mkdir -p "$destination_dir"
fi

# Copy files concurrently
copy_files_concurrently "$source_dir" "$destination_dir"
copy_lines_concurrently "$source_dir" "$destination_dir"

