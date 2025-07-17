#!/bin/bash

# Airport Transcript Display - Pi SSH Setup Script
# This script sets up SSH keys and initial Pi configuration

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
DEFAULT_PI_PASSWORD="pi"

# Pi configurations - ACTUAL IP ADDRESSES
# Using arrays compatible with bash 3.2
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
    echo -e "${BLUE}Airport Transcript Display - Pi SSH Setup${NC}"
    echo ""
    echo "Usage: $0 [command] [pi_number]"
    echo ""
    echo "Commands:"
    echo "  setup-keys                    - Generate SSH keys for Pi access"
    echo "  setup-pi [pi_number]          - Setup specific Pi (1, 2, or 3)"
    echo "  setup-all                     - Setup all configured Pis"
    echo "  test-connection [pi_number]   - Test SSH connection to Pi"
    echo "  test-all                      - Test all Pi connections"
    echo "  scan-network                  - Scan network for Pis"
    echo "  update-ips                    - Update Pi IP addresses in config"
    echo ""
    echo "Examples:"
    echo "  $0 setup-keys                 - Generate SSH keys"
    echo "  $0 setup-pi 1                 - Setup Pi 1"
    echo "  $0 setup-all                  - Setup all Pis"
    echo "  $0 test-connection 1          - Test connection to Pi 1"
    echo ""
    echo "Current Pi Configuration:"
    for id in 1 2 3; do
        echo "  Pi $id (Display $id): $(get_pi_ip $id)"
    done
}

generate_ssh_keys() {
    echo -e "${YELLOW}🔑 Generating SSH keys for Pi access...${NC}"
    
    if [ -f "$SSH_KEY_PATH" ]; then
        echo -e "${YELLOW}⚠️  SSH key already exists at $SSH_KEY_PATH${NC}"
        read -p "Do you want to overwrite it? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Keeping existing key."
            return 0
        fi
    fi
    
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "airport-display-$(date +%Y%m%d)"
    
    echo -e "${GREEN}✅ SSH keys generated:${NC}"
    echo "  Private key: $SSH_KEY_PATH"
    echo "  Public key: $SSH_KEY_PATH.pub"
    
    # Add to SSH agent
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY_PATH"
    
    echo -e "${GREEN}✅ SSH key added to agent${NC}"
}

scan_network() {
    echo -e "${YELLOW}🔍 Scanning network for Raspberry Pis...${NC}"
    
    # Get network range (macOS compatible)
    NETWORK=$(route get default | grep interface | awk '{print $2}')
    if [ -n "$NETWORK" ]; then
        NETWORK_IP=$(ifconfig "$NETWORK" | grep "inet " | awk '{print $2}' | head -1)
        if [ -n "$NETWORK_IP" ]; then
            # Extract network part (assuming /24)
            NETWORK_PART=$(echo "$NETWORK_IP" | cut -d'.' -f1-3)
            NETWORK="${NETWORK_PART}.0/24"
            echo -e "${YELLOW}Detected network: $NETWORK${NC}"
        else
            NETWORK="192.168.1.0/24"
            echo -e "${YELLOW}Using default network: $NETWORK${NC}"
        fi
    else
        NETWORK="192.168.1.0/24"
        echo -e "${YELLOW}Using default network: $NETWORK${NC}"
    fi
    
    echo "Looking for devices with SSH open..."
    
    # Check if nmap is available
    if command -v nmap > /dev/null 2>&1; then
        nmap -p 22 --open "$NETWORK" | grep -B 2 -A 2 "22/tcp open"
    else
        echo -e "${YELLOW}nmap not found. Trying manual scan...${NC}"
        # Manual scan for common Pi IPs
        NETWORK_BASE=$(echo "$NETWORK" | cut -d'/' -f1 | cut -d'.' -f1-3)
        echo "Scanning ${NETWORK_BASE}.100-110 for SSH..."
        for i in {100..110}; do
            ip="${NETWORK_BASE}.${i}"
            echo -n "Checking $ip... "
            if timeout 2 bash -c "echo >/dev/tcp/$ip/22" 2>/dev/null; then
                echo "SSH open"
            else
                echo "closed/timeout"
            fi
        done
    fi
    
    echo ""
    echo -e "${YELLOW}💡 Look for devices with SSH open and try connecting with:${NC}"
    echo "ssh pi@[IP_ADDRESS]"
    echo ""
    echo -e "${YELLOW}💡 Default Pi credentials:${NC}"
    echo "Username: pi"
    echo "Password: raspberry"
    echo ""
}

