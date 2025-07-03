#!/bin/bash
# Comprehensive Health Check for Fennel Validator
# Checks all aspects of validator health and connectivity

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🏥 Fennel Validator Health Check${NC}"
echo "================================="

# Load configuration
if [ -f "config/validator.conf" ]; then
    source config/validator.conf
else
    echo -e "${RED}❌ Configuration not found${NC}"
    exit 1
fi

HEALTH_SCORE=0
MAX_SCORE=10

# Check if validator process is running
check_process() {
    echo -e "\n${BLUE}🔍 Process Status${NC}"
    
    if pgrep -f "fennel-node.*--validator" > /dev/null; then
        echo -e "${GREEN}✅ Validator process is running${NC}"
        PROCESS_PID=$(pgrep -f "fennel-node.*--validator")
        echo "   PID: $PROCESS_PID"
        ((HEALTH_SCORE++))
    else
        echo -e "${RED}❌ Validator process is not running${NC}"
        echo "   Start with: ./validate.sh start"
    fi
}

# Check RPC connectivity
check_rpc() {
    echo -e "\n${BLUE}🌐 RPC Connectivity${NC}"
    
    if command -v curl >/dev/null 2>&1; then
        if curl -s --connect-timeout 5 http://localhost:${RPC_PORT:-9944} > /dev/null; then
            echo -e "${GREEN}✅ RPC endpoint accessible${NC}"
            echo "   URL: http://localhost:${RPC_PORT:-9944}"
            ((HEALTH_SCORE++))
        else
            echo -e "${RED}❌ RPC endpoint not accessible${NC}"
            echo "   Check if validator is running"
        fi
    else
        echo -e "${YELLOW}⚠️  curl not available for RPC testing${NC}"
    fi
}

