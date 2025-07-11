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
DOCKER_IMAGE="ghcr.io/corruptedaesthetic/fennel-solonet:sha-3fb1b156c14d912798d09f935bd5550a4d131346"

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
            echo "💡 Try: sudo systemctl start docker"
            return 1
        fi
    else
        print_warning "Docker is not installed"
        echo "💡 Docker installation options:"
        echo "   Oracle Linux: sudo yum install -y docker"
        echo "   Ubuntu/Debian: sudo apt-get install -y docker.io"
        echo "   Alternative: This script will try release download as fallback"
        return 1
    fi
}

# Extract binary from Docker image
extract_binary_from_docker() {
    echo "🐳 Extracting fennel-node binary from Docker image..."
    
    # Try the specific SHA first, then fall back to latest
    local images=("$DOCKER_IMAGE" "ghcr.io/corruptedaesthetic/fennel-solonet:latest")
    
    for image in "${images[@]}"; do
        echo "📥 Trying Docker image: $image"
        
        # Pull the image first
        if docker pull "$image" >/dev/null 2>&1; then
            echo "✅ Successfully pulled $image"
        else
            echo "⚠️  Failed to pull $image, trying with existing local image..."
        fi
        
        # Create temporary container and copy binary
        CONTAINER_ID=$(docker create "$image" 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "🔍 Searching for fennel-node binary in container..."
            
            # Try common binary locations
            for path in "/usr/local/bin/fennel-node" "/usr/bin/fennel-node" "/fennel-node" "/app/fennel-node" "/target/release/fennel-node"; do
                if docker cp "$CONTAINER_ID:$path" "bin/fennel-node-temp" 2>/dev/null; then
                    # Handle case where extraction creates a directory instead of a file
                    if [ -d "bin/fennel-node-temp" ]; then
                        echo "🔧 Extracted directory, looking for binary inside..."
                        FOUND_BINARY=$(find "bin/fennel-node-temp" -name "fennel-node" -type f 2>/dev/null | head -1)
                        if [ -n "$FOUND_BINARY" ]; then
                            mv "$FOUND_BINARY" "bin/fennel-node"
                            rm -rf "bin/fennel-node-temp"
                            chmod +x "bin/fennel-node"
                            docker rm "$CONTAINER_ID" >/dev/null 2>&1
                            # Verify the binary works
                            if ./bin/fennel-node --version >/dev/null 2>&1; then
                                print_info "Binary extracted from Docker image ($image) and verified working"
                                return 0
                            else
                                print_warning "Binary extracted but verification failed, trying next option..."
                                rm -f "bin/fennel-node"
                                return 1
                            fi
                        else
                            rm -rf "bin/fennel-node-temp"
                        fi
                    elif [ -f "bin/fennel-node-temp" ]; then
                        mv "bin/fennel-node-temp" "bin/fennel-node"
                        chmod +x "bin/fennel-node"
                        docker rm "$CONTAINER_ID" >/dev/null 2>&1
                        # Verify the binary works
                        if ./bin/fennel-node --version >/dev/null 2>&1; then
                            print_info "Binary extracted from Docker image ($image) and verified working"
                            return 0
                        else
                            print_warning "Binary extracted but verification failed, trying next option..."
                            rm -f "bin/fennel-node"
                            return 1
                        fi
                    fi
                fi
            done
            
            # If direct paths don't work, search the entire container
            echo "🔍 Performing deep search for binary..."
            if docker export "$CONTAINER_ID" | tar -tf - | grep -E "fennel-node$" | head -1 > temp_binary_path.txt 2>/dev/null; then
                BINARY_PATH=$(cat temp_binary_path.txt)
                if [ -n "$BINARY_PATH" ]; then
                    if docker cp "$CONTAINER_ID:/$BINARY_PATH" "bin/fennel-node-temp" 2>/dev/null; then
                        # Handle extraction result properly
                        if [ -d "bin/fennel-node-temp" ]; then
                            FOUND_BINARY=$(find "bin/fennel-node-temp" -name "fennel-node" -type f 2>/dev/null | head -1)
                            if [ -n "$FOUND_BINARY" ]; then
                                mv "$FOUND_BINARY" "bin/fennel-node"
                                rm -rf "bin/fennel-node-temp"
                                chmod +x "bin/fennel-node"
                                docker rm "$CONTAINER_ID" >/dev/null 2>&1
                                rm -f temp_binary_path.txt
                                # Verify the binary works
                                if ./bin/fennel-node --version >/dev/null 2>&1; then
                                    print_info "Binary found at $BINARY_PATH and verified working"
                                    return 0
                                else
                                    print_warning "Binary found but verification failed"
                                    rm -f "bin/fennel-node"
                                    return 1
                                fi
                            fi
                            rm -rf "bin/fennel-node-temp"
                        elif [ -f "bin/fennel-node-temp" ]; then
                            mv "bin/fennel-node-temp" "bin/fennel-node"
                            chmod +x "bin/fennel-node"
                            docker rm "$CONTAINER_ID" >/dev/null 2>&1
                            rm -f temp_binary_path.txt
                            # Verify the binary works
                            if ./bin/fennel-node --version >/dev/null 2>&1; then
                                print_info "Binary found at $BINARY_PATH and verified working"
                                return 0
                            else
                                print_warning "Binary found but verification failed"
                                rm -f "bin/fennel-node"
                                return 1
                            fi
                        fi
                    fi
                fi
                rm -f temp_binary_path.txt
            fi
            
            docker rm "$CONTAINER_ID" >/dev/null 2>&1
        fi
        
        echo "⚠️  Failed to extract from $image, trying next option..."
    done
    
    print_error "Failed to extract binary from any Docker image"
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
echo "⬇️  Getting Fennel node binary..."

BINARY_DOWNLOADED=false

# Try Docker first (most reliable method for Fennel)
echo "🎯 Primary method: Docker image extraction"
if check_docker; then
    echo "🐳 Using Docker to extract binary (recommended method)..."
    echo "🎯 Using specific SHA image for consistency: sha-3fb1b156c14d912798d09f935bd5550a4d131346"
    if extract_binary_from_docker; then
        BINARY_DOWNLOADED=true
        print_info "✅ Successfully extracted binary from Docker image!"
    else
        print_error "❌ Docker extraction failed despite Docker being available"
    fi
else
    print_warning "🐳 Docker not available - this is the preferred method for binary extraction"
    echo "💡 For best results, install Docker and re-run this script"
fi

# Only try release download if Docker completely fails
if [ "$BINARY_DOWNLOADED" = false ]; then
    echo
    print_warning "🔄 Fallback method: GitHub release download"
    echo "⚠️  Note: Docker extraction is more reliable for Fennel validator"
    
    # Get latest release info
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/CorruptedAesthetic/fennel-solonet/releases/latest 2>/dev/null)
    
    if [ -n "$LATEST_RELEASE" ]; then
        # Try to find binary asset in latest release
        ASSET_NAME=$(echo "$LATEST_RELEASE" | grep -o '"name": "[^"]*fennel-node[^"]*"' | head -1 | cut -d'"' -f4)
        if [ -n "$ASSET_NAME" ]; then
            DOWNLOAD_URL="$RELEASES_URL/latest/download/$ASSET_NAME"
            echo "📦 Found release asset: $ASSET_NAME"
            
            if download_file "$DOWNLOAD_URL" "bin/$ASSET_NAME" "Fennel node binary package"; then
                # Extract if it's a tar.gz
                if [[ "$ASSET_NAME" == *.tgz ]] || [[ "$ASSET_NAME" == *.tar.gz ]]; then
                    echo "📂 Extracting binary from archive..."
                    cd bin
                    tar -xzf "$ASSET_NAME" 2>/dev/null || tar -xf "$ASSET_NAME" 2>/dev/null
                    # Find the binary in extracted files
                    if [ -f "fennel-node" ]; then
                        chmod +x "fennel-node"
                        rm -f "$ASSET_NAME"
                        print_info "Binary extracted and ready for use"
                        BINARY_DOWNLOADED=true
                    elif find . -name "fennel-node" -type f 2>/dev/null | head -1 | xargs -I {} mv {} . 2>/dev/null; then
                        chmod +x "fennel-node"
                        rm -f "$ASSET_NAME"
                        print_info "Binary found and extracted successfully"
                        BINARY_DOWNLOADED=true
                    fi
                    cd ..
                else
                    # Direct binary file
                    mv "bin/$ASSET_NAME" "bin/fennel-node"
                    chmod +x "bin/fennel-node"
                    print_info "Binary ready for use"
                    BINARY_DOWNLOADED=true
                fi
            fi
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
echo "📥 Downloading Fennel staging chainspec..."
echo "⚠️  This is a large file (~3.7MB) and may take a moment..."

CHAINSPEC_URL="https://raw.githubusercontent.com/CorruptedAesthetic/fennel-solonet/main/chainspecs/staging/staging-raw.json"
CHAINSPEC_DOWNLOADED=false

# Try multiple download methods
if command -v curl > /dev/null; then
    echo "🌐 Downloading with curl..."
    if curl -L --connect-timeout 30 --max-time 300 "$CHAINSPEC_URL" -o "config/staging-chainspec.json" 2>/dev/null; then
        # Verify the file is valid JSON and not empty
        if [ -s "config/staging-chainspec.json" ] && jq . "config/staging-chainspec.json" >/dev/null 2>&1; then
            print_info "Staging chainspec downloaded and validated"
            CHAINSPEC_DOWNLOADED=true
        else
            print_warning "Downloaded chainspec appears invalid, retrying..."
            rm -f "config/staging-chainspec.json"
        fi
    fi
elif command -v wget > /dev/null; then
    echo "🌐 Downloading with wget..."
    if wget --timeout=300 "$CHAINSPEC_URL" -O "config/staging-chainspec.json" 2>/dev/null; then
        if [ -s "config/staging-chainspec.json" ] && jq . "config/staging-chainspec.json" >/dev/null 2>&1; then
            print_info "Staging chainspec downloaded and validated"
            CHAINSPEC_DOWNLOADED=true
        else
            print_warning "Downloaded chainspec appears invalid"
            rm -f "config/staging-chainspec.json"
        fi
    fi
else
    print_error "Neither curl nor wget found for chainspec download"
fi

if [ "$CHAINSPEC_DOWNLOADED" = false ]; then
    print_warning "Chainspec download failed - validator will try to download it at startup"
    echo "💡 You can manually download it later with:"
    echo "   curl -L '$CHAINSPEC_URL' -o config/staging-chainspec.json"
fi

echo
echo "📜 Setting up validator scripts..."

# Since this is being run from the cloned repository, all scripts should already exist
# Just make sure they're executable and verify they exist

# Make existing scripts executable
for script in setup-validator.sh validate.sh start.sh; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        print_info "$script is ready"
    else
        print_warning "$script not found - this may be expected if running from a different location"
    fi
done

# Make scripts in subdirectories executable
find scripts tools -name "*.sh" -type f 2>/dev/null | while read script; do
    chmod +x "$script"
done

# Check if essential scripts exist, create basic versions if missing
if [ ! -f "scripts/generate-session-keys.sh" ]; then
    mkdir -p scripts
    echo "📝 Creating basic session key generation script..."
fi

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