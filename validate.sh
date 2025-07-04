#!/bin/bash
# Fennel Validator Management Script

CONFIG_FILE="config/validator.conf"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "❌ Configuration not found. Please run ./setup-validator.sh first"
    exit 1
fi

# Determine binary path
BINARY="bin/fennel-node"
if [ -f "bin/fennel-node.exe" ]; then
    BINARY="bin/fennel-node.exe"
fi

# Ensure latest chainspec before starting
update_chainspec() {
    echo "🔄 Checking for chainspec updates..."
    RAW_URL="https://raw.githubusercontent.com/CorruptedAesthetic/fennel-solonet/main"
    
    if [ "$NETWORK" = "staging" ]; then
        CHAINSPEC_URL="$RAW_URL/chainspecs/staging/staging-raw.json"
        LOCAL_CHAINSPEC="config/staging-chainspec.json"
    else
        CHAINSPEC_URL="$RAW_URL/chainspecs/mainnet/mainnet-raw.json"
        LOCAL_CHAINSPEC="config/mainnet-chainspec.json"
    fi
    
    # For staging: Auto-update (safe for testing)
    if [ "$NETWORK" = "staging" ]; then
        echo "📥 Auto-updating staging chainspec (safe for testing)..."
        if curl -s --max-time 30 "$CHAINSPEC_URL" -o "${LOCAL_CHAINSPEC}.tmp"; then
            if [ -s "${LOCAL_CHAINSPEC}.tmp" ]; then
                mv "${LOCAL_CHAINSPEC}.tmp" "$LOCAL_CHAINSPEC"
                echo "✅ Updated to latest staging chainspec"
            else
                rm -f "${LOCAL_CHAINSPEC}.tmp"
                echo "⚠️  Downloaded chainspec is empty, using existing"
            fi
        else
            rm -f "${LOCAL_CHAINSPEC}.tmp"
            if [ ! -f "$LOCAL_CHAINSPEC" ]; then
                echo "❌ Failed to download chainspec and no local copy exists"
                return 1
            fi
            echo "⚠️  Failed to download latest chainspec, using existing"
        fi
    else
        # For production: Check for updates but require manual confirmation
        echo "🔍 Checking for mainnet chainspec updates..."
        if curl -s --max-time 30 "$CHAINSPEC_URL" -o "${LOCAL_CHAINSPEC}.tmp"; then
            if [ -s "${LOCAL_CHAINSPEC}.tmp" ]; then
                # Compare checksums to detect changes
                if [ -f "$LOCAL_CHAINSPEC" ]; then
                    OLD_HASH=$(sha256sum "$LOCAL_CHAINSPEC" | cut -d' ' -f1)
                    NEW_HASH=$(sha256sum "${LOCAL_CHAINSPEC}.tmp" | cut -d' ' -f1)
                    
                    if [ "$OLD_HASH" != "$NEW_HASH" ]; then
                        echo ""
                        echo "⚠️  CHAINSPEC UPDATE DETECTED FOR MAINNET"
                        echo "⚠️  This may require coordinated validator restart"
                        echo "⚠️  Current chainspec: $OLD_HASH"
                        echo "⚠️  New chainspec:     $NEW_HASH"
                        echo ""
                        echo "🛑 PRODUCTION SAFETY: Manual update required"
                        echo "   Run: ./validate.sh update-chainspec --force"
                        echo "   Only after coordinating with network operators"
                        rm -f "${LOCAL_CHAINSPEC}.tmp"
                        return 0  # Don't fail, just warn
                    else
                        echo "✅ Mainnet chainspec is current"
                        rm -f "${LOCAL_CHAINSPEC}.tmp"
                    fi
                else
                    # No existing chainspec, use the new one
                    mv "${LOCAL_CHAINSPEC}.tmp" "$LOCAL_CHAINSPEC"
                    echo "✅ Downloaded initial mainnet chainspec"
                fi
            else
                rm -f "${LOCAL_CHAINSPEC}.tmp"
                echo "⚠️  Downloaded chainspec is empty"
            fi
        else
            rm -f "${LOCAL_CHAINSPEC}.tmp"
            if [ ! -f "$LOCAL_CHAINSPEC" ]; then
                echo "❌ Failed to download chainspec and no local copy exists"
                return 1
            fi
            echo "⚠️  Failed to download latest chainspec, using existing"
        fi
    fi
    return 0
}

