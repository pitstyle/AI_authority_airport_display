#!/bin/bash

# Airport Transcript Display - Pi Management Script
# Usage: ./pi-management.sh [command] [options]

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PI_USER="pitstyle"
SSH_KEY_PATH="$HOME/.ssh/id_rsa_airport_display"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${BLUE}Airport Transcript Display - Pi Management${NC}"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  deploy [pi_ip] [display_id] [scale]  - Deploy app to Pi"
    echo "  status [pi_ip]                       - Check Pi status"
    echo "  restart [pi_ip]                      - Restart app service"
    echo "  logs [pi_ip]                         - View app logs"
    echo "  update [pi_ip]                       - Update app code"
    echo "  config [pi_ip] [display_id] [scale]  - Change display config"
    echo "  reboot [pi_ip]                       - Reboot Pi"
    echo "  monitor                              - Monitor all configured Pis"
    echo "  ssh [pi_ip]                          - SSH into Pi"
    echo "  exit-kiosk [pi_ip]                   - Exit kiosk mode"
    echo "  start-kiosk [pi_ip]                  - Start kiosk mode"
    echo ""
    echo "Examples:"
    echo "  $0 deploy 192.168.1.101 1 1.0       - Deploy Display 1 (standard)"
    echo "  $0 deploy 192.168.1.102 2 2.0       - Deploy Display 2 (large)"
    echo "  $0 status 192.168.1.101              - Check Pi status"
    echo "  $0 config 192.168.1.102 1 1.5       - Change to Display 1 with 1.5x scale"
    echo "  $0 monitor                           - Monitor all Pis"
    echo "  $0 exit-kiosk 192.168.1.101         - Exit kiosk mode"
    echo "  $0 start-kiosk 192.168.1.101        - Start kiosk mode"
    echo ""
    echo "Configured Pis:"
    for id in 1 2 3; do
        echo "  Display $id: $(get_pi_ip $id)"
    done
}

check_pi_connectivity() {
    local pi_ip=$1
    if ! ping -c 1 -W 2 $pi_ip > /dev/null 2>&1; then
        echo -e "${RED}❌ Cannot reach Pi at $pi_ip${NC}"
        return 1
    fi
    return 0
}

deploy_to_pi() {
    local pi_ip=$1
    local display_id=$2
    local scale=$3
    
    echo -e "${GREEN}🚀 Deploying to Pi: $pi_ip${NC}"
    ./deploy-to-pi.sh "$pi_ip" "$display_id" "$scale"
}

check_pi_status() {
    local pi_ip=$1
    
    echo -e "${YELLOW}📊 Checking Pi status: $pi_ip${NC}"
    
    if ! check_pi_connectivity $pi_ip; then
        return 1
    fi
    
    ssh -i "$SSH_KEY_PATH" $DEFAULT_PI_USER@$pi_ip << 'EOF'
echo "=== System Status ==="
uptime
echo ""
echo "=== App Service Status ==="
sudo systemctl status airport-display.service --no-pager
echo ""
echo "=== Display Configuration ==="
if [ -f /home/pitstyle/airport-transcript-display/.env ]; then
    grep "REACT_APP_DISPLAY" /home/pitstyle/airport-transcript-display/.env
else
    echo "❌ Configuration file not found"
fi
echo ""
echo "=== Network Status ==="
hostname -I
echo ""
echo "=== Disk Usage ==="
df -h / | tail -1
echo ""
echo "=== Memory Usage ==="
free -h | grep Mem
EOF
}

restart_service() {
    local pi_ip=$1
    
    echo -e "${YELLOW}🔄 Restarting service on Pi: $pi_ip${NC}"
    
    if ! check_pi_connectivity $pi_ip; then
        return 1
    fi
    
    ssh -i "$SSH_KEY_PATH" $DEFAULT_PI_USER@$pi_ip << 'EOF'
sudo systemctl restart airport-display.service
sleep 5
sudo systemctl status airport-display.service --no-pager
EOF
    
    echo -e "${GREEN}✅ Service restarted${NC}"
}

