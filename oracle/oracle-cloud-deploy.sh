#!/bin/bash
# Oracle Cloud Validator Deployment Script
# This script helps deploy Fennel validator on Oracle Cloud

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

echo -e "${BLUE}☁️  Oracle Cloud Validator Deployment${NC}"
echo "======================================"
echo

# Check prerequisites
print_header "Prerequisites Check"

if ! command -v oci &> /dev/null; then
    print_error "Oracle CLI not found. Please run ./setup-oracle-cli.sh first"
    exit 1
fi

if [[ ! -f "$HOME/.oci/config" ]]; then
    print_error "Oracle CLI not configured. Please run: oci setup config"
    exit 1
fi

print_info "✅ Oracle CLI is available and configured"

# Check if we're on Oracle Cloud instance
print_header "Deployment Environment"

if curl -s -m 5 http://169.254.169.254/opc/v2/instance/ > /dev/null 2>&1; then
    print_info "✅ Running on Oracle Cloud instance"
    INSTANCE_METADATA=$(curl -s http://169.254.169.254/opc/v2/instance/)
    print_info "Instance information available"
else
    print_warning "Not running on Oracle Cloud instance"
    print_info "This script works best when run on your Oracle Cloud VM"
fi

# Configure firewall for validator
print_header "Firewall Configuration"

configure_firewall() {
    print_info "Configuring firewall for Fennel validator..."
    
    # Check if iptables-persistent is installed
    if ! dpkg -l | grep -q iptables-persistent; then
        print_info "Installing iptables-persistent..."
        sudo apt-get update
        sudo apt-get install -y iptables-persistent
    fi
    
    # Add rule for P2P port (30333)
    print_info "Opening port 30333 for P2P connections..."
    sudo iptables -I INPUT 5 -p tcp --dport 30333 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    
    # Add rule for RPC port (9944) - localhost only by default
    print_info "Configuring RPC port 9944 (localhost only)..."
    sudo iptables -I INPUT 6 -p tcp --dport 9944 -s 127.0.0.1 -j ACCEPT
    
    # Save iptables rules
    sudo netfilter-persistent save
    
    print_info "✅ Firewall configured for validator"
}

# Configure Oracle Cloud security lists
configure_security_lists() {
    print_header "Oracle Cloud Security Lists"
    
    print_info "Checking security lists..."
    
    # Get VCN ID
    VCN_ID=$(oci network vcn list --query 'data[0].id' --raw-output 2>/dev/null || echo "")
    
    if [[ -z "$VCN_ID" ]]; then
        print_error "No VCN found. Please create a VCN first."
        return 1
    fi
    
    print_info "Found VCN: $VCN_ID"
    
    # Get security list ID
    SECURITY_LIST_ID=$(oci network security-list list --vcn-id "$VCN_ID" --query 'data[0].id' --raw-output 2>/dev/null || echo "")
    
    if [[ -z "$SECURITY_LIST_ID" ]]; then
        print_error "No security list found."
        return 1
    fi
    
    print_info "Found security list: $SECURITY_LIST_ID"
    
    # Add ingress rule for P2P port 30333
    print_info "Adding ingress rule for port 30333..."
    
    # Note: This is a simplified example. In practice, you'd want to check if rule already exists
    print_warning "Manual step required:"
    echo "  1. Go to Oracle Cloud Console"
    echo "  2. Navigate to Networking > Virtual Cloud Networks"
    echo "  3. Select your VCN"
    echo "  4. Click on your subnet"
    echo "  5. Click on 'Default Security List'"
    echo "  6. Click 'Add Ingress Rules'"
    echo "  7. Add rule: Source CIDR: 0.0.0.0/0, Protocol: TCP, Port: 30333"
    echo
    print_info "This allows P2P connections to your validator"
}

# Install and configure validator
install_validator() {
    print_header "Installing Fennel Validator"
    
    # Check if we're in the right directory
    if [[ ! -f "start.sh" ]]; then
        print_error "Not in FennelValidator directory"
        print_info "Please run this script from the FennelValidator directory"
        return 1
    fi
    
    # Run the validator installation
    print_info "Starting validator installation..."
    
    # Make scripts executable
    chmod +x start.sh
    chmod +x install.sh
    chmod +x setup-validator.sh
    
    # Run installation
    print_info "Running validator installation..."
    ./install.sh
    
    print_info "✅ Validator installed successfully"
}

# Main deployment flow
main() {
    print_header "Starting Oracle Cloud Validator Deployment"
    
    # Configure firewall
    configure_firewall
    
    # Configure security lists (manual steps)
    configure_security_lists
    
    # Install validator
    install_validator
    
    print_header "Deployment Complete!"
    print_info "Next steps:"
    echo "  1. Complete the manual security list configuration"
    echo "  2. Run: ./start.sh to configure and start your validator"
    echo "  3. Generate keys and submit for network inclusion"
    echo
    print_info "Your 'slowblock' validator is ready for Oracle Cloud!"
}

# Run main function
main "$@"
