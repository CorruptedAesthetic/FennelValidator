#!/bin/bash
# Generate Session Keys for Validator Registration

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔑 Generating Validator Session Keys${NC}"
echo "===================================="

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

echo -e "\n${GREEN}🔐 Generating session keys...${NC}"

# Generate session keys
KEYS_RESPONSE=$(curl -s -H "Content-Type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}' \
    http://localhost:9944)

SESSION_KEYS=$(echo "$KEYS_RESPONSE" | jq -r '.result')

if [ "$SESSION_KEYS" = "null" ] || [ -z "$SESSION_KEYS" ]; then
    echo -e "${RED}❌ Failed to generate session keys${NC}"
    exit 1
fi

# Extract individual keys  
AURA_KEY="0x${SESSION_KEYS:2:64}"
GRANDPA_KEY="0x${SESSION_KEYS:66:64}"

# Get validator name from config or use default
VALIDATOR_NAME="External-Validator-$(hostname)"
if [ -f "config/validator.conf" ]; then
    NAME_FROM_CONFIG=$(grep "VALIDATOR_NAME=" config/validator.conf | cut -d'"' -f2 2>/dev/null || echo "")
    if [ -n "$NAME_FROM_CONFIG" ]; then
        VALIDATOR_NAME="$NAME_FROM_CONFIG"
    fi
fi

# Create simple info file
cat > session-keys.json << EOF
{
    "validator_name": "$VALIDATOR_NAME",
    "session_keys": "$SESSION_KEYS",
    "aura_key": "$AURA_KEY",
    "grandpa_key": "$GRANDPA_KEY",
    "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")"
}
EOF

echo -e "${GREEN}✅ Session keys generated!${NC}"
echo
echo "Validator: $VALIDATOR_NAME"
echo "Session Keys: $SESSION_KEYS"
echo
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Send us the session-keys.json file contents"
echo "2. We'll add you to the validator set via Polkadot.js Apps"
echo "3. You'll start producing blocks once added!"
echo
echo -e "${BLUE}💾 Keys saved to: session-keys.json${NC}" 