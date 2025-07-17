# CODE CHANGES SUMMARY - January 17, 2025

## React Application Changes

### File: `src/components/TranscriptFlapDisplay.jsx`

**Purpose:** Added complete cursor hiding via CSS

**Lines Modified:** 520-535

**Before:**
```css
* {
  box-sizing: border-box;
  padding: 0px;
  margin: 0px;
}

body, html {
  background-color: #CCCCCC;
  width: 100vw;
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
}
```

**After:**
```css
* {
  box-sizing: border-box;
  padding: 0px;
  margin: 0px;
  cursor: none !important;
}

body, html {
  background-color: #CCCCCC;
  width: 100vw;
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  cursor: none !important;
}
```

**Impact:** Completely hides mouse cursor in all browsers

## Build Process Changes

### Separate Builds for Each Display

**Purpose:** Ensure each Pi shows different content via time-based distribution

**Build Commands Used:**
```bash
# For Pi 1 (Display 1)
REACT_APP_DISPLAY_ID=1 npm run build
# Deploy to: pitstyle@10.20.23.213

# For Pi 2 (Display 2)  
REACT_APP_DISPLAY_ID=2 npm run build
# Deploy to: pitstyle@10.20.23.211

# For Pi 3 (Display 3)
REACT_APP_DISPLAY_ID=3 npm run build  
# Deploy to: pitstyle@10.20.23.212
```

**Result:** Each Pi now has unique display ID embedded at build time

## Systemd Service Files Created

### File: `/etc/systemd/system/airport-kiosk.service` (All 3 Pis)

**Purpose:** Reliable browser autostart with cursor positioning

**Complete Service Configuration:**

**Pi 1 & Pi 2:**
```ini
[Unit]
Description=Airport Display Kiosk Browser
After=graphical.target airport-display.service
Wants=airport-display.service

[Service]
Environment=XAUTHORITY=/home/pitstyle/.Xauthority
Environment=DISPLAY=:0
User=pitstyle
Type=simple
ExecStartPre=/bin/bash -c "until curl -sf http://localhost:3000 >/dev/null; do sleep 1; done"
ExecStartPre=/usr/bin/xdotool mousemove 1079 0
ExecStartPre=/usr/bin/xsetroot -cursor_name none
ExecStart=/usr/bin/chromium-browser --noerrdialogs --kiosk --incognito --autoplay-policy=no-user-gesture-required --disable-background-timer-throttling --disable-features=TranslateUI --use-fake-ui-for-media-stream http://localhost:3000
Restart=on-abort
RestartSec=5

[Install]
WantedBy=graphical.target
```

**Pi 3:**
```ini
[Unit]
Description=Airport Display Kiosk Browser
After=graphical.target airport-display.service
Wants=airport-display.service

[Service]
Environment=XAUTHORITY=/home/pitstyle/.Xauthority
Environment=DISPLAY=:0
User=pitstyle
Type=simple
ExecStartPre=/bin/bash -c "until curl -sf http://localhost:3000 >/dev/null; do sleep 1; done"
ExecStartPre=/usr/bin/xdotool mousemove 540 960
ExecStartPre=/usr/bin/xsetroot -cursor_name none
ExecStart=/usr/bin/chromium-browser --noerrdialogs --kiosk --incognito --autoplay-policy=no-user-gesture-required --disable-background-timer-throttling --disable-features=TranslateUI --use-fake-ui-for-media-stream http://localhost:3000
Restart=on-abort
RestartSec=5

[Install]
WantedBy=graphical.target
```

### File: `/etc/systemd/system/airport-display.service` (Updated on Pi 3)

**Purpose:** Fix missing environment variables for display ID

**Updated Configuration:**
```ini
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
Environment=REACT_APP_DISPLAY_ID=3
Environment=REACT_APP_DISPLAY_SCALE=1.0

[Install]
WantedBy=multi-user.target
```

## Dependencies Installed

### Packages Added to All Pis:
```bash
sudo apt install -y unclutter xdotool
sudo npm install -g serve
```

**Purpose:**
- `unclutter`: Cursor hiding utility
- `xdotool`: Cursor positioning tool  
- `serve`: Static file server for React build

## Configuration Files Updated

### File: `/boot/firmware/config.txt` (All Pis)

**Added:**
```
display_rotate=1
```

**Purpose:** 90° display rotation for vertical TV orientation

### Files Cleaned Up:
- Removed broken cron jobs from all Pis
- Cleaned `/etc/rc.local` on all Pis
- Removed old autostart methods that weren't working

## Cursor Position Coordinates Captured

### Manual Positioning Results:
- **Pi 1:** x:1079 y:0 (top-right edge)
- **Pi 2:** x:1079 y:0 (top-right edge)
- **Pi 3:** x:540 y:960 (center position chosen by user)

### Commands Used for Capture:
```bash
export DISPLAY=:0 && xdotool getmouselocation
```

## Network Configuration

### SSH Key Setup:
- **Key File:** `~/.ssh/id_rsa_airport_display`
- **All Pis:** Key authentication working
- **Username:** `pitstyle`
- **Password:** `pi` (for emergency access)

### IP Addresses Confirmed:
- **Pi 1:** 10.20.23.213 - Display ID 1
- **Pi 2:** 10.20.23.211 - Display ID 2
- **Pi 3:** 10.20.23.212 - Display ID 3

## Deployment Process Final

### Working Deployment Commands:
```bash
# Build for specific display
REACT_APP_DISPLAY_ID=[1|2|3] npm run build

# Deploy to Pi
scp -i ~/.ssh/id_rsa_airport_display -r build/* pitstyle@[IP]:/home/pitstyle/airport-transcript-display/build/

# Restart services
ssh -i ~/.ssh/id_rsa_airport_display pitstyle@[IP] 'sudo systemctl restart airport-display.service'
```

## Testing & Validation

### Successful Tests Performed:
1. **Multiple reboot tests** - All autostart working
2. **Cursor positioning tests** - All positions captured and applied
3. **Service dependency tests** - Proper startup order confirmed
4. **Time-based distribution test** - Different content on each display
5. **Remote management tests** - SSH control working

## Key Technical Insights

### Critical Success Factors:
1. **Systemd Target Selection:** `graphical.target` not `multi-user.target`
2. **Service Dependencies:** Proper `After=` and `Wants=` configuration
3. **Environment Setup:** `XAUTHORITY` and `DISPLAY=:0` essential
4. **Wait Conditions:** `curl` check ensures web service ready
5. **Build-time Configuration:** React env vars embedded during build

### Architecture Pattern:
```
Boot → graphical.target → airport-display.service → airport-kiosk.service
                                ↓                         ↓
                        Web service (port 3000)    Browser kiosk mode
```

---

## Summary

**Total Files Modified:** 4 (1 React component + 3 systemd services per Pi)  
**Total Services Created:** 6 (2 per Pi × 3 Pis)  
**Total Builds Created:** 3 (one per display ID)  
**Total Deployments:** 3 successful Pi deployments  

**Result:** Exhibition-ready airport display system with reliable autostart, hidden cursors, and unique content per display.