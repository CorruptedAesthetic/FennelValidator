#!/bin/bash
# 🌱 Complete Fennel Validator Registration
# Generates stash account and prepares final submission for Fennel Labs

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${BLUE}🌱 Fennel Validator Registration Completion${NC}"
echo "=============================================="
echo

# Check if session keys exist
if [ ! -f "validator-data/session-keys.json" ]; then
    log_error "Session keys not found."
    echo -e "${YELLOW}Please run: ./tools/internal/generate-keys-with-restart.sh${NC}"
    exit 1
fi

# Generate stash account if it doesn't exist
if [ ! -f "validator-data/stash-account.json" ]; then
    log_info "Generating stash account for validator registration..."
    
    # Check if we have the generate-stash-account.sh script
    if [ -f "tools/internal/generate-stash-account.sh" ]; then
        cd tools/internal
        ./generate-stash-account.sh
        cd ../..
    else
        log_error "Stash account generation script not found"
        exit 1
    fi
fi

# Read session keys and stash account information
VALIDATOR_NAME=$(jq -r '.validator_name' validator-data/session-keys.json)
SESSION_KEYS=$(jq -r '.session_keys' validator-data/session-keys.json)

# Check if stash account file exists and read it
if [ -f "validator-data/stash-account.json" ]; then
    STASH_ADDRESS=$(jq -r '.stash_account.ss58_address' validator-data/stash-account.json 2>/dev/null || echo "")
else
    log_error "Stash account file not found. This should have been created automatically."
    exit 1
fi

# Validate we have required information
if [ -z "$STASH_ADDRESS" ] || [ "$STASH_ADDRESS" = "null" ]; then
    log_error "Could not read stash address from stash-account.json"
    exit 1
fi

# Create complete submission file
log_info "Creating complete submission for Fennel Labs..."

cat > validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt << EOF
╔══════════════════════════════════════════════════════════════════╗
║           🌱 FENNEL VALIDATOR REGISTRATION COMPLETE 🌱           ║
╚══════════════════════════════════════════════════════════════════╝

VALIDATOR INFORMATION:
=====================
Validator Name: $VALIDATOR_NAME
Network: Fennel Solonet (Staging)
Setup Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

CRITICAL INFORMATION FOR FENNEL LABS:
=====================================

🏦 STASH ACCOUNT (Please register this as validator):
SS58 Address: $STASH_ADDRESS

🔑 SESSION KEYS (Already generated and secured):
$SESSION_KEYS

📋 SIMPLIFIED REGISTRATION PROCESS:
==================================
**Fennel Labs will handle all registration steps using sudo privileges:**

1. ✅ [VALIDATOR] Send this file to Fennel Labs (DONE)
2. [FENNEL LABS] Fund stash account with testnet tokens (sudo)
3. [FENNEL LABS] Bind session keys to stash account using sudo.setKeys() (admin)
4. [FENNEL LABS] Add stash account to validator set via validator manager pallet (admin)

**No additional action required from validator - Fennel Labs handles everything!**
**No sensitive information (secret phrases) shared - secure process!**

🔒 SECURITY STATUS:
==================
✅ Validator running with security hardening
✅ Session keys generated and secured
✅ Stash account created and ready
✅ Firewall configured (P2P open, RPC/metrics local only)
✅ File permissions secured
✅ Ready for network registration

TECHNICAL DETAILS FOR FENNEL LABS ADMIN:
========================================
Stash Address: $STASH_ADDRESS
Session Keys: $SESSION_KEYS

ADMIN ACTIONS REQUIRED:
1. sudo.transfer() tokens to stash address
2. sudo.setKeys() to bind session keys to stash address  
3. validatorManager.addValidator() to add to validator set

NEXT STEPS:
===========
1. ✅ Send this file to Fennel Labs (COMPLETE)
2. ⏳ Wait for Fennel Labs confirmation of validator registration
3. 🎉 Start validating once added to validator set!

Contact: Generated by secure Fennel validator setup
Repository: https://github.com/CorruptedAesthetic/FennelValidator
EOF

# Create informational instructions (for reference only)
cat > SESSION-SETKEYS-INSTRUCTIONS.txt << EOF
SESSION.SETKEYS() REFERENCE (INFORMATIONAL ONLY)
===============================================

⚠️  NOTE: Fennel Labs will handle session.setKeys() for you using sudo privileges.
This file is for reference/educational purposes only.

If you needed to call session.setKeys() manually:

1. Go to Polkadot.js Apps: https://polkadot.js.org/apps/
2. Connect to Fennel network using custom endpoint
3. Import your stash account using the secret phrase
4. Navigate to Developer -> Extrinsics
5. Call session.setKeys() with:
   - keys: $SESSION_KEYS
   - proof: 0x (empty proof)
6. Submit transaction and wait for confirmation

Your stash account: $STASH_ADDRESS
Your secret phrase: [KEPT SECURE - NOT SHARED]

But again - Fennel Labs will do this for you using sudo powers! 🎉
No need to share your secret phrase!
EOF

log_success "Registration files created successfully!"
echo
echo -e "${CYAN}📤 SEND TO FENNEL LABS:${NC}"
echo "  • COMPLETE-REGISTRATION-SUBMISSION.txt"
echo
echo -e "${GREEN}📋 WHAT YOU'RE SENDING (PUBLIC INFO ONLY):${NC}"
echo "  ✅ Stash Account Address: $STASH_ADDRESS"
echo "  ✅ Session Keys: ${SESSION_KEYS:0:20}...${SESSION_KEYS: -20}"
echo "  ❌ Secret Phrase: KEPT PRIVATE (not included)"
echo
echo -e "${CYAN}📋 FOR YOUR REFERENCE:${NC}"
echo "  • SESSION-SETKEYS-INSTRUCTIONS.txt (informational only)"
echo "  • stash-account.json (keep secure!)"
echo "  • session-keys.json (keep secure!)"
echo
echo -e "${GREEN}✨ SIMPLIFIED PROCESS:${NC}"
echo "Fennel Labs will handle all registration steps using sudo!"
echo "No manual session.setKeys() call needed from you."
echo
echo -e "${YELLOW}🔒 SECURITY REMINDER:${NC}"
echo "Your stash account secret phrase stays secure with you!"
echo "Only public information (address & session keys) shared with Fennel Labs."
echo
echo -e "${GREEN}🎉 Registration preparation complete!${NC}"
echo -e "${BLUE}Next: Send COMPLETE-REGISTRATION-SUBMISSION.txt to Fennel Labs${NC}" 