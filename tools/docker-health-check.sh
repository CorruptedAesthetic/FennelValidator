#!/bin/bash
# Docker Validator Health Check

echo "=== Docker Validator Health Check ==="
echo

# Check if container is running
if docker ps | grep -q fennel-validator; then
    echo "✅ Container is running"
    CONTAINER_RUNNING=true
else
    echo "❌ Container is not running"
    echo "Recent logs:"
    docker logs --tail 20 fennel-validator 2>/dev/null || echo "No logs available"
    CONTAINER_RUNNING=false
fi

if [ "$CONTAINER_RUNNING" = true ]; then
    # Check RPC connectivity
    if curl -s -m 5 -H "Content-Type: application/json" \
        -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' \
        http://localhost:9933 > /dev/null 2>&1; then
        echo "✅ RPC is accessible"
        RPC_OK=true
    else
        echo "❌ RPC is not accessible"
        RPC_OK=false
    fi

    if [ "$RPC_OK" = true ]; then
        # Check peer count
        PEERS=$(curl -s -H "Content-Type: application/json" \
            -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' \
            http://localhost:9933 2>/dev/null | jq -r '.result.peers // 0' 2>/dev/null)

        if [ "$PEERS" != "null" ] && [ "$PEERS" -gt 0 ] 2>/dev/null; then
            echo "✅ Connected to $PEERS peers"
        else
            echo "❌ No peers connected"
        fi

        # Check sync status
        SYNC_INFO=$(curl -s -H "Content-Type: application/json" \
            -d '{"id":1, "jsonrpc":"2.0", "method": "system_syncState", "params":[]}' \
            http://localhost:9933 2>/dev/null)

        if echo "$SYNC_INFO" | jq -e '.result.currentBlock' > /dev/null 2>&1; then
            CURRENT=$(echo "$SYNC_INFO" | jq -r '.result.currentBlock' 2>/dev/null)
            HIGHEST=$(echo "$SYNC_INFO" | jq -r '.result.highestBlock' 2>/dev/null)
            echo "✅ Sync status: $CURRENT / $HIGHEST"
        else
            echo "❌ Cannot get sync status"
        fi
    fi

    # Check disk usage
    if [ -d "validator-data" ]; then
        DISK_USAGE=$(df -h validator-data/ 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null)
        if [ -n "$DISK_USAGE" ] && [ "$DISK_USAGE" -lt 80 ] 2>/dev/null; then
            echo "✅ Disk usage: ${DISK_USAGE}%"
        elif [ -n "$DISK_USAGE" ]; then
            echo "⚠️  Disk usage high: ${DISK_USAGE}%"
        else
            echo "⚠️  Cannot check disk usage"
        fi
    fi

    # Check memory usage
    MEMORY_USAGE=$(docker stats --no-stream --format "table {{.MemPerc}}" fennel-validator 2>/dev/null | tail -1 | sed 's/%//' 2>/dev/null)
    if [ -n "$MEMORY_USAGE" ] && [ "$MEMORY_USAGE" -lt 80 ] 2>/dev/null; then
        echo "✅ Memory usage: ${MEMORY_USAGE}%"
    elif [ -n "$MEMORY_USAGE" ]; then
        echo "⚠️  Memory usage high: ${MEMORY_USAGE}%"
    else
        echo "⚠️  Cannot check memory usage"
    fi
fi

echo
echo "=== Health Check Complete ==="

# Additional system checks
echo
echo "=== System Information ==="
echo "Docker version: $(docker --version 2>/dev/null || echo 'Docker not available')"
echo "Available disk space: $(df -h . 2>/dev/null | tail -1 | awk '{print $4}' || echo 'Unknown')"
echo "Available memory: $(free -h 2>/dev/null | grep Mem | awk '{print $7}' || echo 'Unknown')"
echo "Load average: $(uptime 2>/dev/null | awk -F'load average:' '{print $2}' || echo 'Unknown')"

# Check if key files exist
echo
echo "=== Key Files Check ==="
if [ -f "config/fennel-staging.raw.json" ]; then
    echo "✅ Chainspec file exists"
else
    echo "❌ Chainspec file missing"
fi

if [ -d "validator-data" ]; then
    echo "✅ Validator data directory exists"
else
    echo "❌ Validator data directory missing"
fi

# Show recent Docker events
echo
echo "=== Recent Docker Events ==="
docker events --since 1h --filter container=fennel-validator --format "{{.Time}}: {{.Action}}" 2>/dev/null | tail -5 || echo "No recent events"

echo
echo "💡 Tips:"
echo "   - Run 'docker logs -f fennel-validator' to see live logs"
echo "   - Run 'docker restart fennel-validator' to restart validator"
echo "   - Check docs/DOCKER-TROUBLESHOOTING.md for common issues"
