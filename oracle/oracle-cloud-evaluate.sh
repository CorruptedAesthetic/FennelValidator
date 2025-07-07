#!/bin/bash
# Oracle Cloud Infrastructure Evaluation for Fennel Validator
# This script evaluates your Oracle Cloud setup for running validators

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
print_header() { echo -e "${BLUE}🔍 $1${NC}"; }

echo -e "${BLUE}☁️  Oracle Cloud Infrastructure Evaluation${NC}"
echo "=============================================="
echo

# Check if OCI CLI is configured
if [[ ! -f "$HOME/.oci/config" ]]; then
    print_error "Oracle CLI not configured"
    echo "Please run: ./setup-oracle-cli.sh first"
    exit 1
fi

# Get current region and tenancy
print_header "Current Configuration"
REGION=$(oci iam region list --query "data[?contains(\"region-name\", 'phx') || contains(\"region-name\", 'ash') || contains(\"region-name\", 'lhr')]" --output table 2>/dev/null | head -1 || echo "unknown")
print_info "Region: $REGION"

# List available compute instances
print_header "Compute Instances"
echo "Checking for existing compute instances..."

if oci compute instance list --output table 2>/dev/null; then
    print_info "✅ Found compute instances"
else
    print_warning "No compute instances found or access denied"
fi

# Check compartments
print_header "Compartments"
echo "Available compartments:"
oci iam compartment list --output table 2>/dev/null || print_warning "Could not list compartments"

# Check VCN (Virtual Cloud Networks)
print_header "Virtual Cloud Networks"
echo "Checking VCN configuration..."
oci network vcn list --output table 2>/dev/null || print_warning "Could not list VCNs"

# Check security lists
print_header "Security Configuration"
echo "This will help identify firewall rules needed for validator..."

# Get VCN ID for security list check
VCN_ID=$(oci network vcn list --query 'data[0].id' --raw-output 2>/dev/null || echo "")

if [[ -n "$VCN_ID" ]]; then
    print_info "Checking security lists for VCN: $VCN_ID"
    oci network security-list list --vcn-id "$VCN_ID" --output table 2>/dev/null || print_warning "Could not check security lists"
else
    print_warning "No VCN found - you'll need to create networking resources"
fi

# Check free tier availability
print_header "Free Tier Resources"
echo "Checking Always Free resources..."

# This would need to be expanded based on specific Oracle Cloud Free Tier API calls
print_info "For detailed free tier usage, check the Oracle Cloud Console"

# Recommendations
print_header "Recommendations for Fennel Validator"
echo
print_info "For optimal Fennel validator performance, ensure you have:"
echo "  • At least 2 CPU cores (use VM.Standard.E2.1.Micro for free tier)"
echo "  • 4GB+ RAM (scale up from 1GB free tier if needed)"
echo "  • 50GB+ storage for blockchain data"
echo "  • Port 30333 open for P2P connections"
echo "  • Port 9944 open for RPC (optional, for monitoring)"
echo "  • Stable internet connection with good uptime"
echo
print_info "Free tier limitations:"
echo "  • 1/8 OCPU, 1GB RAM (may need upgrade for production)"
echo "  • 47GB storage (sufficient for staging network)"
echo "  • 1 IPv4 address (perfect for validator)"
echo

print_info "Evaluation complete! Use this information to configure your validator."
