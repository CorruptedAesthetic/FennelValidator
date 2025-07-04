#!/bin/bash
# 🔍 Fennel Validator Pre-flight Check
# Validates system requirements before setup

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🔍 Fennel Validator Pre-flight Check${NC}"
echo "===================================="
echo

# Initialize check results
CHECKS_PASSED=true

# Function to check requirement
check_requirement() {
    local name=$1
    local check_command=$2
    local min_version=$3
    local install_hint=$4
    
    echo -n "Checking $name... "
    
    if eval "$check_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Found${NC}"
        return 0
    else
        echo -e "${RED}✗ Not found${NC}"
        echo -e "${YELLOW}  Install hint: $install_hint${NC}"
        CHECKS_PASSED=false
        return 1
    fi
}

# System checks
echo -e "${CYAN}System Requirements:${NC}"
echo "-------------------"

# Check OS
echo -n "Operating System... "
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "${GREEN}✓ Linux${NC}"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${GREEN}✓ macOS${NC}"
else
    echo -e "${RED}✗ Unsupported: $OSTYPE${NC}"
    CHECKS_PASSED=false
fi

# Check architecture
echo -n "CPU Architecture... "
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
    echo -e "${GREEN}✓ $ARCH (64-bit)${NC}"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    echo -e "${GREEN}✓ $ARCH (ARM 64-bit)${NC}"
else
    echo -e "${YELLOW}⚠ $ARCH (may not be supported)${NC}"
fi

# Check memory
echo -n "Available Memory... "
if command -v free >/dev/null 2>&1; then
    MEM_GB=$(($(free -m | awk '/^Mem:/ {print $2}') / 1024))
    if [ $MEM_GB -ge 4 ]; then
        echo -e "${GREEN}✓ ${MEM_GB}GB (minimum 4GB)${NC}"
    else
        echo -e "${YELLOW}⚠ ${MEM_GB}GB (4GB+ recommended)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot check (4GB+ recommended)${NC}"
fi

# Check disk space
echo -n "Available Disk Space... "
DISK_GB=$(($(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//') ))
if [ $DISK_GB -ge 50 ]; then
    echo -e "${GREEN}✓ ${DISK_GB}GB (minimum 50GB)${NC}"
else
    echo -e "${YELLOW}⚠ ${DISK_GB}GB (50GB+ recommended)${NC}"
fi

echo

# Required tools
echo -e "${CYAN}Required Tools:${NC}"
echo "---------------"

check_requirement "curl" "command -v curl" "" "sudo apt install curl"
check_requirement "jq" "command -v jq" "" "sudo apt install jq"
check_requirement "wget" "command -v wget" "" "sudo apt install wget"
check_requirement "git" "command -v git" "" "sudo apt install git"

echo

# Network checks
echo -e "${CYAN}Network Connectivity:${NC}"
echo "--------------------"

echo -n "Internet connection... "
if ping -c 1 google.com >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ No internet connection${NC}"
    CHECKS_PASSED=false
fi

echo -n "GitHub access... "
if curl -s -m 5 https://api.github.com >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Cannot reach GitHub${NC}"
    CHECKS_PASSED=false
fi

echo

# Port availability
echo -e "${CYAN}Port Availability:${NC}"
echo "-----------------"

check_port() {
    local port=$1
    local description=$2
    
    echo -n "Port $port ($description)... "
    
    if ! netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}✓ Available${NC}"
    else
        echo -e "${YELLOW}⚠ In use (will need alternative)${NC}"
    fi
}

check_port 30333 "P2P"
check_port 9944 "RPC"
check_port 9615 "Metrics"

echo

# Security checks
echo -e "${CYAN}Security Settings:${NC}"
echo "-----------------"

echo -n "Firewall (ufw)... "
if command -v ufw >/dev/null 2>&1; then
    if sudo ufw status | grep -q "Status: active"; then
        echo -e "${GREEN}✓ Active${NC}"
    else
        echo -e "${YELLOW}⚠ Installed but inactive${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Not installed (recommended)${NC}"
fi

echo -n "User permissions... "
if [ "$EUID" -ne 0 ]; then
    echo -e "${GREEN}✓ Not running as root (good)${NC}"
else
    echo -e "${YELLOW}⚠ Running as root (not recommended)${NC}"
fi

echo

# Summary
echo -e "${CYAN}Summary:${NC}"
echo "--------"

if [ "$CHECKS_PASSED" = true ]; then
    echo -e "${GREEN}✅ All critical checks passed!${NC}"
    echo -e "${GREEN}You're ready to run ./quick-start.sh${NC}"
    exit 0
else
    echo -e "${RED}❌ Some critical checks failed${NC}"
    echo -e "${YELLOW}Please address the issues above before proceeding${NC}"
    exit 1
fi 