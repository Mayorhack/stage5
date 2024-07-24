#!/bin/bash

# Install necessary dependencies
sudo apt update
sudo apt install -y net-tools docker.io nginx logrotate

# Copy devopsfetch.sh to /usr/local/bin
sudo cp devopsfetch.sh /usr/local/bin/devopsfetch
sudo chmod +x /usr/local/bin/devopsfetch

# Create systemd service file
sudo bash -c 'cat << EOF > /etc/systemd/system/devopsfetch.service
[Unit]
Description=DevOpsFetch Service

[Service]
ExecStart=/usr/local/bin/devopsfetch.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd and enable the service
sudo systemctl daemon-reload
sudo systemctl enable devopsfetch.service
sudo systemctl start devopsfetch.service

# Set up log rotation
sudo bash -c 'cat << EOF > /etc/logrotate.d/devopsfetch
/var/log/devopsfetch.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        systemctl restart devopsfetch.service > /dev/null 2>/dev/null || true
    endscript
}
EOF'
