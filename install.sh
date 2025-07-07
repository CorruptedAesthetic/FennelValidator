#!/bin/bash
# Fennel Validator Installer - Simple 3-Step Setup
# Downloads and sets up everything needed for external validators

set -e

echo "🧪 Fennel External Validator Installer"
echo "====================================="
echo "Simple 3-step setup for staging network"
echo

REPO_URL="https://github.com/CorruptedAesthetic/fennel-solonet"
RELEASES_URL="$REPO_URL/releases"
VALIDATOR_REPO_URL="https://raw.githubusercontent.com/CorruptedAesthetic/FennelValidator/main"
DOCKER_IMAGE="ghcr.io/corruptedaesthetic/fennel-solonet:sha-c31d08ee9aff81c0cb9ea255278780e79ffd559c"

# Function to print status
print_info() {
    echo "✅ $1"
}

print_warning() {
    echo "⚠️  $1"
}

print_error() {
    echo "❌ $1"
}

# Get absolute path of script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if Docker is available
check_docker() {
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            return 0
        else
            print_warning "Docker is installed but not running"
            return 1
        fi
    else
        print_warning "Docker is not installed"
        return 1
    fi
}

# Extract binary from Docker image
extract_binary_from_docker() {
    echo "🐳 Extracting fennel-node binary from Docker image..."
    
    # Create temporary container and copy binary
    CONTAINER_ID=$(docker create "$DOCKER_IMAGE" 2>/dev/null)
    if [ $? -eq 0 ]; then
        # Try common binary locations
        for path in "/usr/local/bin/fennel-node" "/usr/bin/fennel-node" "/fennel-node"; do
            if docker cp "$CONTAINER_ID:$path" "bin/fennel-node" 2>/dev/null; then
                docker rm "$CONTAINER_ID" >/dev/null 2>&1
                chmod +x "bin/fennel-node"
                print_info "Binary extracted from Docker image and ready for use"
                return 0
            fi
        done
        
        # If direct paths don't work, find the binary
        docker cp "$CONTAINER_ID:/" "temp_extract" 2>/dev/null
        if [ -d "temp_extract" ]; then
            BINARY_PATH=$(find temp_extract -name "fennel-node" -type f 2>/dev/null | head -1)
            if [ -n "$BINARY_PATH" ]; then
                cp "$BINARY_PATH" "bin/fennel-node"
                chmod +x "bin/fennel-node"
                rm -rf temp_extract
                docker rm "$CONTAINER_ID" >/dev/null 2>&1
                print_info "Binary found and extracted successfully"
                return 0
            fi
            rm -rf temp_extract
        fi
        
        docker rm "$CONTAINER_ID" >/dev/null 2>&1
    fi
    
    print_error "Failed to extract binary from Docker image"
    return 1
}

# Detect platform
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case $arch in
        x86_64) arch="x64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) print_error "Unsupported architecture: $arch"; exit 1 ;;
    esac
    
    case $os in
        linux) platform="linux-$arch" ;;
        darwin) platform="macos-$arch" ;;
        mingw*|cygwin*|msys*) platform="windows-$arch"; ext=".exe" ;;
        *) print_error "Unsupported OS: $os"; exit 1 ;;
    esac
    
    echo "$platform"
}

# Get latest release version
get_latest_version() {
    local version=$(curl -s "$RELEASES_URL/latest" 2>/dev/null | grep -o 'tag/[^"]*' | cut -d'/' -f2 | head -1 2>/dev/null)
    if [ -z "$version" ]; then
        echo "v0.3.1"  # Fallback to known version
    else
        echo "$version"
    fi
}

# Download file with progress
download_file() {
    local url="$1"
    local output="$2"
    local description="$3"
    
    echo "⬇️  Downloading $description..."
    if command -v curl > /dev/null; then
        if curl -L "$url" -o "$output" 2>/dev/null; then
            print_info "$description downloaded successfully"
            return 0
        else
            print_error "Failed to download $description from $url"
            return 1
        fi
    elif command -v wget > /dev/null; then
        if wget "$url" -O "$output" 2>/dev/null; then
            print_info "$description downloaded successfully"
            return 0
        else
            print_error "Failed to download $description from $url"
            return 1
        fi
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
}

