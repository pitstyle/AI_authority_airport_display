#!/bin/bash

# Airport Transcript Display - Pi System Optimization Script
# Optimizes Pi performance for display applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SSH_KEY_PATH="$HOME/.ssh/id_rsa_airport_display"
DEFAULT_PI_USER="pitstyle"

# Pi configurations - Using arrays compatible with bash 3.2
PI_IPS=(
    "10.20.23.213"  # Pi 1 - Display 1 - Standard
    "10.20.23.211"  # Pi 2 - Display 2 - Large  
    "10.20.23.212"  # Pi 3 - Display 3 - Standard
)

get_pi_ip() {
    local pi_number=$1
    if [ "$pi_number" -ge 1 ] && [ "$pi_number" -le 3 ]; then
        echo "${PI_IPS[$((pi_number-1))]}"
    fi
}

show_help() {
    echo -e "${BLUE}Pi System Optimization for Airport Display${NC}"
    echo ""
    echo "Usage: $0 [command] [pi_number]"
    echo ""
    echo "Commands:"
    echo "  optimize-pi [pi_number]       - Optimize specific Pi"
    echo "  optimize-all                  - Optimize all Pis"
    echo "  display-config [pi_number]    - Configure display settings"
    echo "  performance-test [pi_number]  - Test Pi performance"
    echo "  monitor [pi_number]           - Monitor Pi resources"
    echo "  cleanup [pi_number]           - Clean up Pi system"
    echo ""
    echo "Examples:"
    echo "  $0 optimize-pi 1              - Optimize Pi 1"
    echo "  $0 display-config 2           - Configure display for Pi 2"
    echo "  $0 performance-test 1         - Test Pi 1 performance"
}

check_ssh_connection() {
    local pi_number=$1
    local pi_ip=$(get_pi_ip $pi_number)
    
    if [ -z "$pi_ip" ]; then
        echo -e "${RED}❌ Invalid Pi number: $pi_number${NC}"
        return 1
    fi
    
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo -e "${RED}❌ SSH key not found. Run setup-pi-ssh.sh first${NC}"
        return 1
    fi
    
    if ! ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=5 "$DEFAULT_PI_USER@$pi_ip" exit 2>/dev/null; then
        echo -e "${RED}❌ Cannot connect to Pi $pi_number ($pi_ip)${NC}"
        return 1
    fi
    
    return 0
}

optimize_pi_system() {
    local pi_number=$1
    local pi_ip=$(get_pi_ip $pi_number)
    
    echo -e "${BLUE}🚀 Optimizing Pi $pi_number ($pi_ip)...${NC}"
    
    if ! check_ssh_connection "$pi_number"; then
        return 1
    fi
    
    ssh -i "$SSH_KEY_PATH" "$DEFAULT_PI_USER@$pi_ip" << 'EOF'
set -e

echo "🔧 Starting Pi optimization..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install optimization tools
echo "🛠️ Installing optimization tools..."
sudo apt install -y htop iotop nethogs dphys-swapfile

# Configure GPU memory split
echo "🎮 Configuring GPU memory..."
sudo raspi-config nonint do_memory_split 128

# Optimize boot configuration
echo "⚙️ Optimizing boot configuration..."
sudo tee -a /boot/firmware/config.txt > /dev/null << 'EOL'

# Performance optimizations for display
gpu_mem=128
gpu_freq=500
over_voltage=2
arm_freq=1800
sdram_freq=500

# Display optimizations
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=16
hdmi_drive=2
display_rotate=1
disable_overscan=1

# Reduce boot time
boot_delay=0
disable_splash=1
EOL

# Optimize swap
echo "💾 Optimizing swap configuration..."
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=100/CONF_SWAPSIZE=512/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# Disable unnecessary services
echo "🔇 Disabling unnecessary services..."
sudo systemctl disable bluetooth.service
sudo systemctl disable cups.service
sudo systemctl disable cups-browsed.service
sudo systemctl disable avahi-daemon.service
sudo systemctl disable triggerhappy.service
sudo systemctl disable hciuart.service

# Configure system limits
echo "⚡ Configuring system limits..."
sudo tee -a /etc/security/limits.conf > /dev/null << 'EOL'
pi soft nofile 65536
pi hard nofile 65536
pi soft nproc 32768
pi hard nproc 32768
EOL

# Optimize filesystem
echo "💿 Optimizing filesystem..."
sudo tune2fs -o journal_data_writeback /dev/mmcblk0p2
sudo tune2fs -O ^has_journal /dev/mmcblk0p2
sudo e2fsck -f /dev/mmcblk0p2 || true
sudo tune2fs -o journal_data_ordered /dev/mmcblk0p2

# Configure network optimizations
echo "🌐 Optimizing network settings..."
sudo tee -a /etc/sysctl.conf > /dev/null << 'EOL'
# Network optimizations
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
EOL

# Set up log rotation
echo "📝 Configuring log rotation..."
sudo tee /etc/logrotate.d/airport-display > /dev/null << 'EOL'
/home/pitstyle/airport-transcript-display/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 pitstyle pitstyle
}
EOL

