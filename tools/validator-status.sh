#!/bin/bash
# 📊 Fennel Validator Status Dashboard
# Shows comprehensive validator status and health

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║              🔍 FENNEL VALIDATOR STATUS 🔍                    ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Function to check status
check_status() {
    local name=$1
    local check_command=$2
    local success_msg=$3
    local fail_msg=$4
    
    echo -n "$name "
    if eval "$check_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $success_msg${NC}"
        return 0
    else
        echo -e "${RED}✗ $fail_msg${NC}"
        return 1
    fi
}

# Validator Process Status
echo -e "${CYAN}Validator Process:${NC}"
echo "-----------------"

if pgrep -f "fennel-node.*--validator" >/dev/null; then
    PID=$(pgrep -f "fennel-node.*--validator")
    echo -e "Status: ${GREEN}✓ Running${NC} (PID: $PID)"
    
    # Get process info
    CPU=$(ps -p $PID -o %cpu= | tr -d ' ')
    MEM=$(ps -p $PID -o %mem= | tr -d ' ')
    TIME=$(ps -p $PID -o etime= | tr -d ' ')
    
    echo -e "CPU Usage: ${CYAN}${CPU}%${NC}"
    echo -e "Memory Usage: ${CYAN}${MEM}%${NC}"
    echo -e "Uptime: ${CYAN}$TIME${NC}"
else
    echo -e "Status: ${RED}✗ Not Running${NC}"
    echo -e "${YELLOW}Start with: ./validate.sh start${NC}"
fi

echo

# Network Connectivity
echo -e "${CYAN}Network Status:${NC}"
echo "---------------"

