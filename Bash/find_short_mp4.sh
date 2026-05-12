#!/bin/bash
# find unique mp4 files shorter than 4 minutes, and zips to desktop

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

