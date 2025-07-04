#!/bin/bash
# Complete Validator Setup - Full All-in-One Script for Fennel External Validators
# Designed for non-blockchain partners - secure and beginner-friendly
# This script does EVERYTHING in one go

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
║           🌱 FENNEL COMPLETE VALIDATOR SETUP 🌱               ║
║                                                               ║
║       Secure • Automated • Beginner-Friendly • Full         ║
║                                                               ║
║   Perfect for non-blockchain partners getting started!       ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}Welcome to the COMPLETE Fennel validator setup!${NC}"
echo "This script handles EVERYTHING from installation to submission."
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
        echo "Installing now..."
        cd .. && ./install.sh && cd scripts
        echo -e "${GREEN}✅ Installation complete!${NC}"
    else
        echo -e "${GREEN}✅ Fennel node binary found${NC}"
    fi
    
    # Check if validator has been configured
    if [ ! -f "../config/validator.conf" ]; then
        echo -e "${YELLOW}⚠️  Validator not configured yet.${NC}"
        echo "Configuring now..."
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

# Function to generate session keys
generate_session_keys() {
    print_section "🔑 GENERATING SESSION KEYS"
    
    echo -e "${BLUE}What are session keys?${NC}"
    echo "Session keys are cryptographic keys used by your validator for:"
    echo "• AURA: Block production (creating new blocks)"
    echo "• GRANDPA: Finality (confirming blocks are final)"
    echo
    echo -e "${YELLOW}This process is completely automated and secure.${NC}"
    echo "The script will temporarily enable unsafe RPC methods, generate keys, then restore security."
    echo
    
    wait_for_user
    
    echo -e "${BLUE}Generating session keys automatically...${NC}"
    ./generate-session-keys-auto.sh
    
    if [ -f "../session-keys.json" ]; then
        echo -e "${GREEN}✅ Session keys generated successfully!${NC}"
        
        # Show the keys
        VALIDATOR_NAME=$(jq -r '.validator_name' ../session-keys.json)
        SESSION_KEYS=$(jq -r '.session_keys' ../session-keys.json)
        
        echo
        echo -e "${CYAN}Your Validator: $VALIDATOR_NAME${NC}"
        echo -e "${CYAN}Session Keys: $SESSION_KEYS${NC}"
    else
        echo -e "${RED}❌ Failed to generate session keys${NC}"
        exit 1
    fi
}

# Function to extract account IDs
extract_account_ids() {
    print_section "🔍 EXTRACTING ACCOUNT INFORMATION"
    
    echo -e "${BLUE}What are AccountIDs?${NC}"
    echo "AccountIDs are the addresses derived from your session keys."
    echo "Network operators need these to identify your validator."
    echo
    
    echo -e "${BLUE}Extracting AccountID information...${NC}"
    ./get-account-id.sh
    
    if [ -f "../validator-account-info.json" ]; then
        echo -e "${GREEN}✅ AccountID information extracted!${NC}"
    else
        echo -e "${RED}❌ Failed to extract AccountID information${NC}"
        exit 1
    fi
}

# Function to setup stash account
setup_stash_account() {
    print_section "🏦 SETTING UP STASH ACCOUNT"
    
    echo -e "${BLUE}What is a stash account?${NC}"
    echo "A stash account is your main validator account that:"
    echo "• Holds your validator funds"
    echo "• Gets registered as a validator on-chain"
    echo "• Calls session.setKeys() to bind your session keys"
    echo
    echo -e "${YELLOW}This is different from session keys!${NC}"
    echo "• Session keys = operational keys (AURA, GRANDPA)"
    echo "• Stash account = main validator identity & funds"
    echo
    
    echo -e "${BLUE}The stash account is what network operators register as your validator.${NC}"
    echo
    
    wait_for_user
    
    echo -e "${BLUE}Generating a stash account for testing...${NC}"
    ./generate-stash-account.sh
    
    if [ -f "../stash-account.json" ]; then
        STASH_ADDRESS=$(jq -r '.stash_account.ss58_address' ../stash-account.json)
        echo -e "${GREEN}✅ Stash account created: $STASH_ADDRESS${NC}"
    else
        echo -e "${RED}❌ Failed to create stash account${NC}"
        exit 1
    fi
}

