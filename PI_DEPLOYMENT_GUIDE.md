# Raspberry Pi Deployment Guide
## Airport Transcript Display System

### 🔧 Pi Hardware Requirements
- **Raspberry Pi 4** or **Pi 5** (recommended)
- **32GB+ microSD card** (Class 10 or better)
- **HDMI cable** for display connection
- **Network connection** (Ethernet or WiFi)
- **HD Display** (1920x1080 recommended)

---

## 📡 SSH Setup & Initial Configuration

### 1. Enable SSH on Fresh Pi OS
```bash
# On Pi terminal or via SSH after first boot
sudo systemctl enable ssh
sudo systemctl start ssh

# Set a secure password
sudo passwd pi
```

### 2. Find Pi IP Address
```bash
# On Pi
hostname -I

# Or scan network from your computer
nmap -sn 192.168.1.0/24
```

### 3. SSH Connection from Your Computer
```bash
# Replace IP with your Pi's IP
ssh pi@192.168.1.100

# Or use hostname if available
ssh pi@raspberrypi.local
```

---

## 🖥️ Display Configuration for HD Vertical

### 1. Edit Boot Config
```bash
sudo nano /boot/firmware/config.txt
```

### 2. Add Display Settings
```bash
# HD Display Configuration
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=16
hdmi_drive=2

# For vertical orientation (rotate 90 degrees)
display_rotate=1

# GPU Memory for better performance
gpu_mem=128

# Disable overscan for full screen
disable_overscan=1
```

### 3. Restart Pi
```bash
sudo reboot
```

---

## 🚀 App Deployment Process

### 1. Install Node.js on Pi
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node --version
npm --version
```

### 2. Transfer App Files
```bash
# From your computer, copy the built app
scp -r /path/to/airport-transcript-display pi@192.168.1.100:/home/pi/

# Or clone from GitHub
ssh pi@192.168.1.100
cd /home/pi
git clone https://github.com/pitstyle/AI_authority_airport_display.git
cd AI_authority_airport_display
git checkout impact-font-multi-display
```

### 3. Install Dependencies
```bash
# On Pi
cd /home/pi/airport-transcript-display
npm install
```

### 4. Configure Display Environment
```bash
# For Display 1 (standard size)
cp .env.display1 .env

# For Display 2 (double size)
cp .env.display2 .env

# For Display 3 (standard size)
cp .env.display3 .env
```

### 5. Build Production App
```bash
npm run build
```

---

## 🔄 Auto-Start Service Setup

### 1. Create Service File
```bash
sudo nano /etc/systemd/system/airport-display.service
```

### 2. Service Configuration
```ini
[Unit]
Description=Airport Transcript Display
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/airport-transcript-display
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

### 3. Enable Service
```bash
sudo systemctl enable airport-display.service
sudo systemctl start airport-display.service
sudo systemctl status airport-display.service
```

---

## 🌐 Browser Auto-Launch

### 1. Install Chromium
```bash
sudo apt install chromium-browser unclutter -y
```

### 2. Create Auto-Start Script
```bash
nano /home/pi/start-display.sh
```

```bash
#!/bin/bash
# Wait for network
sleep 30

# Start the app
cd /home/pi/airport-transcript-display
npm start &

# Wait for app to start
sleep 15

# Hide cursor and launch browser in kiosk mode
unclutter -idle 0 &
chromium-browser --kiosk --no-sandbox --disable-infobars --disable-restore-session-state --disable-web-security http://localhost:3000
```

### 3. Create Exit Kiosk Script
```bash
nano /home/pi/exit-kiosk.sh
```

```bash
#!/bin/bash
# Simple script to exit kiosk mode
pkill chromium-browser
echo "Kiosk mode exited. Desktop should be visible now."
echo "To restart kiosk mode, run: /home/pi/start-display.sh"
```

```bash
chmod +x /home/pi/exit-kiosk.sh
```

### 4. Make Scripts Executable
```bash
chmod +x /home/pi/start-display.sh
chmod +x /home/pi/exit-kiosk.sh
```

### 5. Add to Autostart
```bash
mkdir -p /home/pi/.config/lxsession/LXDE-pi
nano /home/pi/.config/lxsession/LXDE-pi/autostart
```

Add:
```bash
@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
@xscreensaver -no-splash
@/home/pi/start-display.sh
```

---

## 🚪 Exiting Kiosk Mode

