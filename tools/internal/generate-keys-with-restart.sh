#!/bin/bash
# Generate Session Keys with Temporary Unsafe RPC
# This script temporarily restarts the validator with unsafe RPC to generate keys

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
CYAN='\033[0;36m'

echo -e "${BLUE}🔑 Generating Session Keys (Secure Method)${NC}"
echo "=========================================="
echo

# Load configuration
if [ -f "config/validator.conf" ]; then
    source "config/validator.conf"
else
    echo -e "${RED}❌ Configuration not found${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  This will briefly restart your validator to generate keys${NC}"
echo "The validator will be offline for about 10-15 seconds."
echo
read -p "Continue? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Stop validator
echo -e "${YELLOW}Stopping validator...${NC}"
pkill -f "fennel-node.*--validator" || true
sleep 3

# Start with unsafe RPC temporarily
echo -e "${YELLOW}Starting validator with temporary key generation mode...${NC}"
./bin/fennel-node \
    --chain "config/${CHAINSPEC}" \
    --validator \
    --name "${VALIDATOR_NAME}" \
    --base-path "${DATA_DIR}" \
    --port "${P2P_PORT}" \
    --rpc-port "${RPC_PORT}" \
    --rpc-cors all \
    --rpc-methods unsafe \
    --prometheus-port "${PROMETHEUS_PORT}" \
    --log error > /dev/null 2>&1 &

TEMP_PID=$!

# Wait for RPC to be ready
echo -n "Waiting for RPC to be ready"
for i in {1..30}; do
    if curl -s http://localhost:${RPC_PORT} > /dev/null 2>&1; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

# Generate session keys
echo -e "${GREEN}Generating session keys...${NC}"
KEYS_RESPONSE=$(curl -s -H "Content-Type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}' \
    http://localhost:${RPC_PORT})

SESSION_KEYS=$(echo "$KEYS_RESPONSE" | jq -r '.result')

# Stop temporary validator
echo -e "${YELLOW}Stopping temporary validator...${NC}"
kill $TEMP_PID 2>/dev/null || true
sleep 3

if [ "$SESSION_KEYS" = "null" ] || [ -z "$SESSION_KEYS" ]; then
    echo -e "${RED}❌ Failed to generate session keys${NC}"
    echo "Response: $KEYS_RESPONSE"
    # Restart validator normally
    echo -e "${YELLOW}Restarting validator in normal mode...${NC}"
    ./validate.sh start > /dev/null 2>&1
    exit 1
fi

# Extract individual keys  
AURA_KEY="0x${SESSION_KEYS:2:64}"
GRANDPA_KEY="0x${SESSION_KEYS:66:64}"

# Create session keys file
cat > validator-data/session-keys.json << EOF
{
    "validator_name": "$VALIDATOR_NAME",
    "session_keys": "$SESSION_KEYS",
    "aura_key": "$AURA_KEY",
    "grandpa_key": "$GRANDPA_KEY",
    "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")"
}
EOF

echo -e "${GREEN}✅ Session keys generated successfully!${NC}"
echo
echo "Validator: $VALIDATOR_NAME"
echo "Session Keys: $SESSION_KEYS"
echo

# Restart validator in normal secure mode
echo -e "${YELLOW}Restarting validator in secure mode...${NC}"
./validate.sh start > /dev/null 2>&1 &

# Wait a moment for startup
sleep 3

# Check if validator started
if pgrep -f "fennel-node.*--validator" > /dev/null; then
    echo -e "${GREEN}✅ Validator restarted in secure mode${NC}"
else
    echo -e "${YELLOW}⚠️  Validator starting in background${NC}"
fi
echo
echo -e "${BLUE}💾 Keys saved to: validator-data/session-keys.json${NC}"
echo
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Run ./tools/complete-registration.sh to generate your submission"
echo "2. Send the registration file to Fennel Labs"

# Add seamless flow to registration
echo
echo -e "${CYAN}Would you like to complete your registration now?${NC}"
echo "This will generate all required files for Fennel Labs."
read -p "Continue to registration? (y/n) [y]: " -n 1 -r CONTINUE_REG
echo

# Default to yes if just Enter is pressed
if [[ -z "$CONTINUE_REG" ]] || [[ $CONTINUE_REG =~ ^[Yy]$ ]]; then
    echo
    # Change to main directory and run registration
    cd "$(dirname "$0")/../.."
    exec "./tools/complete-registration.sh"
fi 