#!/bin/bash
# Fennel Validator Setup Script
# Interactive configuration for external validators

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

CONFIG_FILE="config/validator.conf"
REPO_URL="https://github.com/CorruptedAesthetic/fennel-solonet"

echo -e "${BLUE}⚙️  Fennel Validator Setup${NC}"
echo "=================================="

# Function to print status
print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

print_question() {
    echo -e "${CYAN}❓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if binaries exist
check_prerequisites() {
    echo -e "\n${BLUE}🔍 Checking prerequisites...${NC}"
    
    if [ ! -f "bin/fennel-node" ] && [ ! -f "bin/fennel-node.exe" ]; then
        print_error "Fennel node binary not found!"
        echo "Please run: ./install.sh first"
        exit 1
    fi
    
    if [ ! -f "config/staging-chainspec.json" ]; then
        print_error "Staging chainspec not found!"
        echo "Please run: ./install.sh first"
        exit 1
    fi
    
    print_info "Prerequisites check passed"
}

# Get user input with default
get_input() {
    local prompt="$1"
    local default="$2"
    local result
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " result
        echo "${result:-$default}"
    else
        read -p "$prompt: " result
        echo "$result"
    fi
}

# Validate port number
validate_port() {
    local port="$1"
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1024 ] && [ "$port" -le 65535 ]; then
        return 0
    else
        return 1
    fi
}

# Interactive configuration
configure_validator() {
    echo -e "\n${BLUE}🔧 Validator Configuration${NC}"
    echo "Let's configure your Fennel validator..."
    echo
    
    # Validator name
    echo "ℹ️  Validator Name: How your validator appears on the network"
    echo "   • Default includes your hostname (press Enter to accept)"
    echo "   • Make it unique and identifiable (avoid special characters)"
    echo "   • Examples: 'MyCompany-Validator', 'Alice-Staging', 'University-Node'"
    echo "   • This name will be visible to other validators and in blockchain explorers"
    echo
    default_name="External-Validator-$(hostname)"
    print_question "What should we call your validator?"
    VALIDATOR_NAME=$(get_input "Validator name (press Enter for $default_name)" "$default_name")
    
    # Network selection (staging only)
    echo
    print_info "🧪 Configuring for Fennel Staging Network"
    echo
    echo "This repository is designed exclusively for staging validation:"
    echo "✅ Safe learning environment - no financial risk"
    echo "✅ Full validator functionality"
    echo "✅ Connect to real staging blockchain"
    echo "✅ Perfect for mastering validator operations"
    echo
    
    NETWORK="staging"
    CHAINSPEC="staging-chainspec.json"
    
    print_info "Network configured: Fennel Staging"
    
    # For production validation, direct to production repository
    echo
    print_info "💡 Ready for production later? Check out FennelValidatorProduction repository"
    
    # Port configuration
    echo
    print_question "Network port configuration:"
    echo
    echo "ℹ️  P2P Port: This is the port other validators use to connect to you"
    echo "   • Default 30333 works for 99% of cases (press Enter to accept)"
    echo "   • Only change if: port conflict, multiple validators, or firewall issues"
    echo "   • Common alternatives: 30334, 30335, 30336"
    echo
    
    P2P_PORT=$(get_input "P2P port (press Enter for 30333)" "30333")
    while ! validate_port "$P2P_PORT"; do
        print_warning "Invalid port. Please enter a port between 1024-65535"
        P2P_PORT=$(get_input "P2P port (press Enter for 30333)" "30333")
    done
    
    echo "ℹ️  RPC Port: For local tools to connect to your validator (Polkadot.js, etc.)"
    echo "   • Default 9944 is standard (press Enter to accept)"
    echo "   • Keep default unless you have specific requirements"
    echo
    RPC_PORT=$(get_input "RPC port (press Enter for 9944)" "9944")
    while ! validate_port "$RPC_PORT"; do
        print_warning "Invalid port. Please enter a port between 1024-65535"
        RPC_PORT=$(get_input "RPC port (press Enter for 9944)" "9944")
    done
    
    echo "ℹ️  Prometheus Port: For monitoring and metrics collection"
    echo "   • Default 9615 is standard (press Enter to accept)"
    echo "   • Used by monitoring tools like Grafana"
    echo
    PROMETHEUS_PORT=$(get_input "Prometheus port (press Enter for 9615)" "9615")
    while ! validate_port "$PROMETHEUS_PORT"; do
        print_warning "Invalid port. Please enter a port between 1024-65535"
        PROMETHEUS_PORT=$(get_input "Prometheus port (press Enter for 9615)" "9615")
    done
    
    # Data directory
    echo
    echo "ℹ️  Data Directory: Where your validator stores blockchain data and keys"
    echo "   • Default './data' works for most cases (press Enter to accept)"
    echo "   • Staging network: ~2-5GB storage needed"
    echo "   • Consider external drive for: production, limited disk space, or faster SSD"
    echo "   • Examples: './data', '/mnt/validator-data', '/opt/fennel/data'"
    echo
    DEFAULT_DATA_DIR="./data"
    DATA_DIR=$(get_input "Data directory (press Enter for ./data)" "$DEFAULT_DATA_DIR")
    
    # Create data directory
    mkdir -p "$DATA_DIR"
    print_info "Created data directory: $DATA_DIR"
    
    # Advanced options
    echo
    echo "ℹ️  Advanced Options: External RPC access, monitoring, and debug settings"
    echo "   • Most validators: Press Enter (no) - defaults work great for staging"
    echo "   • Only enable if you need: external monitoring tools, debug logging, or RPC access"
    echo "   • You can always re-run setup later to change these"
    echo
    print_question "Would you like to configure advanced options? (y/n)"
    advanced_config=$(get_input "Configure advanced options (press Enter for no)" "n")
    
    if [[ "$advanced_config" =~ ^[Yy] ]]; then
        configure_advanced
    else
        # Use defaults
        RPC_EXTERNAL="false"
        PROMETHEUS_EXTERNAL="false"
        LOG_LEVEL="info"
    fi
}

