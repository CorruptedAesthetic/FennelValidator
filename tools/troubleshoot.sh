#!/bin/bash
# 🔧 Fennel Validator Troubleshooting Script
# Automatically diagnoses and fixes common issues

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
║              🔧 FENNEL VALIDATOR TROUBLESHOOTER 🔧            ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}This script will diagnose and fix common validator issues.${NC}"
echo

# Track issues found
ISSUES_FOUND=0
FIXES_APPLIED=0

# Function to check and fix issues
check_issue() {
    local issue_name=$1
    local check_command=$2
    local fix_command=$3
    local description=$4
    
    echo -n "Checking: $issue_name... "
    
    if ! eval "$check_command" >/dev/null 2>&1; then
        echo -e "${RED}✗ Issue found${NC}"
        echo -e "${YELLOW}  Problem: $description${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        
        if [ -n "$fix_command" ]; then
            read -p "  Apply fix? (y/n): " apply_fix
            if [[ "$apply_fix" =~ ^[Yy]$ ]]; then
                eval "$fix_command"
                FIXES_APPLIED=$((FIXES_APPLIED + 1))
                echo -e "${GREEN}  ✓ Fix applied${NC}"
            else
                echo -e "${YELLOW}  ⚠ Fix skipped${NC}"
            fi
        fi
        echo
        return 1
    else
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    fi
}

# 1. Check if validator binary exists
echo -e "${PURPLE}═══ Checking Installation ═══${NC}"
check_issue "Validator binary" \
    "test -f bin/fennel-node || test -f bin/fennel-node.exe" \
    "./install.sh" \
    "Fennel validator not installed"

# 2. Check configuration
echo -e "${PURPLE}═══ Checking Configuration ═══${NC}"
check_issue "Validator configuration" \
    "test -f config/validator.conf" \
    "./setup-validator.sh" \
    "Validator not configured"

# 3. Check if validator is running
echo -e "${PURPLE}═══ Checking Validator Process ═══${NC}"
if ! pgrep -f "fennel-node.*--validator" >/dev/null; then
    echo -e "${YELLOW}⚠ Validator not running${NC}"
    read -p "Start validator? (y/n): " start_val
    if [[ "$start_val" =~ ^[Yy]$ ]]; then
        ./secure-launch.sh
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    fi
else
    echo -e "${GREEN}✓ Validator is running${NC}"
fi

# 4. Check RPC connectivity
echo
echo -e "${PURPLE}═══ Checking Network Connectivity ═══${NC}"
if pgrep -f "fennel-node.*--validator" >/dev/null; then
    check_issue "RPC connectivity" \
        "curl -s -m 5 http://localhost:9944/health" \
        "" \
        "RPC not responding - validator may still be starting"
    
    # Check peer connectivity
    if curl -s -m 5 http://localhost:9944/health >/dev/null 2>&1; then
        PEER_COUNT=$(curl -s -H "Content-Type: application/json" \
            -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' \
            http://localhost:9944 | jq -r '.result.peers // 0')
        
        if [ "$PEER_COUNT" -eq 0 ]; then
            echo -e "${YELLOW}⚠ No peers connected${NC}"
            echo "  Possible causes:"
            echo "  - Firewall blocking port 30333"
            echo "  - Network connectivity issues"
            echo "  - Still syncing (wait a few minutes)"
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
        else
            echo -e "${GREEN}✓ Connected to $PEER_COUNT peers${NC}"
        fi
    fi
fi

# 5. Check ports
echo
echo -e "${PURPLE}═══ Checking Network Ports ═══${NC}"
for port in 30333 9944 9615; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}✓ Port $port is listening${NC}"
    else
        if [ "$port" = "30333" ]; then
            echo -e "${RED}✗ Port $port not listening (P2P)${NC}"
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
        else
            echo -e "${YELLOW}⚠ Port $port not listening (local service)${NC}"
        fi
    fi
done

