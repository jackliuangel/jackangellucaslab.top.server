#!/bin/bash

echo "=== Deploying File Cleanup Service ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root"
    echo "Please run: sudo $0"
    exit 1
fi

# Check if script exists in current directory
if [ ! -f "cleanup_old_files.sh" ]; then
    echo "ERROR: cleanup_old_files.sh not found in current directory"
    echo "Please make sure you're in the correct directory"
    exit 1
fi

if [ ! -f "cleanup-old-files.service" ]; then
    echo "ERROR: cleanup-old-files.service not found in current directory"
    echo "Please make sure you're in the correct directory"
    exit 1
fi

# Copy script to system directory
echo "1. Copying cleanup script to /usr/local/bin..."
cp cleanup_old_files.sh /usr/local/bin/
chmod +x /usr/local/bin/cleanup_old_files.sh

# Copy service file
echo "2. Copying systemd service file..."
cp cleanup-old-files.service /etc/systemd/system/

# Reload systemd
echo "3. Reloading systemd..."
systemctl daemon-reload

# Enable service
echo "4. Enabling service..."
systemctl enable cleanup-old-files.service

# Start service
echo "5. Starting service..."
systemctl start cleanup-old-files.service

# Check service status
echo "6. Checking service status..."
systemctl status cleanup-old-files.service --no-pager

# Check logs
echo "7. Checking service logs..."
journalctl -u cleanup-old-files.service -n 10 --no-pager

echo ""
echo "=== Deployment completed ==="
echo "Service configuration:"
echo "  - Executes cleanup every 2 hours"
echo "  - Deletes files older than 1 hour"
echo "  - Log file: /var/log/cleanup_old_files.log"
echo ""
echo "Management commands:"
echo "  - Check status: systemctl status cleanup-old-files.service"
echo "  - View logs: journalctl -u cleanup-old-files.service -f"
echo "  - Stop service: systemctl stop cleanup-old-files.service"
echo "  - Restart service: systemctl restart cleanup-old-files.service"
echo ""
echo "To view cleanup logs:"
echo "  - tail -f /var/log/cleanup_old_files.log" 