# Check network health
check_network_health() {
    echo -e "\n${BLUE}🌍 Network Health${NC}"
    
    if command -v curl >/dev/null 2>&1; then
        HEALTH_RESPONSE=$(curl -s -H "Content-Type: application/json" \
            -d '{"id":1,"jsonrpc":"2.0","method":"system_health","params":[]}' \
            http://localhost:${RPC_PORT:-9944} 2>/dev/null || echo '{}')
        
        if [ "$HEALTH_RESPONSE" != '{}' ]; then
            PEERS=$(echo "$HEALTH_RESPONSE" | jq -r '.result.peers // 0' 2>/dev/null || echo "0")
            IS_SYNCING=$(echo "$HEALTH_RESPONSE" | jq -r '.result.isSyncing // true' 2>/dev/null || echo "true")
            SHOULD_HAVE_PEERS=$(echo "$HEALTH_RESPONSE" | jq -r '.result.shouldHavePeers // false' 2>/dev/null || echo "false")
            
            echo "Connected Peers: $PEERS"
            echo "Is Syncing: $IS_SYNCING"
            echo "Should Have Peers: $SHOULD_HAVE_PEERS"
            
            if [ "$PEERS" -gt 0 ]; then
                echo -e "${GREEN}✅ Connected to peers${NC}"
                ((HEALTH_SCORE++))
            else
                echo -e "${RED}❌ No peer connections${NC}"
            fi
            
            if [ "$IS_SYNCING" = "false" ]; then
                echo -e "${GREEN}✅ Fully synchronized${NC}"
                ((HEALTH_SCORE++))
            else
                echo -e "${YELLOW}⚠️  Still synchronizing${NC}"
            fi
        else
            echo -e "${RED}❌ Cannot retrieve network health${NC}"
        fi
    fi
}

# Check current block
check_sync_status() {
    echo -e "\n${BLUE}🔗 Synchronization Status${NC}"
    
    if command -v curl >/dev/null 2>&1; then
        HEADER_RESPONSE=$(curl -s -H "Content-Type: application/json" \
            -d '{"id":1,"jsonrpc":"2.0","method":"chain_getHeader","params":[]}' \
            http://localhost:${RPC_PORT:-9944} 2>/dev/null || echo '{}')
        
        if [ "$HEADER_RESPONSE" != '{}' ]; then
            BLOCK_HEX=$(echo "$HEADER_RESPONSE" | jq -r '.result.number // "0x0"' 2>/dev/null || echo "0x0")
            BLOCK_NUMBER=$((BLOCK_HEX))
            BLOCK_HASH=$(echo "$HEADER_RESPONSE" | jq -r '.result.hash // "unknown"' 2>/dev/null || echo "unknown")
            
            echo "Current Block: #$BLOCK_NUMBER"
            echo "Block Hash: ${BLOCK_HASH:0:20}..."
            
            if [ "$BLOCK_NUMBER" -gt 0 ]; then
                echo -e "${GREEN}✅ Chain is progressing${NC}"
                ((HEALTH_SCORE++))
            else
                echo -e "${RED}❌ No blocks received${NC}"
            fi
        else
            echo -e "${RED}❌ Cannot retrieve block information${NC}"
        fi
    fi
}

# Check session keys
check_session_keys() {
    echo -e "\n${BLUE}🔑 Session Keys${NC}"
    
    if [ -f "session-keys.json" ]; then
        SESSION_KEYS=$(jq -r '.session_keys' session-keys.json 2>/dev/null || echo "")
        if [ -n "$SESSION_KEYS" ] && [ "$SESSION_KEYS" != "null" ]; then
            echo -e "${GREEN}✅ Session keys generated${NC}"
            echo "   Keys: ${SESSION_KEYS:0:20}...${SESSION_KEYS: -10}"
            
            # Check if keys are loaded in validator
            if command -v curl >/dev/null 2>&1; then
                HAS_KEYS_RESPONSE=$(curl -s -H "Content-Type: application/json" \
                    -d "{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"author_hasSessionKeys\",\"params\":[\"$SESSION_KEYS\"]}" \
                    http://localhost:${RPC_PORT:-9944} 2>/dev/null || echo '{}')
                
                HAS_KEYS=$(echo "$HAS_KEYS_RESPONSE" | jq -r '.result // false' 2>/dev/null || echo "false")
                if [ "$HAS_KEYS" = "true" ]; then
                    echo -e "${GREEN}✅ Session keys loaded in validator${NC}"
                    ((HEALTH_SCORE++))
                else
                    echo -e "${YELLOW}⚠️  Session keys not loaded in validator${NC}"
                fi
            fi
            ((HEALTH_SCORE++))
        else
            echo -e "${RED}❌ Session keys not found or invalid${NC}"
            echo "   Generate with: ./scripts/generate-session-keys.sh"
        fi
    else
        echo -e "${RED}❌ Session keys file not found${NC}"
        echo "   Generate with: ./scripts/generate-session-keys.sh"
    fi
}

# Check file system
check_filesystem() {
    echo -e "\n${BLUE}💾 File System${NC}"
    
    # Check data directory
    if [ -d "${DATA_DIR:-./data}" ]; then
        echo -e "${GREEN}✅ Data directory exists${NC}"
        echo "   Path: ${DATA_DIR:-./data}"
        
        # Check available space
        if command -v df >/dev/null 2>&1; then
            AVAILABLE_SPACE=$(df -h "${DATA_DIR:-./data}" | awk 'NR==2 {print $4}')
            echo "   Available space: $AVAILABLE_SPACE"
            
            # Check if we have at least 10GB free
            AVAILABLE_KB=$(df "${DATA_DIR:-./data}" | awk 'NR==2 {print $4}')
            if [ "$AVAILABLE_KB" -gt 10485760 ]; then  # 10GB in KB
                echo -e "${GREEN}✅ Sufficient disk space${NC}"
                ((HEALTH_SCORE++))
            else
                echo -e "${YELLOW}⚠️  Low disk space (less than 10GB)${NC}"
            fi
        fi
        
        # Check for network key
        NETWORK_KEY_PATH="${DATA_DIR:-./data}/chains/custom/network/secret_ed25519"
        if [ -f "$NETWORK_KEY_PATH" ]; then
            echo -e "${GREEN}✅ Network identity key exists${NC}"
            ((HEALTH_SCORE++))
        else
            echo -e "${RED}❌ Network identity key missing${NC}"
            echo "   Initialize with: ./validate.sh init"
        fi
    else
        echo -e "${RED}❌ Data directory missing${NC}"
        echo "   Create with: mkdir -p ${DATA_DIR:-./data}"
    fi
}

# Check port accessibility
check_ports() {
    echo -e "\n${BLUE}🔌 Port Status${NC}"
    
    P2P_PORT_TO_CHECK=${P2P_PORT:-30333}
    RPC_PORT_TO_CHECK=${RPC_PORT:-9944}
    
    # Check if ports are in use
    if command -v netstat >/dev/null 2>&1; then
        if netstat -ln | grep ":$P2P_PORT_TO_CHECK " > /dev/null; then
            echo -e "${GREEN}✅ P2P port $P2P_PORT_TO_CHECK is bound${NC}"
            ((HEALTH_SCORE++))
        else
            echo -e "${RED}❌ P2P port $P2P_PORT_TO_CHECK is not bound${NC}"
        fi
        
        if netstat -ln | grep ":$RPC_PORT_TO_CHECK " > /dev/null; then
            echo -e "${GREEN}✅ RPC port $RPC_PORT_TO_CHECK is bound${NC}"
        else
            echo -e "${RED}❌ RPC port $RPC_PORT_TO_CHECK is not bound${NC}"
        fi
    elif command -v ss >/dev/null 2>&1; then
        if ss -ln | grep ":$P2P_PORT_TO_CHECK " > /dev/null; then
            echo -e "${GREEN}✅ P2P port $P2P_PORT_TO_CHECK is bound${NC}"
            ((HEALTH_SCORE++))
        else
            echo -e "${RED}❌ P2P port $P2P_PORT_TO_CHECK is not bound${NC}"
        fi
        
        if ss -ln | grep ":$RPC_PORT_TO_CHECK " > /dev/null; then
            echo -e "${GREEN}✅ RPC port $RPC_PORT_TO_CHECK is bound${NC}"
        else
            echo -e "${RED}❌ RPC port $RPC_PORT_TO_CHECK is not bound${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Cannot check port status (netstat/ss not available)${NC}"
    fi
}

# Check bootnode connectivity
check_bootnode_connectivity() {
    echo -e "\n${BLUE}🌐 Bootnode Connectivity${NC}"
    
    BOOTNODE1="135.18.208.132"
    BOOTNODE2="132.196.191.14"
    PORT="30333"
    
    if command -v nc >/dev/null 2>&1; then
        echo "Testing bootnode connections..."
        
        if timeout 5 nc -z "$BOOTNODE1" "$PORT" 2>/dev/null; then
            echo -e "${GREEN}✅ Bootnode 1 reachable ($BOOTNODE1:$PORT)${NC}"
        else
            echo -e "${RED}❌ Bootnode 1 unreachable ($BOOTNODE1:$PORT)${NC}"
        fi
        
        if timeout 5 nc -z "$BOOTNODE2" "$PORT" 2>/dev/null; then
            echo -e "${GREEN}✅ Bootnode 2 reachable ($BOOTNODE2:$PORT)${NC}"
        else
            echo -e "${RED}❌ Bootnode 2 unreachable ($BOOTNODE2:$PORT)${NC}"
        fi
    elif command -v telnet >/dev/null 2>&1; then
        echo "Testing with telnet (may take a moment)..."
        if timeout 5 bash -c "echo | telnet $BOOTNODE1 $PORT" 2>/dev/null | grep -q "Connected"; then
            echo -e "${GREEN}✅ Bootnode 1 reachable${NC}"
        else
            echo -e "${RED}❌ Bootnode 1 unreachable${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Cannot test bootnode connectivity (nc/telnet not available)${NC}"
    fi
}

# Generate health summary
generate_summary() {
    echo -e "\n${BLUE}📊 Health Summary${NC}"
    echo "=================="
    
    PERCENTAGE=$((HEALTH_SCORE * 100 / MAX_SCORE))
    
    echo "Health Score: $HEALTH_SCORE/$MAX_SCORE ($PERCENTAGE%)"
    
    if [ $PERCENTAGE -ge 80 ]; then
        echo -e "${GREEN}🎉 Validator is healthy and ready!${NC}"
        echo "Your validator appears to be working correctly."
    elif [ $PERCENTAGE -ge 60 ]; then
        echo -e "${YELLOW}⚠️  Validator has some issues${NC}"
        echo "Please address the issues marked above."
    else
        echo -e "${RED}❌ Validator has significant problems${NC}"
        echo "Multiple issues need to be resolved before validator can work properly."
    fi
    
    echo
    echo -e "${BLUE}💡 Next Steps:${NC}"
    if [ ! -f "session-keys.json" ]; then
        echo "1. Generate session keys: ./scripts/generate-session-keys.sh"
    fi
    if [ $HEALTH_SCORE -lt $MAX_SCORE ]; then
        echo "2. Fix issues identified above"
        echo "3. Re-run health check: ./scripts/health-check.sh"
    fi
    if [ -f "session-keys.json" ] && [ $PERCENTAGE -ge 80 ]; then
        echo "4. Submit validation request: ./scripts/submit-validation-request.sh"
    fi
}

# Main execution
main() {
    check_process
    check_rpc
    check_network_health
    check_sync_status
    check_session_keys
    check_filesystem
    check_ports
    check_bootnode_connectivity
    generate_summary
}

# Run main function
main "$@" 