#!/bin/bash
# FennelValidator Infrastructure Update Script
# Updates external validator to connect to new staging environment

set -e

echo "🔄 Updating FennelValidator Infrastructure"
echo "=========================================="
echo "Updating to connect to new Fennel staging environment"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "install.sh" ] || [ ! -f "validate.sh" ]; then
    print_error "Not in FennelValidator directory!"
    echo "Please run this script from the FennelValidator root directory"
    exit 1
fi

echo "📋 Updates to be applied:"
echo "========================"
echo "• Docker Image: sha-c31d08ee → sha-3fb1b156c14d912798d09f935bd5550a4d131346"
echo "• Bootnode DNS: Using bootnode1.fennel.network & bootnode2.fennel.network"
echo "• Bootnode IPs: 135.18.208.132 → 9.169.240.42 (bootnode1)"
echo "• Bootnode IPs: 132.196.191.14 → 130.213.254.26 (bootnode2)"
echo "• Network: Staging environment with validator manager pallet fixes"
echo ""

read -p "Continue with updates? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled"
    exit 0
fi

# Backup existing configuration
echo ""
print_info "Creating backup of current configuration..."
cp config/validator.conf config/validator.conf.backup.$(date +%Y%m%d_%H%M%S)

# Update validator configuration to point to new bootnodes
print_info "Updating validator configuration..."

# Check if bootnode is set in config and update it to use DNS
if grep -q "BOOTNODE=" config/validator.conf; then
    # Update to use DNS names instead of hardcoded IPs
    sed -i 's|BOOTNODE=.*|BOOTNODE="/dns4/bootnode1.fennel.network/tcp/30333/p2p/12D3KooWS84f71ufMQRsm9YWynfK5Zxa6iSooStJECnAT3RBVVxz,/dns4/bootnode2.fennel.network/tcp/30333/p2p/12D3KooWLWzcGVuLycfL1W83yc9S4UmVJ8qBd4Rk5mS6RJ4Bh7Su"|' config/validator.conf
else
    # Add bootnode configuration if it doesn't exist
    echo 'BOOTNODE="/dns4/bootnode1.fennel.network/tcp/30333/p2p/12D3KooWS84f71ufMQRsm9YWynfK5Zxa6iSooStJECnAT3RBVVxz,/dns4/bootnode2.fennel.network/tcp/30333/p2p/12D3KooWLWzcGVuLycfL1W83yc9S4UmVJ8qBd4Rk5mS6RJ4Bh7Su"' >> config/validator.conf
fi

# Update validator name to indicate it's an external validator
sed -i 's|VALIDATOR_NAME=.*|VALIDATOR_NAME="External-Validator-Oracle-$(hostname)"|' config/validator.conf

print_info "Updated validator configuration"

# Clean old chain data to sync with new environment
if [ -d "data" ]; then
    print_warning "Cleaning old chain data for fresh sync..."
    rm -rf data/chains/*/db data/chains/*/network
    print_info "Cleaned old chain data"
fi

# Update binary if needed (will be handled by install.sh with new Docker image)
print_info "Configuration updates completed!"

echo ""
echo "🎉 FennelValidator Updated Successfully!"
echo "======================================="
echo ""
echo "📊 New Configuration:"
echo "• Network: Staging"
echo "• Bootnodes: bootnode1.fennel.network & bootnode2.fennel.network"  
echo "• Docker Image: sha-3fb1b156c14d912798d09f935bd5550a4d131346"
echo "• Validator Manager: Includes latest pallet fixes"
echo ""
echo "🚀 Next Steps:"
echo "1. Run './install.sh' to download updated binary"
echo "2. Run './start.sh' to launch your external validator"
echo "3. Follow setup wizard to generate keys and register"
echo ""
echo "💡 Your validator will connect to the staging environment with:"
echo "   • 4 existing validators (Alice, Bob, Charlie + 2 bootnodes)"
echo "   • Session period: 50 blocks (~10 minutes)"
echo "   • Network: Fully operational with GRANDPA finalization"
echo ""
print_info "Update completed! Ready to launch external validator."
