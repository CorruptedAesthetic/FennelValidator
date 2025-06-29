#!/bin/bash
# Fennel Validator Health Check Script

CONFIG_FILE="../config/validator.conf"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    local status="$1"
    local message="$2"
    case $status in
        "ok") echo -e "${GREEN}✅ $message${NC}" ;;
        "warn") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "error") echo -e "${RED}❌ $message${NC}" ;;
        "info") echo -e "${BLUE}ℹ️  $message${NC}" ;;
    esac
}

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    print_status "error" "Configuration not found. Please run ./setup-validator.sh first"
    exit 1
fi

echo -e "${BLUE}🏥 Fennel Validator Health Check${NC}"
echo "===================================="

# Check if validator process is running
print_status "info" "Checking validator process..."
if pgrep -f "fennel-node.*--validator" > /dev/null; then
    print_status "ok" "Validator process is running"
    VALIDATOR_PID=$(pgrep -f "fennel-node.*--validator")
    print_status "info" "Process ID: $VALIDATOR_PID"
else
    print_status "error" "Validator process is not running"
    echo "Run: ./validate.sh start"
    exit 1
fi

# Check network connectivity
print_status "info" "Checking network connectivity..."
if curl -s --max-time 5 -H "Content-Type: application/json" \
   -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' \
   "http://localhost:$RPC_PORT" > /dev/null 2>&1; then
    print_status "ok" "RPC endpoint is responding"
    
    # Get detailed health info
    HEALTH_RESPONSE=$(curl -s -H "Content-Type: application/json" \
        -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' \
        "http://localhost:$RPC_PORT")
    
    if [ $? -eq 0 ] && [ -n "$HEALTH_RESPONSE" ]; then
        # Parse health response (basic parsing)
        if echo "$HEALTH_RESPONSE" | grep -q '"result"'; then
            print_status "ok" "Node is healthy"
            
            # Extract peer count if available
            if echo "$HEALTH_RESPONSE" | grep -q '"peers"'; then
                PEERS=$(echo "$HEALTH_RESPONSE" | grep -o '"peers":[0-9]*' | cut -d':' -f2)
                if [ "$PEERS" -gt 0 ]; then
                    print_status "ok" "Connected to $PEERS peers"
                else
                    print_status "warn" "No peers connected - check network connectivity"
                fi
            fi
            
            # Check if syncing
            if echo "$HEALTH_RESPONSE" | grep -q '"isSyncing":false'; then
                print_status "ok" "Node is fully synced"
            elif echo "$HEALTH_RESPONSE" | grep -q '"isSyncing":true'; then
                print_status "warn" "Node is still syncing"
            fi
        else
            print_status "warn" "Unexpected health response format"
        fi
    fi
else
    print_status "error" "RPC endpoint is not responding"
    print_status "info" "Check if validator is fully started (may take a few minutes)"
fi

# Check current block height
print_status "info" "Checking current block height..."
BLOCK_RESPONSE=$(curl -s --max-time 5 -H "Content-Type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "chain_getHeader", "params":[]}' \
    "http://localhost:$RPC_PORT" 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$BLOCK_RESPONSE" ]; then
    if echo "$BLOCK_RESPONSE" | grep -q '"number"'; then
        BLOCK_NUMBER=$(echo "$BLOCK_RESPONSE" | grep -o '"number":"[^"]*"' | cut -d'"' -f4)
        # Convert hex to decimal if needed (basic conversion)
        if [[ "$BLOCK_NUMBER" == "0x"* ]]; then
            BLOCK_DECIMAL=$((BLOCK_NUMBER))
            print_status "ok" "Current block: $BLOCK_DECIMAL ($BLOCK_NUMBER)"
        else
            print_status "ok" "Current block: $BLOCK_NUMBER"
        fi
    else
        print_status "warn" "Could not determine current block"
    fi
else
    print_status "warn" "Could not fetch block information"
fi

# Check Prometheus metrics
print_status "info" "Checking Prometheus metrics..."
if curl -s --max-time 5 "http://localhost:$PROMETHEUS_PORT/metrics" | head -n 1 > /dev/null 2>&1; then
    print_status "ok" "Prometheus metrics endpoint is responding"
    
    # Get some basic metrics
    METRICS=$(curl -s --max-time 5 "http://localhost:$PROMETHEUS_PORT/metrics")
    if echo "$METRICS" | grep -q "substrate_block_height"; then
        BLOCK_HEIGHT=$(echo "$METRICS" | grep "substrate_block_height{" | head -n 1 | grep -o '[0-9]*$')
        if [ -n "$BLOCK_HEIGHT" ]; then
            print_status "ok" "Block height from metrics: $BLOCK_HEIGHT"
        fi
    fi
    
    if echo "$METRICS" | grep -q "substrate_network_peers"; then
        PEER_COUNT=$(echo "$METRICS" | grep "substrate_network_peers{" | head -n 1 | grep -o '[0-9]*$')
        if [ -n "$PEER_COUNT" ]; then
            print_status "ok" "Peer count from metrics: $PEER_COUNT"
        fi
    fi
else
    print_status "warn" "Prometheus metrics endpoint is not responding"
fi

# Check disk space
print_status "info" "Checking disk space..."
if [ -d "$DATA_DIR" ]; then
    DISK_USAGE=$(df -h "$DATA_DIR" | awk 'NR==2{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -lt 80 ]; then
        print_status "ok" "Disk usage: ${DISK_USAGE}%"
    elif [ "$DISK_USAGE" -lt 90 ]; then
        print_status "warn" "Disk usage: ${DISK_USAGE}% - consider cleaning up"
    else
        print_status "error" "Disk usage: ${DISK_USAGE}% - critically low space!"
    fi
    
    DATA_SIZE=$(du -sh "$DATA_DIR" 2>/dev/null | cut -f1)
    if [ -n "$DATA_SIZE" ]; then
        print_status "info" "Data directory size: $DATA_SIZE"
    fi
else
    print_status "warn" "Data directory not found: $DATA_DIR"
fi

# Check log files
print_status "info" "Checking recent logs..."
LOG_FILE=$(find "$DATA_DIR" -name "*.log" -type f -exec ls -t {} + 2>/dev/null | head -n 1)
if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
    print_status "ok" "Log file found: $LOG_FILE"
    
    # Check for recent activity (last 5 minutes)
    if find "$LOG_FILE" -mmin -5 2>/dev/null | grep -q .; then
        print_status "ok" "Recent log activity detected"
    else
        print_status "warn" "No recent log activity - validator might be idle"
    fi
    
    # Check for error patterns in recent logs
    ERROR_COUNT=$(tail -n 100 "$LOG_FILE" 2>/dev/null | grep -i "error\|panic\|fatal" | wc -l)
    if [ "$ERROR_COUNT" -eq 0 ]; then
        print_status "ok" "No recent errors in logs"
    else
        print_status "warn" "$ERROR_COUNT recent errors found in logs"
        echo "Recent errors:"
        tail -n 100 "$LOG_FILE" 2>/dev/null | grep -i "error\|panic\|fatal" | tail -n 3
    fi
else
    print_status "warn" "No log files found yet"
fi

echo
print_status "info" "Health check completed"
echo
echo "Validator Configuration:"
echo "• Name: $VALIDATOR_NAME"
echo "• Network: $NETWORK"
echo "• Data directory: $DATA_DIR"
echo "• RPC: http://localhost:$RPC_PORT"
echo "• Metrics: http://localhost:$PROMETHEUS_PORT/metrics"

if pgrep -f "fennel-node.*--validator" > /dev/null; then
    echo
    echo "Management commands:"
    echo "• Status: ./validate.sh status"
    echo "• Logs: ./validate.sh logs"
    echo "• Stop: ./validate.sh stop"
fi 