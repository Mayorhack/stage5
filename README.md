# DevOpsFetch

## Overview

DevOpsFetch is a tool for retrieving and monitoring server information. It collects data on active ports, user logins, Nginx configurations, Docker images, and container statuses. It also supports continuous monitoring with a systemd service.

## Installation

Run the installation script to set up DevOpsFetch and its dependencies:

```sh
sudo bash install_devopsfetch.sh
```

## Usage

Command-Line Flags
-p, --port [port_number]

Description: Display all active ports and services or detailed information about a specific port.
Usage:
Display all ports: devopsfetch -p
Display details for a specific port: devopsfetch -p [port_number]

-d, --docker [container_name]

Description: List all Docker images and containers or detailed information about a specific container.
Usage:
List all Docker images and containers: devopsfetch -d
Display details for a specific container: devopsfetch -d [container_name]

-n, --nginx [domain]

Description: Display all Nginx domains and their ports or detailed configuration for a specific domain.
Usage:
Display all domains and ports: devopsfetch -n
Display details for a specific domain: devopsfetch -n [domain]

-u, --users [username]

Description: List all users and their last login times or detailed information about a specific user.
Usage:
List all users: devopsfetch -u
Display details for a specific user: devopsfetch -u [username]

-t, --time [time_range]

Description: Display activities within a specified time range.
Usage:
Display activities: devopsfetch -t [time_range]

-h, --help

Description: Display help information about the script and its usage.
Usage: devopsfetch -h
Output Formatting
devopsfetch formats all outputs in well-organized tables with descriptive column names for readability.

## Logging Mechanism

Log File Location
Logs are stored in /var/log/devopsfetch.log.

Log Rotation
Frequency: Daily
Retention: 7 days
Compression: Enabled
Permissions: 0640 for root and adm group
The log rotation configuration ensures that logs are rotated daily, with old logs compressed and retained for up to 7 days.
