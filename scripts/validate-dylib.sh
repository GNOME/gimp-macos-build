#!/bin/bash

# Usage message
usage() {
  echo "Usage: $0 directory"
  echo "Checks all .dylib files in the specified directory to verify they contain specific lines in a specific order."
  exit 1
}

# Check for --help or no argument
if [ "$#" -ne 1 ] || [ "$1" == "--help" ]; then
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
error_files=()

# Prepare the target string
target_string="cmd LC_VERSION_MIN_MACOSX\n\s*cmdsize 16\n\s*version 10.13\n\s*sdk 10.13"

# Iterate over all .dylib files in the directory excluding .dSYM directories
while IFS= read -r -d '' file; do
  # Run the otool command and check the output
  if file "$file" | grep -q 'Mach-O'; then
    output=$(otool -l "$file")

    # Use perl to match multi-line pattern, considering white spaces
    echo "$output" | perl -0777 -ne 'exit 1 if /'"$target_string"'/s'

    # Check the exit status of perl command, if non-zero, add the file to error_files
    if [ $? -eq 0 ]; then
      error_files+=("$file")
    fi
  fi
done < <(find "$directory" -type f \( -perm +111 -o -name "*.dylib" \) ! -path "*.dSYM*" -print0)

# If the array is not empty, print the error message
if [ ${#error_files[@]} -ne 0 ]; then
  echo "Error: The following files do not support MacOS 10.13:"
  for file in "${error_files[@]}"; do
    echo "$file"
  done
  exit 1
else
  echo "All .dylib files passed the test."
fi