# Create performance monitoring script
echo "📊 Creating performance monitoring script..."
tee /home/pitstyle/performance-monitor.sh > /dev/null << 'EOL'
#!/bin/bash
echo "=== Pi Performance Monitor ==="
echo "Date: $(date)"
echo ""
echo "=== CPU Usage ==="
top -bn1 | grep "Cpu(s)" | head -1
echo ""
echo "=== Memory Usage ==="
free -h
echo ""
echo "=== Disk Usage ==="
df -h / | tail -1
echo ""
echo "=== Temperature ==="
vcgencmd measure_temp
echo ""
echo "=== GPU Memory ==="
vcgencmd get_mem arm && vcgencmd get_mem gpu
echo ""
echo "=== Network ==="
hostname -I
echo ""
echo "=== Processes ==="
ps aux | head -10
EOL

chmod +x /home/pitstyle/performance-monitor.sh

# Create system cleanup script
echo "🧹 Creating cleanup script..."
tee /home/pitstyle/cleanup-system.sh > /dev/null << 'EOL'
#!/bin/bash
echo "🧹 Cleaning up system..."

# Clean package cache
sudo apt autoremove -y
sudo apt autoclean

# Clean logs
sudo journalctl --vacuum-time=7d
sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;

# Clean browser cache
rm -rf /home/pitstyle/.cache/chromium/
rm -rf /home/pitstyle/.config/chromium/

# Clean temporary files
sudo find /tmp -type f -atime +7 -delete
sudo find /var/tmp -type f -atime +7 -delete

echo "✅ Cleanup complete!"
EOL

chmod +x /home/pitstyle/cleanup-system.sh

# Create display restart script
echo "🖥️ Creating display restart script..."
tee /home/pitstyle/restart-display.sh > /dev/null << 'EOL'
#!/bin/bash
echo "🔄 Restarting display system..."

# Stop services
sudo systemctl stop airport-display.service
pkill chromium-browser

# Clear cache
rm -rf /home/pitstyle/.cache/chromium/
rm -rf /home/pitstyle/.config/chromium/

# Restart X11
sudo systemctl restart lightdm

# Wait and restart service
sleep 5
sudo systemctl start airport-display.service

echo "✅ Display system restarted!"
EOL

chmod +x /home/pitstyle/restart-display.sh

