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
        service=$(grep -w "$port" /etc/services | awk '{print $1}' | head -n 1)
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
        created_date=$(echo "$created_date" | awk '{print $1, $2}')
        
      
        if [ ${#image_name} -gt 20 ]; then
            image_name="${image_name:0:17}..."
        fi
       printf "| %-20s | %-20s | %-6s | %-20s |\n" " $container_id"  "$image_name"  "$size"  "$created_date"
    done <<< "$docker_info"

    echo "+----------------------+----------------------+---------+---------------------+"
}

# Function to list all Docker containers
function list_docker_containers {
    echo "Docker Containers:"
   # Fetching Docker containers with ID, Image, Status, Ports, and Created date
    docker_info=$(sudo docker ps -a --format "{{.ID}}|{{.Image}}|{{.Status}}|{{.Ports}}|{{.CreatedAt}}")

    # Displaying in a tabular format
    echo "+------------------+--------------+---------+------------+------------------+"
    echo "| Container ID     | Image        | Status  | Ports      | Created Date     |"
    echo "+------------------+--------------+---------+------------+------------------+"

    # Loop through each line of docker_info
    while IFS='|' read -r container_id image status ports created_date; do
        # Truncate image name if too long
       # Strip off the timezone information (+0000 UTC) from created_date
        created_date=$(echo "$created_date" | awk '{print $1, $2}')
        
        # Convert the stripped date to a human-readable format (e.g., YYYY-MM-DD HH:MM:SS)
       
        if [[ "$status" == *"Up"* ]]; then
            status="Up"
        else
            status="Exited"
        fi
        if [ ${#image} -gt 20 ]; then
            image="${image:0:17}..."
        fi
            # Extract only the port binding :::8000->80
        specific_port=$(echo "$ports" | grep -oE ':::[0-9]+->80' | head -n 1)
        printf "| %-16s | %-12s | %-7s | %-10s | %-20s |\n" "$container_id" "$image" "$status" "$specific_port" "$created_date"
    done <<< "$docker_info"

    echo "+----------------+------------+------------+-------------+---------------+"
}

# Function to display detailed information about a specific Docker container
function display_container_details {
    local container=$1
    echo "Details for Docker Container $container:"
    sudo docker inspect $container
}

# Function to display all Nginx domains and their ports
function display_nginx_domains {
      echo "Retrieving Nginx configurations..."

    # Find all Nginx configuration files
    config_files=$(find /etc/nginx -type f -name '*.conf')

    # Print table header
    echo "+------------------------------------+----------------------+----------------------+" 
    echo "| Config File Path                   | Domain               | Ports                |"
    echo "+------------------------------------+----------------------+----------------------+"

    # Loop through each configuration file
    for conf_file in $config_files; do
        # Extract domains and ports from each configuration file
        grep -E 'server_name|listen' "$conf_file" | awk '
        BEGIN {file=""; domain=""; port=""}
        /server_name/ {domain=$2; file=FILENAME}
        /listen/ {port=$2; if (domain != "") {printf "| %-48s | %-28s | %-18s |\n", file, domain, port; domain=""; port=""}}
        ' OFS='\t'
    done

    # Print table footer
    echo "+-------------------------------------+---------------------+----------------------+"
}

# Function to display detailed Nginx configuration for a specific domain
function display_nginx_domain_details {
    local domain=$1
    echo "Details for Nginx Domain $domain:"
    grep -r "server_name $domain;" /etc/nginx/sites-available/*
}

# Function to list all users and their last login times
function list_users {
#!/bin/bash

echo "Users and Last Login Times:"

# Fetching users and their last login times
users_info=$(sudo lastlog -u 0)

# Displaying in a tabular format
echo "+----------------------+----------------------+"
echo "| Username             | Last Login Time      |"
echo "+----------------------+----------------------+"

# Loop through each line of users_info
while IFS=' ' read -r username _ _ last_login1 last_login2 last_login3; do
    # Combine potential multi-word last_login fields
    last_login_info="${last_login1} ${last_login2} ${last_login3}"
    
    # Handle cases where last_login_info is not a valid date
    if [[ "$last_login_info" != "**Never logged in**" ]]; then
        # Attempt to convert last_login_info to a date format
        last_login_date=$(date -d "$last_login_info" "+%b %d %Y" 2>/dev/null)
        
        if [[ $? -ne 0 ]]; then
            last_login_date=$last_login1
        fi
    else
        last_login_date="Never logged in"
    fi

    # Print in a tabular format
    printf "| %-20s | %-20s |\n" "$username" "$last_login_date"
done <<< "$users_info"

# Print table footer
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
    local start_time="$1"
    local end_time="$2"

    if [[ -z "$start_time" || -z "$end_time" ]]; then
        echo "Usage: display_time_range_activities <start_time> <end_time>"
        echo "Example: display_time_range_activities '2024-07-24 00:00:00' '2024-07-24 23:59:59'"
        return 1
    fi

    local log_file="/var/log/devopsfetch.log."

    if [[ ! -f "$log_file" ]]; then
        echo "Error: Log file '$log_file' not found."
        return 1
    fi

    # Convert start and end timestamps to epoch for comparison
    local start_epoch=$(date -d "$start_time" +%s)
    local end_epoch=$(date -d "$end_time" +%s)

    if [[ $? -ne 0 ]]; then
        echo "Error: Invalid date format. Use 'YYYY-MM-DD HH:MM:SS'."
        return 1
    fi

    echo "Fetching syslog entries from '$start_time' to '$end_time'..."

    awk -v start_epoch="$start_epoch" -v end_epoch="$end_epoch" '
    {
        # Extract date and time from log line
        log_date = $1 " " $2 " " $3
        log_time = substr($0, index($0, $4))
        log_datetime = log_date " " log_time
        
        # Convert log datetime to epoch
        cmd = "date -d \"" log_datetime "\" +%s"
        cmd | getline log_epoch
        close(cmd)

        # Check if the log entry is within the specified time range
        if (log_epoch >= start_epoch && log_epoch <= end_epoch) {
            print $0
        }
    }' "$log_file"
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
        if [[ -z "$2" || -z "$3" ]]; then
            echo "Please provide a time range."
        else
            display_time_range_activities "$2" "$3"
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