check_pi_connectivity() {
    local pi_ip=$1
    
    echo -e "${YELLOW}📡 Testing connectivity to $pi_ip...${NC}"
    
    if ! ping -c 1 -W 2 "$pi_ip" > /dev/null 2>&1; then
        echo -e "${RED}❌ Cannot reach Pi at $pi_ip${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Pi is reachable${NC}"
    return 0
}

setup_pi_ssh() {
    local pi_number=$1
    local pi_ip=$(get_pi_ip $pi_number)
    
    if [ -z "$pi_ip" ]; then
        echo -e "${RED}❌ Invalid Pi number: $pi_number${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔧 Setting up Pi $pi_number ($pi_ip)...${NC}"
    
    # Check connectivity
    if ! check_pi_connectivity "$pi_ip"; then
        return 1
    fi
    
    # Check if SSH key exists
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo -e "${RED}❌ SSH key not found. Run: $0 setup-keys${NC}"
        return 1
    fi
    
    # Test if SSH key auth already works
    if ssh -i "$SSH_KEY_PATH" -o BatchMode=yes -o ConnectTimeout=5 "$DEFAULT_PI_USER@$pi_ip" exit 2>/dev/null; then
        echo -e "${GREEN}✅ SSH key authentication already working${NC}"
    else
        echo -e "${YELLOW}🔑 Setting up SSH key authentication...${NC}"
        echo "You may need to enter the Pi password (default: raspberry)"
        
        # Copy SSH key to Pi
        ssh-copy-id -i "$SSH_KEY_PATH.pub" "$DEFAULT_PI_USER@$pi_ip"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ SSH key copied successfully${NC}"
        else
            echo -e "${RED}❌ Failed to copy SSH key${NC}"
            return 1
        fi
    fi
    
    # Test the connection
    echo -e "${YELLOW}🧪 Testing SSH connection...${NC}"
    if ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=5 "$DEFAULT_PI_USER@$pi_ip" "echo 'SSH connection successful'" 2>/dev/null; then
        echo -e "${GREEN}✅ SSH connection test passed${NC}"
    else
        echo -e "${RED}❌ SSH connection test failed${NC}"
        return 1
    fi
    
    # Configure Pi
    echo -e "${YELLOW}⚙️  Configuring Pi $pi_number...${NC}"
    
    ssh -i "$SSH_KEY_PATH" "$DEFAULT_PI_USER@$pi_ip" << EOF
set -e

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Enable SSH service
sudo systemctl enable ssh
sudo systemctl start ssh

# Set hostname
sudo hostnamectl set-hostname airport-display-$pi_number

# Install required packages
sudo apt install -y curl wget git htop nano chromium-browser unclutter

# Configure automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Set up basic firewall
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 3000/tcp

# Create project directory
mkdir -p /home/pi/airport-transcript-display

# Set timezone (adjust as needed)
sudo timedatectl set-timezone UTC

echo "Pi $pi_number configuration complete!"
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Pi $pi_number setup complete${NC}"
        echo "  IP: $pi_ip"
        echo "  SSH: $DEFAULT_PI_USER@$pi_ip"
        echo "  Test: ssh -i $SSH_KEY_PATH $DEFAULT_PI_USER@$pi_ip"
    else
        echo -e "${RED}❌ Pi $pi_number setup failed${NC}"
        return 1
    fi
}

setup_all_pis() {
    echo -e "${BLUE}🚀 Setting up all Pis...${NC}"
    
    for pi_number in 1 2 3; do
        echo ""
        echo -e "${YELLOW}--- Setting up Pi $pi_number ---${NC}"
        setup_pi_ssh "$pi_number"
        echo ""
    done
    
    echo -e "${GREEN}🎉 All Pis setup complete!${NC}"
    test_all_connections
}

test_connection() {
    local pi_number=$1
    local pi_ip=$(get_pi_ip $pi_number)
    
    if [ -z "$pi_ip" ]; then
        echo -e "${RED}❌ Invalid Pi number: $pi_number${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}🧪 Testing connection to Pi $pi_number ($pi_ip)...${NC}"
    
    if ! check_pi_connectivity "$pi_ip"; then
        return 1
    fi
    
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo -e "${RED}❌ SSH key not found. Run: $0 setup-keys${NC}"
        return 1
    fi
    
    # Test SSH connection
    if ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=5 "$DEFAULT_PI_USER@$pi_ip" "hostname && uptime" 2>/dev/null; then
        echo -e "${GREEN}✅ Pi $pi_number connection successful${NC}"
        return 0
    else
        echo -e "${RED}❌ Pi $pi_number connection failed${NC}"
        return 1
    fi
}

test_all_connections() {
    echo -e "${BLUE}🧪 Testing all Pi connections...${NC}"
    
    local success_count=0
    local total_count=3
    
    for pi_number in 1 2 3; do
        echo ""
        if test_connection "$pi_number"; then
            ((success_count++))
        fi
    done
    
    echo ""
    echo "==============================================="
    echo -e "${BLUE}📊 Connection Test Summary${NC}"
    echo "  Successful: $success_count/$total_count"
    
    if [ $success_count -eq $total_count ]; then
        echo -e "${GREEN}✅ All Pis are accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  Some Pis are not accessible${NC}"
    fi
}

update_pi_ips() {
    echo -e "${YELLOW}🔄 Updating Pi IP addresses...${NC}"
    echo "Current configuration:"
    
    for id in 1 2 3; do
        echo "  Pi $id: $(get_pi_ip $id)"
    done
    
    echo ""
    echo "Enter new IP addresses (press Enter to keep current):"
    
    for id in 1 2 3; do
        current_ip=$(get_pi_ip $id)
        read -p "Pi $id (current: $current_ip): " new_ip
        
        if [ -n "$new_ip" ]; then
            PI_IPS[$((id-1))]="$new_ip"
            echo "Updated Pi $id to: $new_ip"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✅ IP addresses updated${NC}"
    echo "Updated configuration:"
    
    for id in 1 2 3; do
        echo "  Pi $id: $(get_pi_ip $id)"
    done
    
    echo ""
    echo -e "${YELLOW}💡 Remember to update the IP addresses in pi-management.sh as well${NC}"
}

# Add SSH key to config
add_ssh_config() {
    echo -e "${YELLOW}⚙️  Adding SSH configuration...${NC}"
    
    SSH_CONFIG_FILE="$HOME/.ssh/config"
    
    # Backup existing config
    if [ -f "$SSH_CONFIG_FILE" ]; then
        cp "$SSH_CONFIG_FILE" "$SSH_CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Add Pi configurations
    for id in 1 2 3; do
        pi_ip=$(get_pi_ip $id)
        
        # Remove existing entries
        sed -i "/^Host airport-display-$id$/,/^$/d" "$SSH_CONFIG_FILE" 2>/dev/null || true
        
        # Add new entry
        cat >> "$SSH_CONFIG_FILE" << EOF

Host airport-display-$id
    HostName $pi_ip
    User $DEFAULT_PI_USER
    IdentityFile $SSH_KEY_PATH
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

EOF
    done
    
    echo -e "${GREEN}✅ SSH config updated${NC}"
    echo "You can now connect using:"
    for id in 1 2 3; do
        echo "  ssh airport-display-$id"
    done
}

# Main script logic
case "$1" in
    setup-keys)
        generate_ssh_keys
        add_ssh_config
        ;;
    setup-pi)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 setup-pi [pi_number]"
            exit 1
        fi
        setup_pi_ssh "$2"
        ;;
    setup-all)
        if [ ! -f "$SSH_KEY_PATH" ]; then
            echo -e "${YELLOW}SSH keys not found. Generating them first...${NC}"
            generate_ssh_keys
            add_ssh_config
        fi
        setup_all_pis
        ;;
    test-connection)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 test-connection [pi_number]"
            exit 1
        fi
        test_connection "$2"
        ;;
    test-all)
        test_all_connections
        ;;
    scan-network)
        scan_network
        ;;
    update-ips)
        update_pi_ips
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