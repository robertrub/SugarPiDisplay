#!/bin/bash

# Modern installation script for SugarPiDisplay with latest Raspbian (Bookworm)
# This script sets up the application with systemd service management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}SugarPiDisplay Installation Script${NC}"
echo "For Raspberry Pi Zero W with latest Raspbian (Bookworm)"
echo ""

# Check if running on Raspberry Pi
if ! grep -q "BCM2" /proc/cpuinfo; then
    echo -e "${YELLOW}Warning: This does not appear to be a Raspberry Pi${NC}"
fi

# Install system dependencies for latest Raspbian
echo -e "${GREEN}Installing system dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y \
    python3-pip \
    python3-venv \
    python3-dev \
    libopenjp2-7 \
    libtiff6 \
    libharfbuzz0b \
    libwebp6 \
    libatlas-base-dev \
    git \
    build-essential \
    gpiod

# Navigate to project directory
PROJECT_DIR="${HOME}/SugarPiDisplay"
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: Project directory not found at $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

# Create Python virtual environment
echo -e "${GREEN}Creating Python virtual environment...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate virtual environment and install dependencies
echo -e "${GREEN}Installing Python dependencies...${NC}"
source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

# Set up GPIO and SPI permissions for non-root access
echo -e "${GREEN}Configuring GPIO and SPI access...${NC}"
sudo usermod -aG gpio "$USER"
sudo usermod -aG spi "$USER"

# Enable SPI interface if not already enabled
echo -e "${GREEN}Enabling SPI interface...${NC}"
sudo raspi-config nonint do_spi 0 2>/dev/null || echo "SPI already enabled or raspi-config unavailable"

# Create systemd service file
echo -e "${GREEN}Setting up systemd service...${NC}"
sudo tee /etc/systemd/system/sugarpidisplay.service > /dev/null <<EOF
[Unit]
Description=SugarPi Display Service - CGM Display
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$PROJECT_DIR/venv/bin"
ExecStart=$PROJECT_DIR/venv/bin/python3 -m sugarpidisplay
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create systemd timer for network health checks
echo -e "${GREEN}Setting up network health check timer...${NC}"
sudo tee /etc/systemd/system/sugarpidisplay-network-check.service > /dev/null <<EOF
[Unit]
Description=SugarPi Network Health Check
After=network.target

[Service]
Type=oneshot
ExecStart=$PROJECT_DIR/network-check.sh
StandardOutput=journal
StandardError=journal
EOF

sudo tee /etc/systemd/system/sugarpidisplay-network-check.timer > /dev/null <<EOF
[Unit]
Description=Run SugarPi Network Check Every 5 Minutes
Requires=sugarpidisplay-network-check.service

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable sugarpidisplay.service
sudo systemctl enable sugarpidisplay-network-check.timer

echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Log out and log back in for GPIO/SPI permissions to take effect:"
echo "   exit"
echo ""
echo "2. After logging back in, start the service:"
echo "   sudo systemctl start sugarpidisplay.service"
echo ""
echo "3. Check service status:"
echo "   sudo systemctl status sugarpidisplay.service"
echo ""
echo "4. View service logs (real-time):"
echo "   sudo journalctl -u sugarpidisplay.service -f"
echo ""
echo "5. Access web configuration interface at:"
echo "   http://<your-pi-ip>:8080"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  Stop service:          sudo systemctl stop sugarpidisplay.service"
echo "  Disable on boot:       sudo systemctl disable sugarpidisplay.service"
echo "  View recent logs:      sudo journalctl -u sugarpidisplay.service -n 50"