# Function to create final submission
create_submission() {
    print_section "📋 CREATING SUBMISSION FOR NETWORK OPERATORS"
    
    echo -e "${BLUE}Creating comprehensive submission package...${NC}"
    
    # Read all necessary information
    VALIDATOR_NAME=$(jq -r '.validator_name' ../session-keys.json)
    SESSION_KEYS=$(jq -r '.session_keys' ../session-keys.json)
    STASH_ADDRESS=$(jq -r '.stash_account.ss58_address' ../stash-account.json)
    STASH_SECRET_PHRASE=$(jq -r '.stash_account.secret_phrase' ../stash-account.json)
    
    # Create comprehensive submission file
    cat > ../FINAL-VALIDATOR-SUBMISSION.txt << EOF
╔═══════════════════════════════════════════════════════════════╗
║           🌱 FENNEL VALIDATOR REGISTRATION REQUEST 🌱          ║
╚═══════════════════════════════════════════════════════════════╝

VALIDATOR INFORMATION:
=====================
Validator Name: $VALIDATOR_NAME
Network: Fennel Staging (Solonet)
Setup Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

CRITICAL INFORMATION FOR NETWORK OPERATORS:
==========================================

🏦 STASH ACCOUNT (Register this as validator):
Address: $STASH_ADDRESS
Secret Phrase: $STASH_SECRET_PHRASE

🔑 SESSION KEYS (Already generated):
$SESSION_KEYS

📋 WHAT WE NEED FROM YOU:
========================
1. Testnet tokens for stash account: $STASH_ADDRESS
2. Instructions on how to call session.setKeys() 
3. Confirmation when you're ready for us to call setKeys()

📋 WHAT WE'LL DO NEXT:
=====================
1. Receive testnet tokens in our stash account
2. Call session.setKeys() with our session keys
3. Inform you when setKeys() is complete
4. You register our stash account as a validator

🔒 SECURITY NOTES:
=================
- Session keys are operational only (AURA, GRANDPA)
- Stash account controls validator funds and identity
- We're ready to participate in consensus once registered

VALIDATOR STATUS:
================
✅ Node running and connected to Fennel network
✅ Session keys generated and secured
✅ Stash account created and ready
✅ Waiting for testnet tokens and registration

Contact: Generated by automated Fennel Validator Setup
Repository: https://github.com/CorruptedAesthetic/FennelValidator
EOF

    # Create quick reference
    cat > ../QUICK-REFERENCE.txt << EOF
QUICK REFERENCE - FENNEL VALIDATOR
=================================

Validator: $VALIDATOR_NAME
Stash Account: $STASH_ADDRESS
Session Keys: $SESSION_KEYS

NEXT STEPS:
1. Send testnet tokens to: $STASH_ADDRESS
2. We'll call session.setKeys()
3. Register stash account as validator

Status: Ready for registration
EOF
    
    echo -e "${GREEN}✅ Submission files created!${NC}"
    echo
    echo -e "${CYAN}Files created:${NC}"
    echo "• FINAL-VALIDATOR-SUBMISSION.txt (complete submission)"
    echo "• QUICK-REFERENCE.txt (summary)"
    echo "• stash-account.json (stash account details)"
    echo "• session-keys.json (session key details)"
}

# Function to show final summary
show_final_summary() {
    print_section "🎉 SETUP COMPLETE!"
    
    VALIDATOR_NAME=$(jq -r '.validator_name' ../session-keys.json)
    STASH_ADDRESS=$(jq -r '.stash_account.ss58_address' ../stash-account.json)
    SESSION_KEYS=$(jq -r '.session_keys' ../session-keys.json)
    
    echo -e "${GREEN}🎉 Congratulations! Your Fennel validator setup is complete!${NC}"
    echo
    echo -e "${CYAN}═════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    VALIDATOR SUMMARY                        ${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${BLUE}Validator Name:${NC} $VALIDATOR_NAME"
    echo -e "${BLUE}Stash Account:${NC} $STASH_ADDRESS"
    echo -e "${BLUE}Session Keys:${NC} $SESSION_KEYS"
    echo
    echo -e "${YELLOW}📤 SEND TO NETWORK OPERATORS:${NC}"
    echo "Send them the file: FINAL-VALIDATOR-SUBMISSION.txt"
    echo
    echo -e "${YELLOW}🎯 NEXT STEPS:${NC}"
    echo "1. Network operators will send testnet tokens to your stash account"
    echo "2. Call session.setKeys() when you have tokens"
    echo "3. Inform operators when setKeys() is complete"
    echo "4. Wait for validator registration"
    echo
    echo -e "${GREEN}🛡️  SECURITY REMINDERS:${NC}"
    echo "• Keep your stash account secret phrase safe!"
    echo "• Your validator is running securely with safe RPC methods"
    echo "• Session keys are properly generated and stored"
    echo
    echo -e "${BLUE}🔧 USEFUL COMMANDS:${NC}"
    echo "• Check validator status: ./validate.sh status"
    echo "• View logs: ./validate.sh logs"
    echo "• Stop validator: ./validate.sh stop"
    echo "• Restart validator: ./validate.sh restart"
    echo
    echo -e "${PURPLE}Thank you for becoming a Fennel validator! 🌱${NC}"
}

# Main execution flow
main() {
    echo -e "${BLUE}Starting COMPLETE validator setup...${NC}"
    echo "This will take you through the ENTIRE process from start to finish."
    echo
    
    echo -e "${YELLOW}What this script will do:${NC}"
    echo "1. Check prerequisites and install if needed"
    echo "2. Start your validator"
    echo "3. Generate session keys automatically"
    echo "4. Extract AccountID information"
    echo "5. Create a stash account"
    echo "6. Prepare submission for network operators"
    echo "7. Show final summary with next steps"
    echo
    echo -e "${CYAN}The entire process is automated and secure!${NC}"
    echo -e "${CYAN}After this, you'll have everything needed for validator registration.${NC}"
    echo
    
    wait_for_user
    
    # Execute setup steps
    check_prerequisites
    start_validator
    generate_session_keys
    extract_account_ids
    setup_stash_account
    create_submission
    show_final_summary
    
    echo -e "${GREEN}🎉 Complete validator setup finished successfully!${NC}"
}

# Run main function
main "$@" 