echo "✅ Pi optimization complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Reboot the Pi: sudo reboot"
echo "  2. Test performance: /home/pitstyle/performance-monitor.sh"
echo "  3. Monitor temperature during operation"
echo ""
echo "🛠️ Available scripts:"
echo "  - /home/pitstyle/performance-monitor.sh - Check system performance"
echo "  - /home/pitstyle/cleanup-system.sh - Clean up system files"
echo "  - /home/pitstyle/restart-display.sh - Restart display system"
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Pi $pi_number optimization complete${NC}"
        echo "  📋 Reboot required for all changes to take effect"
        echo "  🔄 Run: ssh airport-display-$pi_number 'sudo reboot'"
    else
        echo -e "${RED}❌ Pi $pi_number optimization failed${NC}"
        return 1
    fi
}

configure_display() {
    local pi_number=$1
    local pi_ip=$(get_pi_ip $pi_number)
    
    echo -e "${BLUE}🖥️ Configuring display for Pi $pi_number ($pi_ip)...${NC}"
    
    if ! check_ssh_connection "$pi_number"; then
        return 1
    fi
    
    echo "Choose display configuration:"
    echo "1. HD Vertical (1080x1920) - Recommended"
    echo "2. HD Horizontal (1920x1080)"
    echo "3. 4K Vertical (2160x3840)"
    echo "4. Custom"
    
    read -p "Enter choice (1-4): " choice
    
    case $choice in
        1)
            mode=16
            rotate=1
            ;;
        2)
            mode=16
            rotate=0
            ;;
        3)
            mode=31
            rotate=1
            ;;
        4)
            echo "Enter custom HDMI mode (see /opt/vc/bin/tvservice -m CEA):"
            read -p "HDMI mode: " mode
            read -p "Rotation (0=normal, 1=90°, 2=180°, 3=270°): " rotate
            ;;
        *)
            echo "Invalid choice"
            return 1
            ;;
    esac
    
    ssh -i "$SSH_KEY_PATH" "$DEFAULT_PI_USER@$pi_ip" << EOF
# Backup current config
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup

# Update display configuration
sudo sed -i '/# Display optimizations/,/^$/d' /boot/firmware/config.txt
sudo tee -a /boot/firmware/config.txt > /dev/null << 'EOL'

# Display optimizations
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=$mode
hdmi_drive=2
display_rotate=$rotate
disable_overscan=1
EOL

echo "Display configuration updated!"
echo "Reboot required: sudo reboot"
EOF

    echo -e "${GREEN}✅ Display configuration updated${NC}"
    echo "  🔄 Reboot required for changes to take effect"
}

performance_test() {
    local pi_number=$1
    local pi_ip=$(get_pi_ip $pi_number)
    
    echo -e "${BLUE}🧪 Testing Pi $pi_number performance...${NC}"
    
    if ! check_ssh_connection "$pi_number"; then
        return 1
    fi
    
    ssh -i "$SSH_KEY_PATH" "$DEFAULT_PI_USER@$pi_ip" << 'EOF'
echo "=== Pi Performance Test ==="
echo "Date: $(date)"
echo ""

echo "=== System Info ==="
cat /etc/os-release | head -2
uname -a
echo ""

echo "=== CPU Info ==="
lscpu | grep "Model name\|Architecture\|CPU(s)\|Thread(s)\|CPU max MHz"
echo ""

echo "=== Memory Info ==="
free -h
echo ""

echo "=== Storage Info ==="
df -h /
echo ""

echo "=== Temperature ==="
vcgencmd measure_temp
echo ""

echo "=== GPU Memory ==="
vcgencmd get_mem arm
vcgencmd get_mem gpu
echo ""

echo "=== Network Speed ==="
ping -c 4 8.8.8.8 | tail -1
echo ""

echo "=== CPU Stress Test (10 seconds) ==="
timeout 10 yes > /dev/null &
PID=$!
sleep 2
top -bn1 | grep "Cpu(s)" | head -1
kill $PID 2>/dev/null
wait $PID 2>/dev/null
echo ""

echo "=== Browser Test ==="
if command -v chromium-browser &> /dev/null; then
    echo "✅ Chromium browser installed"
    chromium-browser --version
else
    echo "❌ Chromium browser not found"
fi
echo ""

echo "=== Service Status ==="
systemctl is-active airport-display.service || echo "Service not installed"
echo ""

echo "=== Performance Test Complete ==="
EOF

    echo -e "${GREEN}✅ Performance test complete${NC}"
}

