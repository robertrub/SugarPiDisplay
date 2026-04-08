#!/bin/bash

# SugarPiDisplay Installation Script for Raspberry Pi
# Modern setup with systemd service management
# Compatible with Raspbian Bookworm

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="${HOME}/SugarPiDisplay"
SERVICE_NAME="sugarpidisplay"
TIMER_NAME="sugarpidisplay-network-check"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${GREEN}SugarPiDisplay Installation${NC}${BLUE}                           ║${NC}"
echo -e "${BLUE}║${NC}  For Raspberry Pi with Raspbian Bookworm${BLUE}               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════���═══════════════════╝${NC}"
echo ""

# Verify running on Raspberry Pi
if ! grep -q "BCM2" /proc/cpuinfo; then
    echo -e "${YELLOW}⚠️  Warning: This does not appear to be a Raspberry Pi${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Verify project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}✗ Error: Project directory not found at $PROJECT_DIR${NC}"
    echo "Please clone the repository first:"
    echo "  git clone https://github.com/robertrub/SugarPiDisplay.git ~/SugarPiDisplay"
    exit 1
fi

cd "$PROJECT_DIR"

# Step 1: Update system packages
echo -e "${GREEN}📦 Step 1: Installing system dependencies...${NC}"
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
    libwebp7 \
    libfreetype6 \
    zlib1g \
    libharfbuzz0b

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ System dependencies installed${NC}\n"
else
    echo -e "${RED}✗ Failed to install system dependencies${NC}"
    exit 1
fi

# Step 2: Create virtual environment
echo -e "${GREEN}📦 Step 2: Creating Python virtual environment...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}\n"
else
    echo -e "${YELLOW}ℹ Virtual environment already exists${NC}\n"
fi

# Step 3: Install Python dependencies
echo -e "${GREEN}📦 Step 3: Installing Python dependencies...${NC}"
source venv/bin/activate
pip install --upgrade pip setuptools wheel > /dev/null 2>&1

if [ -f "requirements.txt" ]; then
    pip install --no-cache-dir -r requirements.txt
else
    pip install --no-cache-dir \
        Flask>=2.3.0 \
        Flask-WTF>=1.1.0 \
        Pillow>=10.0.0 \
        requests>=2.31.0 \
        Werkzeug>=2.3.0 \
        spidev>=3.6 \
        RPi.GPIO>=0.7.0 \
        gpiozero>=2.0.0
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Python dependencies installed${NC}\n"
else
    echo -e "${RED}✗ Failed to install Python dependencies${NC}"
    exit 1
fi

deactivate

# Step 4: Configure GPIO and SPI access
echo -e "${GREEN}🔧 Step 4: Configuring GPIO and SPI access...${NC}"
CURRENT_USER=$(whoami)
sudo usermod -aG gpio "$CURRENT_USER" 2>/dev/null || true
sudo usermod -aG spi "$CURRENT_USER" 2>/dev/null || true
echo -e "${GREEN}✓ User added to gpio and spi groups${NC}\n"

# Step 5: Enable SPI interface
echo -e "${GREEN}🔧 Step 5: Enabling SPI interface...${NC}"
if command -v raspi-config &> /dev/null; then
    sudo raspi-config nonint do_spi 0 2>/dev/null
    echo -e "${GREEN}✓ SPI interface enabled${NC}\n"
else
    echo -e "${YELLOW}ℹ raspi-config not found. Please enable SPI manually${NC}"
    echo "   Run: sudo raspi-config -> Interface Options -> SPI\n"
fi

# Step 6: Create systemd service
echo -e "${GREEN}🚀 Step 6: Setting up systemd service...${NC}"

cat << EOF | sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null
[Unit]
Description=SugarPi Display Service - CGM Display
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_USER
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

echo -e "${GREEN}✓ Service file created${NC}\n"

# Step 7: Create systemd timer for network health checks
echo -e "${GREEN}🚀 Step 7: Setting up network health check timer...${NC}"

cat << EOF | sudo tee /etc/systemd/system/${TIMER_NAME}.service > /dev/null
[Unit]
Description=SugarPi Network Health Check
After=network.target

[Service]
Type=oneshot
ExecStart=$PROJECT_DIR/network-check.sh
StandardOutput=journal
StandardError=journal
EOF

cat << EOF | sudo tee /etc/systemd/system/${TIMER_NAME}.timer > /dev/null
[Unit]
Description=Run SugarPi Network Check Every 5 Minutes
Requires=${TIMER_NAME}.service

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF

echo -e "${GREEN}✓ Timer files created${NC}\n"

# Step 8: Enable and configure services
echo -e "${GREEN}🚀 Step 8: Enabling systemd services...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}.service
sudo systemctl enable ${TIMER_NAME}.timer
echo -e "${GREEN}✓ Services enabled${NC}\n"

# Final summary
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${GREEN}Installation Complete!${NC}${BLUE}                              ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📋 NEXT STEPS:${NC}"
echo ""
echo "1️⃣  Log out and log back in for GPIO/SPI permissions to take effect:"
echo -e "   ${BLUE}exit${NC}"
echo ""
echo "2️⃣  After logging back in, start the service:"
echo -e "   ${BLUE}sudo systemctl start ${SERVICE_NAME}.service${NC}"
echo ""
echo "3️⃣  Check service status:"
echo -e "   ${BLUE}sudo systemctl status ${SERVICE_NAME}.service${NC}"
echo ""
echo "4️⃣  View real-time logs:"
echo -e "   ${BLUE}sudo journalctl -u ${SERVICE_NAME}.service -f${NC}"
echo ""
echo "5️⃣  Access web configuration interface:"
echo -e "   ${BLUE}http://<your-pi-ip>:8080${NC}"
echo ""
echo -e "${YELLOW}📚 USEFUL COMMANDS:${NC}"
echo ""
echo "  Stop service:           ${BLUE}sudo systemctl stop ${SERVICE_NAME}.service${NC}"
echo "  Restart service:        ${BLUE}sudo systemctl restart ${SERVICE_NAME}.service${NC}"
echo "  Check service status:   ${BLUE}sudo systemctl status ${SERVICE_NAME}.service${NC}"
echo "  View recent logs:       ${BLUE}sudo journalctl -u ${SERVICE_NAME}.service -n 50${NC}"
echo "  Disable on boot:        ${BLUE}sudo systemctl disable ${SERVICE_NAME}.service${NC}"
echo "  View timer status:      ${BLUE}sudo systemctl status ${TIMER_NAME}.timer${NC}"
echo ""
echo -e "${GREEN}✓ Installation successful!${NC}"
