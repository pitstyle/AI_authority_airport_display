#!/bin/bash

# Airport Transcript Display - Pi Deployment Script
# Usage: ./deploy-to-pi.sh [PI_IP] [DISPLAY_ID] [SCALE]
# Example: ./deploy-to-pi.sh 192.168.1.100 1 1.0

set -e

# Configuration
PI_IP=${1:-"192.168.1.100"}
DISPLAY_ID=${2:-"1"}
DISPLAY_SCALE=${3:-"1.0"}
PI_USER="pitstyle"
SSH_KEY_PATH="$HOME/.ssh/id_rsa_airport_display"
APP_NAME="airport-transcript-display"
APP_PATH="/home/pitstyle/$APP_NAME"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Pi Deployment...${NC}"
echo "Target Pi: $PI_IP"
echo "Display ID: $DISPLAY_ID"
echo "Scale: $DISPLAY_SCALE"
echo "----------------------------------------"

# Check if Pi is reachable
echo -e "${YELLOW}📡 Checking Pi connectivity...${NC}"
if ! ping -c 1 $PI_IP > /dev/null 2>&1; then
    echo -e "${RED}❌ Cannot reach Pi at $PI_IP${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Pi is reachable${NC}"

# Check SSH connection
echo -e "${YELLOW}🔐 Testing SSH connection...${NC}"
if ! ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=5 -o BatchMode=yes $PI_USER@$PI_IP exit 2>/dev/null; then
    echo -e "${RED}❌ SSH connection failed. Please check SSH keys or run setup-pi-ssh.sh${NC}"
    exit 1
fi
echo -e "${GREEN}✅ SSH connection successful${NC}"

# Build production app locally
echo -e "${YELLOW}🏗️  Building production app...${NC}"
npm run build
echo -e "${GREEN}✅ Production build complete${NC}"

# Create deployment package
echo -e "${YELLOW}📦 Creating deployment package...${NC}"
tar -czf airport-display-deploy.tar.gz \
    build/ \
    package.json \
    package-lock.json \
    .env.display1 \
    .env.display2 \
    .env.display3 \
    PI_DEPLOYMENT_GUIDE.md \
    KIOSK_EXIT_GUIDE.md
echo -e "${GREEN}✅ Deployment package created${NC}"

# Transfer files to Pi
echo -e "${YELLOW}📤 Transferring files to Pi...${NC}"
scp -i "$SSH_KEY_PATH" airport-display-deploy.tar.gz $PI_USER@$PI_IP:/home/pitstyle/
echo -e "${GREEN}✅ Files transferred${NC}"

# Clean up local package
rm airport-display-deploy.tar.gz

# Execute deployment on Pi
echo -e "${YELLOW}🔧 Executing deployment on Pi...${NC}"
ssh -i "$SSH_KEY_PATH" $PI_USER@$PI_IP << EOF
set -e

# Extract deployment package
cd /home/pitstyle
tar -xzf airport-display-deploy.tar.gz
rm airport-display-deploy.tar.gz

# Create app directory if it doesn't exist
mkdir -p $APP_PATH
mv build/ package.json package-lock.json .env.display* PI_DEPLOYMENT_GUIDE.md KIOSK_EXIT_GUIDE.md $APP_PATH/

# Navigate to app directory
cd $APP_PATH

# Install/update Node.js if needed
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install serve for production
npm install -g serve

# Configure environment for this display
cp .env.display$DISPLAY_ID .env
echo "REACT_APP_DISPLAY_SCALE=$DISPLAY_SCALE" >> .env

# Create service file
sudo tee /etc/systemd/system/airport-display.service > /dev/null << 'EOL'
[Unit]
Description=Airport Transcript Display
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=$APP_PATH
ExecStart=/usr/local/bin/serve -s build -l 3000
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOL

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable airport-display.service
sudo systemctl stop airport-display.service 2>/dev/null || true
sudo systemctl start airport-display.service

# Create browser auto-start script
tee /home/pitstyle/start-display.sh > /dev/null << 'EOL'
#!/bin/bash
# Wait for network and app to be ready
sleep 30

# Wait for the service to be fully ready
while ! curl -f http://localhost:3000 > /dev/null 2>&1; do
    echo "Waiting for app to be ready..."
    sleep 5
done

# Hide cursor and launch browser in kiosk mode
unclutter -idle 0 &
DISPLAY=:0 chromium-browser --kiosk --no-sandbox --disable-infobars --disable-restore-session-state --disable-web-security --allow-running-insecure-content http://localhost:3000
EOL

# Create exit kiosk script
tee /home/pitstyle/exit-kiosk.sh > /dev/null << 'EOL'
#!/bin/bash
# Simple script to exit kiosk mode
pkill chromium-browser
echo "Kiosk mode exited. Desktop should be visible now."
echo "To restart kiosk mode, run: /home/pitstyle/start-display.sh"
echo "Or restart the service: sudo systemctl restart airport-display.service"
EOL

chmod +x /home/pitstyle/start-display.sh
chmod +x /home/pitstyle/exit-kiosk.sh

# Setup autostart
mkdir -p /home/pitstyle/.config/lxsession/LXDE-pi
tee /home/pitstyle/.config/lxsession/LXDE-pi/autostart > /dev/null << 'EOL'
@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
@xscreensaver -no-splash
@/home/pitstyle/start-display.sh
EOL

echo "Deployment complete!"
EOF

# Verify deployment
echo -e "${YELLOW}🔍 Verifying deployment...${NC}"
sleep 5

SERVICE_STATUS=$(ssh -i "$SSH_KEY_PATH" $PI_USER@$PI_IP "sudo systemctl is-active airport-display.service")
if [ "$SERVICE_STATUS" = "active" ]; then
    echo -e "${GREEN}✅ Service is running${NC}"
else
    echo -e "${RED}❌ Service is not running. Status: $SERVICE_STATUS${NC}"
    echo "Check logs with: ssh -i $SSH_KEY_PATH $PI_USER@$PI_IP 'sudo journalctl -u airport-display.service -f'"
fi

# Final status
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "----------------------------------------"
echo "Pi IP: $PI_IP"
echo "Display ID: $DISPLAY_ID"
echo "Scale: $DISPLAY_SCALE"
echo "Service Status: $SERVICE_STATUS"
echo ""
echo "Next steps:"
echo "1. Reboot Pi: ssh -i $SSH_KEY_PATH $PI_USER@$PI_IP 'sudo reboot'"
echo "2. Check service: ssh -i $SSH_KEY_PATH $PI_USER@$PI_IP 'sudo systemctl status airport-display.service'"
echo "3. View logs: ssh -i $SSH_KEY_PATH $PI_USER@$PI_IP 'sudo journalctl -u airport-display.service -f'"
echo "4. Access display: http://$PI_IP:3000"
echo ""
echo -e "${YELLOW}🔄 To change display configuration:${NC}"
echo "ssh -i $SSH_KEY_PATH $PI_USER@$PI_IP 'cd $APP_PATH && cp .env.display[1-3] .env && sudo systemctl restart airport-display.service'"