monitor_pi() {
    local pi_number=$1
    local pi_ip=$(get_pi_ip $pi_number)
    
    echo -e "${BLUE}📊 Monitoring Pi $pi_number ($pi_ip)...${NC}"
    echo "Press Ctrl+C to stop monitoring"
    
    if ! check_ssh_connection "$pi_number"; then
        return 1
    fi
    
    ssh -i "$SSH_KEY_PATH" "$DEFAULT_PI_USER@$pi_ip" << 'EOF'
# Create monitoring script
tee /tmp/monitor.sh > /dev/null << 'EOL'
#!/bin/bash
while true; do
    clear
    echo "=== Real-time Pi Monitor ==="
    echo "Date: $(date)"
    echo ""
    
    echo "=== CPU & Memory ==="
    top -bn1 | head -5
    echo ""
    
    echo "=== Temperature ==="
    vcgencmd measure_temp
    echo ""
    
    echo "=== Disk Usage ==="
    df -h / | tail -1
    echo ""
    
    echo "=== Network ==="
    hostname -I
    echo ""
    
    echo "=== Top Processes ==="
    ps aux --sort=-%cpu | head -5
    echo ""
    
    echo "Press Ctrl+C to exit"
    sleep 5
done
EOL

chmod +x /tmp/monitor.sh
/tmp/monitor.sh
EOF
}

cleanup_pi() {
    local pi_number=$1
    local pi_ip=$(get_pi_ip $pi_number)
    
    echo -e "${BLUE}🧹 Cleaning up Pi $pi_number ($pi_ip)...${NC}"
    
    if ! check_ssh_connection "$pi_number"; then
        return 1
    fi
    
    ssh -i "$SSH_KEY_PATH" "$DEFAULT_PI_USER@$pi_ip" << 'EOF'
echo "🧹 Starting system cleanup..."

# Clean package cache
sudo apt autoremove -y
sudo apt autoclean

# Clean logs
sudo journalctl --vacuum-time=7d

# Clean browser cache
rm -rf /home/pitstyle/.cache/chromium/
rm -rf /home/pitstyle/.config/chromium/

# Clean temporary files
sudo find /tmp -type f -atime +7 -delete
sudo find /var/tmp -type f -atime +7 -delete

# Clean old kernels
sudo apt autoremove --purge -y

echo "✅ Cleanup complete!"
echo ""
echo "=== Disk Usage After Cleanup ==="
df -h /
EOF

    echo -e "${GREEN}✅ Pi $pi_number cleanup complete${NC}"
}

optimize_all_pis() {
    echo -e "${BLUE}🚀 Optimizing all Pis...${NC}"
    
    for pi_number in 1 2 3; do
        echo ""
        echo -e "${YELLOW}--- Optimizing Pi $pi_number ---${NC}"
        optimize_pi_system "$pi_number"
        echo ""
    done
    
    echo -e "${GREEN}🎉 All Pis optimization complete!${NC}"
    echo "  📋 Reboot all Pis for changes to take effect"
}

# Main script logic
case "$1" in
    optimize-pi)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 optimize-pi [pi_number]"
            exit 1
        fi
        optimize_pi_system "$2"
        ;;
    optimize-all)
        optimize_all_pis
        ;;
    display-config)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 display-config [pi_number]"
            exit 1
        fi
        configure_display "$2"
        ;;
    performance-test)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 performance-test [pi_number]"
            exit 1
        fi
        performance_test "$2"
        ;;
    monitor)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 monitor [pi_number]"
            exit 1
        fi
        monitor_pi "$2"
        ;;
    cleanup)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 cleanup [pi_number]"
            exit 1
        fi
        cleanup_pi "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac