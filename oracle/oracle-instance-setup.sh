#!/bin/bash
# Oracle Cloud Instance Setup for Slowblock Validator
# Run this script on your Oracle Cloud instance

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${GREEN}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_header() { echo -e "${BLUE}🚀 $1${NC}"; }

echo -e "${BLUE}☁️  Oracle Cloud Slowblock Validator Setup${NC}"
echo "==========================================="
echo

print_header "Step 1: System Update and Firewall Configuration"

# Update system
print_info "Updating system packages..."
sudo apt-get update

# Install iptables-persistent
print_info "Installing iptables-persistent..."
sudo apt-get install -y iptables-persistent

# Configure firewall for validator
print_info "Configuring firewall for Fennel validator..."

# Open P2P port (30333)
print_info "Opening port 30333 for P2P connections..."
sudo iptables -I INPUT 5 -p tcp --dport 30333 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Save firewall rules
print_info "Saving firewall configuration..."
sudo netfilter-persistent save

print_info "✅ Firewall configured for validator"

print_header "Step 2: Download FennelValidator Repository"

# Check if FennelValidator exists
if [ -d "FennelValidator" ]; then
    print_warning "FennelValidator directory already exists"
    print_info "Backing up existing directory..."
    mv FennelValidator FennelValidator.backup.$(date +%Y%m%d_%H%M%S)
fi

# Clone repository
print_info "Cloning FennelValidator repository..."
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator

print_header "Step 3: Configure Slowblock Validator"

# Update validator configuration
print_info "Configuring validator for slowblock..."

# Ensure config directory exists
mkdir -p config

# Create validator configuration
cat > config/validator.conf << EOF
# Fennel Validator Configuration
# Generated on $(date)

VALIDATOR_NAME="slowblock"
NETWORK="staging"
CHAINSPEC="staging-chainspec.json"
DATA_DIR="./data"
P2P_PORT="30333"
RPC_PORT="9944"
PROMETHEUS_PORT="9615"
RPC_EXTERNAL="false"
PROMETHEUS_EXTERNAL="false"
LOG_LEVEL="info"
BOOTNODE=""
REPO_URL="https://github.com/CorruptedAesthetic/fennel-solonet"
EOF

print_info "✅ Validator configured as 'slowblock'"

print_header "Step 4: Install Validator Dependencies"

# Make scripts executable
chmod +x *.sh

# Install validator
print_info "Installing Fennel validator..."
./install.sh

print_header "Step 5: Ready to Start!"

echo
print_info "🎉 Oracle Cloud setup complete!"
echo
echo -e "${CYAN}Next steps:${NC}"
echo "1. Run: ./start.sh"
echo "2. Choose 'Complete Setup' from the menu"
echo "3. Confirm validator name as 'slowblock'"
echo "4. Generate session keys"
echo "5. Submit registration to Fennel Labs"
echo
print_info "Your slowblock validator is ready to join the live Fennel network!"

print_header "Network Connection Info"
echo
print_info "Your validator will automatically connect to:"
echo "  • Bootnode 1: 135.18.208.132:30333"
echo "  • Bootnode 2: 132.196.191.14:30333"
echo "  • Live Fennel Staging Network"
echo

print_header "Useful Commands"
echo
echo "Start validator:    ./start.sh"
echo "Check status:       ./validate.sh status"
echo "View logs:          ./validate.sh logs"
echo "Generate keys:      ./scripts/generate-session-keys.sh"
echo "Restart validator:  ./validate.sh restart"
echo

print_info "Setup complete! Run ./start.sh to begin validation." 