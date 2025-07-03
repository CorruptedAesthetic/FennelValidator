#!/bin/bash
# Simple Validator Management Script

CONFIG_FILE="config/validator.conf"
BINARY="bin/fennel-node"
if [ -f "bin/fennel-node.exe" ]; then
    BINARY="bin/fennel-node.exe"
fi

# Function to check and update chainspec
check_and_update_chainspec() {
    local chainspec_url="https://raw.githubusercontent.com/CorruptedAesthetic/fennel-solonet/main/chainspecs/staging/staging-raw.json"
    local local_chainspec="config/staging-chainspec.json"
    
    echo "🔍 Checking chainspec freshness..."
    
    # If local chainspec doesn't exist, download it
    if [ ! -f "$local_chainspec" ]; then
        echo "📥 Downloading staging chainspec..."
        if curl -L "$chainspec_url" -o "$local_chainspec" 2>/dev/null; then
            echo "✅ Chainspec downloaded successfully"
        else
            echo "❌ Failed to download chainspec"
            exit 1
        fi
        return 0
    fi
    
    # Check if local chainspec is older than 24 hours
    if [ -f "$local_chainspec" ]; then
        local file_age=$(stat -c %Y "$local_chainspec" 2>/dev/null || echo 0)
        local current_time=$(date +%s)
        local age_hours=$(( (current_time - file_age) / 3600 ))
        
        if [ $age_hours -gt 24 ]; then
            echo "⏰ Local chainspec is $age_hours hours old, checking for updates..."
            
            # Download remote chainspec to temp file
            local temp_chainspec="config/staging-chainspec.json.tmp"
            if curl -L "$chainspec_url" -o "$temp_chainspec" 2>/dev/null; then
                # Compare checksums
                local local_hash=$(sha256sum "$local_chainspec" 2>/dev/null | cut -d' ' -f1)
                local remote_hash=$(sha256sum "$temp_chainspec" 2>/dev/null | cut -d' ' -f1)
                
                if [ "$local_hash" != "$remote_hash" ]; then
                    echo "🔄 Chainspec has been updated remotely, updating local copy..."
                    mv "$temp_chainspec" "$local_chainspec"
                    echo "✅ Chainspec updated successfully"
                else
                    echo "✅ Local chainspec is up to date"
                    rm -f "$temp_chainspec"
                fi
            else
                echo "⚠️  Failed to check for chainspec updates, using local copy"
                rm -f "$temp_chainspec"
            fi
        else
            echo "✅ Local chainspec is fresh (${age_hours}h old)"
        fi
    fi
}

