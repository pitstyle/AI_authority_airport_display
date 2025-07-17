# Complete Pi Deployment Guide - Airport Display

## CRITICAL DEPLOYMENT LEARNINGS (Jan 16, 2025)

### ✅ WORKING CONFIGURATION - Pi 3 (10.20.23.212)

**Current Status:**
- SSH: ✅ Working with key authentication
- App Service: ✅ Running on port 3000
- Display: ✅ 90° rotated for vertical TV
- Fonts: ✅ Impact font installed and working
- Kiosk: ✅ Auto-starts on boot
- Mouse: ⚠️ Still visible (needs further work)

## STEP-BY-STEP DEPLOYMENT PROCESS

### 1. Network Configuration
**Pi IP Addresses:**
- Pi 1 (Display 1): 10.20.23.213 - Standard
- Pi 2 (Display 2): 10.20.23.211 - Large
- Pi 3 (Display 3): 10.20.23.212 - Standard ✅ WORKING

**Network Details:**
- Username: `pitstyle` (NOT `pi`)
- Password: `pi`
- SSH Key: `~/.ssh/id_rsa_airport_display`
- Network: `10.20.23.0/24`

### 2. SSH Setup Process
```bash
# Enable SSH on Pi manually first (via Pi interface)
# Then from Mac:
./setup-pi-ssh.sh setup-keys
./setup-pi-ssh.sh setup-pi 3  # (or 1, 2)
```

### 3. System Optimization
```bash
./pi-system-optimization.sh optimize-pi 3
```

**Key optimizations applied:**
- GPU memory split: 128MB
- Swap: 512MB
- Boot optimizations
- Display rotation: `display_rotate=1`
- Unnecessary services disabled

### 4. Font Installation (CRITICAL)
```bash
# Install Microsoft Core Fonts (includes Impact)
sudo apt install -y ttf-mscorefonts-installer
fc-cache -fv  # Refresh font cache
```

### 5. App Deployment
```bash
# Deploy app files
./deploy-to-pi.sh 10.20.23.212 3 1.0

# Create systemd service
sudo tee /etc/systemd/system/airport-display.service << EOF
[Unit]
Description=Airport Transcript Display
After=network.target

[Service]
Type=simple
User=pitstyle
WorkingDirectory=/home/pitstyle/airport-transcript-display
ExecStart=/usr/bin/serve -s build -l 3000
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable airport-display.service
sudo systemctl start airport-display.service
```

### 6. Kiosk Mode Setup
```bash
# Create start-display script
tee /home/pitstyle/start-display.sh << EOF
#!/bin/bash
sleep 30
export DISPLAY=:0
unclutter -display :0 -idle 0.5 -root &
chromium-browser --kiosk --no-sandbox --disable-infobars --disable-restore-session-state --disable-web-security --allow-running-insecure-content --app=http://localhost:3000
EOF

chmod +x /home/pitstyle/start-display.sh

# Create autostart
mkdir -p /home/pitstyle/.config/lxsession/LXDE-pi
tee /home/pitstyle/.config/lxsession/LXDE-pi/autostart << EOF
@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
@xscreensaver -no-splash
@/home/pitstyle/start-display.sh
EOF
```

### 7. Display Rotation
```bash
# Add to /boot/firmware/config.txt
echo "display_rotate=1" | sudo tee -a /boot/firmware/config.txt
sudo reboot
```

## DEPLOYMENT CHECKLIST FOR NEXT 2 PIS

### Pre-Deployment (Manual on Pi):
- [ ] Enable SSH via Pi interface
- [ ] Connect to network
- [ ] Note IP address

### Automated Deployment:
- [ ] `./setup-pi-ssh.sh setup-pi [1|2]`
- [ ] `./pi-system-optimization.sh optimize-pi [1|2]`
- [ ] `sudo apt install -y ttf-mscorefonts-installer`
- [ ] `./deploy-to-pi.sh [IP] [DISPLAY_ID] 1.0`
- [ ] Create systemd service
- [ ] Setup kiosk mode scripts
- [ ] Add display rotation to config.txt
- [ ] Reboot Pi

