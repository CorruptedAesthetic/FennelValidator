#!/bin/bash
# 🚀 Fennel Validator Quick Start
# One-command setup for new validators - secure and beginner-friendly

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
║                                                               ║
║          🌱 FENNEL VALIDATOR - QUICK START 🌱                 ║
║                                                               ║
║        Secure • Automated • Beginner-Friendly                 ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}Welcome to the Fennel Validator Quick Start!${NC}"
echo -e "${CYAN}This will guide you through the complete setup process.${NC}"
echo
echo -e "${YELLOW}📋 What this script will do:${NC}"
echo "  1. ✓ Check system requirements"
echo "  2. ✓ Install Fennel validator binary"
echo "  3. ✓ Configure your validator settings"
echo "  4. ✓ Launch validator with security hardening"
echo "  5. ✓ Generate session keys"
echo "  6. ✓ Create stash account"
echo "  7. ✓ Generate registration files for Fennel Labs"
echo
echo -e "${GREEN}The entire process takes about 5-10 minutes.${NC}"
echo

# Confirmation
read -p "Ready to become a Fennel validator? Press Enter to start... " -r
echo

# Step 1: Install dependencies
echo -e "${CYAN}Step 1/7: Installing dependencies...${NC}"
if [ -f tools/install-dependencies.sh ]; then
    if ./tools/install-dependencies.sh; then
        echo -e "${GREEN}✓ Dependencies installed${NC}"
    else
        echo -e "${YELLOW}⚠ Some dependencies may be missing${NC}"
        echo -e "${YELLOW}Continuing anyway...${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Dependency installer not found${NC}"
    echo -e "${YELLOW}Proceeding without dependency check...${NC}"
fi

echo

# Step 2: Pre-flight checks
echo -e "${CYAN}Step 2/7: Running pre-flight checks...${NC}"
if [ -f tools/preflight-check.sh ]; then
    if ./tools/preflight-check.sh; then
        echo -e "${GREEN}✓ All checks passed${NC}"
    else
        echo -e "${YELLOW}⚠ Some checks failed, but continuing...${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Pre-flight check not found, skipping...${NC}"
fi

echo

# Step 3: Install
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  Step 3 of 7: Installing Fennel Validator${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo

if [ ! -f "bin/fennel-node" ]; then
    ./install.sh
else
    echo -e "${GREEN}✓ Fennel validator already installed${NC}"
fi

echo
read -p "Press Enter to continue to configuration... " -r

# Step 4: Configure
echo
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  Step 4 of 7: Configuring Your Validator${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo

if [ ! -f "config/validator.conf" ]; then
    ./setup-validator.sh
else
    echo -e "${GREEN}✓ Validator already configured${NC}"
    echo -e "${CYAN}To reconfigure, delete config/validator.conf and run this again${NC}"
fi

echo
read -p "Press Enter to launch your validator... " -r

# Step 5: Secure Launch
echo
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  Step 5 of 7: Launching Validator Securely${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo

./tools/secure-launch.sh

echo
read -p "Press Enter to generate session keys... " -r

# Step 6: Generate Session Keys
echo
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  Step 6 of 7: Generating Session Keys${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo

./scripts/generate-session-keys.sh

echo
read -p "Press Enter to complete registration... " -r

# Step 7: Complete Registration
echo
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  Step 7 of 7: Generating Registration Information${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo

./tools/complete-registration.sh

# Final Summary
echo
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   🎉 SETUP COMPLETE! 🎉                       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}Your Fennel validator is now running securely!${NC}"
echo
echo -e "${YELLOW}📤 IMPORTANT NEXT STEPS:${NC}"
echo -e "${WHITE}1. Send this file to Fennel Labs:${NC}"
echo -e "${GREEN}   → COMPLETE-REGISTRATION-SUBMISSION.txt${NC}"
echo
echo -e "${WHITE}2. Wait for Fennel Labs to:${NC}"
echo "   • Review your submission"
echo "   • Send testnet tokens to your stash account"
echo "   • Provide instructions for session.setKeys()"
echo
echo -e "${WHITE}3. When you receive tokens:${NC}"
echo "   • Follow SESSION-SETKEYS-INSTRUCTIONS.txt"
echo "   • Notify Fennel Labs when complete"
echo
echo -e "${BLUE}🛠️  Validator Management:${NC}"
echo "  ./validate.sh status    - Check if running"
echo "  ./validate.sh logs      - View logs"
echo "  ./validate.sh stop      - Stop validator"
echo "  ./validate.sh restart   - Restart validator"
echo
echo -e "${GREEN}🔒 Security Files (Keep Safe):${NC}"
echo "  • session-keys.json     - Your validator keys"
echo "  • stash-account.json    - Your stash account"
echo
echo -e "${PURPLE}Thank you for joining the Fennel network! 🌱${NC}"
echo
echo -e "${CYAN}Questions? Check EXAMPLE-VALIDATOR-SETUP.md for examples${NC}" 