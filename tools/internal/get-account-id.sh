#!/bin/bash
# Extract Validator AccountId - Automatic AccountId extraction from session keys
# Provides all formats needed by network operators

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔍 Validator AccountId Extractor${NC}"
echo "================================="
echo "Automatically extracts AccountId from your session keys"
echo

# Check if session keys exist
if [ ! -f "../validator-data/session-keys.json" ]; then
    echo -e "${RED}❌ Session keys not found!${NC}"
    echo "Generate session keys first: ./tools/internal/generate-keys-with-restart.sh"
    exit 1
fi

# Check if we have subkey available
if ! command -v subkey > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  subkey not found, checking for fennel-node key inspect...${NC}"
    if [ ! -f "../bin/fennel-node" ]; then
        echo -e "${RED}❌ Neither subkey nor fennel-node found!${NC}"
        echo "Install subkey: cargo install --force subkey --git https://github.com/paritytech/substrate --version 3.0.0"
        exit 1
    fi
    USE_FENNEL_NODE=true
else
    USE_FENNEL_NODE=false
fi

# Read session keys
AURA_KEY=$(jq -r '.aura_key' ../validator-data/session-keys.json)
GRANDPA_KEY=$(jq -r '.grandpa_key' ../validator-data/session-keys.json)
VALIDATOR_NAME=$(jq -r '.validator_name' ../validator-data/session-keys.json)

if [ "$AURA_KEY" = "null" ] || [ "$GRANDPA_KEY" = "null" ]; then
    echo -e "${RED}❌ Invalid session keys file!${NC}"
    exit 1
fi

echo -e "${GREEN}📋 Validator: $VALIDATOR_NAME${NC}"
echo

# Function to extract AccountId using subkey
extract_with_subkey() {
    local key=$1
    local key_type=$2
    
    echo -e "${BLUE}$key_type Key Information:${NC}"
    echo "Raw Key: $key"
    
    local output=$(subkey inspect --public "$key")
    local account_id=$(echo "$output" | grep "Account ID:" | awk '{print $3}')
    local ss58_address=$(echo "$output" | grep "SS58 Address:" | awk '{print $3}')
    
    echo "AccountId (hex): $account_id"
    echo "SS58 Address: $ss58_address"
    echo
    
    # Store for later use
    if [ "$key_type" = "AURA" ]; then
        AURA_ACCOUNT_ID="$account_id"
        AURA_SS58="$ss58_address"
    else
        GRANDPA_ACCOUNT_ID="$account_id"
        GRANDPA_SS58="$ss58_address"
    fi
}

# Function to extract AccountId using fennel-node
extract_with_fennel_node() {
    local key=$1
    local key_type=$2
    
    echo -e "${BLUE}$key_type Key Information:${NC}"
    echo "Raw Key: $key"
    
    local output=$(../bin/fennel-node key inspect --public "$key")
    local account_id=$(echo "$output" | grep "Account ID:" | awk '{print $3}')
    local ss58_address=$(echo "$output" | grep "SS58 Address:" | awk '{print $3}')
    
    echo "AccountId (hex): $account_id"
    echo "SS58 Address: $ss58_address"
    echo
    
    # Store for later use
    if [ "$key_type" = "AURA" ]; then
        AURA_ACCOUNT_ID="$account_id"
        AURA_SS58="$ss58_address"
    else
        GRANDPA_ACCOUNT_ID="$account_id"
        GRANDPA_SS58="$ss58_address"
    fi
}

# Extract AccountIds
echo -e "${GREEN}🔐 Extracting AccountId information...${NC}"
echo

if [ "$USE_FENNEL_NODE" = "true" ]; then
    extract_with_fennel_node "$AURA_KEY" "AURA"
    extract_with_fennel_node "$GRANDPA_KEY" "GRANDPA"
else
    extract_with_subkey "$AURA_KEY" "AURA"
    extract_with_subkey "$GRANDPA_KEY" "GRANDPA"
fi

# Create comprehensive AccountId file
cat > ../validator-data/validator-account-info.json << EOF
{
    "validator_name": "$VALIDATOR_NAME",
    "aura": {
        "public_key": "$AURA_KEY",
        "account_id": "$AURA_ACCOUNT_ID",
        "ss58_address": "$AURA_SS58"
    },
    "grandpa": {
        "public_key": "$GRANDPA_KEY",
        "account_id": "$GRANDPA_ACCOUNT_ID",
        "ss58_address": "$GRANDPA_SS58"
    },
    "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")"
}
EOF

# Create quick reference file for network operators
cat > ../validator-data/account-id-for-operators.txt << EOF
VALIDATOR ACCOUNT ID INFORMATION
===============================

Validator Name: $VALIDATOR_NAME

PRIMARY ACCOUNT (AURA - Block Production):
AccountId: $AURA_ACCOUNT_ID
SS58 Address: $AURA_SS58

FINALITY ACCOUNT (GRANDPA):
AccountId: $GRANDPA_ACCOUNT_ID
SS58 Address: $GRANDPA_SS58

Generated: $(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

NOTE: Network operators typically need the AURA AccountId for validator registration.
EOF

echo -e "${GREEN}✅ AccountId extraction complete!${NC}"
echo
echo -e "${YELLOW}📋 For Network Operators (most likely need AURA):${NC}"
echo "AccountId: $AURA_ACCOUNT_ID"
echo "SS58 Address: $AURA_SS58"
echo
echo -e "${BLUE}💾 Files created:${NC}"
echo "- validator-data/validator-account-info.json (complete JSON format)"
echo "- validator-data/account-id-for-operators.txt (quick reference)"
echo
echo -e "${GREEN}🎯 Next: Send the AccountId to network operators for validator registration!${NC}" 