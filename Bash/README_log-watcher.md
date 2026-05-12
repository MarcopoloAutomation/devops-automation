# log-watcher

A small Bash script for watching a log file and printing lines that match a regex.

If `notify-send` is installed, it also shows a desktop notification. If not, it
still works normally and prints matches to stdout, so it is fine to use on a
headless server too.

## Optional desktop notifications

`notify-send` is optional. Install it only if you want desktop notifications.

```bash
sudo apt install libnotify-bin   # Debian/Ubuntu
sudo dnf install libnotify       # Fedora
```

## Usage

```bash
chmod +x log-watcher.sh

# Watch for ERROR lines
./log-watcher.sh /var/log/app.log

# Watch for a custom pattern
./log-watcher.sh -p "ERROR|WARN|FATAL" /var/log/app.log

# Print the last 20 lines first, then keep watching
./log-watcher.sh -n 20 /var/log/app.log

# Use a custom notification title
./log-watcher.sh -t "prod-api" -p "FATAL" /var/log/app.log

# Quiet mode: send notifications only, do not print matches
./log-watcher.sh -q -p "ERROR" /var/log/app.log &
```

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `-p <pattern>` | Pattern passed to `grep -E` | `ERROR` |
| `-t <title>` | Notification title | `log-watcher` |
| `-n <lines>` | Number of existing lines to check before watching | `0` |
| `-q` | Quiet mode, no stdout output | off |
| `-h` | Show help | — |

## Notes

The script uses `tail -F`, so it keeps working after log rotation.

Patterns are handled by `grep -E`, so extended regex syntax is supported.

If `notify-send` is missing or cannot run, the script still prints matching lines
unless quiet mode is enabled.

## Testing

The tests are plain Bash, no test framework needed.

```bash
chmod +x test-log-watcher.sh
./test-log-watcher.sh
```

## Test cases

| # | Case | Expected |
|---|------|----------|
| 1 | No arguments | exits 1 and prints usage |
| 2 | Missing file | exits 1 and prints an error |
| 3 | `-n abc` | exits 1 and prints an error |
| 4 | `-p` without a value | exits 1 and prints an error |
| 5 | Unknown flag | exits 1 and prints usage |
| 6 | `-h` | exits 0 and prints usage |
| 7 | Pattern match | prints the matching line |
| 8 | No match | prints nothing |
| 9 | `-q` quiet mode | does not print to stdout |
| 10 | `-n 2` | checks the last 2 lines before watching |
