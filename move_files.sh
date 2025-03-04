#!/bin/bash

# Script for organizing and processing Distributed Acoustic Sensing (DAS) data files.
#
# This script takes an input directory containing HDF5 (.h5) files and organizes them into a structured 
# directory format based on metadata extracted from filenames. It supports customizable project and base 
# directory names, sample rate detection, and a dry-run mode for testing without making changes.
#
# Usage:
#   ./script.sh -i INPUT_DIR [-b BASE_DIR] [-p PROJECT_NAME] [-s SAMPLE_RATE] [-d|--dry-run]
#
# Options:
#   -i, --inputDir     Path to the directory containing the raw .h5 files (required).
#   -b, --baseDir      Base directory for storing organized data (default: /data/jbod1/das4orcas).
#   -p, --projectName  Project name used in file organization (default: das4orcas).
#   -s, --sampleRate   Optional sample rate; if not provided, it is inferred from filenames.
#   -d, --dry-run      If set, no actual changes are made—only prints actions.
#   -h, --help         Displays usage information and exits.
#
# Functionality:
#   - Validates the presence of an input directory.
#   - Removes trailing slashes from paths for consistency.
#   - Extracts sample rate from filenames if not explicitly provided.
#   - Parses timestamps from filenames to organize files by date.
#   - Processes .h5 files and moves them into a structured directory hierarchy.
#   - Supports parallel execution using exported environment variables.
#
# Example:
#   ./script.sh -i /path/to/raw_data -b /output/das_data -p projectX -s 1000 -d
#   (This runs in dry-run mode, showing how files would be processed without moving them.)
#
# Notes:
#   - Filenames should follow the pattern: *_YYYY-MM-DD_HH.MM.SS_UTC*.h5 for proper date extraction.
#   - Sample rate is inferred from directory name if not provided explicitly.

# Default values
BASE_DIR="/data/jbod1/das4orcas"
PROJECT_NAME="das4orcas"
SAMPLE_RATE=""
DRY_RUN=0

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--inputDir)
            INPUT_DIR="$2"
            shift
            shift
            ;;
        -b|--baseDir)
            BASE_DIR="$2"
            shift
            shift
            ;;
        -p|--projectName)
            PROJECT_NAME="$2"
            shift
            shift
            ;;
        -s|--sampleRate)
            SAMPLE_RATE="$2"
            shift
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 -i INPUT_DIR [-b BASE_DIR] [-p PROJECT_NAME] [-s SAMPLE_RATE] [-d|--dry-run]"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            echo "Usage: $0 -i INPUT_DIR [-b BASE_DIR] [-p PROJECT_NAME] [-s SAMPLE_RATE] [-d|--dry-run]"
            exit 1
            ;;
    esac
done

# Check if input directory is provided
if [[ -z "$INPUT_DIR" ]]; then
    echo "Error: Input directory is required."
    echo "Usage: $0 -i INPUT_DIR [-b BASE_DIR] [-p PROJECT_NAME] [-s SAMPLE_RATE] [-d|--dry-run]"
    exit 1
fi

# Remove trailing slashes from BASE_DIR and INPUT_DIR
BASE_DIR="${BASE_DIR%/}"
INPUT_DIR="${INPUT_DIR%/}"

# Function to extract sample rate from directory name
extract_sample_rate() {
    local dir_path="$1"
    if [[ -z "$SAMPLE_RATE" ]]; then
        if [[ "$dir_path" =~ orca([0-9]+) ]]; then
            SAMPLE_RATE="${BASH_REMATCH[1]}"
        else
            SAMPLE_RATE=""
        fi
    fi
}

# Export variables for subshells (if using xargs for parallel execution)
export BASE_DIR
export PROJECT_NAME
export SAMPLE_RATE
export DRY_RUN

# Find all .h5 files and process them
find "$INPUT_DIR" -type f -name "*.h5" | while read -r file; do
    filename=$(basename "$file")

    # Extract date from filename
    if [[ "$filename" =~ .*_([0-9]{4}-[0-9]{2}-[0-9]{2})_[0-9]{2}\.[0-9]{2}\.[0-9]{2}_UTC.*\.h5 ]]; then
        date_str="${BASH_REMATCH[1]}"
    else
        echo "Filename $filename does not match expected pattern. Skipping."
        continue
    fi

    # Parse date components
    year=$(echo "$date_str" | cut -d'-' -f1)
    month=$(echo "$date_str" | cut -d'-' -f2)
    day=$(echo "$date_str" | cut -d'-' -f3)

    # Extract sample rate if not provided
    extract_sample_rate "$file"

    # Build destination directory
    dest_dir="$BASE_DIR"
    if [[ -n "$SAMPLE_RATE" ]]; then
        dest_dir="$dest_dir/${SAMPLE_RATE}hz"
    fi
    dest_dir="$dest_dir/$year/$month/$day"

    # Create destination directory if it doesn't exist
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "Would create directory: $dest_dir"
    else
        mkdir -p "$dest_dir"
    fi

    # Move file to destination directory
    dest_path="$dest_dir/$filename"
    if [[ -e "$dest_path" ]]; then
        echo "File $dest_path already exists. Skipping."
    else
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "Would move $file to $dest_path"
        else
            mv "$file" "$dest_path"
            if [[ $? -eq 0 ]]; then
                echo "Moved $file to $dest_path"
            else
                echo "Failed to move $file to $dest_path"
            fi
        fi
    fi
done
