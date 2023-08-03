#!/bin/bash

# Usage message
usage() {
  echo "Usage: $0 directory target_string_regex"
  echo "Checks all .dylib files in the specified directory to verify they contain specific lines in a specific order."
  exit 1
}

# Check for --help or no argument
if [ "$#" -ne 2 ] || [ "$1" == "--help" ]; then
  usage
fi

# Take the directory as an argument
directory="$1"

# Check if the directory exists
if [ ! -d "$directory" ]; then
  echo "Error: Directory $directory does not exist."
  exit 1
fi

# Initialize an empty array to hold files that do not pass the test
found_files=()

# Prepare the target string
target_string="$2"

# Iterate over all .dylib files in the directory excluding .dSYM directories
while IFS= read -r -d '' file; do
  # Run the otool command and check the output
  output=$(otool -l "$file")

  # Use perl to match (possibly multi-line) pattern, considering white spaces
  echo "$output" | perl -0777 -ne 'exit 1 if /'"$target_string"'/s'

  # Check the exit status of perl command, if non-zero, add the file to found_files
  if [ $? -ne 0 ]; then
    found_files+=("$file")
  fi
done < <(find "$directory" -type f \( -perm +111 -o -name "*.dylib" \) ! -path "*.dSYM*" -print0)

# If the array is not empty, print the error message
if [ ${#found_files[@]} -ne 0 ]; then
  echo "Found the following files:"
  for file in "${found_files[@]}"; do
    echo "$file"
  done
  exit 1
else
  echo "Did not find the pattern."
fi