configure_advanced() {
    echo -e "\n${BLUE}🔧 Advanced Configuration${NC}"
    
    # External RPC access
    print_question "Allow external RPC access? (Only enable if you know what you're doing)"
    echo "This allows other applications to connect to your validator's RPC interface"
    rpc_choice=$(get_input "Enable external RPC? (y/n)" "n")
    if [[ "$rpc_choice" =~ ^[Yy] ]]; then
        RPC_EXTERNAL="true"
        print_warning "External RPC enabled - ensure your firewall is properly configured!"
    else
        RPC_EXTERNAL="false"
    fi
    
    # External Prometheus access
    print_question "Allow external Prometheus metrics access?"
    echo "This allows monitoring systems to collect metrics from your validator"
    prom_choice=$(get_input "Enable external Prometheus? (y/n)" "n")
    if [[ "$prom_choice" =~ ^[Yy] ]]; then
        PROMETHEUS_EXTERNAL="true"
    else
        PROMETHEUS_EXTERNAL="false"
    fi
    
    # Log level
    print_question "Log verbosity level?"
    echo "Options: error, warn, info, debug, trace"
    LOG_LEVEL=$(get_input "Log level" "info")
}

# Generate validator keys
generate_keys() {
    echo -e "\n${BLUE}🔑 Generating Validator Keys${NC}"
    
    BINARY="bin/fennel-node"
    if [ -f "bin/fennel-node.exe" ]; then
        BINARY="bin/fennel-node.exe"
    fi
    
    # Generate session keys
    print_info "Generating session keys..."
    KEY_OUTPUT=$("./$BINARY" key generate --scheme sr25519 --password-interactive)
    
    # Extract the seed phrase and public key (this is a simplified version)
    echo -e "\n${YELLOW}🔐 IMPORTANT: Save this information securely!${NC}"
    echo "----------------------------------------"
    echo "$KEY_OUTPUT"
    echo "----------------------------------------"
    echo
    print_warning "Write down the seed phrase above and store it safely!"
    print_warning "You'll need it to recover your validator if needed."
    
    echo
    read -p "Press Enter after you've saved the seed phrase..." -r
}

# Auto-discover network connection
discover_network() {
    echo -e "\n${BLUE}🔍 Discovering Network Connection${NC}"
    
    if [ "$NETWORK" = "staging" ]; then
        # Try to use the connection discovery script if available
        if [ -f "scripts/get-connection-info.sh" ]; then
            print_info "Using automatic network discovery..."
            bash scripts/get-connection-info.sh > network-info.tmp 2>/dev/null || true
            
            # Extract bootnode information from the output
            if grep -q "Bootnode Multiaddr" network-info.tmp 2>/dev/null; then
                BOOTNODE=$(grep "Bootnode Multiaddr" network-info.tmp | cut -d' ' -f3)
                print_info "Discovered bootnode: $BOOTNODE"
            else
                print_warning "Could not auto-discover network, using defaults"
                BOOTNODE=""
            fi
            
            rm -f network-info.tmp
        else
            print_info "Using default staging network configuration"
            BOOTNODE=""
        fi
    else
        print_info "Using mainnet configuration"
        BOOTNODE=""
    fi
}

