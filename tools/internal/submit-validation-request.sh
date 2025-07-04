#!/bin/bash
# Submit Validation Request to Fennel Network
# Collects validator information and creates a comprehensive request

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🎯 Fennel Validator Admission Request${NC}"
echo "====================================="

# Check prerequisites
check_prerequisites() {
    local errors=0
    
    echo -e "\n${BLUE}🔍 Checking Prerequisites${NC}"
    
    # Check if validator is configured
    if [ ! -f "config/validator.conf" ]; then
        echo -e "${RED}❌ Validator not configured${NC}"
        echo "   Run: ./setup-validator.sh"
        ((errors++))
    fi
    
    # Check if session keys exist
    if [ ! -f "session-keys.json" ]; then
        echo -e "${RED}❌ Session keys not generated${NC}"
        echo "   Run: ./scripts/generate-session-keys.sh"
        ((errors++))
    fi
    
    # Check if validator is running
    if ! pgrep -f "fennel-node.*--validator" > /dev/null; then
        echo -e "${YELLOW}⚠️  Validator is not currently running${NC}"
        echo "   Consider starting it: ./validate.sh start"
    else
        echo -e "${GREEN}✅ Validator is running${NC}"
    fi
    
    # Check network connectivity
    if command -v curl >/dev/null 2>&1; then
        if curl -s --connect-timeout 5 http://localhost:9944 > /dev/null; then
            echo -e "${GREEN}✅ RPC connection working${NC}"
        else
            echo -e "${YELLOW}⚠️  RPC not accessible (validator may not be running)${NC}"
        fi
    fi
    
    if [ $errors -gt 0 ]; then
        echo -e "\n${RED}❌ Please fix the above issues before submitting${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Get validator information
get_validator_info() {
    echo -e "\n${BLUE}📋 Validator Information${NC}"
    
    # Load existing config
    source config/validator.conf 2>/dev/null || true
    
    # Get session keys
    SESSION_KEYS=$(jq -r '.session_keys' session-keys.json 2>/dev/null || echo "")
    VALIDATOR_NAME_FROM_KEYS=$(jq -r '.validator_name' session-keys.json 2>/dev/null || echo "")
    
    # Use validator name from session keys if available
    if [ -n "$VALIDATOR_NAME_FROM_KEYS" ]; then
        VALIDATOR_NAME="$VALIDATOR_NAME_FROM_KEYS"
    fi
    
    echo "Validator Name: ${VALIDATOR_NAME:-Unknown}"
    echo "Session Keys: ${SESSION_KEYS:-Not generated}"
    echo "P2P Port: ${P2P_PORT:-30333}"
    echo "Data Directory: ${DATA_DIR:-./data}"
}

# Get network status
get_network_status() {
    echo -e "\n${BLUE}🌐 Network Status${NC}"
    
    if pgrep -f "fennel-node.*--validator" > /dev/null && command -v curl >/dev/null 2>&1; then
        # Get system health
        HEALTH=$(curl -s -H "Content-Type: application/json" \
            -d '{"id":1,"jsonrpc":"2.0","method":"system_health","params":[]}' \
            http://localhost:9944 2>/dev/null || echo '{}')
        
        PEERS=$(echo "$HEALTH" | jq -r '.result.peers // "unknown"' 2>/dev/null || echo "unknown")
        IS_SYNCING=$(echo "$HEALTH" | jq -r '.result.isSyncing // "unknown"' 2>/dev/null || echo "unknown")
        
        # Get current block
        HEADER=$(curl -s -H "Content-Type: application/json" \
            -d '{"id":1,"jsonrpc":"2.0","method":"chain_getHeader","params":[]}' \
            http://localhost:9944 2>/dev/null || echo '{}')
        
        BLOCK_HEX=$(echo "$HEADER" | jq -r '.result.number // "0x0"' 2>/dev/null || echo "0x0")
        BLOCK_NUMBER=$((BLOCK_HEX))
        
        echo "Connected Peers: $PEERS"
        echo "Syncing: $IS_SYNCING"
        echo "Current Block: #$BLOCK_NUMBER"
        
        if [ "$PEERS" != "unknown" ] && [ "$PEERS" -gt 0 ] && [ "$IS_SYNCING" = "false" ]; then
            echo -e "${GREEN}✅ Network status: Healthy${NC}"
            NETWORK_HEALTHY=true
        else
            echo -e "${YELLOW}⚠️  Network status: Syncing or low peers${NC}"
            NETWORK_HEALTHY=false
        fi
    else
        echo -e "${YELLOW}⚠️  Cannot check network status (validator not running)${NC}"
        NETWORK_HEALTHY=false
    fi
}

# Get contact information
get_contact_info() {
    echo -e "\n${BLUE}📞 Contact Information${NC}"
    echo "Please provide your contact details for network administration:"
    echo
    
    read -p "Organization/Name: " CONTACT_NAME
    read -p "Email: " CONTACT_EMAIL
    read -p "Discord/Telegram (optional): " CONTACT_SOCIAL
    read -p "Location/Timezone: " CONTACT_LOCATION
    
    echo
    echo "Additional information (optional):"
    read -p "Technical background: " TECH_BACKGROUND
    read -p "Validator experience: " VALIDATOR_EXPERIENCE
    read -p "Commitment level (hours/day): " COMMITMENT
}

# Generate system information
get_system_info() {
    echo -e "\n${BLUE}💻 System Information${NC}"
    
    # Basic system info
    OS=$(uname -s)
    ARCH=$(uname -m)
    HOSTNAME=$(hostname)
    
    # Resource information
    if command -v free >/dev/null 2>&1; then
        MEMORY=$(free -h | awk '/^Mem:/ {print $2}')
    else
        MEMORY="Unknown"
    fi
    
    if command -v df >/dev/null 2>&1; then
        DISK=$(df -h . | awk 'NR==2 {print $4}')
    else
        DISK="Unknown"
    fi
    
    echo "Operating System: $OS $ARCH"
    echo "Hostname: $HOSTNAME"
    echo "Available Memory: $MEMORY"
    echo "Available Disk: $DISK"
}

# Create validation request
create_request() {
    echo -e "\n${BLUE}📄 Creating Validation Request${NC}"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local request_id="fennel-validator-$(date +%s)-$(hostname)"
    
    cat > validation-request.json << EOF
{
    "request_id": "$request_id",
    "timestamp": "$timestamp",
    "validator_info": {
        "name": "$VALIDATOR_NAME",
        "session_keys": "$SESSION_KEYS",
        "p2p_port": "${P2P_PORT:-30333}",
        "data_directory": "${DATA_DIR:-./data}"
    },
    "network_status": {
        "peers": "${PEERS:-unknown}",
        "syncing": "${IS_SYNCING:-unknown}",
        "current_block": "${BLOCK_NUMBER:-0}",
        "healthy": $NETWORK_HEALTHY
    },
    "contact_info": {
        "name": "$CONTACT_NAME",
        "email": "$CONTACT_EMAIL",
        "social": "$CONTACT_SOCIAL",
        "location": "$CONTACT_LOCATION",
        "technical_background": "$TECH_BACKGROUND",
        "validator_experience": "$VALIDATOR_EXPERIENCE",
        "commitment": "$COMMITMENT"
    },
    "system_info": {
        "os": "$OS",
        "architecture": "$ARCH",
        "hostname": "$HOSTNAME",
        "memory": "$MEMORY",
        "disk": "$DISK"
    },
    "network_config": {
        "bootnodes": [
            "/ip4/135.18.208.132/tcp/30333/p2p/12D3KooWS84f71ufMQRsm9YWynfK5Zxa6iSooStJECnAT3RBVVxz",
            "/ip4/132.196.191.14/tcp/30333/p2p/12D3KooWLWzcGVuLycfL1W83yc9S4UmVJ8qBd4Rk5mS6RJ4Bh7Su"
        ],
        "chain": "staging"
    }
}
EOF
    
    echo -e "${GREEN}✅ Validation request created: validation-request.json${NC}"
}

# Display submission instructions
show_submission_instructions() {
    echo -e "\n${CYAN}📤 Submission Instructions${NC}"
    echo "=========================================="
    echo
    echo -e "${YELLOW}📋 Files to Submit:${NC}"
    echo "1. validation-request.json (comprehensive request)"
    echo "2. session-keys.json (your session keys)"
    echo
    echo -e "${YELLOW}📧 How to Submit:${NC}"
    echo "Option 1: Email both files to: validators@fennel.network"
    echo "Option 2: Create GitHub issue with file contents"
    echo "Option 3: Submit via Discord/Telegram to Fennel team"
    echo
    echo -e "${YELLOW}📝 Email Template:${NC}"
    echo "Subject: Fennel Validator Admission Request - $VALIDATOR_NAME"
    echo
    echo "Dear Fennel Team,"
    echo
    echo "I would like to request admission to the Fennel staging network as a validator."
    echo
    echo "Validator Name: $VALIDATOR_NAME"
    echo "Contact: $CONTACT_EMAIL"
    echo "Request ID: $request_id"
    echo
    echo "Please find attached:"
    echo "- validation-request.json (complete request details)"
    echo "- session-keys.json (session keys for validator setup)"
    echo
    echo "I confirm that I have:"
    echo "✅ Successfully set up and tested my validator node"
    echo "✅ Generated secure session keys locally"
    echo "✅ Verified network connectivity to Fennel bootnodes"
    echo "✅ Committed to maintaining high uptime and participating in governance"
    echo
    echo "Thank you for considering my application."
    echo
    echo "Best regards,"
    echo "$CONTACT_NAME"
    echo
    echo -e "${YELLOW}⏱️  What Happens Next:${NC}"
    echo "1. Fennel team reviews your request (usually 1-3 business days)"
    echo "2. Technical verification of your validator setup"
    echo "3. Security review and background check"
    echo "4. Network admission via validator manager pallet"
    echo "5. Confirmation email with next steps"
    echo
    echo -e "${GREEN}🎉 Once approved, you'll start validating and earning rewards!${NC}"
}

# Create backup files
create_backups() {
    echo -e "\n${BLUE}💾 Creating Backups${NC}"
    
    # Create backup directory
    BACKUP_DIR="validator-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Copy important files
    cp validation-request.json "$BACKUP_DIR/" 2>/dev/null || true
    cp session-keys.json "$BACKUP_DIR/" 2>/dev/null || true
    cp config/validator.conf "$BACKUP_DIR/" 2>/dev/null || true
    
    # Create README for backup
    cat > "$BACKUP_DIR/README.md" << EOF
# Fennel Validator Backup

Created: $(date)
Validator: $VALIDATOR_NAME

## Files Included:
- validation-request.json: Complete validation request
- session-keys.json: Generated session keys
- validator.conf: Validator configuration

## Important Notes:
- Keep these files secure and private
- Session keys should never be shared publicly
- Use validation-request.json for admission requests
- Keep this backup in a safe location

## Recovery:
If you need to restore your validator:
1. Copy validator.conf to config/
2. Ensure session keys match what's registered on-chain
3. Restart validator with same configuration
EOF
    
    echo -e "${GREEN}✅ Backup created: $BACKUP_DIR${NC}"
    echo "Keep this backup in a secure location!"
}

# Main execution
main() {
    check_prerequisites
    get_validator_info
    get_network_status
    get_contact_info
    get_system_info
    create_request
    create_backups
    show_submission_instructions
    
    echo
    echo -e "${GREEN}🎯 Validation request ready for submission!${NC}"
    echo
    echo -e "${CYAN}Quick Summary:${NC}"
    echo "Validator: $VALIDATOR_NAME"
    echo "Contact: $CONTACT_EMAIL"
    echo "Status: Ready for review"
    echo
    echo -e "${YELLOW}Next step: Submit validation-request.json and session-keys.json to the Fennel team${NC}"
}

# Run main function
main "$@" 