echo
echo "🔍 Detecting system..."
PLATFORM=$(detect_platform)
VERSION=$(get_latest_version)
print_info "Platform: $PLATFORM"
print_info "Version: $VERSION"

echo
echo "📦 Creating comprehensive directory structure..."
mkdir -p bin scripts config validator-data tools/internal tools/bin
print_info "Essential directories created"

# Create symlinks for session key script compatibility
echo "🔗 Setting up script compatibility links..."
if [ ! -f "tools/bin/fennel-node" ]; then
    ln -sf "../../bin/fennel-node" "tools/bin/fennel-node" 2>/dev/null || true
fi
print_info "Script compatibility links created"

echo
echo "⬇️  Downloading Fennel node binary..."
# Try to download from GitHub releases first
BINARY_NAME="fennel-node"
if [[ "$PLATFORM" == *"windows"* ]]; then
    BINARY_NAME="fennel-node.exe"
fi

DOWNLOAD_URL="$RELEASES_URL/download/$VERSION/$BINARY_NAME"
BINARY_DOWNLOADED=false

if curl -s --head "$DOWNLOAD_URL" 2>/dev/null | head -n 1 | grep -q "200 OK"; then
    if download_file "$DOWNLOAD_URL" "bin/fennel-node$ext" "Fennel node binary"; then
        chmod +x "bin/fennel-node$ext"
        print_info "Binary ready for use"
        BINARY_DOWNLOADED=true
    fi
fi

# If binary download failed, try Docker extraction
if [ "$BINARY_DOWNLOADED" = false ]; then
    print_warning "Pre-built binary not available for $PLATFORM"
    
    if check_docker; then
        echo "🐳 Attempting to extract binary from Docker image..."
        if extract_binary_from_docker; then
            BINARY_DOWNLOADED=true
        fi
    fi
fi

# If both methods failed, provide build instructions
if [ "$BINARY_DOWNLOADED" = false ]; then
    echo "📝 Creating build instructions..."
    echo "# Build from source" > bin/README.md
    echo "Requirements: Rust toolchain (https://rustup.rs/)" >> bin/README.md
    echo "" >> bin/README.md
    echo "Steps:" >> bin/README.md
    echo "1. git clone $REPO_URL" >> bin/README.md
    echo "2. cd fennel-solonet" >> bin/README.md
    echo "3. cargo build --release" >> bin/README.md
    echo "4. cp target/release/fennel-node ../bin/" >> bin/README.md
    echo "" >> bin/README.md
    echo "Alternative: Install Docker and re-run this installer" >> bin/README.md
    print_info "Build instructions created in bin/README.md"
fi

echo
echo "📥 Downloading staging chainspec..."
CHAINSPEC_URL="https://raw.githubusercontent.com/CorruptedAesthetic/fennel-solonet/main/chainspecs/staging/staging-raw.json"
if download_file "$CHAINSPEC_URL" "config/staging-chainspec.json" "Staging chainspec"; then
    print_info "Staging chainspec ready for use"
else
    print_warning "Chainspec download failed - will retry when starting validator"
fi

echo
echo "📜 Downloading enhanced validator scripts..."

# Download comprehensive script set
SCRIPTS_TO_DOWNLOAD=(
    "setup-validator.sh:setup-validator.sh"
    "scripts/generate-session-keys.sh:scripts/generate-session-keys.sh"
    "tools/complete-registration.sh:tools/complete-registration.sh"
    "tools/internal/generate-keys-with-restart.sh:tools/internal/generate-keys-with-restart.sh"
    "tools/internal/generate-stash-account.sh:tools/internal/generate-stash-account.sh"
)

for script_info in "${SCRIPTS_TO_DOWNLOAD[@]}"; do
    remote_path="${script_info%%:*}"
    local_path="${script_info##*:}"
    
    # Create directory if needed
    mkdir -p "$(dirname "$local_path")"
    
    if download_file "$VALIDATOR_REPO_URL/$remote_path" "$local_path" "$(basename "$remote_path")"; then
        chmod +x "$local_path"
    else
        print_warning "Failed to download $remote_path - will create basic version"
fi
done