# Save configuration
save_config() {
    echo -e "\n${BLUE}💾 Saving Configuration${NC}"
    
    cat > "$CONFIG_FILE" << EOF
# Fennel Validator Configuration
# Generated on $(date)

VALIDATOR_NAME="$VALIDATOR_NAME"
NETWORK="$NETWORK"
CHAINSPEC="$CHAINSPEC"
DATA_DIR="$DATA_DIR"
P2P_PORT="$P2P_PORT"
RPC_PORT="$RPC_PORT"
PROMETHEUS_PORT="$PROMETHEUS_PORT"
RPC_EXTERNAL="$RPC_EXTERNAL"
PROMETHEUS_EXTERNAL="$PROMETHEUS_EXTERNAL"
LOG_LEVEL="$LOG_LEVEL"
BOOTNODE="$BOOTNODE"
REPO_URL="$REPO_URL"
EOF
    
    print_info "Configuration saved to $CONFIG_FILE"
}

# Generate startup script
generate_startup_script() {
    echo -e "\n${BLUE}📝 Generating Startup Script${NC}"
    
    BINARY="bin/fennel-node"
    if [ -f "bin/fennel-node.exe" ]; then
        BINARY="bin/fennel-node.exe"
    fi
    
    cat > validate.sh << 'EOF'
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
    
    # Always add staging bootnode for external validators
    if [ "$NETWORK" = "staging" ]; then
        CMD="$CMD --bootnodes \"/ip4/192.168.49.2/tcp/30604/p2p/12D3KooWRpzRTivvJ5ySvgbFnPeEE6rDhitQKL1fFJvvBGhnenSk\""
    elif [ -n "$BOOTNODE" ]; then
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
        
        FULL_CMD=$(build_command)
        echo "Command: $FULL_CMD"
        echo
        
        eval "$FULL_CMD"
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
        echo "Usage: $0 {start|stop|restart|status|logs|command|update-chainspec}"
        echo
        echo "Commands:"
        echo "  start                      - Start validator (auto-updates staging chainspec)"
        echo "  stop                       - Stop the validator"
        echo "  restart                    - Restart the validator"  
        echo "  status                     - Check validator status"
        echo "  logs                       - View validator logs"
        echo "  command                    - Show the command that would be executed"
        echo "  update-chainspec           - Update chainspec from fennel-solonet"
        echo "  update-chainspec --force   - Force update (production use only)"
        echo
        echo "Chainspec Update Behavior:"
        echo "  • Staging: Automatically updates on start (safe for testing)"
        echo "  • Mainnet: Detects updates but requires manual confirmation"
        echo "  • Force update: Bypasses safety checks (coordinate with operators)"
        ;;
esac
EOF
    
    chmod +x validate.sh
    print_info "Created validate.sh management script"
}

# Main setup flow
main() {
    check_prerequisites
    configure_validator
    discover_network
    save_config
    generate_startup_script
    
    echo -e "\n${GREEN}🎉 Setup Complete!${NC}"
    echo "=================================="
    echo
    echo "Your Fennel validator is now configured:"
    echo "• Name: $VALIDATOR_NAME"
    echo "• Network: $NETWORK"
    echo "• Data directory: $DATA_DIR"
    echo "• P2P port: $P2P_PORT"
    echo "• RPC port: $RPC_PORT"
    echo "• Prometheus port: $PROMETHEUS_PORT"
    echo
    echo "Next steps:"
    echo -e "1. Start your validator: ${BLUE}./validate.sh start${NC}"
    echo -e "2. Check status: ${BLUE}./validate.sh status${NC}"
    echo -e "3. Generate session keys: ${BLUE}./scripts/generate-session-keys.sh${NC}"
    echo "4. Send us your session-keys.json file for network inclusion!"
    echo
    echo "Additional commands:"
    echo -e "• View logs: ${BLUE}./validate.sh logs${NC}"
    echo -e "• Stop validator: ${BLUE}./validate.sh stop${NC}"
    echo
    echo "Repository: $REPO_URL"
}

# Run main function
main "$@" 