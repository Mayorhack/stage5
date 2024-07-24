# Use an official Nginx image as a base
FROM nginx:alpine

# Copy the frontend application files to the Nginx HTML directory
COPY ./frontend /usr/share/nginx/html

# Copy the custom Nginx configuration file
COPY ./nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
