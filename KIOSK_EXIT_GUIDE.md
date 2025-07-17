# 🚪 Kiosk Mode Exit Guide
## Quick Reference for Airport Transcript Display

### 🎯 Quick Exit Methods

#### **Method 1: Keyboard Shortcuts (Fastest)**
- **Alt + F4**: Close browser instantly
- **F11**: Toggle fullscreen mode
- **Ctrl + Alt + T**: Open terminal over kiosk

#### **Method 2: Terminal Commands (On Pi)**
```bash
# Exit kiosk mode
./exit-kiosk.sh

# Or kill browser directly
pkill chromium-browser

# Stop the service
sudo systemctl stop airport-display.service
```

#### **Method 3: Remote Control (From your computer)**
```bash
# Exit kiosk remotely
./pi-management.sh exit-kiosk 192.168.1.100

# Or SSH command
ssh pi@192.168.1.100 "pkill chromium-browser"
```

---

## 🔄 Restart Kiosk Mode

#### **Method 1: Remote Control (Recommended)**
```bash
# Start kiosk remotely
./pi-management.sh start-kiosk 192.168.1.100

# Or restart service
./pi-management.sh restart 192.168.1.100
```

#### **Method 2: On Pi Terminal**
```bash
# Start kiosk mode
./start-display.sh

# Or restart service
sudo systemctl restart airport-display.service
```

#### **Method 3: Reboot Pi**
```bash
sudo reboot
```

---

## 🆘 Emergency Console Access

If kiosk mode is stuck or unresponsive:

1. **Switch to console**: Press **Ctrl + Alt + F1**
2. **Login as pi user**
3. **Kill all processes**: `pkill chromium-browser`
4. **Switch back to desktop**: Press **Ctrl + Alt + F7**

---

## 📋 Common Scenarios

### Scenario 1: Need to Access Pi Desktop
- **Quick**: Press **Alt + F4**
- **Terminal**: Run `./exit-kiosk.sh`
- **Remote**: Run `./pi-management.sh exit-kiosk [PI_IP]`

### Scenario 2: Kiosk Mode Frozen
- **Force quit**: Press **Ctrl + Alt + F1** → Login → `pkill chromium-browser`
- **Remote**: `ssh pi@[PI_IP] "pkill chromium-browser"`

### Scenario 3: Wrong Display Content
- **Exit kiosk**: Press **Alt + F4**
- **Change config**: `cp .env.display2 .env`
- **Restart**: `sudo systemctl restart airport-display.service`

### Scenario 4: Maintenance Mode
- **Exit kiosk**: Press **Alt + F4**
- **Stop auto-restart**: `sudo systemctl stop airport-display.service`
- **Do maintenance work**
- **Restart when done**: `sudo systemctl start airport-display.service`

---

## 🎮 Management Commands

```bash
# Exit kiosk mode
./pi-management.sh exit-kiosk 192.168.1.100

# Start kiosk mode
./pi-management.sh start-kiosk 192.168.1.100

# Check status
./pi-management.sh status 192.168.1.100

# Monitor all displays
./pi-management.sh monitor

# SSH into Pi
./pi-management.sh ssh 192.168.1.100
```

---

## 🔧 Files Created on Pi

- **`/home/pi/start-display.sh`** - Starts kiosk mode
- **`/home/pi/exit-kiosk.sh`** - Exits kiosk mode
- **`/etc/systemd/system/airport-display.service`** - Auto-start service
- **`/home/pi/.config/lxsession/LXDE-pi/autostart`** - Desktop autostart

---

## 💡 Pro Tips

1. **Always have SSH access** as backup exit method
2. **Alt + F4 is the fastest** local exit method
3. **Use management script** for remote control
4. **F11 toggles fullscreen** if you need quick access to desktop
5. **Ctrl + Alt + T opens terminal** even in kiosk mode
6. **Service restart** automatically restarts kiosk mode

---

*Keep this guide handy for quick reference during Pi maintenance and troubleshooting.*