view_logs() {
    local pi_ip=$1
    
    echo -e "${YELLOW}📋 Viewing logs on Pi: $pi_ip${NC}"
    echo "Press Ctrl+C to exit"
    
    if ! check_pi_connectivity $pi_ip; then
        return 1
    fi
    
    ssh -i "$SSH_KEY_PATH" $DEFAULT_PI_USER@$pi_ip "sudo journalctl -u airport-display.service -f"
}

update_app() {
    local pi_ip=$1
    
    echo -e "${YELLOW}🔄 Updating app on Pi: $pi_ip${NC}"
    
    if ! check_pi_connectivity $pi_ip; then
        return 1
    fi
    
    # Build locally
    echo "Building latest version..."
    npm run build
    
    # Transfer and update
    tar -czf airport-display-update.tar.gz build/
    scp -i "$SSH_KEY_PATH" airport-display-update.tar.gz $DEFAULT_PI_USER@$pi_ip:/home/pitstyle/
    rm airport-display-update.tar.gz
    
    ssh -i "$SSH_KEY_PATH" $DEFAULT_PI_USER@$pi_ip << 'EOF'
cd /home/pitstyle/airport-transcript-display
tar -xzf /home/pitstyle/airport-display-update.tar.gz
rm /home/pitstyle/airport-display-update.tar.gz
sudo systemctl restart airport-display.service
EOF
    
    echo -e "${GREEN}✅ App updated${NC}"
}

change_config() {
    local pi_ip=$1
    local display_id=$2
    local scale=$3
    
    echo -e "${YELLOW}⚙️  Changing configuration on Pi: $pi_ip${NC}"
    echo "Display ID: $display_id, Scale: $scale"
    
    if ! check_pi_connectivity $pi_ip; then
        return 1
    fi
    
    ssh -i "$SSH_KEY_PATH" $DEFAULT_PI_USER@$pi_ip << EOF
cd /home/pitstyle/airport-transcript-display
cp .env.display$display_id .env
echo "REACT_APP_DISPLAY_SCALE=$scale" >> .env
sudo systemctl restart airport-display.service
echo "Configuration updated!"
grep "REACT_APP_DISPLAY" .env
EOF
    
    echo -e "${GREEN}✅ Configuration changed${NC}"
}

reboot_pi() {
    local pi_ip=$1
    
    echo -e "${YELLOW}🔄 Rebooting Pi: $pi_ip${NC}"
    
    if ! check_pi_connectivity $pi_ip; then
        return 1
    fi
    
    ssh -i "$SSH_KEY_PATH" $DEFAULT_PI_USER@$pi_ip "sudo reboot"
    echo -e "${GREEN}✅ Reboot command sent${NC}"
}

monitor_all_pis() {
    echo -e "${BLUE}📊 Monitoring All Configured Pis${NC}"
    echo "========================================"
    
    for id in 1 2 3; do
        pi_ip=$(get_pi_ip $id)
        echo -e "${YELLOW}Display $id ($pi_ip):${NC}"
        
        if check_pi_connectivity $pi_ip; then
            service_status=$(ssh -i "$SSH_KEY_PATH" $DEFAULT_PI_USER@$pi_ip "sudo systemctl is-active airport-display.service" 2>/dev/null || echo "unknown")
            display_config=$(ssh -i "$SSH_KEY_PATH" $DEFAULT_PI_USER@$pi_ip "grep 'REACT_APP_DISPLAY_ID' /home/pitstyle/airport-transcript-display/.env 2>/dev/null || echo 'REACT_APP_DISPLAY_ID=unknown'" | cut -d'=' -f2)
            scale_config=$(ssh -i "$SSH_KEY_PATH" $DEFAULT_PI_USER@$pi_ip "grep 'REACT_APP_DISPLAY_SCALE' /home/pitstyle/airport-transcript-display/.env 2>/dev/null || echo 'REACT_APP_DISPLAY_SCALE=unknown'" | cut -d'=' -f2)
            
            if [ "$service_status" = "active" ]; then
                echo -e "  Status: ${GREEN}✅ Online${NC}"
            else
                echo -e "  Status: ${RED}❌ Offline/Error${NC}"
            fi
            echo "  Display ID: $display_config"
            echo "  Scale: $scale_config"
            echo "  URL: http://$pi_ip:3000"
        else
            echo -e "  Status: ${RED}❌ Unreachable${NC}"
        fi
        echo ""
    done
}

