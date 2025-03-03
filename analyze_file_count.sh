#!/bin/bash

# -----------------------------------------------------------------------------
# Data Gap Finder and Completeness Calculator for Daily File Counts
#
# This script analyzes a text file containing dates and file counts to:
# 1. Identify data gaps (missing days or days with fewer than 1440 files).
# 2. Print each day with missing files and the exact number missing.
# 3. Calculate the percentage of completeness based on expected vs. actual files.
#
# Usage:
#   ./check_data_gaps.sh [filename]
#
# If no filename is provided, it defaults to "rainier_count.txt".
# -----------------------------------------------------------------------------

# Input file (default: rainier_count.txt)
FILE=${1:-rainier_count.txt}

# Ensure the file exists
if [[ ! -f "$FILE" ]]; then
    echo "Error: File '$FILE' not found."
    exit 1
fi

# Extract all available dates and file counts
declare -A file_counts
first_date=""
last_date=""

while read -r date count _; do
    file_counts["$date"]=$count
    if [[ -z "$first_date" ]]; then
        first_date=$date
    fi
    last_date=$date
done < "$FILE"

# Convert dates to a sequence
start_date=$(date -d "$first_date" +"%Y-%m-%d")
end_date=$(date -d "$last_date" +"%Y-%m-%d")

# Initialize tracking variables
missing_days=()
total_files=0
expected_files=0

# Loop through expected dates
current_date="$start_date"
while [[ "$current_date" != "$end_date" ]]; do
    expected_files=$((expected_files + 1440))
    
    actual_files=${file_counts[$current_date]:-0}  # Default to 0 if missing
    total_files=$((total_files + actual_files))

    if [[ "$actual_files" -lt 1440 ]]; then
        missing_files=$((1440 - actual_files))
        missing_days+=("$current_date $missing_files files missing")
    fi

    current_date=$(date -d "$current_date +1 day" +"%Y-%m-%d")
done

# Compute completeness safely using awk for floating-point division
if [[ "$expected_files" -gt 0 ]]; then
    percent_completeness=$(awk "BEGIN {printf \"%.2f\", ($total_files / $expected_files) * 100}")
else
    percent_completeness="0.00"
fi

# Print results
echo "Data Gaps:"
for gap in "${missing_days[@]}"; do
    echo "$gap"
done

echo "Percent Completeness: $percent_completeness%"