# Create enhanced validate.sh script with better path handling
echo "📝 Creating enhanced validator management script..."
cat > validate.sh << 'EOF'
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
            --bootnodes="/ip4/135.18.208.132/tcp/30333/p2p/12D3KooWS84f71ufMQRsm9YWynfK5Zxa6iSooStJECnAT3RBVVxz" \
            --bootnodes="/ip4/132.196.191.14/tcp/30333/p2p/12D3KooWLWzcGVuLycfL1W83yc9S4UmVJ8qBd4Rk5mS6RJ4Bh7Su" \
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
            --bootnodes="/ip4/135.18.208.132/tcp/30333/p2p/12D3KooWS84f71ufMQRsm9YWynfK5Zxa6iSooStJECnAT3RBVVxz" \
            --bootnodes="/ip4/132.196.191.14/tcp/30333/p2p/12D3KooWLWzcGVuLycfL1W83yc9S4UmVJ8qBd4Rk5mS6RJ4Bh7Su" \
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
EOF

chmod +x validate.sh
print_info "Enhanced validator management script created"

echo
echo "🔧 Creating session key generation compatibility..."

# Create enhanced session key script that handles path issues
if [ ! -f "scripts/generate-session-keys.sh" ]; then
    cat > scripts/generate-session-keys.sh << 'EOF'
#!/bin/bash
# Enhanced Session Key Generation with path resolution

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATOR_DIR="$(dirname "$SCRIPT_DIR")"
cd "$VALIDATOR_DIR"

# Check if enhanced script exists, otherwise use basic method
if [ -f "tools/internal/generate-keys-with-restart.sh" ]; then
    echo "Using enhanced key generation method..."
    exec "./tools/internal/generate-keys-with-restart.sh" "$@"
else
    echo "Using basic key generation method..."
    
    # Basic session key generation
    if [ ! -f "config/validator.conf" ]; then
        echo "❌ Configuration not found. Run ./setup-validator.sh first"
        exit 1
    fi
    
    source "config/validator.conf"
    
    echo "🔑 Generating session keys..."
    echo "This requires the validator to be running with unsafe RPC temporarily."
    echo
    
    # Check if validator is running
    if ! pgrep -f "fennel-node.*--validator" > /dev/null; then
        echo "❌ Validator is not running. Start it with: ./validate.sh start"
        exit 1
    fi
    
    # Generate keys via RPC
    KEYS_RESPONSE=$(curl -s -H "Content-Type: application/json" \
        -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}' \
        http://localhost:${RPC_PORT:-9944})
    
    if echo "$KEYS_RESPONSE" | grep -q '"result"'; then
        SESSION_KEYS=$(echo "$KEYS_RESPONSE" | jq -r '.result' 2>/dev/null || echo "$KEYS_RESPONSE" | grep -o '"result":"[^"]*' | cut -d'"' -f4)
        
        if [ -n "$SESSION_KEYS" ] && [ "$SESSION_KEYS" != "null" ]; then
            echo "✅ Session keys generated successfully!"
            echo "Session Keys: $SESSION_KEYS"
            
            # Save to file
            mkdir -p validator-data
            cat > validator-data/session-keys.json << END
{
    "validator_name": "$VALIDATOR_NAME",
    "session_keys": "$SESSION_KEYS",
    "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")"
}
END
            echo "💾 Keys saved to: validator-data/session-keys.json"
        else
            echo "❌ Failed to extract session keys from response"
            echo "Response: $KEYS_RESPONSE"
            exit 1
        fi
    else
        echo "❌ RPC call failed. Make sure validator is running and RPC is accessible."
        echo "Response: $KEYS_RESPONSE"
        exit 1
    fi
fi
EOF
    chmod +x scripts/generate-session-keys.sh
    print_info "Basic session key generation script created"
fi

echo
echo "🎉 Installation complete!"
echo
echo "📋 Robust 3-step process:"
echo "1. Setup: ./setup-validator.sh"
echo "2. Initialize: ./validate.sh init"
echo "3. Start: ./validate.sh start"
echo "4. Generate keys: ./scripts/generate-session-keys.sh"
echo
echo "🔧 Management commands:"
echo "  ./validate.sh status  - Check validator status"
echo "  ./validate.sh stop    - Stop validator"  
echo "  ./validate.sh restart - Restart validator"
echo "  ./validate.sh logs    - View logs"
echo
echo "✨ All path issues resolved - should work seamlessly!"
echo "Repository: $REPO_URL"