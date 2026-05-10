"""
Simple ICMP ping checker with logging.
Checks connectivity to a host and saves results to a log file.
Works on Windows and Linux.

Author: MarcoPolo | @tech.cloud.automation
GitHub: github.com/MarcopoloAutomation
"""

import subprocess
import platform
import os
from datetime import datetime


def check_and_save_ping(host):
    # Path to save logs — works on both Windows and Linux
    folder_path = os.path.join(os.path.expanduser("~"), "ping_logs")
    file_path = os.path.join(folder_path, "log_ping.txt")

    # Create folder if it doesn't exist
    if not os.path.exists(folder_path):
        os.makedirs(folder_path)

    # Ping parameters per operating system
    parameter = '-n' if platform.system().lower() == 'windows' else '-c'
    command = ['ping', parameter, '4', host]

    print(f"Checking connection to host: {host}...")

    try:
        # Execute command and capture output
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        status = "SUCCESS"
        output_text = result.stdout
    except subprocess.CalledProcessError as e:
        status = "FAIL"
        output_text = e.output if e.output else "Host not responding or no network connection"

    # Build log entry
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"--- {now} | Host: {host} | Status: {status} ---\n{output_text}\n"

    # Append to log file
    with open(file_path, "a", encoding="utf-8") as file:
        file.write(log_entry)

    print(f"Status : {status}")
    print(f"Log saved to: {file_path}")


if __name__ == "__main__":
    check_and_save_ping("google.com")
    input("\nPress Enter to exit...")
