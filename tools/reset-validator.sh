#!/bin/bash
# 🔄 Fennel Validator Reset Script
# Safely reset validator state while preserving important configurations

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${RED}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║              ⚠️  FENNEL VALIDATOR RESET ⚠️                     ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${YELLOW}This script will reset your validator to a clean state.${NC}"
echo
echo -e "${CYAN}What will be preserved:${NC}"
echo "  ✓ Validator binary (bin/)"
echo "  ✓ Chain specification (config/staging-chainspec.json)"
echo "  ✓ Scripts and documentation"
echo
echo -e "${YELLOW}What will be removed:${NC}"
echo "  ✗ Validator configuration (config/validator.conf)"
echo "  ✗ Session keys (session-keys.json)"
echo "  ✗ Stash account (stash-account.json)"
echo "  ✗ Registration files (*.txt)"
echo "  ✗ Blockchain data (data/)"
echo "  ✗ Validator process"
echo

# Confirmation
echo -e "${RED}⚠️  This action cannot be undone!${NC}"
read -p "Are you sure you want to reset? Type 'yes' to confirm: " confirmation

if [ "$confirmation" != "yes" ]; then
    echo -e "${GREEN}Reset cancelled.${NC}"
    exit 0
fi

echo
echo -e "${BLUE}Starting reset process...${NC}"
echo

# Step 1: Stop validator
echo -e "${CYAN}1. Stopping validator...${NC}"
if pgrep -f "fennel-node.*--validator" >/dev/null; then
    ./validate.sh stop || pkill -f "fennel-node.*--validator" || true
    sleep 2
    echo -e "${GREEN}✓ Validator stopped${NC}"
else
    echo -e "${GREEN}✓ No validator running${NC}"
fi

# Step 2: Backup important files (optional)
echo
echo -e "${CYAN}2. Creating backup...${NC}"
BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup keys if they exist
if [ -f "session-keys.json" ]; then
    cp session-keys.json "$BACKUP_DIR/"
    echo -e "${GREEN}✓ Backed up session keys${NC}"
fi

if [ -f "stash-account.json" ]; then
    cp stash-account.json "$BACKUP_DIR/"
    echo -e "${GREEN}✓ Backed up stash account${NC}"
fi

if [ -f "config/validator.conf" ]; then
    cp config/validator.conf "$BACKUP_DIR/"
    echo -e "${GREEN}✓ Backed up configuration${NC}"
fi

if [ -f "COMPLETE-REGISTRATION-SUBMISSION.txt" ]; then
    cp COMPLETE-REGISTRATION-SUBMISSION.txt "$BACKUP_DIR/"
    echo -e "${GREEN}✓ Backed up registration file${NC}"
fi

echo -e "${BLUE}Backup saved to: $BACKUP_DIR/${NC}"

# Step 3: Remove validator data
echo
echo -e "${CYAN}3. Removing validator data...${NC}"

# Remove blockchain data
if [ -d "data" ]; then
    rm -rf data
    echo -e "${GREEN}✓ Removed blockchain data${NC}"
fi

# Remove keys
rm -f session-keys.json
rm -f stash-account.json
rm -f validator-account-info.json
echo -e "${GREEN}✓ Removed key files${NC}"

# Remove configuration
rm -f config/validator.conf
echo -e "${GREEN}✓ Removed validator configuration${NC}"

# Remove generated files
rm -f COMPLETE-REGISTRATION-SUBMISSION.txt
rm -f SESSION-SETKEYS-INSTRUCTIONS.txt
rm -f VALIDATOR-SUBMISSION-READY.txt
rm -f QUICK-REFERENCE.txt
rm -f FINAL-VALIDATOR-SUBMISSION.txt
rm -f *-SUBMISSION.txt
rm -f *-REGISTRATION*.txt
rm -f *-INSTRUCTIONS.txt
echo -e "${GREEN}✓ Removed registration files${NC}"

# Remove logs
rm -f *.log
rm -rf logs/
rm -rf monitoring/
echo -e "${GREEN}✓ Removed log files${NC}"

# Step 4: Reset firewall rules (optional)
echo
echo -e "${CYAN}4. Resetting firewall rules...${NC}"
if command -v ufw >/dev/null 2>&1 && sudo ufw status | grep -q "30333/tcp"; then
    read -p "Remove firewall rules for Fennel? (y/n): " remove_fw
    if [[ "$remove_fw" =~ ^[Yy]$ ]]; then
        sudo ufw delete allow 30333/tcp >/dev/null 2>&1 || true
        sudo ufw delete deny 9944/tcp >/dev/null 2>&1 || true
        sudo ufw delete deny 9615/tcp >/dev/null 2>&1 || true
        echo -e "${GREEN}✓ Removed firewall rules${NC}"
    else
        echo -e "${YELLOW}✓ Kept firewall rules${NC}"
    fi
else
    echo -e "${GREEN}✓ No firewall rules to remove${NC}"
fi

# Summary
echo
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    RESET COMPLETE                             ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}Your validator has been reset to a clean state.${NC}"
echo
echo -e "${YELLOW}Backup location: $BACKUP_DIR/${NC}"
echo
echo -e "${BLUE}To set up a new validator, run:${NC}"
echo -e "${GREEN}  ./quick-start.sh${NC}"
echo
echo -e "${BLUE}To restore from backup:${NC}"
echo -e "${GREEN}  cp $BACKUP_DIR/* .${NC}"
echo -e "${GREEN}  cp $BACKUP_DIR/validator.conf config/${NC}"
echo 