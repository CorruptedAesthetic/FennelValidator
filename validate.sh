#!/bin/bash
# Enhanced Validator Management Script with robust path handling

# Get script directory and ensure we're in the right place
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CONFIG_FILE="config/validator.conf"
BINARY="bin/fennel-node"
if [ -f "bin/fennel-node.exe" ]; then
    BINARY="bin/fennel-node.exe"
fi

# Load configuration if available
load_config() {
        if [ -f "$CONFIG_FILE" ]; then
            source "$CONFIG_FILE"
        return 0
    else
        # Set defaults
        VALIDATOR_NAME="${VALIDATOR_NAME:-External-Validator}"
        DATA_DIR="${DATA_DIR:-./data}"
        P2P_PORT="${P2P_PORT:-30333}"
        RPC_PORT="${RPC_PORT:-9944}"
        PROMETHEUS_PORT="${PROMETHEUS_PORT:-9615}"
        return 1
        fi
}

# Check binary exists
check_binary() {
        if [ ! -f "$BINARY" ]; then
            echo "❌ Fennel node binary not found!"
            echo "   Run: ./install.sh first"
            exit 1
        fi
    
    # Test binary compatibility
    if ! ./"$BINARY" --version >/dev/null 2>&1; then
        echo "❌ Binary compatibility issue detected"
        echo "   Try running: ./install.sh to re-download"
        exit 1
    fi
}
        
        # Download chainspec if needed
ensure_chainspec() {
        if [ ! -f "config/staging-chainspec.json" ]; then
            echo "📥 Downloading staging chainspec..."
            curl -L "https://raw.githubusercontent.com/CorruptedAesthetic/fennel-solonet/main/chainspecs/staging/staging-raw.json" -o "config/staging-chainspec.json"
        if [ $? -eq 0 ]; then
            echo "✅ Staging chainspec downloaded"
        else
            echo "❌ Failed to download chainspec"
            exit 1
        fi
        else
            echo "✅ Using existing staging chainspec"
        fi
}

case "${1:-}" in
    start)
        echo "🚀 Starting validator..."
        load_config
        check_binary
        ensure_chainspec
        
        echo "Network: staging"
        echo "Validator: $VALIDATOR_NAME"
        echo "Data directory: $DATA_DIR"
        echo
        
        # Auto-update chainspec for staging safety
        echo "🔄 Checking for chainspec updates..."
        echo "📥 Auto-updating staging chainspec (safe for testing)..."
        curl -L "https://raw.githubusercontent.com/CorruptedAesthetic/fennel-solonet/main/chainspecs/staging/staging-raw.json" -o "config/staging-chainspec.json" 2>/dev/null && echo "✅ Updated to latest staging chainspec"
        
        echo "🔧 Initializing validator..."
        
        # Check network keys
        NETWORK_KEY_PATH="$DATA_DIR/chains/custom/network/secret_ed25519"
        if [ -f "$NETWORK_KEY_PATH" ]; then
            echo "✅ Network keys already exist"
        else
            echo "🔑 Generating network keys first..."
            $0 init
        fi
        
        echo
        echo "Command: ./$BINARY --chain config/staging-chainspec.json --validator --name \"$VALIDATOR_NAME\" --base-path \"$DATA_DIR\" --port $P2P_PORT --rpc-port $RPC_PORT --prometheus-port $PROMETHEUS_PORT --log info --rpc-cors all --rpc-methods safe --db-cache 1024"
        echo
        
        # Start validator
        ./"$BINARY" \
            --chain "config/staging-chainspec.json" \
            --validator \
            --name "$VALIDATOR_NAME" \
            --base-path "$DATA_DIR" \
            --port "$P2P_PORT" \
            --rpc-port "$RPC_PORT" \
            --prometheus-port "$PROMETHEUS_PORT" \
            --bootnodes="/dns4/bootnode1.fennel.network/tcp/30333/p2p/12D3KooWS84f71ufMQRsm9YWynfK5Zxa6iSooStJECnAT3RBVVxz" \
            --bootnodes="/dns4/bootnode2.fennel.network/tcp/30333/p2p/12D3KooWLWzcGVuLycfL1W83yc9S4UmVJ8qBd4Rk5mS6RJ4Bh7Su" \
            --rpc-cors all \
            --rpc-methods safe \
            --log info \
            --db-cache 1024
        ;;
    
    init)
        echo "🔧 Initializing validator..."
        load_config
        check_binary
        ensure_chainspec
        
        # Check if network key already exists
        NETWORK_KEY_PATH="$DATA_DIR/chains/custom/network/secret_ed25519"
        if [ -f "$NETWORK_KEY_PATH" ]; then
            echo "✅ Network keys already exist"
            return 0
        fi
        
        echo "🔑 Generating network keys..."
        echo "This will take 30-60 seconds..."
        
        # Create data directory if it doesn't exist
        mkdir -p "$DATA_DIR"
        
        # Start briefly to generate keys with timeout handling
        timeout 120 ./"$BINARY" \
            --chain "config/staging-chainspec.json" \
            --name "$VALIDATOR_NAME" \
            --base-path "$DATA_DIR" \
            --port "$P2P_PORT" \
            --rpc-port "$RPC_PORT" \
            --prometheus-port "$PROMETHEUS_PORT" \
            --bootnodes="/dns4/bootnode1.fennel.network/tcp/30333/p2p/12D3KooWS84f71ufMQRsm9YWynfK5Zxa6iSooStJECnAT3RBVVxz" \
            --bootnodes="/dns4/bootnode2.fennel.network/tcp/30333/p2p/12D3KooWLWzcGVuLycfL1W83yc9S4UmVJ8qBd4Rk5mS6RJ4Bh7Su" \
            --rpc-cors all \
            --rpc-methods safe \
            --log error > /dev/null 2>&1 &
        
        INIT_PID=$!
        
        # Wait for network key to be generated
        for i in {1..60}; do
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
            echo "❌ Failed to generate network keys after 120 seconds"
            echo "❌ Check your network connection and try again"
            echo "💡 You can retry with: ./validate.sh init"
            exit 1
        fi
        ;;
    
    stop)
        echo "🛑 Stopping validator..."
        pkill -f "fennel-node.*--validator" || echo "Validator was not running"
        ;;
    
    status)
        if pgrep -f "fennel-node.*--validator" > /dev/null; then
            echo "✅ Validator is running"
            echo "📊 Status: http://localhost:${RPC_PORT:-9944}"
            echo "📈 Metrics: http://localhost:${PROMETHEUS_PORT:-9615}/metrics"
        else
            echo "❌ Validator is not running"
        fi
        ;;
    
    restart)
        $0 stop
        sleep 3
        $0 start
        ;;
    
    logs)
        echo "📋 Recent validator logs:"
        journalctl --user -u fennel-validator --lines 50 2>/dev/null || \
        pkill -USR1 -f "fennel-node.*--validator" 2>/dev/null || \
        echo "No logs available - check if validator is running"
        ;;
    
    *)
        echo "Usage: $0 {init|start|stop|status|restart|logs}"
        echo
        echo "Commands:"
        echo "  init    - Initialize validator (generate network keys) - Run this first!"
        echo "  start   - Start the validator"
        echo "  stop    - Stop the validator" 
        echo "  status  - Check if validator is running"
        echo "  restart - Restart the validator"
        echo "  logs    - View recent validator logs"
        echo
        echo "🔧 Tip: Run './setup-validator.sh' first if you haven't configured your validator"
        ;;
esac