# Initialize validator (generate network keys and sync on first run)
initialize_validator() {
    echo "🔧 Initializing validator..."
    
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
    
    # Build initialization command (without --validator flag)
    local INIT_CMD="./$BINARY"
    INIT_CMD="$INIT_CMD --chain config/$CHAINSPEC"
    INIT_CMD="$INIT_CMD --name \"$VALIDATOR_NAME\""
    INIT_CMD="$INIT_CMD --base-path \"$DATA_DIR\""
    INIT_CMD="$INIT_CMD --port $P2P_PORT"
    INIT_CMD="$INIT_CMD --rpc-port $RPC_PORT"
    INIT_CMD="$INIT_CMD --prometheus-port $PROMETHEUS_PORT"
    INIT_CMD="$INIT_CMD --log $LOG_LEVEL"
    
    if [ "$RPC_EXTERNAL" = "true" ]; then
        INIT_CMD="$INIT_CMD --rpc-external"
    fi
    
    if [ "$PROMETHEUS_EXTERNAL" = "true" ]; then
        INIT_CMD="$INIT_CMD --prometheus-external"
    fi
    
    INIT_CMD="$INIT_CMD --rpc-cors all"
    INIT_CMD="$INIT_CMD --rpc-methods safe"
    
    # Only use custom bootnode if explicitly configured
    # Let chainspec handle bootnode discovery by default
    if [ -n "$BOOTNODE" ]; then
        INIT_CMD="$INIT_CMD --bootnodes \"$BOOTNODE\""
    fi
    
    # Performance optimizations
    INIT_CMD="$INIT_CMD --db-cache 1024"
    
    echo "Initialization command: $INIT_CMD"
    echo "Starting initialization (will stop automatically after key generation)..."
    
    # Start the node briefly to generate keys and initial sync
    # Use a longer timeout and better error handling
    timeout 90 bash -c "eval '$INIT_CMD'" &
    INIT_PID=$!
    
    # Wait for network key to be generated (check every 2 seconds)
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
        return 0
    else
        echo "❌ Failed to generate network keys after 90 seconds"
        echo "❌ Check your network connection and try again"
        echo "💡 You can retry with: ./validate.sh init"
        return 1
    fi
}

# Build the command
build_command() {
    local CMD="./$BINARY"
    CMD="$CMD --chain config/$CHAINSPEC"
    CMD="$CMD --validator"
    CMD="$CMD --name \"$VALIDATOR_NAME\""
    CMD="$CMD --base-path \"$DATA_DIR\""
    CMD="$CMD --port $P2P_PORT"
    CMD="$CMD --rpc-port $RPC_PORT"
    CMD="$CMD --prometheus-port $PROMETHEUS_PORT"
    CMD="$CMD --log $LOG_LEVEL"
    
    if [ "$RPC_EXTERNAL" = "true" ]; then
        CMD="$CMD --rpc-external"
    fi
    
    if [ "$PROMETHEUS_EXTERNAL" = "true" ]; then
        CMD="$CMD --prometheus-external"
    fi
    
    CMD="$CMD --rpc-cors all"
    CMD="$CMD --rpc-methods safe"
    
    # Only use custom bootnode if explicitly configured
    # Let chainspec handle bootnode discovery by default
    if [ -n "$BOOTNODE" ]; then
        CMD="$CMD --bootnodes \"$BOOTNODE\""
    fi
    
    # Performance optimizations (conservative settings for compatibility)
    CMD="$CMD --db-cache 1024"
    
    echo "$CMD"
}

