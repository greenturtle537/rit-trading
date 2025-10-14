#!/bin/bash

# RIT Trading Backend Service Installation Script
# This script installs the backend as a systemd service on Debian/Ubuntu

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}RIT Trading Backend Service Installation${NC}"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
    echo "Usage: sudo ./install-service.sh"
    exit 1
fi

# Configuration
SERVICE_NAME="rit-trading"
INSTALL_DIR="/glitchtech/rit-trading"
BACKEND_DIR="$INSTALL_DIR/backend"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
SERVICE_USER="www-data"
SERVICE_GROUP="www-data"

echo -e "${YELLOW}Configuration:${NC}"
echo "  Service name: $SERVICE_NAME"
echo "  Install directory: $INSTALL_DIR"
echo "  Backend directory: $BACKEND_DIR"
echo "  Service user: $SERVICE_USER"
echo "  Service group: $SERVICE_GROUP"
echo ""

# Ask for confirmation
read -p "Continue with installation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Verify backend directory exists
if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}Error: Backend directory not found at $BACKEND_DIR${NC}"
    echo "Please ensure the repository is cloned to $INSTALL_DIR"
    exit 1
fi

# Set correct permissions
echo -e "${YELLOW}Setting permissions...${NC}"
chown -R $SERVICE_USER:$SERVICE_GROUP "$BACKEND_DIR"
chmod -R 755 "$BACKEND_DIR"
chmod 644 "$BACKEND_DIR"/*.pl
chmod +x "$BACKEND_DIR/server.pl"
chmod 660 "$BACKEND_DIR"/*.db 2>/dev/null || true

# Install Perl dependencies
echo -e "${YELLOW}Installing Perl dependencies...${NC}"
cd "$BACKEND_DIR"

if command -v cpanm &> /dev/null; then
    echo "Using cpanm to install dependencies..."
    cpanm --installdeps . --local-lib=local
else
    echo "cpanm not found. Installing cpanminus..."
    apt-get update
    apt-get install -y cpanminus libdbi-perl libdbd-sqlite3-perl
    cpanm --installdeps . --local-lib=local
fi

# Initialize database if it doesn't exist
if [ ! -f "$BACKEND_DIR/rit-trading.db" ]; then
    echo -e "${YELLOW}Initializing database...${NC}"
    sudo -u $SERVICE_USER perl "$BACKEND_DIR/init-db.pl" prod
else
    echo "Database already exists. Skipping initialization."
fi

# Copy and install systemd service file
echo -e "${YELLOW}Installing systemd service...${NC}"
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=RIT Trading Backend Server
After=network.target
Documentation=https://github.com/greenturtle537/rit-trading

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$BACKEND_DIR
ExecStart=/usr/bin/perl $BACKEND_DIR/server.pl
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$BACKEND_DIR

# Environment
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
Environment="PERL5LIB=$BACKEND_DIR/local/lib/perl5"

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
echo -e "${YELLOW}Reloading systemd daemon...${NC}"
systemctl daemon-reload

# Enable service to start on boot
echo -e "${YELLOW}Enabling service to start on boot...${NC}"
systemctl enable $SERVICE_NAME

# Start the service
echo -e "${YELLOW}Starting service...${NC}"
systemctl start $SERVICE_NAME

# Wait a moment for service to start
sleep 2

# Check service status
echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Service status:"
systemctl status $SERVICE_NAME --no-pager || true

echo ""
echo -e "${GREEN}Useful commands:${NC}"
echo "  Start service:   sudo systemctl start $SERVICE_NAME"
echo "  Stop service:    sudo systemctl stop $SERVICE_NAME"
echo "  Restart service: sudo systemctl restart $SERVICE_NAME"
echo "  View status:     sudo systemctl status $SERVICE_NAME"
echo "  View logs:       sudo journalctl -u $SERVICE_NAME -f"
echo "  Disable service: sudo systemctl disable $SERVICE_NAME"
echo ""
echo "Backend directory: $BACKEND_DIR"
echo "Service file: $SERVICE_FILE"
echo ""

# Check if service is running
if systemctl is-active --quiet $SERVICE_NAME; then
    echo -e "${GREEN}✓ Service is running successfully!${NC}"
else
    echo -e "${RED}✗ Service failed to start. Check logs with: journalctl -u $SERVICE_NAME${NC}"
    exit 1
fi
