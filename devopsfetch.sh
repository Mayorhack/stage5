#!/bin/bash

# Function to display all active ports and services
function display_ports {
    echo "Active Ports and Services:"
     ports_info=$(sudo netstat -tuln | awk 'NR > 2 {print $4, $7}')

    # Displaying in a tabular format
    echo "+--------------+--------------+"
    echo "| Port Number  | Service Name |"
    echo "+--------------+--------------+"
    # Loop through each line of ports_info
    while IFS= read -r line; do
        port=$(echo "$line" | awk '{print $1}')
        service=$(echo "$line" | awk '{print $2}')
        echo "| $port | $service |"
    done <<< "$ports_info"
    echo "+--------------+--------------+"
}

# Function to display detailed information about a specific port
function display_port_details {
    local port=$1
    echo "Details for Port $port:"
    sudo netstat -tulnp | grep ":$port "
}

# Function to list all Docker images
function list_docker_images {
    echo "Docker Images:"
# Fetching Docker images with ID, Repository, Tag, Size, and Created date
    docker_info=$(sudo docker images --format "{{.ID}}|{{.Repository}}:{{.Tag}}|{{.Size}}|{{.CreatedAt}}")

    # Displaying in a tabular format
    echo "+----------------------+----------------------+---------+---------------------+"
    echo "| Container ID         | Image Name           | Size    | Created Date        |"
    echo "+----------------------+----------------------+---------+---------------------+"

    # Loop through each line of docker_info
    while IFS='|' read -r container_id image_name size created_date; do
        # Truncate image name if too long
        # Strip off the timezone information (+0000 UTC) from created_date
        created_date=$(echo "$created_date" | awk '{print $1, $2, $3, $4}')
        
        # Convert the stripped date to a human-readable format (e.g., YYYY-MM-DD HH:MM:SS)
        formatted_date=$(date -d "$created_date" "+%Y-%m-%d %H:%M:%S")
        if [ ${#image_name} -gt 20 ]; then
            image_name="${image_name:0:17}..."
        fi
       printf "| %-20s | %-20s | %-10s | %-20s |\n" " $container_id"  "$image_name"  "$size"  "$formatted_date"
    done <<< "$docker_info"

    echo "+----------------------+----------------------+---------+---------------------+"
}

# Function to list all Docker containers
function list_docker_containers {
    echo "Docker Containers:"
   # Fetching Docker containers with ID, Image, Status, Ports, and Created date
    docker_info=$(sudo docker ps -a --format "{{.ID}}|{{.Image}}|{{.Status}}|{{.Ports}}|{{.CreatedAt}}")

    # Displaying in a tabular format
    echo "+----------------------+------------------+--------------+----------------+------------------+"
    echo "| Container ID         | Image            | Status       | Ports          | Created Date     |"
    echo "+----------------------+------------------+--------------+----------------+------------------+"

    # Loop through each line of docker_info
    while IFS='|' read -r container_id image status ports created_date; do
        # Truncate image name if too long
       # Strip off the timezone information (+0000 UTC) from created_date
        created_date=$(echo "$created_date" | awk '{print $1, $2, $3, $4}')
        
        # Convert the stripped date to a human-readable format (e.g., YYYY-MM-DD HH:MM:SS)
        formatted_date=$(date -d "$created_date" "+%Y-%m-%d %H:%M:%S")
        if [[ "$status" == *"Up"* ]]; then
            status="Up"
        else
            status="Exited"
        fi
        if [ ${#image} -gt 20 ]; then
            image="${image:0:17}..."
        fi
        printf "| %-20s | %-20s | %-10s | %-10s | %-20s |\n" "$container_id" "$image" "$status" "$ports" "$formatted_date"
    done <<< "$docker_info"

    echo "+----------------------+------------------+--------------+----------------+------------------+"
}

# Function to display detailed information about a specific Docker container
function display_container_details {
    local container=$1
    echo "Details for Docker Container $container:"
    sudo docker inspect $container
}

# Function to display all Nginx domains and their ports
function display_nginx_domains {
     # Fetching Nginx domains, ports, and configuration file paths
    nginx_info=$(sudo nginx -T | grep -E 'server_name|listen' | awk '{print $1, $2, $3}')

    # Displaying in a tabular format
    echo "+-------------------+------------+----------------------+"
    echo "| Domain            | Port       | Configuration File   |"
    echo "+-------------------+------------+----------------------+"

    # Variables to store current domain, port, and configuration file path
    current_domain=""
    current_port=""
    config_file=""

    # Loop through each line of nginx_info
    while IFS=' ' read -r directive value path; do
        if [[ $directive == "server_name" ]]; then
            # Extract domain name
            current_domain="$value"
        elif [[ $directive == "listen" ]]; then
            # Extract port number
            current_port="$value"
            # Print domain, port, and configuration file path in tabular format
            echo "| $current_domain | $current_port | $path |"
            current_domain=""
            current_port=""
        fi
    done <<< "$nginx_info"

    echo "+-------------------+------------+----------------------+"
}

# Function to display detailed Nginx configuration for a specific domain
function display_nginx_domain_details {
    local domain=$1
    echo "Details for Nginx Domain $domain:"
    grep -r "server_name $domain;" /etc/nginx/sites-available/*
}

# Function to list all users and their last login times
function list_users {
   echo "Users and Last Login Times:"
    
    # Fetching users and their last login times
    users_info=$(sudo lastlog -u 0)

    # Displaying in a tabular format
    echo "+----------------------+----------------------+"
    echo "| Username             | Last Login Time      |"
    echo "+----------------------+----------------------+"

    # Loop through each line of users_info
    while IFS=: read -r username _ _ last_login; do
        if [[ "$last_login" != "**Never logged in**" ]]; then
            # Convert last login time from epoch to human-readable format
            last_login_date=$(date -d "$(echo $last_login | awk '{print $1}')")
        else
            last_login_date="Never logged in"
        fi
        echo "| $username | $last_login_date |"
    done <<< "$users_info"

    echo "+----------------------+----------------------+"

}

# Function to display detailed information about a specific user
function display_user_details {
    local username=$1
    echo "Details for User $username:"
    finger $username
}

# Function to display activities within a specified time range
function display_time_range_activities {
    local exact_time="$1"

    if [[ -z "$exact_time" ]]; then
        echo "Usage: get_syslog_by_exact_timestamp <exact_time>"
        echo "Example: get_syslog_by_exact_timestamp '2024-07-24 00:00:00'"
        return 1
    fi

    local log_file="/var/log/syslog"

    if [[ ! -f "$log_file" ]]; then
        echo "Error: Log file '$log_file' not found."
        return 1
    fi

    # Convert exact timestamp to epoch for comparison
    exact_epoch=$(date -d "$exact_time" +%s)

    echo "Fetching syslog entries for '$exact_time'..."

    awk -v exact_epoch="$exact_epoch" '
    {
        # Extract timestamp from log line, assuming format: "MMM DD HH:MM:SS" (e.g., "Jul 24 00:00:00")
        log_date = $1 " " $2 " " $3
        log_time = substr($0, index($0, $4))
        log_datetime = log_date " " log_time
        cmd = "date -d \"" log_datetime "\" +%s"
        cmd | getline log_epoch
        close(cmd)

        if (log_epoch == exact_epoch) {
            print $0
        }
    }' "$log_file"
    # Implement your logic here to filter activities by time range
}

# Function to display help
function display_help {
    echo "Usage: devopsfetch.sh [OPTION]"
    echo "Options:"
    echo "  -p, --port [port_number]    Display all active ports and services or details of a specific port"
    echo "  -d, --docker [container]    List all Docker images and containers or details of a specific container"
    echo "  -n, --nginx [domain]        Display all Nginx domains and their ports or details of a specific domain"
    echo "  -u, --users [username]      List all users and their last login times or details of a specific user"
    echo "  -t, --time [time_range]     Display activities within a specified time range"
    echo "  -h, --help                  Display this help message"
}

# Main logic to parse command-line arguments
case "$1" in
    -p|--port)
        if [[ -z "$2" ]]; then
            display_ports
        else
            display_port_details "$2"
        fi
        ;;
    -d|--docker)
        if [[ -z "$2" ]]; then
            list_docker_images
            list_docker_containers
        else
            display_container_details "$2"
        fi
        ;;
    -n|--nginx)
        if [[ -z "$2" ]]; then
            display_nginx_domains
        else
            display_nginx_domain_details "$2"
        fi
        ;;
    -u|--users)
        if [[ -z "$2" ]]; then
            list_users
        else
            display_user_details "$2"
        fi
        ;;
    -t|--time)
        if [[ -z "$2" ]]; then
            echo "Please provide a time range."
        else
            display_time_range_activities "$2"
        fi
        ;;
    -h|--help)
        display_help
        ;;
    *)
        echo "Invalid option: $1"
        display_help
        ;;
esac
