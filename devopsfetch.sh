#!/bin/bash

# Function to display all active ports and services
function display_ports {
    echo "Active Ports and Services:"
    netstat -tuln | awk 'NR>2 {print $1, $4, $7}'
}

# Function to display detailed information about a specific port
function display_port_details {
    local port=$1
    echo "Details for Port $port:"
    netstat -tulnp | grep ":$port "
}

# Function to list all Docker images
function list_docker_images {
    echo "Docker Images:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"
}

# Function to list all Docker containers
function list_docker_containers {
    echo "Docker Containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
}

# Function to display detailed information about a specific Docker container
function display_container_details {
    local container=$1
    echo "Details for Docker Container $container:"
    docker inspect $container
}

# Function to display all Nginx domains and their ports
function display_nginx_domains {
    echo "Nginx Domains and Ports:"
    grep -r 'server_name' /etc/nginx/sites-available/* | awk '{print $3}' | sed 's/;//'
    grep -r 'listen' /etc/nginx/sites-available/* | awk '{print $2}' | sed 's/;//'
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
    last -a | head -n -2
}

# Function to display detailed information about a specific user
function display_user_details {
    local username=$1
    echo "Details for User $username:"
    finger $username
}

# Function to display activities within a specified time range
function display_time_range_activities {
    local time_range=$1
    echo "Activities within the time range $time_range:"
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
