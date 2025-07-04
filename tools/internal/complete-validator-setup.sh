#!/bin/bash
# Complete Validator Setup - All-in-One Script for Fennel External Validators
# Designed for non-blockchain partners - secure and beginner-friendly

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ASCII Art Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                🌱 FENNEL COMPLETE VALIDATOR SETUP 🌱           ║
║                                                               ║
║          Secure • Automated • Beginner-Friendly              ║
║                                                               ║
║   Perfect for non-blockchain partners getting started!       ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}Welcome to the complete Fennel validator setup!${NC}"
echo "This script will guide you through the entire process step-by-step."
echo

# Function to print section headers
print_section() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}\n"
}

# Function to wait for user confirmation
wait_for_user() {
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# Function to check prerequisites
check_prerequisites() {
    print_section "🔍 CHECKING PREREQUISITES"
    
    echo -e "${BLUE}Checking system requirements...${NC}"
    
    # Check if we're in the right directory
    if [ ! -f "../install.sh" ]; then
        echo -e "${RED}❌ Error: Please run this script from the FennelValidator/scripts/ directory${NC}"
        exit 1
    fi
    
    # Check if validator has been installed
    if [ ! -f "../bin/fennel-node" ]; then
        echo -e "${YELLOW}⚠️  Fennel node not installed yet.${NC}"
        echo "Let's install it first..."
        cd .. && ./install.sh && cd scripts
        echo -e "${GREEN}✅ Installation complete!${NC}"
    else
        echo -e "${GREEN}✅ Fennel node binary found${NC}"
    fi
    
    # Check if validator has been configured
    if [ ! -f "../config/validator.conf" ]; then
        echo -e "${YELLOW}⚠️  Validator not configured yet.${NC}"
        echo "Let's configure it..."
        cd .. && ./setup-validator.sh && cd scripts
        echo -e "${GREEN}✅ Configuration complete!${NC}"
    else
        echo -e "${GREEN}✅ Validator configuration found${NC}"
    fi
    
    # Check required tools
    echo -e "${BLUE}Checking required tools...${NC}"
    for tool in curl jq; do
        if command -v $tool > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $tool found${NC}"
        else
            echo -e "${RED}❌ $tool not found. Please install: sudo apt install $tool${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}🎉 All prerequisites met!${NC}"
}

# Function to start validator
start_validator() {
    print_section "🚀 STARTING VALIDATOR"
    
    echo -e "${BLUE}Starting your Fennel validator...${NC}"
    
    # Initialize if needed
    if [ ! -f "../data/chains/custom/network/secret_ed25519" ]; then
        echo "Initializing validator (this may take a moment)..."
        cd .. && ./validate.sh init && cd scripts
    fi
    
    # Start validator
    echo "Starting validator service..."
    cd .. && ./validate.sh start > /dev/null 2>&1 & cd scripts
    
    # Wait for startup
    echo "Waiting for validator to start..."
    for i in {1..30}; do
        if curl -s -m 2 http://localhost:9944 > /dev/null 2>&1; then
            break
        fi
        sleep 1
        echo -n "."
    done
    echo
    
    if curl -s -m 2 http://localhost:9944 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Validator is running and accessible!${NC}"
    else
        echo -e "${RED}❌ Failed to start validator. Check logs: ./validate.sh logs${NC}"
        exit 1
    fi
}

# Main execution flow
main() {
    echo -e "${BLUE}Starting complete validator setup...${NC}"
    echo "This will take you through the entire process step by step."
    echo
    
    echo -e "${YELLOW}What this script will do:${NC}"
    echo "1. Check prerequisites and install if needed"
    echo "2. Start your validator"
    echo "3. Generate session keys automatically"
    echo "4. Extract AccountID information"
    echo "5. Create a stash account"
    echo "6. Prepare submission for network operators"
    echo
    echo -e "${CYAN}The entire process is automated and secure!${NC}"
    echo
    
    wait_for_user
    
    # Execute setup steps
    check_prerequisites
    start_validator
    
    echo -e "${GREEN}🎉 Basic setup complete! Run individual scripts for full setup.${NC}"
    echo "Next: ./generate-session-keys-auto.sh"
}

# Run main function
main "$@" 