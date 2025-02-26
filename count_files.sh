#!/bin/bash

###############################################################################
# Script Name: count_files.sh
#
# Description:
#   This script counts the number of `.h5` files in a directory structure
#   organized by year, month, and day in the format: `/YYYY/MM/DD/`.
#
#   It scans all `.h5` files under the provided base path and outputs the
#   number of files for each day in the format:
#
#       YYYY-MM-DD n files
#
#   Additionally, the script logs any files that do not match the expected
#   directory structure into a temporary log file for review.
#
# Directory Structure Example:
#   /data/jbod1/rainier/2023/11/01/decimator_2023-11-01_09.20.00_UTC.h5
#   /data/jbod1/rainier/2023/11/02/decimator_2023-11-02_12.45.00_UTC.h5
#
# Usage:
#   ./count_files.sh /path/to/base_directory
#
# Example:
#   ./count_files.sh /data/jbod1/rainier
#
# Output:
#   2023-11-01 1523 files
#   2023-11-02 1440 files
#   2023-11-03 1789 files
#
# Dependencies:
#   - bash
#   - find
#   - awk
#
# Notes:
#   - The script uses `find` with `-print0` to handle filenames with spaces.
#   - A temporary log is created for unmatched files and displayed if needed.
#
###############################################################################

# Check if the path argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 PATH"
    exit 1
fi

# Set the base path from the argument
BASE_PATH="$1"

# Check if the provided path exists and is a directory
if [ ! -d "$BASE_PATH" ]; then
    echo "Error: $BASE_PATH is not a valid directory."
    exit 1
fi

# Temp file for logging unmatched files
UNMATCHED_LOG=$(mktemp)

# Use find and process the files directly with awk for performance
find "$BASE_PATH" -type f -name "*.h5" -print0 | \
    awk -v RS='\0' -v unmatched_log="$UNMATCHED_LOG" '
    {
        # Match the year, month, and day from the directory structure
        if (match($0, /\/([0-9]{4})\/([0-9]{2})\/([0-9]{2})\//, arr)) {
            year_month_day = arr[1] "-" arr[2] "-" arr[3];
            count[year_month_day]++;
        } else {
            # Log unmatched files for further inspection
            print $0 >> unmatched_log;
        }
    }
    END {
        # Print counts per day
        for (ymd in count) {
            print ymd, count[ymd], "files";
        }
    }' | sort

# Check if there were unmatched files
if [ -s "$UNMATCHED_LOG" ]; then
    echo "Warning: Some files did not match the expected directory structure."
    echo "Unmatched files are logged in: $UNMATCHED_LOG"
else
    rm "$UNMATCHED_LOG"
fi

