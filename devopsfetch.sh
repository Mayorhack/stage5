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
    echo "  -s, --stop [CONTAINER] Stop Docker containers (all or specify container name/ID)"
    echo "  -h, --help            Display this help message"
}

# Function to format output in table
format_table() {
    column -t -s $'\t'
}

# Function to get port information
get_port_info() {
    if [ -z "$1" ]; then
        echo -e "Port\tPID\tProcess"
        lsof -i -P -n | grep LISTEN | awk '{print $9"\t"$2"\t"$1}' | format_table
    else
        lsof -i -P -n | grep LISTEN | grep ":$1" | awk '{print $9"\t"$2"\t"$1}' | format_table
    fi
}

# Function to get Docker information
get_docker_info() {
    if [ -z "$1" ]; then
        docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"
    else
        docker ps --filter "name=$1" --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"
    fi
}

# Function to get Nginx information
get_nginx_info() {
    if [ -z "$1" ]; then
        nginx -T 2>/dev/null | grep -oP 'server_name\s+\K.*;' | tr -d ';'
    else
        nginx -T 2>/dev/null | grep -A 10 "server_name $1" | grep -oP 'server_name\s+\K.*;' | tr -d ';'
    fi
}

# Function to get user information
get_user_info() {
    if [ -z "$1" ]; then
        lastlog | awk '{print $1"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7}'
    else
        lastlog | grep "^$1" | awk '{print $1"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7}'
    fi
}

# Function to install devopsfetch
install_devopsfetch() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run the installation as root"
        exit 1
    fi

    apt-get update
    apt-get install -y lsof jq nginx docker.io

    cp "$0" /usr/local/bin/devopsfetch
    chmod +x /usr/local/bin/devopsfetch

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

    systemctl daemon-reload
    systemctl enable devopsfetch.service
    systemctl start devopsfetch.service

    echo "DevOpsFetch has been installed and the service has been started."
}

# Function for continuous monitoring
monitor_system() {
    log_dir="/var/log/devopsfetch"
    
    mkdir -p "$log_dir"
    if [ ! -w "$log_dir" ]; then
        echo "Log directory $log_dir is not writable. Please run as root or change the log directory permissions."
        exit 1
    fi

    while true; do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] System Information:" >> "$log_dir/devopsfetch.log"
        get_port_info >> "$log_dir/devopsfetch.log"
        get_docker_info >> "$log_dir/devopsfetch.log"
        get_nginx_info >> "$log_dir/devopsfetch.log"
        get_user_info >> "$log_dir/devopsfetch.log"
        echo "" >> "$log_dir/devopsfetch.log"
        sleep 300  # Wait for 5 minutes before the next check
    done
}

# Function to set up container environment
container_setup() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run the container setup as root"
        exit 1
    fi

    apt-get update
    apt-get install -y lsof jq nginx docker.io cron

    mkdir -p /var/log/devopsfetch

    echo "*/5 * * * * root /usr/local/bin/devopsfetch -m >> /var/log/devopsfetch/devopsfetch.log 2>&1" > /etc/cron.d/devopsfetch-cron
    chmod 0644 /etc/cron.d/devopsfetch-cron

    cron

    monitor_system
}

# Function to stop Docker containers
stop_docker_containers() {
    if [ -z "$1" ]; then
        echo "Stopping all running Docker containers..."
        docker stop $(docker ps -q)
    else
        echo "Stopping Docker container: $1..."
        docker stop "$1"
    fi
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
    -s|--stop)
        stop_docker_containers "$2"
        ;;
    -h|--help)
        display_help
        ;;
    *)
        echo "Invalid option. Use -h or --help for usage information."
        exit 1
        ;;
esac