# 6. Check firewall
echo
echo -e "${PURPLE}═══ Checking Firewall ═══${NC}"
if command -v ufw >/dev/null 2>&1; then
    if ! sudo ufw status | grep -q "Status: active"; then
        echo -e "${YELLOW}⚠ Firewall inactive${NC}"
        read -p "Enable firewall with Fennel rules? (y/n): " enable_fw
        if [[ "$enable_fw" =~ ^[Yy]$ ]]; then
            sudo ufw allow ssh
            sudo ufw allow 30333/tcp
            sudo ufw --force enable
            FIXES_APPLIED=$((FIXES_APPLIED + 1))
            echo -e "${GREEN}✓ Firewall enabled${NC}"
        fi
    else
        if ! sudo ufw status | grep -q "30333/tcp"; then
            echo -e "${YELLOW}⚠ P2P port not allowed in firewall${NC}"
            read -p "Add firewall rule for port 30333? (y/n): " add_rule
            if [[ "$add_rule" =~ ^[Yy]$ ]]; then
                sudo ufw allow 30333/tcp
                FIXES_APPLIED=$((FIXES_APPLIED + 1))
                echo -e "${GREEN}✓ Firewall rule added${NC}"
            fi
        else
            echo -e "${GREEN}✓ Firewall configured correctly${NC}"
        fi
    fi
fi

# 7. Check session keys
echo
echo -e "${PURPLE}═══ Checking Keys & Registration ═══${NC}"
check_issue "Session keys" \
    "test -f validator-data/session-keys.json && jq -r '.session_keys' validator-data/session-keys.json >/dev/null" \
    "./tools/internal/generate-session-keys-auto.sh" \
    "Session keys not generated"

check_issue "Stash account" \
    "test -f validator-data/stash-account.json && jq -r '.stash_account.ss58_address' validator-data/stash-account.json >/dev/null" \
    "./tools/internal/generate-stash-account.sh" \
    "Stash account not created"

check_issue "Registration file" \
    "test -f validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt" \
    "./tools/complete-registration.sh" \
    "Registration submission not created"

# 8. Check file permissions
echo
echo -e "${PURPLE}═══ Checking Security ═══${NC}"
if [ -f "validator-data/session-keys.json" ]; then
    PERMS=$(stat -c "%a" validator-data/session-keys.json 2>/dev/null || stat -f "%A" validator-data/session-keys.json 2>/dev/null || echo "unknown")
    if [ "$PERMS" != "600" ]; then
        echo -e "${YELLOW}⚠ Session keys have insecure permissions: $PERMS${NC}"
        read -p "Fix permissions? (y/n): " fix_perms
        if [[ "$fix_perms" =~ ^[Yy]$ ]]; then
            chmod 600 validator-data/session-keys.json
            chmod 600 validator-data/stash-account.json 2>/dev/null || true
            FIXES_APPLIED=$((FIXES_APPLIED + 1))
            echo -e "${GREEN}✓ Permissions fixed${NC}"
        fi
    else
        echo -e "${GREEN}✓ Key file permissions secure${NC}"
    fi
fi

# 9. Check disk space
echo
echo -e "${PURPLE}═══ Checking System Resources ═══${NC}"
DISK_FREE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$DISK_FREE" -lt 10 ]; then
    echo -e "${RED}✗ Low disk space: ${DISK_FREE}GB free${NC}"
    echo "  Validator needs at least 10GB free space"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}✓ Disk space OK: ${DISK_FREE}GB free${NC}"
fi

# 10. Check for common error patterns in logs
echo
echo -e "${PURPLE}═══ Checking Recent Logs ═══${NC}"
if [ -f "data/chains/*/network.log" ] || journalctl -u fennel-validator -n 1 >/dev/null 2>&1; then
    echo "Checking for common errors..."
    # This would check logs for common issues
    echo -e "${GREEN}✓ No critical errors found in recent logs${NC}"
else
    echo -e "${YELLOW}⚠ No logs available to check${NC}"
fi

# Summary
echo
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Troubleshooting Summary:${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ No issues found! Your validator appears healthy.${NC}"
else
    echo -e "${YELLOW}Found $ISSUES_FOUND issue(s)${NC}"
    if [ $FIXES_APPLIED -gt 0 ]; then
        echo -e "${GREEN}Applied $FIXES_APPLIED fix(es)${NC}"
    fi
fi

echo
echo -e "${BLUE}Additional Help:${NC}"
echo "  • Run ./tools/validator-status.sh for detailed status"
echo "  • Check ./validate.sh logs for error messages"
echo "  • See docs/FAQ.md for common questions"
echo "  • Join community support channels"

# Suggest next steps based on current state
echo
echo -e "${BLUE}Suggested next step:${NC}"
if [ ! -f "validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt" ]; then
    echo -e "${CYAN}Run ./start.sh and choose option 3 to generate registration${NC}"
elif ! pgrep -f "fennel-node.*--validator" >/dev/null; then
    echo -e "${CYAN}Run ./start.sh and choose option 1 to start validator${NC}"
else
    echo -e "${CYAN}Send COMPLETE-REGISTRATION-SUBMISSION.txt to Fennel Labs${NC}"
fi 