exit_kiosk_mode() {
    local pi_ip=$1
    
    echo -e "${YELLOW}🚪 Exiting kiosk mode on Pi: $pi_ip${NC}"
    
    if ! check_pi_connectivity $pi_ip; then
        return 1
    fi
    
    ssh -i "$SSH_KEY_PATH" $DEFAULT_PI_USER@$pi_ip << 'EOF'
# Kill chromium browser
pkill chromium-browser 2>/dev/null || true
echo "Kiosk mode exited. Desktop should be visible now."
echo "Browser processes killed."
EOF
    
    echo -e "${GREEN}✅ Kiosk mode exited${NC}"
    echo "To restart kiosk mode, use: $0 start-kiosk $pi_ip"
}

start_kiosk_mode() {
    local pi_ip=$1
    
    echo -e "${YELLOW}🖥️  Starting kiosk mode on Pi: $pi_ip${NC}"
    
    if ! check_pi_connectivity $pi_ip; then
        return 1
    fi
    
    ssh -i "$SSH_KEY_PATH" $DEFAULT_PI_USER@$pi_ip << 'EOF'
# Kill any existing browser
pkill chromium-browser 2>/dev/null || true
sleep 2

# Start kiosk mode
if [ -f /home/pitstyle/start-display.sh ]; then
    echo "Starting kiosk mode..."
    DISPLAY=:0 /home/pitstyle/start-display.sh &
    echo "Kiosk mode started."
else
    echo "❌ start-display.sh not found. Please deploy first."
    exit 1
fi
EOF
    
    echo -e "${GREEN}✅ Kiosk mode started${NC}"
    echo "To exit kiosk mode, use: $0 exit-kiosk $pi_ip"
}

ssh_to_pi() {
    local pi_ip=$1
    
    echo -e "${YELLOW}🔐 Connecting to Pi: $pi_ip${NC}"
    
    if ! check_pi_connectivity $pi_ip; then
        return 1
    fi
    
    ssh -i "$SSH_KEY_PATH" $DEFAULT_PI_USER@$pi_ip
}

# Main script logic
case "$1" in
    deploy)
        if [ $# -lt 4 ]; then
            echo "Usage: $0 deploy [pi_ip] [display_id] [scale]"
            exit 1
        fi
        deploy_to_pi "$2" "$3" "$4"
        ;;
    status)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 status [pi_ip]"
            exit 1
        fi
        check_pi_status "$2"
        ;;
    restart)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 restart [pi_ip]"
            exit 1
        fi
        restart_service "$2"
        ;;
    logs)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 logs [pi_ip]"
            exit 1
        fi
        view_logs "$2"
        ;;
    update)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 update [pi_ip]"
            exit 1
        fi
        update_app "$2"
        ;;
    config)
        if [ $# -lt 4 ]; then
            echo "Usage: $0 config [pi_ip] [display_id] [scale]"
            exit 1
        fi
        change_config "$2" "$3" "$4"
        ;;
    reboot)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 reboot [pi_ip]"
            exit 1
        fi
        reboot_pi "$2"
        ;;
    monitor)
        monitor_all_pis
        ;;
    ssh)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 ssh [pi_ip]"
            exit 1
        fi
        ssh_to_pi "$2"
        ;;
    exit-kiosk)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 exit-kiosk [pi_ip]"
            exit 1
        fi
        exit_kiosk_mode "$2"
        ;;
    start-kiosk)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 start-kiosk [pi_ip]"
            exit 1
        fi
        start_kiosk_mode "$2"
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