#!/bin/bash
# 🔧 Fennel Validator Dependency Installer
# Automatically installs all required dependencies

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🔧 Installing Dependencies for Fennel Validator${NC}"
echo "=============================================="
echo

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            VER=$VERSION_ID
        elif [ -f /etc/debian_version ]; then
            OS="debian"
        elif [ -f /etc/redhat-release ]; then
            OS="centos"
        else
            OS="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    echo $OS
}

# Update package manager
update_package_manager() {
    echo -e "${CYAN}Updating package manager...${NC}"
    
    case $OS in
        ubuntu|debian)
            sudo apt-get update -qq
            ;;
        centos|rhel|fedora)
            sudo yum check-update -q || true
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew update
            else
                echo -e "${YELLOW}Installing Homebrew...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            ;;
    esac
}

# Install a package
install_package() {
    local package=$1
    local brew_package=${2:-$1}  # macOS might have different names
    
    echo -n "Installing $package... "
    
    case $OS in
        ubuntu|debian)
            if sudo apt-get install -y $package >/dev/null 2>&1; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗${NC}"
                return 1
            fi
            ;;
        centos|rhel|fedora)
            if sudo yum install -y $package >/dev/null 2>&1; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗${NC}"
                return 1
            fi
            ;;
        macos)
            if brew install $brew_package >/dev/null 2>&1; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}✗ (unsupported OS)${NC}"
            return 1
            ;;
    esac
}

# Check if tool exists
check_tool() {
    command -v "$1" >/dev/null 2>&1
}

# Main installation
OS=$(detect_os)
echo -e "${CYAN}Detected OS: $OS${NC}"
echo

# Check if we need sudo
if [ "$OS" != "macos" ] && [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}This script needs sudo privileges to install packages.${NC}"
    echo -e "${YELLOW}You may be prompted for your password.${NC}"
    echo
    
    # Test sudo access
    if ! sudo -v; then
        echo -e "${RED}Failed to get sudo access${NC}"
        exit 1
    fi
fi

# Update package manager first
update_package_manager

echo
echo -e "${CYAN}Installing essential tools...${NC}"

# Essential tools needed by scripts
TOOLS=(
    "curl"
    "wget"
    "jq"
    "git"
)

# Additional helpful tools
EXTRA_TOOLS=(
    "net-tools"      # For netstat
    "procps"         # For ps, pgrep
    "coreutils"      # For various utilities
)

# Install essential tools
for tool in "${TOOLS[@]}"; do
    if check_tool "$tool"; then
        echo -e "$tool... ${GREEN}✓ already installed${NC}"
    else
        install_package "$tool"
    fi
done

echo
echo -e "${CYAN}Installing additional utilities...${NC}"

# Install extra tools based on OS
case $OS in
    ubuntu|debian)
        for tool in "${EXTRA_TOOLS[@]}"; do
            if ! check_tool "${tool%% *}"; then
                install_package "$tool"
            else
                echo -e "$tool... ${GREEN}✓ already installed${NC}"
            fi
        done
        
        # Ubuntu/Debian specific
        install_package "netcat-openbsd"
        install_package "iproute2"
        ;;
        
    centos|rhel|fedora)
        install_package "net-tools"
        install_package "procps-ng"
        install_package "coreutils"
        install_package "nc"
        install_package "iproute"
        ;;
        
    macos)
        # macOS has most tools built-in
        echo -e "${GREEN}macOS includes most required tools${NC}"
        ;;
esac

# Install firewall if not present
echo
echo -e "${CYAN}Checking firewall...${NC}"
case $OS in
    ubuntu|debian)
        if ! command -v ufw >/dev/null 2>&1; then
            echo -e "${YELLOW}Installing UFW firewall...${NC}"
            install_package "ufw"
        else
            echo -e "UFW... ${GREEN}✓ already installed${NC}"
        fi
        ;;
    centos|rhel|fedora)
        if ! command -v firewall-cmd >/dev/null 2>&1; then
            echo -e "${YELLOW}Installing firewalld...${NC}"
            install_package "firewalld"
            sudo systemctl enable firewalld
            sudo systemctl start firewalld
        else
            echo -e "firewalld... ${GREEN}✓ already installed${NC}"
        fi
        ;;
    macos)
        echo -e "${CYAN}macOS uses built-in firewall${NC}"
        ;;
esac

# Check for Docker (optional but helpful)
echo
echo -e "${CYAN}Checking optional dependencies...${NC}"
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${YELLOW}Docker not found (optional)${NC}"
    echo -e "${CYAN}Docker can be helpful for extracting binaries.${NC}"
    echo -e "${CYAN}Install from: https://docs.docker.com/get-docker/${NC}"
else
    echo -e "Docker... ${GREEN}✓ installed${NC}"
fi

# Verify all essential tools
echo
echo -e "${CYAN}Verifying installation...${NC}"
ALL_GOOD=true

for tool in "${TOOLS[@]}"; do
    if check_tool "$tool"; then
        echo -e "$tool... ${GREEN}✓${NC}"
    else
        echo -e "$tool... ${RED}✗${NC}"
        ALL_GOOD=false
    fi
done

# Summary
echo
if [ "$ALL_GOOD" = true ]; then
    echo -e "${GREEN}✅ All dependencies installed successfully!${NC}"
    echo -e "${GREEN}Your system is ready for Fennel validator setup.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some dependencies failed to install${NC}"
    echo -e "${YELLOW}Please install missing tools manually and try again.${NC}"
    exit 1
fi 