if pgrep -f "fennel-node.*--validator" >/dev/null && curl -s -m 2 http://localhost:9944/health >/dev/null 2>&1; then
    # Get peer count
    PEER_INFO=$(curl -s -H "Content-Type: application/json" \
        -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' \
        http://localhost:9944 2>/dev/null || echo "{}")
    
    PEER_COUNT=$(echo "$PEER_INFO" | jq -r '.result.peers // 0' 2>/dev/null || echo "0")
    IS_SYNCING=$(echo "$PEER_INFO" | jq -r '.result.isSyncing // false' 2>/dev/null || echo "unknown")
    
    echo -e "Connected Peers: ${CYAN}$PEER_COUNT${NC}"
    
    if [ "$PEER_COUNT" -gt 0 ]; then
        echo -e "Peer Status: ${GREEN}✓ Connected${NC}"
    else
        echo -e "Peer Status: ${YELLOW}⚠ No peers${NC}"
    fi
    
    if [ "$IS_SYNCING" = "true" ]; then
        echo -e "Sync Status: ${YELLOW}⏳ Syncing${NC}"
    elif [ "$IS_SYNCING" = "false" ]; then
        echo -e "Sync Status: ${GREEN}✓ Synced${NC}"
    else
        echo -e "Sync Status: ${YELLOW}? Unknown${NC}"
    fi
    
    # Get block info
    BLOCK_INFO=$(curl -s -H "Content-Type: application/json" \
        -d '{"id":1, "jsonrpc":"2.0", "method": "chain_getBlock", "params":[]}' \
        http://localhost:9944 2>/dev/null || echo "{}")
    
    BLOCK_NUMBER=$(echo "$BLOCK_INFO" | jq -r '.result.block.header.number // "unknown"' 2>/dev/null || echo "unknown")
    if [ "$BLOCK_NUMBER" != "unknown" ]; then
        # Convert hex to decimal
        BLOCK_DEC=$((16#${BLOCK_NUMBER#0x}))
        echo -e "Latest Block: ${CYAN}#$BLOCK_DEC${NC}"
    fi
else
    echo -e "RPC Status: ${RED}✗ Not accessible${NC}"
    echo -e "${YELLOW}Validator may be starting up...${NC}"
fi

echo

# Configuration Status
echo -e "${CYAN}Configuration:${NC}"
echo "--------------"

if [ -f "config/validator.conf" ]; then
    source config/validator.conf
    echo -e "Validator Name: ${GREEN}$VALIDATOR_NAME${NC}"
    echo -e "Network: ${GREEN}$NETWORK${NC}"
    echo -e "P2P Port: ${GREEN}$P2P_PORT${NC}"
    echo -e "RPC Port: ${GREEN}$RPC_PORT${NC}"
else
    echo -e "${RED}✗ Configuration not found${NC}"
    echo -e "${YELLOW}Run: ./setup-validator.sh${NC}"
fi

echo

# Key Status
echo -e "${CYAN}Keys & Registration:${NC}"
echo "-------------------"

# Session keys
if [ -f "validator-data/session-keys.json" ]; then
    SESSION_KEYS=$(jq -r '.session_keys // "not found"' validator-data/session-keys.json 2>/dev/null)
    if [ "$SESSION_KEYS" != "not found" ] && [ -n "$SESSION_KEYS" ]; then
        echo -e "Session Keys: ${GREEN}✓ Generated${NC}"
        echo -e "  ${CYAN}${SESSION_KEYS:0:20}...${SESSION_KEYS: -20}${NC}"
    else
        echo -e "Session Keys: ${YELLOW}⚠ Invalid${NC}"
    fi
else
    echo -e "Session Keys: ${RED}✗ Not generated${NC}"
    echo -e "${YELLOW}Run: ./scripts/generate-session-keys-auto.sh${NC}"
fi

# Stash account
if [ -f "validator-data/stash-account.json" ]; then
    STASH_ADDRESS=$(jq -r '.stash_account.ss58_address // "not found"' validator-data/stash-account.json 2>/dev/null)
    if [ "$STASH_ADDRESS" != "not found" ] && [ -n "$STASH_ADDRESS" ]; then
        echo -e "Stash Account: ${GREEN}✓ Created${NC}"
        echo -e "  ${CYAN}$STASH_ADDRESS${NC}"
    else
        echo -e "Stash Account: ${YELLOW}⚠ Invalid${NC}"
    fi
else
    echo -e "Stash Account: ${RED}✗ Not created${NC}"
    echo -e "${YELLOW}Run: ./complete-registration.sh${NC}"
fi

# Registration submission
if [ -f "validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt" ]; then
    echo -e "Registration File: ${GREEN}✓ Ready to submit${NC}"
else
    echo -e "Registration File: ${RED}✗ Not created${NC}"
    echo -e "${YELLOW}Run: ./complete-registration.sh${NC}"
fi

echo

# Security Status
echo -e "${CYAN}Security Status:${NC}"
echo "----------------"

# Check file permissions
SECURE=true
if [ -f "validator-data/session-keys.json" ]; then
    PERMS=$(stat -c "%a" validator-data/session-keys.json 2>/dev/null || stat -f "%A" validator-data/session-keys.json 2>/dev/null || echo "unknown")
    if [ "$PERMS" = "600" ]; then
        echo -e "Session Keys Permissions: ${GREEN}✓ Secure (600)${NC}"
    else
        echo -e "Session Keys Permissions: ${YELLOW}⚠ Insecure ($PERMS)${NC}"
        SECURE=false
    fi
fi

# Check firewall
if command -v ufw >/dev/null 2>&1; then
    if sudo ufw status | grep -q "Status: active" 2>/dev/null; then
        echo -e "Firewall: ${GREEN}✓ Active${NC}"
        
        # Check specific rules
        if sudo ufw status | grep -q "30333/tcp" 2>/dev/null; then
            echo -e "  P2P Port (30333): ${GREEN}✓ Allowed${NC}"
        else
            echo -e "  P2P Port (30333): ${YELLOW}⚠ Not configured${NC}"
        fi
    else
        echo -e "Firewall: ${YELLOW}⚠ Inactive${NC}"
        SECURE=false
    fi
else
    echo -e "Firewall: ${YELLOW}⚠ UFW not installed${NC}"
fi

# Check RPC security
if [ -f "validate.sh" ]; then
    if grep -q "rpc-methods safe" validate.sh; then
        echo -e "RPC Methods: ${GREEN}✓ Safe mode${NC}"
    else
        echo -e "RPC Methods: ${YELLOW}⚠ Check configuration${NC}"
        SECURE=false
    fi
fi

echo

# Summary
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Summary:${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"

# Count statuses
if pgrep -f "fennel-node.*--validator" >/dev/null; then
    if [ -f "validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt" ]; then
        echo -e "${GREEN}✅ Validator is running and ready for registration${NC}"
        echo -e "${CYAN}Next step: Send COMPLETE-REGISTRATION-SUBMISSION.txt to Fennel Labs${NC}"
    elif [ -f "validator-data/session-keys.json" ]; then
        echo -e "${YELLOW}⚠️  Validator running but registration incomplete${NC}"
        echo -e "${CYAN}Next step: Run ./complete-registration.sh${NC}"
    else
        echo -e "${YELLOW}⚠️  Validator running but keys not generated${NC}"
        echo -e "${CYAN}Next step: Run ./scripts/generate-session-keys-auto.sh${NC}"
    fi
else
    if [ -f "config/validator.conf" ]; then
        echo -e "${YELLOW}⚠️  Validator configured but not running${NC}"
        echo -e "${CYAN}Next step: Run ./secure-launch.sh${NC}"
    else
        echo -e "${RED}❌ Validator not set up${NC}"
        echo -e "${CYAN}Next step: Run ./quick-start.sh${NC}"
    fi
fi

if [ "$SECURE" != "true" ]; then
    echo
    echo -e "${YELLOW}⚠️  Security warnings detected - review security status above${NC}"
fi

echo
echo -e "${BLUE}Run this script anytime to check validator status${NC}" 