case "${1:-}" in
    start)
        echo "🚀 Starting validator..."
        if [ -f "$CONFIG_FILE" ]; then
            source "$CONFIG_FILE"
        else
            echo "❌ Configuration not found. Run ./setup-validator.sh first"
            exit 1
        fi
        
        if [ ! -f "$BINARY" ]; then
            echo "❌ Fennel node binary not found!"
            echo "   Run: ./install.sh first"
            exit 1
        fi
        
        # Check and update chainspec
        check_and_update_chainspec
        
        # Start with basic config
        ./$BINARY \
            --chain "config/staging-chainspec.json" \
            --validator \
            --name "${VALIDATOR_NAME:-External-Validator}" \
            --base-path "${DATA_DIR:-./data}" \
            --port "${P2P_PORT:-30333}" \
            --rpc-port "${RPC_PORT:-9944}" \
            --prometheus-port "${PROMETHEUS_PORT:-9615}" \
            --rpc-cors all \
            --rpc-methods safe
        ;;
    
    init)
        echo "🔧 Initializing validator..."
        if [ -f "$CONFIG_FILE" ]; then
            source "$CONFIG_FILE"
        else
            echo "❌ Configuration not found. Run ./setup-validator.sh first"
            exit 1
        fi
        
        if [ ! -f "$BINARY" ]; then
            echo "❌ Fennel node binary not found!"
            echo "   Run: ./install.sh first"
            exit 1
        fi
        
        # Check if network key already exists
        NETWORK_KEY_PATH="${DATA_DIR:-./data}/chains/custom/network/secret_ed25519"
        if [ -f "$NETWORK_KEY_PATH" ]; then
            echo "✅ Network keys already exist"
            return 0
        fi
        
        echo "🔑 Generating network keys..."
        echo "This will take 30-60 seconds..."
        
        # Create data directory if it doesn't exist
        mkdir -p "${DATA_DIR:-./data}"
        
        # Check and update chainspec
        check_and_update_chainspec
        
        # Start briefly to generate keys
        timeout 90 ./$BINARY \
            --chain "config/staging-chainspec.json" \
            --name "${VALIDATOR_NAME:-External-Validator}" \
            --base-path "${DATA_DIR:-./data}" \
            --port "${P2P_PORT:-30333}" \
            --rpc-port "${RPC_PORT:-9944}" \
            --prometheus-port "${PROMETHEUS_PORT:-9615}" \
            --rpc-cors all \
            --rpc-methods safe &
        
        INIT_PID=$!
        
        # Wait for network key to be generated
        for i in {1..45}; do
            if [ -f "$NETWORK_KEY_PATH" ]; then
                echo "✅ Network key detected after $((i*2)) seconds"
                break
            fi
            sleep 2
            echo "⏳ Waiting for key generation... ($((i*2))s)"
        done
        
        # Stop the initialization process
        kill $INIT_PID 2>/dev/null || true
        wait $INIT_PID 2>/dev/null || true
        
        # Final verification
        if [ -f "$NETWORK_KEY_PATH" ]; then
            echo "✅ Network keys generated successfully"
            echo "✅ Validator initialization complete"
        else
            echo "❌ Failed to generate network keys after 90 seconds"
            echo "❌ Check your network connection and try again"
            echo "💡 You can retry with: ./validate.sh init"
            exit 1
        fi
        ;;
    
    start-unsafe)
        echo "🚀 Starting validator with UNSAFE RPC methods..."
        echo "⚠️  WARNING: This enables unsafe RPC methods including author_rotateKeys"
        echo "⚠️  Only use this temporarily for session key generation!"
        echo "⚠️  Stop and restart with 'start' command for normal operation"
        echo
        
        if [ -f "$CONFIG_FILE" ]; then
            source "$CONFIG_FILE"
        else
            echo "❌ Configuration not found. Run ./setup-validator.sh first"
            exit 1
        fi
        
        if [ ! -f "$BINARY" ]; then
            echo "❌ Fennel node binary not found!"
            echo "   Run: ./install.sh first"
            exit 1
        fi
        
        # Check and update chainspec
        check_and_update_chainspec
        
        echo "🔑 Once validator is running, generate session keys with:"
        echo "   ./scripts/generate-session-keys.sh"
        echo
        echo "🛑 Remember to stop and restart with safe methods after key generation!"
        echo
        
        # Start with UNSAFE RPC methods
        ./$BINARY \
            --chain "config/staging-chainspec.json" \
            --validator \
            --name "${VALIDATOR_NAME:-External-Validator}" \
            --base-path "${DATA_DIR:-./data}" \
            --port "${P2P_PORT:-30333}" \
            --rpc-port "${RPC_PORT:-9944}" \
            --prometheus-port "${PROMETHEUS_PORT:-9615}" \
            --rpc-cors all \
            --rpc-methods unsafe
        ;;
    
    stop)
        echo "🛑 Stopping validator..."
        pkill -f "fennel-node.*--validator" || echo "Validator was not running"
        ;;
    
    status)
        if pgrep -f "fennel-node.*--validator" > /dev/null; then
            echo "✅ Validator is running"
            if command -v curl >/dev/null 2>&1; then
                echo "📊 Checking network connection..."
                curl -s -H "Content-Type: application/json" \
                    -d '{"method":"system_health"}' \
                    http://localhost:${RPC_PORT:-9944} 2>/dev/null | grep -o '"peers":[0-9]*' || echo "RPC not accessible"
            fi
        else
            echo "❌ Validator is not running"
        fi
        ;;
    
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    
    logs)
        echo "📋 Validator logs (Ctrl+C to stop):"
        if [ -d "${DATA_DIR:-./data}" ]; then
            tail -f "${DATA_DIR:-./data}/chains/*/network.log" 2>/dev/null || echo "No logs found yet"
        else
            echo "No data directory found. Start validator first."
        fi
        ;;
    
    update-chainspec)
        echo "🔄 Forcing chainspec update..."
        rm -f "config/staging-chainspec.json"
        check_and_update_chainspec
        echo "✅ Chainspec update complete"
        ;;
    
    *)
        echo "Usage: $0 {init|start|start-unsafe|stop|status|restart|logs|update-chainspec}"
        echo
        echo "Commands:"
        echo "  init         - Initialize validator (generate network keys) - Run this first!"
        echo "  start        - Start the validator with SAFE RPC methods (normal operation)"
        echo "  start-unsafe - Start the validator with UNSAFE RPC methods (for session key generation)"
        echo "  stop         - Stop the validator" 
        echo "  status       - Check if validator is running"
        echo "  restart      - Restart the validator"
        echo "  logs         - View validator logs"
        echo "  update-chainspec - Force update chainspec from remote"
        echo
        echo "Session Key Generation Workflow:"
        echo "  1. ./validate.sh stop"
        echo "  2. ./validate.sh start-unsafe"
        echo "  3. ./scripts/generate-session-keys.sh (in another terminal)"
        echo "  4. ./validate.sh stop"
        echo "  5. ./validate.sh start (normal operation)"
        ;;
esac
