#!/bin/bash

# Simple nginx HTTPS Toggle Script
# Usage: ./nginx-https-toggle.sh [on|off]

# Configuration paths - modify these according to your setup
NGINX_CONFIG_DIR="/etc/nginx"
NGINX_CONFIG_FILE="$NGINX_CONFIG_DIR/nginx.conf"
HTTPS_CONFIG_FILE="$NGINX_CONFIG_DIR/nginx-https.conf"    # HTTPS enabled config
HTTP_CONFIG_FILE="$NGINX_CONFIG_DIR/nginx-http.conf"      # HTTPS disabled config
BACKUP_CONFIG_FILE="$NGINX_CONFIG_DIR/nginx-backup.conf"      # backup config

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [on|off]"
    echo ""
    echo "Commands:"
    echo "  on   - Enable HTTPS (copy HTTPS config and restart nginx)"
    echo "  off  - Disable HTTPS (copy HTTP config and restart nginx)"
    echo ""
    echo "Required files:"
    echo "  $HTTPS_CONFIG_FILE - nginx config with HTTPS enabled"
    echo "  $HTTP_CONFIG_FILE  - nginx config with HTTPS disabled"
}

# Test nginx configuration
test_nginx() {
    if nginx -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Restart nginx service
restart_nginx() {
    if systemctl restart nginx >/dev/null 2>&1; then
        print_success "nginx restarted successfully"
        return 0
    elif service nginx restart >/dev/null 2>&1; then
        print_success "nginx restarted successfully"  
        return 0
    else
        print_error "Failed to restart nginx"
        return 1
    fi
}

# Main function
main() {
    local action="$1"
    
    if [[ -z "$action" ]]; then
        show_usage
        exit 1
    fi
    
    check_root
    
    case "$action" in
        "on"|"enable")
            # Check if HTTPS config file exists
            if [[ ! -f "$HTTPS_CONFIG_FILE" ]]; then
                print_error "HTTPS config file not found: $HTTPS_CONFIG_FILE"
                exit 1
            fi
            
            
            # Copy HTTPS config
            cp "$HTTPS_CONFIG_FILE" "$NGINX_CONFIG_FILE"
            print_success "Copied HTTPS configuration"
            
            # Test configuration
            if test_nginx; then
                print_success "nginx configuration is valid"
                restart_nginx
                print_success "HTTPS enabled successfully!"
            else
                print_error "nginx configuration test failed!"
                # Restore backup
                cp "$BACKUP_CONFIG_FILE" "$NGINX_CONFIG_FILE"
                print_warning "Configuration restored from backup"
                exit 1
            fi
            ;;
            
        "off"|"disable")
            # Check if HTTP config file exists
            if [[ ! -f "$HTTP_CONFIG_FILE" ]]; then
                print_error "HTTP config file not found: $HTTP_CONFIG_FILE"
                exit 1
            fi
           
            # Copy HTTP config
            cp "$HTTP_CONFIG_FILE" "$NGINX_CONFIG_FILE"
            print_success "Copied HTTP configuration"
            
            # Test configuration
            if test_nginx; then
                print_success "nginx configuration is valid"
                restart_nginx
                print_success "HTTPS disabled successfully!"
            else
                print_error "nginx configuration test failed!"
                # Restore backup  
                cp "$BACKUP_CONFIG_FILE" "$NGINX_CONFIG_FILE"
                print_warning "Configuration restored from backup"
                exit 1
            fi
            ;;
            
        *)
            print_error "Unknown action: $action"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
