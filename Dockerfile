# Use Ubuntu as the base image
FROM ubuntu:20.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Copy the devopsfetch script into the container
COPY devopsfetch.sh /usr/local/bin/devopsfetch

# Make the script executable
RUN chmod +x /usr/local/bin/devopsfetch

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/devopsfetch", "-c"]

# Expose port 80 for potential future use (e.g., web interface)
EXPOSE 80