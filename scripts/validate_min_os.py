#!/usr/bin/env python3

import os
import subprocess
import sys


def is_executable_or_dylib(filepath):
    """Check if a file is an executable or a dylib."""
    return os.path.isfile(filepath) and (
        os.access(filepath, os.X_OK) or filepath.endswith(".dylib")
    )


def find_executables_and_dylibs(directory):
    """Recursively find all executables and dylibs in a directory, ignoring .dSYM directories."""
    for root, _, files in os.walk(directory):
        if "dylib.dSYM" in root:
            continue  # Skip processing for directories ending with dylib.dSYM
        for file in files:
            full_path = os.path.join(root, file)
            if is_executable_or_dylib(full_path):
                yield full_path


def safe_int_convert(part):
    """Safely convert version parts to integer, return 0 for non-integer strings."""
    try:
        return int(part)
    except ValueError:
        return 0


def version_greater_or_equal(version, target_version):
    """Compare two version strings using version logic, ignoring non-numeric parts."""
    version_parts = list(map(safe_int_convert, version.split(".")))
    target_parts = list(map(safe_int_convert, target_version.split(".")))
    # Pad the shorter version with zeros
    max_length = max(len(version_parts), len(target_parts))
    version_parts.extend([0] * (max_length - len(version_parts)))
    target_parts.extend([0] * (max_length - len(target_parts)))

    return version_parts >= target_parts


def parse_otool_output(output):
    """Parse the otool output to find minos and sdk versions under LC_BUILD_VERSION."""
    lines = output.split("\n")
    is_build_version_block = False
    minos = None
    sdk = None
    for line in lines:
        if "cmd LC_BUILD_VERSION" in line:
            is_build_version_block = True
        elif "cmd " in line and "LC_BUILD_VERSION" not in line:
            is_build_version_block = False
        elif is_build_version_block:
            if line.strip().startswith("minos"):
                minos_value = line.split()[1]
                if minos_value != "n/a":
                    minos = minos_value
            elif line.strip().startswith("sdk"):
                sdk_value = line.split()[1]
                if sdk_value != "n/a":
                    sdk = sdk_value
    return minos, sdk


def main(directory):
    errors_found = False
    dylib_count = 0  # Counter for dylibs processed

    for filepath in find_executables_and_dylibs(directory):
        try:
            # Run otool -l on the executable or dylib
            result = subprocess.run(
                ["otool", "-l", filepath], capture_output=True, text=True
            )
            minos, sdk = parse_otool_output(result.stdout)
            if minos is not None:
                # Ignore sdk check for libstemmer.dylib
                # due to https://trac.macports.org/ticket/69999
                if "libstemmer.dylib" in filepath:
                    if version_greater_or_equal(minos, "12.0"):
                        print(f"File: {filepath}, minos: {minos} (sdk ignored)")
                        errors_found = True
                else:
                    if version_greater_or_equal(minos, "12.0") or (
                        sdk is not None and version_greater_or_equal(sdk, "12.0")
                    ):
                        print(f"File: {filepath}, minos: {minos}, sdk: {sdk}")
                        errors_found = True
            # Count only dylibs
            if filepath.endswith(".dylib"):
                dylib_count += 1
        except Exception as e:
            print(f"Error processing {filepath}: {e}", file=sys.stderr)

    # Print the total number of dylibs processed
    print(f"Processed {dylib_count} dylibs")

    # Exit with an error if any problematic files were found
    if errors_found:
        sys.exit("Error: Found files with minos or sdk versions >= 12.0")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: ./validate_min_os.py <directory>")
        sys.exit(1)

    directory = sys.argv[1]
    main(directory)
