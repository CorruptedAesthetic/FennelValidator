#!/bin/bash
# 🌱 Fennel Validator - Simple Start Script
# The ONLY script you need to get started!

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Function to wait for user input
wait_for_enter() {
    echo
    read -p "Press Enter to continue... " -r
}

# Main menu function
show_menu() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                  🌱 FENNEL VALIDATOR 🌱                       ║
║                                                               ║
║              Simple • Secure • Ready to Go                    ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}Setup & Configuration:${NC}"
    echo "  1) 🚀 Complete Setup (Recommended for new validators)"
    echo "  2) 📦 Install Dependencies"
    echo "  3) 🔧 Setup/Reconfigure Validator"
    echo "  4) 🔑 Generate Keys & Complete Registration"
    echo "  5) 📋 Re-generate Registration (if keys already exist)"
    echo
    echo -e "${CYAN}Operations:${NC}"
    echo "  6) ▶️  Start Validator"
    echo "  7) ⏹️  Stop Validator"
    echo "  8) 🔄 Restart Validator"
    echo "  9) 📊 Check Status"
    echo
    echo -e "${CYAN}Maintenance:${NC}"
    echo "  10) 🔍 Troubleshoot Issues"
    echo "  11) 🔁 Reset Validator"
    echo "  12) 📄 View Logs"
    echo "  13) 🩺 System Check"
    echo
    echo "  0) ❌ Exit"
    echo
}

# Check if this is first run
if [ ! -f "bin/fennel-node" ]; then
    clear
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                  🌱 FENNEL VALIDATOR 🌱                       ║
║                                                               ║
║              Simple • Secure • Ready to Go                    ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}Welcome! Let's set up your Fennel validator.${NC}"
    echo
    echo -e "${YELLOW}This appears to be your first time. We'll help you:${NC}"
    echo "  1. ✓ Install all dependencies"
    echo "  2. ✓ Install the validator software"
    echo "  3. ✓ Configure your settings" 
    echo "  4. ✓ Start your validator securely"
    echo "  5. ✓ Generate all required keys"
    echo "  6. ✓ Create registration for Fennel Labs"
    echo
    echo -e "${GREEN}Ready? Let's go! (Takes about 5-10 minutes)${NC}"
    echo
    read -p "Press Enter to begin setup... " -r
    
    # Run the complete setup
    ./tools/quick-setup.sh
    wait_for_enter
fi

# Main loop
while true; do
    show_menu
    
    read -p "Choose an option (0-13): " choice
    
    case $choice in
        1)
            clear
            ./tools/quick-setup.sh
            wait_for_enter
            ;;
        2)
            clear
            ./tools/install-dependencies.sh
            wait_for_enter
            ;;
        3)
            clear
            ./setup-validator.sh
            wait_for_enter
            ;;
        4)
            clear
            echo -e "${GREEN}Generating session keys and registration...${NC}"
            ./tools/internal/generate-keys-with-restart.sh
            wait_for_enter
            ;;
        5)
            clear
            if [ ! -f "validator-data/session-keys.json" ]; then
                echo -e "${YELLOW}No session keys found. Running key generation first...${NC}"
                ./tools/internal/generate-keys-with-restart.sh
            else
                ./tools/complete-registration.sh
            fi
            wait_for_enter
            ;;
        6)
            clear
            echo -e "${GREEN}Starting validator securely...${NC}"
            ./tools/secure-launch.sh
            wait_for_enter
            ;;
        7)
            clear
            echo -e "${YELLOW}Stopping validator...${NC}"
            ./validate.sh stop
            echo -e "${GREEN}✓ Validator stopped${NC}"
            wait_for_enter
            ;;
        8)
            clear
            echo -e "${YELLOW}Restarting validator...${NC}"
            ./validate.sh stop
            sleep 2
            ./tools/secure-launch.sh
            wait_for_enter
            ;;
        9)
            clear
            ./tools/validator-status.sh
            wait_for_enter
            ;;
        10)
            clear
            ./tools/troubleshoot.sh
            wait_for_enter
            ;;
        11)
            clear
            ./tools/reset-validator.sh
            wait_for_enter
            ;;
        12)
            clear
            echo -e "${CYAN}Viewing validator logs (Ctrl+C to exit)...${NC}"
            ./validate.sh logs
            ;;
        13)
            clear
            ./tools/preflight-check.sh
            wait_for_enter
            ;;
        0)
            echo -e "${GREEN}Thank you for using Fennel Validator! 🌱${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 2
            ;;
    esac
done 