### Post-Deployment Testing:
- [ ] SSH connectivity: `ssh -i ~/.ssh/id_rsa_airport_display pitstyle@[IP]`
- [ ] Service status: `sudo systemctl status airport-display.service`
- [ ] Web access: `curl http://[IP]:3000`
- [ ] Display rotation: Visual check
- [ ] Kiosk auto-start: Reboot test
- [ ] Impact font: Visual verification

## WORKING COMMANDS FOR MANAGEMENT

### Remote Control:
```bash
# Exit kiosk mode
ssh -i ~/.ssh/id_rsa_airport_display pitstyle@[IP] '/home/pitstyle/exit-kiosk.sh'

# Start kiosk mode
ssh -i ~/.ssh/id_rsa_airport_display pitstyle@[IP] 'DISPLAY=:0 /home/pitstyle/start-display.sh &'

# Restart service
ssh -i ~/.ssh/id_rsa_airport_display pitstyle@[IP] 'sudo systemctl restart airport-display.service'

# Reboot Pi
ssh -i ~/.ssh/id_rsa_airport_display pitstyle@[IP] 'sudo reboot'
```

### Local Scripts:
```bash
./pi-management.sh status [IP]
./pi-management.sh monitor-pi [1|2|3]
./pi-system-optimization.sh performance-test [1|2|3]
```

## KNOWN ISSUES & SOLUTIONS

### Issue 1: Mouse Cursor Visible
**Problem:** Mouse cursor still visible in kiosk mode
**Attempted Solutions:**
- `unclutter -idle 1`
- `unclutter -display :0 -idle 0.5 -root`
**Status:** Still needs work

**TODO for next deployment:**
- Try `sudo apt install matchbox`
- Try `--kiosk --app=` instead of just `--kiosk`
- Try CSS cursor hiding in app
- Try `xinput` to disable mouse

### Issue 2: Deployment Script Failures
**Problem:** Original deploy script had bash compatibility issues
**Solution:** Fixed all scripts for bash 3.2 compatibility

### Issue 3: Impact Font Missing
**Problem:** Font not installed by default
**Solution:** Install `ttf-mscorefonts-installer` package

## DISPLAY CONFIGURATION

### Display IDs:
- Display 1: Standard size (1x scale)
- Display 2: Standard size (1x scale)
- Display 3: Standard size (1x scale)

### Environment Files:
- `.env.display1` - `REACT_APP_DISPLAY_ID=1`
- `.env.display2` - `REACT_APP_DISPLAY_ID=2`
- `.env.display3` - `REACT_APP_DISPLAY_ID=3`

### Time-based Distribution:
- Display 1: Messages where `timestamp % 3 === 0`
- Display 2: Messages where `timestamp % 3 === 1`
- Display 3: Messages where `timestamp % 3 === 2`

## KEYBOARD SHORTCUTS

### On Pi (with keyboard/mouse):
- **Alt + F4** - Exit kiosk mode
- **Ctrl + Alt + T** - Open terminal
- **F11** - Toggle fullscreen

### Via SSH:
- Use scripts in `/home/pitstyle/` directory

## NEXT STEPS FOR TOMORROW

1. **Enable SSH on Pi 1 (10.20.23.213) and Pi 2 (10.20.23.211)**
2. **Run deployment checklist for each Pi**
3. **Test mouse cursor hiding solutions**
4. **Verify all 3 displays working simultaneously**
5. **Document any new issues or solutions**

## FILES UPDATED FOR PI DEPLOYMENT

### Fixed Scripts:
- `setup-pi-ssh.sh` - SSH key setup and Pi configuration
- `pi-system-optimization.sh` - Performance optimization
- `pi-management.sh` - Remote management
- `deploy-to-pi.sh` - App deployment

### Configuration Files:
- All scripts now use correct IP addresses (10.20.23.x)
- All scripts now use correct username (pitstyle)
- All scripts now use SSH keys for authentication
- All scripts compatible with bash 3.2 (macOS)

## SUCCESS CRITERIA

✅ Pi 3 is fully operational:
- Vertical display rotation working
- Impact font rendering correctly
- Auto-start kiosk mode working
- SSH remote management working
- Service auto-restart on boot working

Ready for Pi 1 and Pi 2 deployment tomorrow! 🚀