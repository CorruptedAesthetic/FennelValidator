#!/bin/bash
# Generate Stash Account - Creates a stash account for validator testing
# For use in staging/testnet environments

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}🏦 Stash Account Generator${NC}"
echo "=========================="
echo "Generating a stash account for validator testing"
echo

# Check if we have key generation tools
if ! command -v subkey > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  subkey not found, checking for fennel-node...${NC}"
    if [ ! -f "../bin/fennel-node" ]; then
        echo -e "${RED}❌ Neither subkey nor fennel-node found!${NC}"
        echo "Install subkey: cargo install --force subkey --git https://github.com/paritytech/substrate --version 3.0.0"
        exit 1
    fi
    USE_FENNEL_NODE=true
else
    USE_FENNEL_NODE=false
fi

# Check if session keys exist
if [ ! -f "session-keys.json" ]; then
    echo -e "${RED}❌ Session keys not found!${NC}"
    echo "Generate session keys first: ./scripts/generate-session-keys-auto.sh"
    exit 1
fi

VALIDATOR_NAME=$(jq -r '.validator_name' session-keys.json)
SESSION_KEYS=$(jq -r '.session_keys' session-keys.json)

echo -e "${GREEN}📋 Validator: $VALIDATOR_NAME${NC}"
echo "Session Keys: $SESSION_KEYS"
echo

echo -e "${YELLOW}🔑 Generating stash account...${NC}"

# Generate stash account
if [ "$USE_FENNEL_NODE" = "true" ]; then
    STASH_OUTPUT=$(../bin/fennel-node key generate 2>/dev/null)
else
    STASH_OUTPUT=$(subkey generate 2>/dev/null)
fi

# Extract information
STASH_SECRET_PHRASE=$(echo "$STASH_OUTPUT" | grep "Secret phrase:" | sed 's/Secret phrase:[[:space:]]*//')
STASH_SECRET_SEED=$(echo "$STASH_OUTPUT" | grep "Secret seed:" | sed 's/Secret seed:[[:space:]]*//')
STASH_PUBLIC_KEY=$(echo "$STASH_OUTPUT" | grep "Public key" | sed 's/Public key[^:]*:[[:space:]]*//')
STASH_ACCOUNT_ID=$(echo "$STASH_OUTPUT" | grep "Account ID:" | sed 's/Account ID:[[:space:]]*//')
STASH_SS58=$(echo "$STASH_OUTPUT" | grep "SS58 Address:" | sed 's/SS58 Address:[[:space:]]*//')

echo -e "${GREEN}✅ Stash account generated!${NC}"
echo
echo -e "${BLUE}Stash Account Information:${NC}"
echo "Secret Phrase: $STASH_SECRET_PHRASE"
echo "Secret Seed: $STASH_SECRET_SEED"
echo "Public Key: $STASH_PUBLIC_KEY"
echo "Account ID: $STASH_ACCOUNT_ID"
echo "SS58 Address: $STASH_SS58"
echo

# Create comprehensive stash account file
cat > ../stash-account.json << EOF
{
    "validator_name": "$VALIDATOR_NAME",
    "stash_account": {
        "secret_phrase": "$STASH_SECRET_PHRASE",
        "secret_seed": "$STASH_SECRET_SEED",
        "public_key": "$STASH_PUBLIC_KEY",
        "account_id": "$STASH_ACCOUNT_ID",
        "ss58_address": "$STASH_SS58"
    },
    "session_keys": "$SESSION_KEYS",
    "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")"
}
EOF

# Create step-by-step instructions
cat > ../complete-validator-setup-instructions.txt << EOF
COMPLETE VALIDATOR SETUP INSTRUCTIONS
====================================

Validator Name: $VALIDATOR_NAME

STEP 1: STASH ACCOUNT (GENERATED)
---------------------------------
SS58 Address: $STASH_SS58
Account ID: $STASH_ACCOUNT_ID
Secret Phrase: $STASH_SECRET_PHRASE

🔒 SECURITY: Store the secret phrase safely! This controls your validator funds.

STEP 2: SESSION KEYS (ALREADY GENERATED)
----------------------------------------
Session Keys: $SESSION_KEYS

STEP 3: FUND YOUR STASH ACCOUNT
------------------------------
1. Ask network operators for testnet tokens
2. Send to address: $STASH_SS58
3. You need tokens for transaction fees

STEP 4: CALL session.setKeys()
-----------------------------
Option A - Using Polkadot.js Apps:
1. Go to Polkadot.js Apps (connected to Fennel network)
2. Import your stash account using the secret phrase
3. Navigate to Developer > Extrinsics
4. Select your stash account: $STASH_SS58
5. Call: session > setKeys
6. Keys: $SESSION_KEYS
7. Proof: 0x (empty)
8. Submit transaction

Option B - Using Command Line (if supported):
1. Import stash account to your node
2. Submit setKeys extrinsic

STEP 5: INFORM NETWORK OPERATORS
-------------------------------
Tell them:
"I've called session.setKeys() from my stash account.
Stash Account (to register as validator): $STASH_SS58
Session Keys: $SESSION_KEYS
Please register this stash account as a validator."

VERIFICATION
-----------
After registration, check:
1. Your validator appears in the validator set
2. Your session keys are properly bound
3. Your validator is producing blocks when selected

Generated: $(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EOF

echo -e "${RED}🔒 IMPORTANT SECURITY NOTES:${NC}"
echo "1. Save your secret phrase securely: $STASH_SECRET_PHRASE"
echo "2. Never share your secret phrase with anyone"
echo "3. This is for TESTING only - use hardware wallet for production"
echo

echo -e "${GREEN}💾 Files created:${NC}"
echo "- stash-account.json (complete account info)"
echo "- complete-validator-setup-instructions.txt (step-by-step guide)"
echo

echo -e "${YELLOW}📋 Quick Summary for Network Operators:${NC}"
echo "Stash Account Address: $STASH_SS58"
echo "Session Keys: $SESSION_KEYS"
echo "Status: Need to fund account and call session.setKeys()"
echo

echo -e "${BLUE}🎯 Next Steps:${NC}"
echo "1. Ask network operators for testnet tokens to: $STASH_SS58"
echo "2. Once funded, call session.setKeys() (see instructions)"
echo "3. Inform operators that you've completed setKeys"
echo "4. Wait for validator registration" 