#!/bin/bash

# Modern installation script for SugarPiDisplay with latest Raspbian (Bookworm)
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}SugarPiDisplay Installation Script${NC}"
echo "For Raspberry Pi Zero W with latest Raspbian (Bookworm)"
echo ""

if ! grep -q "BCM2" /proc/cpuinfo; then
    echo -e "${YELLOW}Warning: This does not appear to be a Raspberry Pi${NC}"
fi

# Install system dependencies for Bookworm
echo -e "${GREEN}Installing system dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y \
    python3-pip \
    python3-venv \
    python3-dev \
    git \
    build-essential \
    gpiod \
    libopenjp2-7 \
    libjpeg62-turbo \
    libtiff6 \
    libwebp7

PROJECT_DIR="${HOME}/SugarPiDisplay"
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: Project directory not found at $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

echo -e "${GREEN}Creating Python virtual environment...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

echo -e "${GREEN}Installing Python dependencies...${NC}"
source venv/bin/activate
pip install --upgrade pip setuptools wheel

pip install --no-cache-dir \
    Flask>=2.3.0 \
    Flask-WTF>=1.1.0 \
    Pillow>=10.0.0 \
    requests>=2.31.0 \
    Werkzeug>=2.3.0 \
    spidev>=3.6 \
    RPi.GPIO>=0.7.0 \
    gpiozero>=2.0.0

echo -e "${GREEN}Configuring GPIO and SPI access...${NC}"
sudo usermod -aG gpio "$USER" 2>/dev/null || true
sudo usermod -aG spi "$USER" 2>/dev/null || true

if command -v raspi-config &> /dev/null; then
    sudo raspi-config nonint do_spi 0 2>/dev/null || echo "SPI configuration skipped"
fi

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

sudo systemctl daemon-reload
sudo systemctl enable sugarpidisplay.service
sudo systemctl enable sugarpidisplay-network-check.timer

echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Log out and log back in for GPIO/SPI permissions:"
echo "   exit"
echo "2. Start the service:"
echo "   sudo systemctl start sugarpidisplay.service"
echo "3. Check status:"
echo "   sudo systemctl status sugarpidisplay.service"
echo "4. View logs:"
echo "   sudo journalctl -u sugarpidisplay.service -f"
echo "5. Access web interface at http://<your-pi-ip>:8080"
