#!/bin/bash
# Stash Account Setup Guide - Explains the missing piece in validator setup
# Helps understand and set up the stash account for proper validator registration

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}🏦 Stash Account Setup Guide${NC}"
echo "============================"
echo "Understanding the missing piece: Stash Account & session.setKeys()"
echo

echo -e "${YELLOW}📚 What you need to know:${NC}"
echo
echo -e "${PURPLE}1. Stash Account:${NC}"
echo "   - The main account that holds your validator funds"
echo "   - This account gets registered as a validator on-chain"
echo "   - Should have some tokens for transaction fees"
echo
echo -e "${PURPLE}2. Session Keys:${NC}"
echo "   - The keys we generated (AURA, GRANDPA)"
echo "   - Used for actual validator operations (block production, finality)"
echo "   - Bound to your stash account via session.setKeys()"
echo
echo -e "${PURPLE}3. session.setKeys():${NC}"
echo "   - A blockchain transaction called by your stash account"
echo "   - Links your session keys to your validator identity"
echo "   - Must be done before network operators can register you"
echo

# Check if we have session keys
if [ ! -f "../session-keys.json" ]; then
    echo -e "${RED}❌ Session keys not found!${NC}"
    echo "Generate session keys first: ./scripts/generate-session-keys-auto.sh"
    exit 1
fi

# Read session keys
SESSION_KEYS=$(jq -r '.session_keys' ../session-keys.json)
AURA_KEY=$(jq -r '.aura_key' ../session-keys.json)
GRANDPA_KEY=$(jq -r '.grandpa_key' ../session-keys.json)
VALIDATOR_NAME=$(jq -r '.validator_name' ../session-keys.json)

echo -e "${GREEN}✅ Found your session keys:${NC}"
echo "Validator: $VALIDATOR_NAME"
echo "Session Keys: $SESSION_KEYS"
echo

echo -e "${YELLOW}🎯 What Network Operators Need to Know:${NC}"
echo

echo -e "${BLUE}Option 1: Create a New Stash Account (Recommended for Testing)${NC}"
echo "1. Create a new account using Polkadot.js extension or subkey"
echo "2. Fund it with some tokens (for transaction fees)"
echo "3. Use that account to call session.setKeys() with your session keys"
echo "4. Give network operators that stash account's address"
echo

echo -e "${BLUE}Option 2: Use One of Your Generated Accounts${NC}"
echo "If you want to use one of your generated keys as the stash:"
echo "- AURA Account: 5GKNypf9cejNbDHa58gFPGs1zbaak8gnmdy3ESeyarJPA3iP"
echo "- GRANDPA Account: 5EGxWbYCxw7otbkjrpPRiPvBkfL4YLnekWAPKBURh2Mvuxf"
echo
echo -e "${RED}⚠️  Security Note: Using session key accounts as stash is not recommended for production!${NC}"
echo

echo -e "${YELLOW}🔧 Next Steps:${NC}"
echo "1. Create a stash account (or choose one)"
echo "2. Fund it with tokens"
echo "3. Call session.setKeys() with your session keys:"
echo "   session_keys: $SESSION_KEYS"
echo "4. Tell network operators which account called setKeys()"
echo

# Create instruction file
cat > ../stash-account-instructions.txt << EOF
STASH ACCOUNT SETUP INSTRUCTIONS
===============================

Validator: $VALIDATOR_NAME

GENERATED SESSION KEYS:
Session Keys: $SESSION_KEYS
AURA Key: $AURA_KEY  
GRANDPA Key: $GRANDPA_KEY

WHAT YOU NEED TO DO:

1. CREATE A STASH ACCOUNT:
   - Option A: Create new account via Polkadot.js extension
   - Option B: Use subkey: subkey generate
   - Option C: Use one of the generated accounts above (not recommended for production)

2. FUND THE STASH ACCOUNT:
   - Get some Fennel tokens for transaction fees
   - Ask network operators for testnet tokens if needed

3. CALL session.setKeys():
   - Go to Polkadot.js Apps (connected to Fennel network)
   - Navigate to Developer > Extrinsics
   - Select your stash account
   - Call: session > setKeys
   - Keys: $SESSION_KEYS
   - Proof: 0x (empty)
   - Submit transaction

4. INFORM NETWORK OPERATORS:
   - Tell them which account called setKeys()
   - Give them the stash account address
   - They will then register that account as a validator

SECURITY NOTE:
- Keep your stash account secure (it controls validator funds)
- Session keys are for operations only
- Never share private keys, only addresses

Generated: $(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EOF

echo -e "${GREEN}💾 Instructions saved to: stash-account-instructions.txt${NC}"
echo
echo -e "${PURPLE}🚀 Quick Answer for Network Operators:${NC}"
echo "\"We haven't called session.setKeys() yet. We need to:"
echo "1. Create/choose a stash account"
echo "2. Call session.setKeys() with our session keys: $SESSION_KEYS"
echo "3. Then give you the stash account address for validator registration.\""
echo
echo -e "${YELLOW}📝 Would you like us to generate a stash account keypair for testing? (y/n)${NC}" 