#!/bin/bash

# RIT Trading Backend Service Uninstall Script
# This script removes the systemd service and optionally removes installation files

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}RIT Trading Backend Service Uninstall${NC}"
echo "========================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
    echo "Usage: sudo ./uninstall-service.sh"
    exit 1
fi

# Configuration
SERVICE_NAME="rit-trading"
INSTALL_DIR="/glitchtech/rit-trading"
BACKEND_DIR="$INSTALL_DIR/backend"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

echo "This will uninstall the $SERVICE_NAME service."
echo ""
read -p "Continue with uninstall? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

# Stop the service if running
if systemctl is-active --quiet $SERVICE_NAME; then
    echo -e "${YELLOW}Stopping service...${NC}"
    systemctl stop $SERVICE_NAME
fi

# Disable the service
if systemctl is-enabled --quiet $SERVICE_NAME 2>/dev/null; then
    echo -e "${YELLOW}Disabling service...${NC}"
    systemctl disable $SERVICE_NAME
fi

# Remove service file
if [ -f "$SERVICE_FILE" ]; then
    echo -e "${YELLOW}Removing service file...${NC}"
    rm "$SERVICE_FILE"
fi

# Reload systemd
echo -e "${YELLOW}Reloading systemd daemon...${NC}"
systemctl daemon-reload
systemctl reset-failed

echo ""
echo -e "${GREEN}Service uninstalled successfully.${NC}"
echo "Installation directory preserved at: $INSTALL_DIR"
echo ""
echo -e "${GREEN}Uninstall complete!${NC}"
