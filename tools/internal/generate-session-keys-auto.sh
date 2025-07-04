#!/bin/bash
# Enhanced Session Key Generation - Automatically handles RPC method switching
# No manual intervention required

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔑 Enhanced Validator Session Key Generator${NC}"
echo "============================================="
echo "Automatically handles RPC method switching for secure key generation"
echo

# Check if validator is running
if ! pgrep -f "fennel-node.*--validator" > /dev/null; then
    echo -e "${RED}❌ Validator is not running${NC}"
    echo "Start your validator first: ./validate.sh start"
    exit 1
fi

# Check RPC access
if ! curl -s -m 5 http://localhost:9944 > /dev/null; then
    echo -e "${RED}❌ Cannot connect to validator RPC${NC}"
    echo "Make sure validator is running: ./validate.sh status"
    exit 1
fi

# Function to check if RPC methods are unsafe
check_rpc_methods() {
    local test_response=$(curl -s -H "Content-Type: application/json" \
        -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}' \
        http://localhost:9944)
    
    if echo "$test_response" | grep -q "unsafe to be called externally"; then
        return 1  # Methods are safe (need to enable unsafe)
    else
        return 0  # Methods are already unsafe
    fi
}

# Function to temporarily enable unsafe RPC methods
enable_unsafe_rpc() {
    echo -e "${YELLOW}🔧 Temporarily enabling unsafe RPC methods for key generation...${NC}"
    
    # Stop validator
    echo "Stopping validator..."
    ../validate.sh stop > /dev/null 2>&1
    
    # Backup original validate.sh
    cp ../validate.sh ../validate.sh.backup
    
    # Enable unsafe RPC methods
    sed -i 's/--rpc-methods safe/--rpc-methods unsafe/' ../validate.sh
    
    # Start validator with unsafe methods
    echo "Starting validator with unsafe RPC methods..."
    ../validate.sh start > /dev/null 2>&1 &
    
    # Wait for startup
    echo "Waiting for validator to start..."
    for i in {1..30}; do
        if curl -s -m 2 http://localhost:9944 > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    if ! curl -s -m 2 http://localhost:9944 > /dev/null 2>&1; then
        echo -e "${RED}❌ Failed to start validator with unsafe RPC methods${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Validator started with unsafe RPC methods${NC}"
}

# Function to restore safe RPC methods
restore_safe_rpc() {
    echo -e "${YELLOW}🔒 Restoring safe RPC methods for security...${NC}"
    
    # Stop validator
    ../validate.sh stop > /dev/null 2>&1
    
    # Restore original validate.sh
    if [ -f "../validate.sh.backup" ]; then
        mv ../validate.sh.backup ../validate.sh
    else
        # Fallback: manually fix it
        sed -i 's/--rpc-methods unsafe/--rpc-methods safe/' ../validate.sh
    fi
    
    # Start validator with safe methods
    ../validate.sh start > /dev/null 2>&1 &
    
    # Wait for startup
    for i in {1..30}; do
        if curl -s -m 2 http://localhost:9944 > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    echo -e "${GREEN}✅ Validator restarted with secure RPC methods${NC}"
}

# Cleanup function
cleanup() {
    if [ -f "../validate.sh.backup" ]; then
        echo -e "${YELLOW}🧹 Performing cleanup...${NC}"
        restore_safe_rpc
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Check if we need to enable unsafe RPC methods
if ! check_rpc_methods; then
    enable_unsafe_rpc
    sleep 5  # Give it time to fully start
fi

echo -e "\n${GREEN}🔐 Generating session keys...${NC}"

# Generate session keys
KEYS_RESPONSE=$(curl -s -H "Content-Type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}' \
    http://localhost:9944)

SESSION_KEYS=$(echo "$KEYS_RESPONSE" | jq -r '.result')

if [ "$SESSION_KEYS" = "null" ] || [ -z "$SESSION_KEYS" ]; then
    echo -e "${RED}❌ Failed to generate session keys${NC}"
    echo "Response: $KEYS_RESPONSE"
    exit 1
fi

# Extract individual keys  
AURA_KEY="0x${SESSION_KEYS:2:64}"
GRANDPA_KEY="0x${SESSION_KEYS:66:64}"

# Get validator name from config or use default
VALIDATOR_NAME="External-Validator-$(hostname)"
if [ -f "../config/validator.conf" ]; then
    NAME_FROM_CONFIG=$(grep "VALIDATOR_NAME=" ../config/validator.conf | cut -d'"' -f2 2>/dev/null || echo "")
    if [ -n "$NAME_FROM_CONFIG" ]; then
        VALIDATOR_NAME="$NAME_FROM_CONFIG"
    fi
fi

# Create session keys file
cat > ../session-keys.json << EOF
{
    "validator_name": "$VALIDATOR_NAME",
    "session_keys": "$SESSION_KEYS",
    "aura_key": "$AURA_KEY",
    "grandpa_key": "$GRANDPA_KEY",
    "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")"
}
EOF

echo -e "${GREEN}✅ Session keys generated and saved!${NC}"
echo
echo "Validator: $VALIDATOR_NAME"
echo "Session Keys: $SESSION_KEYS"
echo "AURA Key: $AURA_KEY"
echo "GRANDPA Key: $GRANDPA_KEY"
echo
echo -e "${BLUE}💾 Keys saved to: session-keys.json${NC}"

# The cleanup function will automatically restore safe RPC methods
echo -e "${YELLOW}📋 Next: Run './scripts/get-account-id.sh' to get your AccountId for network operators${NC}" 