case "${1:-}" in
    start)
        echo "🚀 Starting Fennel validator..."
        echo "Network: $NETWORK"
        echo "Validator: $VALIDATOR_NAME"
        echo "Data directory: $DATA_DIR"
        echo
        
        # Ensure we have the latest chainspec
        if ! update_chainspec; then
            echo "❌ Failed to update chainspec"
            exit 1
        fi
        echo
        
        # Initialize validator if needed (generates network keys)
        if ! initialize_validator; then
            echo "❌ Failed to initialize validator"
            exit 1
        fi
        echo
        
        FULL_CMD=$(build_command)
        echo "Command: $FULL_CMD"
        echo
        
        eval "$FULL_CMD"
        ;;
    
    init)
        echo "🔧 Initializing Fennel validator..."
        echo "Network: $NETWORK"
        echo "Validator: $VALIDATOR_NAME"
        echo "Data directory: $DATA_DIR"
        echo
        
        # Ensure we have the latest chainspec
        if ! update_chainspec; then
            echo "❌ Failed to update chainspec"
            exit 1
        fi
        echo
        
        # Initialize validator
        if ! initialize_validator; then
            echo "❌ Failed to initialize validator"
            exit 1
        fi
        
        echo "✅ Validator initialization complete!"
        echo "You can now start the validator with: ./validate.sh start"
        ;;
    
    status)
        if pgrep -f "fennel-node.*--validator" > /dev/null; then
            echo "✅ Validator is running"
            echo "📊 Status: http://localhost:$RPC_PORT"
            echo "📈 Metrics: http://localhost:$PROMETHEUS_PORT/metrics"
        else
            echo "❌ Validator is not running"
        fi
        ;;
    
    stop)
        echo "🛑 Stopping validator..."
        pkill -f "fennel-node.*--validator" || echo "Validator was not running"
        ;;
    
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    
    logs)
        echo "📋 Recent validator logs:"
        echo "Use Ctrl+C to stop following logs"
        tail -f "$DATA_DIR/chains/*/network.log" 2>/dev/null || echo "No logs found yet"
        ;;
    
    command)
        echo "Command that would be executed:"
        build_command
        ;;
    
    update-chainspec)
        if [ "$2" = "--force" ]; then
            echo "🔄 Force updating chainspec from fennel-solonet repository..."
            # Force update by temporarily setting network to staging behavior
            FORCE_UPDATE=true
        else
            echo "🔄 Updating chainspec from fennel-solonet repository..."
            FORCE_UPDATE=false
        fi
        
        if [ "$FORCE_UPDATE" = "true" ] && [ "$NETWORK" = "mainnet" ]; then
            echo "⚠️  FORCE UPDATE: Bypassing production safety checks"
            echo "⚠️  Ensure this is coordinated with network operators!"
            echo ""
            read -p "Continue with force update? [y/N]: " -r
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "❌ Force update cancelled"
                exit 1
            fi
            
            # Temporarily override network for force update
            ORIGINAL_NETWORK="$NETWORK"
            NETWORK="staging"  # Use staging update logic
            update_chainspec
            NETWORK="$ORIGINAL_NETWORK"  # Restore original
        else
            update_chainspec
        fi
        
        if [ $? -eq 0 ]; then
            echo "✅ Chainspec update completed"
        else
            echo "❌ Chainspec update failed"
            exit 1
        fi
        ;;
    
    *)
        echo "Fennel Validator Management"
        echo
        echo "Usage: $0 {init|start|stop|restart|status|logs|command|update-chainspec}"
        echo
        echo "Commands:"
        echo "  init                       - Initialize validator (generate network keys)"
        echo "  start                      - Start validator (auto-initializes if needed)"
        echo "  stop                       - Stop the validator"
        echo "  restart                    - Restart the validator"  
        echo "  status                     - Check validator status"
        echo "  logs                       - View validator logs"
        echo "  command                    - Show the command that would be executed"
        echo "  update-chainspec           - Update chainspec from fennel-solonet"
        echo "  update-chainspec --force   - Force update (production use only)"
        echo
        echo "First Time Setup:"
        echo "  1. Run './validate.sh init' to generate network keys (optional)"
        echo "  2. Run './validate.sh start' to start validating"
        echo
        echo "Chainspec Update Behavior:"
        echo "  • Staging: Automatically updates on start (safe for testing)"
        echo "  • Mainnet: Detects updates but requires manual confirmation"
        echo "  • Force update: Bypasses safety checks (coordinate with operators)"
        ;;
esac