### Keyboard Shortcuts (On Pi directly)
- **Alt + F4**: Close browser and exit kiosk mode
- **F11**: Toggle fullscreen mode
- **Ctrl + Alt + T**: Open terminal (works even in kiosk mode)
- **Ctrl + Alt + F1**: Switch to console terminal
- **Ctrl + Alt + F7**: Switch back to desktop

### Simple Exit Methods
```bash
# Method 1: Run exit script
./exit-kiosk.sh

# Method 2: Kill browser process
pkill chromium-browser

# Method 3: Stop the service
sudo systemctl stop airport-display.service

# Method 4: Use keyboard shortcut
# Press Alt+F4 while kiosk is running
```

### Remote Exit (SSH)
```bash
# From your computer
ssh pi@192.168.1.100 "pkill chromium-browser"

# Or stop the service
ssh pi@192.168.1.100 "sudo systemctl stop airport-display.service"
```

### Restart Kiosk Mode
```bash
# Method 1: Run start script
./start-display.sh

# Method 2: Restart service
sudo systemctl restart airport-display.service

# Method 3: Reboot Pi
sudo reboot
```

---

## 🔍 Monitoring & Control

### 1. Check Service Status
```bash
sudo systemctl status airport-display.service
sudo journalctl -u airport-display.service -f
```

### 2. Restart Service
```bash
sudo systemctl restart airport-display.service
```

### 3. View App Logs
```bash
cd /home/pi/airport-transcript-display
npm start 2>&1 | tee app.log
```

### 4. Remote Browser Control
```bash
# Kill browser
pkill chromium-browser

# Restart browser
DISPLAY=:0 chromium-browser --kiosk --no-sandbox http://localhost:3000 &
```

---

## 📊 Performance Optimization

### 1. Disable Unnecessary Services
```bash
sudo systemctl disable bluetooth.service
sudo systemctl disable cups.service
sudo systemctl disable avahi-daemon.service
```

### 2. Increase GPU Memory
```bash
sudo raspi-config
# Advanced Options → Memory Split → 128
```

### 3. Enable Hardware Acceleration
```bash
# Add to /boot/firmware/config.txt
dtoverlay=vc4-kms-v3d
```

---

## 🛠️ Common Scenarios & Solutions

### Scenario 1: Display Not Showing
```bash
# Check if app is running
ps aux | grep node

# Check browser
ps aux | grep chromium

# Restart display
sudo systemctl restart airport-display.service
```

### Scenario 2: Wrong Display Content
```bash
# Check environment variables
cat .env

# Change display ID
nano .env
# Update REACT_APP_DISPLAY_ID=2
sudo systemctl restart airport-display.service
```

### Scenario 3: Network Connection Issues
```bash
# Check network
ping google.com

# Restart networking
sudo systemctl restart networking
sudo systemctl restart dhcpcd
```

### Scenario 4: Database Connection Problems
```bash
# Check Supabase connection
curl -I https://doyxqmbiafltsovdoucy.supabase.co

# Update environment
nano .env
# Check REACT_APP_SUPABASE_URL and REACT_APP_SUPABASE_ANON_KEY
```

---

## 🔄 Update Deployment

### 1. Update App Code
```bash
cd /home/pi/airport-transcript-display
git pull origin impact-font-multi-display
npm install
npm run build
sudo systemctl restart airport-display.service
```

### 2. Change Display Configuration
```bash
# Switch to different display
cp .env.display2 .env
sudo systemctl restart airport-display.service
```

---

## 🚨 Emergency Commands

### Full System Restart
```bash
sudo reboot
```

### Kill All App Processes
```bash
pkill node
pkill chromium-browser
```

### Reset to Factory Display
```bash
cd /home/pi/airport-transcript-display
cp .env.display1 .env
sudo systemctl restart airport-display.service
```

---

## 📋 Deployment Checklist

### Before Deployment:
- [ ] Pi OS installed and updated
- [ ] SSH enabled and tested
- [ ] Display connected and configured
- [ ] Network connection verified
- [ ] Node.js installed

### During Deployment:
- [ ] App code transferred
- [ ] Dependencies installed
- [ ] Environment configured (.env file)
- [ ] Production build created
- [ ] Service installed and enabled
- [ ] Auto-start configured

### After Deployment:
- [ ] Service status verified
- [ ] Browser launches automatically
- [ ] Display shows correct content
- [ ] Database connection working
- [ ] Multi-display distribution working

---

*This guide ensures reliable deployment of the airport transcript display system across multiple Raspberry Pi devices.*