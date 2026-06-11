#!/bin/bash
# Find unique mp4 files shorter than 4 minutes, and zips to desktop

MAX_DURATION=240  # 4 minutes in seconds
DESKTOP="$HOME/Desktop"
OUTPUT_ZIP="$DESKTOP/short_mp4s_$(date +%Y%m%d_%H%M%S).zip"
SEARCH_DIR="${1:-.}"  # first arg or current dir
TMP_LIST=$(mktemp)
TMP_HASHES=$(mktemp)

trap 'rm -f "$TMP_LIST" "$TMP_HASHES"' EXIT

if ! command -v ffprobe &>/dev/null; then
    echo "ffprobe not found, install ffmpeg first"
    exit 1
fi

echo "Scanning $SEARCH_DIR for mp4 files..."
find "$SEARCH_DIR" -type f -iname "*.mp4" | while read -r file; do
    
    dur=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    dur=${dur%.*}
 
    [[ -z "$dur" || "$dur" -ge "$MAX_DURATION" ]] && continue

     hash=$(head -c 1048576 "$file" | md5sum | cut -d' ' -f1)
    if ! grep -qF "$hash" "$TMP_HASHES"; then
        echo "$hash" >> "$TMP_HASHES"
        echo "$file" >> "$TMP_LIST"
    fi
done
count=$(wc -l < "$TMP_LIST")
if [[ "$count" -eq 0 ]]; then
    echo "No matching files found"
    exit 0
fi

echo "Found $count unique files under 4 min, zipping..."
mkdir -p "$DESKTOP"
