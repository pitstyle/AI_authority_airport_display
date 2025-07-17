# 🔐 Pi SSH Setup Guide
## Complete SSH Configuration for Airport Transcript Display

### 🚀 Quick Start

1. **Generate SSH Keys**
   ```bash
   ./setup-pi-ssh.sh setup-keys
   ```

2. **Setup All Pis**
   ```bash
   ./setup-pi-ssh.sh setup-all
   ```

3. **Test Connections**
   ```bash
   ./setup-pi-ssh.sh test-all
   ```

---

## 📋 Step-by-Step Setup

### Step 1: Find Your Pis
```bash
# Scan network for Raspberry Pis
./setup-pi-ssh.sh scan-network

# Or use nmap directly
nmap -p 22 --open 192.168.1.0/24
```

### Step 2: Update IP Addresses
```bash
# Interactive IP update
./setup-pi-ssh.sh update-ips

# Or manually edit setup-pi-ssh.sh
# Update the PI_CONFIG array with your actual IPs
```

### Step 3: Generate SSH Keys
```bash
./setup-pi-ssh.sh setup-keys
```

This creates:
- `~/.ssh/id_rsa_airport_display` (private key)
- `~/.ssh/id_rsa_airport_display.pub` (public key)
- SSH config entries for easy connection

### Step 4: Setup Individual Pi
```bash
# Setup Pi 1
./setup-pi-ssh.sh setup-pi 1

# Setup Pi 2
./setup-pi-ssh.sh setup-pi 2

# Setup Pi 3
./setup-pi-ssh.sh setup-pi 3
```

### Step 5: Test Connections
```bash
# Test specific Pi
./setup-pi-ssh.sh test-connection 1

# Test all Pis
./setup-pi-ssh.sh test-all
```

---

## 🔧 What the Setup Script Does

### SSH Key Configuration
- Generates RSA 4096-bit keys
- Adds keys to SSH agent
- Copies public key to each Pi
- Creates SSH config entries

### Pi System Configuration
- Updates system packages
- Enables SSH service
- Sets unique hostname (`airport-display-1`, etc.)
- Installs required packages:
  - Node.js dependencies
  - Chromium browser
  - System utilities
- Configures basic firewall (UFW)
- Sets up automatic security updates

### Network Configuration
- Tests Pi connectivity
- Configures SSH access
- Sets up firewall rules
- Configures timezone

---

## 🖥️ SSH Config Entries

After setup, you can connect using:
```bash
ssh airport-display-1    # Pi 1
ssh airport-display-2    # Pi 2
ssh airport-display-3    # Pi 3
```

The script creates these entries in `~/.ssh/config`:
```
Host airport-display-1
    HostName 192.168.1.101
    User pi
    IdentityFile ~/.ssh/id_rsa_airport_display
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

---

## 🛠️ Manual Setup (If Script Fails)

### 1. Connect to Pi
```bash
# Default credentials
ssh pi@192.168.1.101
# Password: raspberry
```

### 2. Enable SSH
```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

### 3. Copy SSH Key
```bash
# From your computer
ssh-copy-id -i ~/.ssh/id_rsa_airport_display.pub pi@192.168.1.101
```

### 4. Configure Pi
```bash
# On Pi
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git chromium-browser unclutter
sudo hostnamectl set-hostname airport-display-1
```

---

## 🔍 Troubleshooting

### Pi Not Found
```bash
# Check Pi is powered on and connected
ping 192.168.1.101

# Scan network
nmap -sn 192.168.1.0/24
```

### SSH Connection Refused
```bash
# Check SSH service on Pi
ssh pi@192.168.1.101 "sudo systemctl status ssh"

# Restart SSH service
ssh pi@192.168.1.101 "sudo systemctl restart ssh"
```

### Authentication Failed
```bash
# Check SSH key exists
ls -la ~/.ssh/id_rsa_airport_display*

# Try password authentication
ssh -o PreferredAuthentications=password pi@192.168.1.101
```

### Wrong IP Address
```bash
# Update IP addresses
./setup-pi-ssh.sh update-ips

# Or edit script directly
nano setup-pi-ssh.sh
# Update PI_CONFIG array
```

---

## 🔄 Common Operations

### Check Pi Status
```bash
ssh airport-display-1 "uptime && df -h"
```

### Restart Pi
```bash
ssh airport-display-1 "sudo reboot"
```

### Update Pi
```bash
ssh airport-display-1 "sudo apt update && sudo apt upgrade -y"
```

### Check Network
```bash
ssh airport-display-1 "hostname -I"
```

---

## 📊 Connection Test Results

After running `./setup-pi-ssh.sh test-all`, you should see:
```
✅ Pi 1 connection successful
✅ Pi 2 connection successful  
✅ Pi 3 connection successful

📊 Connection Test Summary
  Successful: 3/3
✅ All Pis are accessible
```

---

## 🔐 Security Notes

### SSH Key Security
- Private key is stored in `~/.ssh/id_rsa_airport_display`
- Only accessible by your user account
- Key is added to SSH agent for convenience

### Pi Security
- SSH password authentication disabled after key setup
- Basic firewall enabled (UFW)
- Automatic security updates configured
- Non-standard hostname set for identification

### Network Security
- Keys are specific to this project
- SSH config prevents host key checking warnings
- Firewall allows only SSH (22) and app (3000) ports

---

## 📋 Next Steps

After SSH setup is complete:

1. **Deploy the app:**
   ```bash
   ./deploy-to-pi.sh 192.168.1.101 1 1.0
   ```

2. **Use management script:**
   ```bash
   ./pi-management.sh monitor
   ```

3. **Test display:**
   ```bash
   ./pi-management.sh status 192.168.1.101
   ```

---

*SSH setup is the foundation for all Pi management operations. Ensure this is working before proceeding with app deployment.*