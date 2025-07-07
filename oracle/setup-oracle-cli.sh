#!/bin/bash
# Oracle CLI Setup Script for Fennel Validator
# This script installs and configures Oracle CLI to evaluate your Oracle Cloud infrastructure

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print status
print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

print_question() {
    echo -e "${CYAN}❓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo -e "${BLUE}🔧 $1${NC}"
}

echo -e "${BLUE}☁️  Oracle Cloud CLI Setup for Fennel Validator${NC}"
echo "================================================="
echo

# Check if running on supported OS
check_os() {
    print_header "Checking Operating System"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_info "Detected Linux - proceeding with installation"
        OS_TYPE="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_info "Detected macOS - proceeding with installation"
        OS_TYPE="macos"
    else
        print_error "Unsupported operating system: $OSTYPE"
        echo "This script supports Linux and macOS only"
        exit 1
    fi
}

# Install prerequisites
install_prerequisites() {
    print_header "Installing Prerequisites"
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        # Check if we have package manager access
        if command -v apt-get &> /dev/null; then
            print_info "Installing prerequisites via apt..."
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip curl wget jq
        elif command -v yum &> /dev/null; then
            print_info "Installing prerequisites via yum..."
            sudo yum install -y python3 python3-pip curl wget jq
        else
            print_warning "Package manager not detected. Please ensure python3, pip, curl, wget, and jq are installed"
        fi
    elif [[ "$OS_TYPE" == "macos" ]]; then
        # Check for Homebrew
        if command -v brew &> /dev/null; then
            print_info "Installing prerequisites via Homebrew..."
            brew install python3 curl wget jq
        else
            print_warning "Homebrew not found. Please install python3, curl, wget, and jq manually"
        fi
    fi
}

# Install Oracle CLI
install_oracle_cli() {
    print_header "Installing Oracle CLI"
    
    # Check if OCI CLI is already installed
    if command -v oci &> /dev/null; then
        print_info "Oracle CLI is already installed"
        oci --version
        return 0
    fi
    
    print_info "Downloading and installing Oracle CLI..."
    
    # Download and install OCI CLI
    curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh | bash
    
    # Add to PATH for current session
    export PATH=$PATH:$HOME/bin
    
    # Add to shell profile
    if [[ -f "$HOME/.bashrc" ]]; then
        echo 'export PATH=$PATH:$HOME/bin' >> "$HOME/.bashrc"
    fi
    
    if [[ -f "$HOME/.zshrc" ]]; then
        echo 'export PATH=$PATH:$HOME/bin' >> "$HOME/.zshrc"
    fi
    
    print_info "Oracle CLI installed successfully"
}

# Configure Oracle CLI
configure_oracle_cli() {
    print_header "Configuring Oracle CLI"
    
    echo "To configure Oracle CLI, you'll need information from your Oracle Cloud account:"
    echo "1. User OCID"
    echo "2. Tenancy OCID"
    echo "3. Region"
    echo "4. API Key (we'll help you create this)"
    echo
    
    print_question "Do you want to configure Oracle CLI now? (y/n)"
    read -r configure_now
    
    if [[ "$configure_now" =~ ^[Yy]$ ]]; then
        print_info "Starting Oracle CLI configuration..."
        
        # Check if config already exists
        if [[ -f "$HOME/.oci/config" ]]; then
            print_warning "Oracle CLI config already exists at $HOME/.oci/config"
            print_question "Do you want to reconfigure? (y/n)"
            read -r reconfigure
            
            if [[ ! "$reconfigure" =~ ^[Yy]$ ]]; then
                print_info "Keeping existing configuration"
                return 0
            fi
        fi
        
        # Run OCI setup
        oci setup config
        
        print_info "Oracle CLI configuration completed!"
        print_info "Config file location: $HOME/.oci/config"
        
    else
        print_info "Skipping configuration for now"
        echo "You can configure later by running: oci setup config"
    fi
}

# Test Oracle CLI setup
test_oracle_cli() {
    print_header "Testing Oracle CLI Setup"
    
    # Check if CLI is available
    if ! command -v oci &> /dev/null; then
        print_error "Oracle CLI not found in PATH"
        print_info "Please restart your terminal or run: export PATH=\$PATH:\$HOME/bin"
        return 1
    fi
    
    # Check if config exists
    if [[ ! -f "$HOME/.oci/config" ]]; then
        print_warning "Oracle CLI not configured yet"
        print_info "Run: oci setup config to configure"
        return 0
    fi
    
    # Test basic connectivity
    print_info "Testing Oracle CLI connectivity..."
    
    if oci iam region list > /dev/null 2>&1; then
        print_info "✅ Oracle CLI is working correctly!"
        
        # Show current configuration
        echo
        print_info "Current configuration:"
        oci iam region list --output table
        
    else
        print_error "Oracle CLI test failed"
        print_info "Please check your configuration with: oci setup config"
    fi
}

# Create Oracle Cloud evaluation script
create_evaluation_script() {
    print_header "Creating Oracle Cloud Evaluation Script"
    
    cat > oracle-cloud-evaluate.sh << 'EOF'
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
EOF

    chmod +x oracle-cloud-evaluate.sh
    print_info "Created oracle-cloud-evaluate.sh evaluation script"
}

# Create Oracle Cloud validator deployment script
create_deployment_script() {
    print_header "Creating Oracle Cloud Deployment Script"
    
    cat > oracle-cloud-deploy.sh << 'EOF'
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
EOF

    chmod +x oracle-cloud-deploy.sh
    print_info "Created oracle-cloud-deploy.sh deployment script"
}

# Main execution
main() {
    check_os
    install_prerequisites
    install_oracle_cli
    configure_oracle_cli
    test_oracle_cli
    create_evaluation_script
    create_deployment_script
    
    echo
    print_header "Setup Complete!"
    print_info "Oracle CLI has been installed and configured"
    print_info "Available scripts:"
    echo "  • ./oracle-cloud-evaluate.sh - Evaluate your Oracle Cloud setup"
    echo "  • ./oracle-cloud-deploy.sh - Deploy validator on Oracle Cloud"
    echo
    print_info "To get started:"
    echo "  1. Run: ./oracle-cloud-evaluate.sh"
    echo "  2. Review your Oracle Cloud resources"
    echo "  3. Run: ./oracle-cloud-deploy.sh (on your Oracle Cloud instance)"
    echo
    print_info "Your 'slowblock' validator is ready for Oracle Cloud deployment!"
}

# Run main function
main "$@" 