#!/bin/bash

# devopsfetch.sh

# Function to display help
display_help() {
    echo "Usage: devopsfetch [OPTION]... [ARGUMENT]..."
    echo "Collect and display system information for DevOps purposes."
    echo
    echo "Options:"
    echo "  -p, --port [PORT]     Display active ports or info about a specific port"
    echo "  -d, --docker [CONTAINER] List Docker images/containers or info about a specific container"
    echo "  -n, --nginx [DOMAIN]  Display Nginx domains or info about a specific domain"
    echo "  -u, --users [USERNAME] List users and last login times or info about a specific user"
    echo "  -t, --time RANGE      Display activities within a specified time range"
    echo "  -i, --install         Install devopsfetch and set up systemd service"
    echo "  -c, --container-setup Set up the container environment"
    echo "  -m, --monitor         Run in monitoring mode"
    echo "  -h, --help            Display this help message"
}

# ... [Keep all the existing functions: format_table, get_port_info, get_docker_info, get_nginx_info, get_user_info] ...

# Function to install devopsfetch
install_devopsfetch() {
    # Check if script is run as root
    if [ "$EUID" -ne 0 ]; then
        echo "Please run the installation as root"
        exit 1
    fi

    # Install dependencies
    apt-get update
    apt-get install -y lsof jq nginx docker.io

    # Copy this script to /usr/local/bin
    # cp "$0" /usr/local/bin/devopsfetch
    # chmod +x /usr/local/bin/devopsfetch

    # Create systemd service file
    cat > /etc/systemd/system/devopsfetch.service <<EOL
[Unit]
Description=DevOpsFetch Monitoring Service
After=network.target

[Service]
ExecStart=/usr/local/bin/devopsfetch -m
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOL

    # Reload systemd, enable and start the service
    systemctl daemon-reload
    systemctl enable devopsfetch.service
    systemctl start devopsfetch.service

    echo "DevOpsFetch has been installed and the service has been started."
}

# Function for continuous monitoring
monitor_system() {
    while true; do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] System Information:" >> /var/log/devopsfetch.log
        get_port_info >> /var/log/devopsfetch.log
        get_docker_info >> /var/log/devopsfetch.log
        get_nginx_info >> /var/log/devopsfetch.log
        get_user_info >> /var/log/devopsfetch.log
        echo "" >> /var/log/devopsfetch.log
        sleep 300  # Wait for 5 minutes before the next check
    done
}

# Function to set up container environment
container_setup() {
    # Install necessary packages
    apt-get update
    apt-get install -y lsof jq nginx docker.io cron

    # Create log directory
    mkdir -p /var/log/devopsfetch

    # Set up cron job
    echo "*/5 * * * * root /usr/local/bin/devopsfetch -m >> /var/log/devopsfetch/devopsfetch.log 2>&1" > /etc/cron.d/devopsfetch-cron
    chmod 0644 /etc/cron.d/devopsfetch-cron

    # Start cron
    cron

    # Start monitoring
    monitor_system
}

# Main logic
case "$1" in
    -p|--port)
        get_port_info "$2"
        ;;
    -d|--docker)
        get_docker_info "$2"
        ;;
    -n|--nginx)
        get_nginx_info "$2"
        ;;
    -u|--users)
        get_user_info "$2"
        ;;
    -t|--time)
        echo "Time range feature not implemented yet"
        ;;
    -i|--install)
        install_devopsfetch
        ;;
    -c|--container-setup)
        container_setup
        ;;
    -m|--monitor)
        monitor_system
        ;;
    -h|--help)
        display_help
        ;;
    *)
        echo "Invalid option. Use -h or --help for usage information."
        exit 1
        ;;
esac