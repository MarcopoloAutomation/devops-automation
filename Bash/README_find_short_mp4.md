# find_short_mp4.sh

Scans a directory for `.mp4` files, keeps unique videos shorter than 4 minutes,
and zips them to the Desktop.

## Requirements

- Linux
- `ffmpeg` / `ffprobe` for checking video duration
- `zip` and `md5sum`

Install ffmpeg if it is missing:

```bash
sudo apt install ffmpeg      # Debian/Ubuntu
sudo dnf install ffmpeg      # Fedora

## Usage

```bash
chmod +x find_short_mp4.sh

# Scan current directory
./find_short_mp4.sh

# Scan a specific directory
./find_short_mp4.sh /path/to/videos
```

~/Desktop/short_mp4s_YYYYMMDD_HHMMSS.zip  
Files inside the zip are flat, without the original directory structure.

## Deduplication

The script hashes only the first 1 MB of each file with `md5sum`.

That keeps it fast when scanning a lot of videos. It catches normal copied duplicates, but it is not meant to be a perfect video fingerprint or a cryptographic check.

## Running tests

```bash
chmod +x test_find_short_mp4.sh
./test_find_short_mp4.sh
```

Tests create real mp4 files using ffmpeg (silent, 64x64px black frames), run the main script, then check the output zip. Cleans up after itself.

Expected output:
```
[PASS] zip file created
[PASS] zip contains 2 unique short files
[PASS] long file correctly excluded
[PASS] duplicate correctly removed
[PASS] handles empty dir gracefully

# Results: 5 passed, 0 failed 

## Notes

- Files exactly 4:00 are excluded (>= 240s)
- Symlinks are not followed (find -type f)
- Search is recursive by default
- Zip uses -j, so files are stored flat in the zip root.

Workflow:
find > ffprobe (filtruj długość) > md5 (filtruj duplikaty) > TMP_LIST > zip > Desktop