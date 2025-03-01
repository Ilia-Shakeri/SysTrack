# SysTrack
A Bash script for monitoring system resources and sending alerts.

## Overview
SysTrack is a Bash script designed for monitoring system resources such as CPU, RAM, Disk, and Network usage. It sends email alerts when resource usage exceeds specified limits and logs the data for future reference. The script is designed to run periodically, making it suitable for long-term system monitoring.

## Features
- **Email Validation**: Prompts the user for an email address and validates the format.
- **Resource Monitoring**: Calculates and logs CPU, RAM, Disk, and Network usage.
- **Alert Notifications**: Sends email alerts when resource usage exceeds predefined limits.
- **Log Rotation**: Automatically rotates log files when they exceed 10MB to prevent excessive disk usage.
- **Scheduled Execution**: Sets up a cron job to run the script every 12 hours.

## Requirements
- Bash shell
- `bc` command for arithmetic calculations
- `mail` command for sending email alerts
- `crontab` command for scheduling tasks

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Ilia-Shakeri/SysTrack.git
   cd SysTrack
   chmod +x SysTrack.sh
   ./SysTrack.sh
