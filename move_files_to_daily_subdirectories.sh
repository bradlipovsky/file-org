#!/bin/bash

# This script reorganizes decimator .h5 files into daily subdirectories based on the date in the filename.
#
# Usage:
#   ./move_files_to_daily_subdirectories.sh <target_directory> [-d|--dry-run]
#
# Arguments:
#   <target_directory>  The directory containing the .h5 files to be reorganized.
#   -d, --dry-run       Optional flag to preview the commands without executing them.
#
# Functionality:
#   - Finds all .h5 files in the specified target directory that match the pattern 'decimator_*.h5'.
#   - Extracts the date (YYYY-MM-DD) from each filename.
#   - Creates a subdirectory for each day (if it doesn't exist) within the target directory.
#   - Moves each file into its corresponding daily subdirectory.
#   - In dry-run mode, prints the commands that would be executed without making any changes.

# Check if directory argument is provided
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <target_directory> [-d|--dry-run]"
  exit 1
fi

TARGET_DIR="$1"
DRY_RUN=false

# Check for dry-run option
if [ "$2" == "-d" ] || [ "$2" == "--dry-run" ]; then
  DRY_RUN=true
fi

# Ensure the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Directory $TARGET_DIR does not exist."
  exit 1
fi

# Find all .h5 files and process them
find "$TARGET_DIR" -maxdepth 1 -type f -name "decimator_*.h5" | while read -r FILE; do
  # Extract the date from the filename
  BASENAME=$(basename "$FILE")
  DATE_PART=$(echo "$BASENAME" | grep -oP '\d{4}-\d{2}-\d{2}')

  if [ -n "$DATE_PART" ]; then
    DAY_DIR="$TARGET_DIR${DATE_PART:8:2}"

    if [ "$DRY_RUN" = true ]; then
      echo "[DRY RUN] mkdir -p $DAY_DIR"
      echo "[DRY RUN] mv $FILE $DAY_DIR/"
    else
      # Create the daily subdirectory if it doesn't exist
      mkdir -p "$DAY_DIR"

      # Move the file
      mv "$FILE" "$DAY_DIR/"

      echo "Moved $BASENAME to $DAY_DIR/"
    fi
  else
    echo "Warning: Could not extract date from $BASENAME"
  fi

done

echo "File rearrangement complete."

