#!/bin/bash

# SMB Control Script
# Usage: ./smb_control.sh [start|stop|restart|status]

# Configuration
SMB_SERVICE="smbd"
NMB_SERVICE="nmbd"
LOG_FILE="/var/log/smb_control.log"
CONFIG_FILE="/etc/samba/smb.conf"
SMB_HOME_PATH="/tmp/youtube_download/congliulyc@gmail.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_status $RED "Error: This script must be run as root"
        exit 1
    fi
}

# Function to create SMB configuration with custom home path
create_smb_config() {
    log "Creating SMB configuration with home path: $SMB_HOME_PATH"
    
    # Create the directory
    # mkdir -p "$SMB_HOME_PATH"
    # chmod 755 "$SMB_HOME_PATH"
    
    # Create SMB configuration
    cat > "$CONFIG_FILE" << EOF
[global]
   workgroup = WORKGROUP
   server string = Samba Server
   server role = standalone server
   map to guest = bad user
   dns proxy = no
   log level = 1
   log file = /var/log/samba/%m.log
   max log size = 50

[youtube_download]
   path = $SMB_HOME_PATH
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0644
   directory mask = 0755
   comment = YouTube Download Directory
EOF

    print_status $GREEN "SMB configuration created with home path: $SMB_HOME_PATH"
}

# Function to start SMB services
start_smb() {
    log "Starting SMB services..."
    
    # Create configuration and directory if they don't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        create_smb_config
    fi
    
    # Ensure the directory exists
    # mkdir -p "$SMB_HOME_PATH"
    # chmod 755 "$SMB_HOME_PATH"
    
    # Start smbd
    if systemctl start "$SMB_SERVICE" 2>/dev/null; then
        print_status $GREEN "Started $SMB_SERVICE"
    else
        print_status $RED "Failed to start $SMB_SERVICE"
        return 1
    fi
    
    # Start nmbd
    if systemctl start "$NMB_SERVICE" 2>/dev/null; then
        print_status $GREEN "Started $NMB_SERVICE"
    else
        print_status $YELLOW "Warning: Failed to start $NMB_SERVICE"
    fi
    
    # Enable services to start on boot
    systemctl enable "$SMB_SERVICE" 2>/dev/null
    systemctl enable "$NMB_SERVICE" 2>/dev/null
    
    print_status $GREEN "SMB services started successfully"
    print_status $BLUE "SMB share available at: $SMB_HOME_PATH"
    return 0
}

# Function to stop SMB services
stop_smb() {
    log "Stopping SMB services..."
    
    # Stop smbd
    if systemctl stop "$SMB_SERVICE" 2>/dev/null; then
        print_status $GREEN "Stopped $SMB_SERVICE"
    else
        print_status $RED "Failed to stop $SMB_SERVICE"
        return 1
    fi
    
    # Stop nmbd
    if systemctl stop "$NMB_SERVICE" 2>/dev/null; then
        print_status $GREEN "Stopped $NMB_SERVICE"
    else
        print_status $YELLOW "Warning: Failed to stop $NMB_SERVICE"
    fi
    
    print_status $GREEN "SMB services stopped successfully"
    return 0
}

# Function to restart SMB services
restart_smb() {
    log "Restarting SMB services..."
    
    stop_smb
    sleep 2
    start_smb
    
    print_status $GREEN "SMB services restarted successfully"
}

# Function to check SMB status
check_smb_status() {
    log "Checking SMB status..."
    
    print_status $BLUE "=== SMB Service Status ==="
    
    # Check smbd status
    if systemctl is-active --quiet "$SMB_SERVICE"; then
        print_status $GREEN "$SMB_SERVICE: RUNNING"
    else
        print_status $RED "$SMB_SERVICE: STOPPED"
    fi
    
    # Check nmbd status
    if systemctl is-active --quiet "$NMB_SERVICE"; then
        print_status $GREEN "$NMB_SERVICE: RUNNING"
    else
        print_status $RED "$NMB_SERVICE: STOPPED"
    fi
    
    # Check if services are enabled
    if systemctl is-enabled --quiet "$SMB_SERVICE"; then
        print_status $GREEN "$SMB_SERVICE: ENABLED (starts on boot)"
    else
        print_status $YELLOW "$SMB_SERVICE: DISABLED"
    fi
    
    if systemctl is-enabled --quiet "$NMB_SERVICE"; then
        print_status $GREEN "$NMB_SERVICE: ENABLED (starts on boot)"
    else
        print_status $YELLOW "$NMB_SERVICE: DISABLED"
    fi
    
    # Show listening ports
    print_status $BLUE "=== Network Status ==="
    if command -v netstat >/dev/null 2>&1; then
        netstat -tlnp | grep -E "(smbd|nmbd)" || print_status $YELLOW "No SMB ports found listening"
    elif command -v ss >/dev/null 2>&1; then
        ss -tlnp | grep -E "(smbd|nmbd)" || print_status $YELLOW "No SMB ports found listening"
    fi
    
    # Show SMB shares
    print_status $BLUE "=== SMB Shares ==="
    if command -v smbclient >/dev/null 2>&1; then
        smbclient -L localhost -U% 2>/dev/null | grep -E "^[[:space:]]*[A-Za-z]" || print_status $YELLOW "No shares found"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     - Start SMB services"
    echo "  stop      - Stop SMB services"
    echo "  restart   - Restart SMB services"
    echo "  status    - Show SMB service status"
    echo "  setup     - Create/update SMB configuration"
    echo "  config    - Show SMB configuration"
    echo "  test      - Test SMB connectivity"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 status"
    echo "  $0 restart"
    echo "  $0 setup"
}

# Function to show SMB configuration
show_config() {
    log "Showing SMB configuration..."
    
    if [[ -f "$CONFIG_FILE" ]]; then
        print_status $BLUE "=== SMB Configuration ==="
        cat "$CONFIG_FILE"
    else
        print_status $RED "SMB configuration file not found: $CONFIG_FILE"
    fi
}

# Function to test SMB connectivity
test_smb() {
    log "Testing SMB connectivity..."
    
    print_status $BLUE "=== SMB Connectivity Test ==="
    
    # Test local connection
    if command -v smbclient >/dev/null 2>&1; then
        print_status $BLUE "Testing local SMB connection..."
        if smbclient -L localhost -U% >/dev/null 2>&1; then
            print_status $GREEN "Local SMB connection: SUCCESS"
        else
            print_status $RED "Local SMB connection: FAILED"
        fi
    else
        print_status $YELLOW "smbclient not available for testing"
    fi
    
    # Test port connectivity
    print_status $BLUE "Testing SMB ports..."
    if nc -z localhost 139 2>/dev/null; then
        print_status $GREEN "Port 139 (NetBIOS): OPEN"
    else
        print_status $RED "Port 139 (NetBIOS): CLOSED"
    fi
    
    if nc -z localhost 445 2>/dev/null; then
        print_status $GREEN "Port 445 (SMB): OPEN"
    else
        print_status $RED "Port 445 (SMB): CLOSED"
    fi
}

# Main script logic
main() {
    # Check if running as root
    check_root
    
    # Parse command line arguments
    case "${1:-}" in
        start)
            start_smb
            ;;
        stop)
            stop_smb
            ;;
        restart)
            restart_smb
            ;;
        status)
            check_smb_status
            ;;
        setup)
            create_smb_config
            ;;
        config)
            show_config
            ;;
        test)
            test_smb
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_status $RED "Error: Unknown command '$1'"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 
