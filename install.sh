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
DOCKER_IMAGE="ghcr.io/corruptedaesthetic/fennel-solonet:sha-e73e4002862328f70a46ee64d8fd681d5ebccdd5"

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
echo "📦 Creating directory structure..."
mkdir -p bin scripts config
print_info "Essential directories created"

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
echo "📜 Downloading validator scripts..."

# Download setup script
if download_file "$VALIDATOR_REPO_URL/setup-validator.sh" "setup-validator.sh" "Setup script"; then
    chmod +x setup-validator.sh
fi

# Download key generation script  
if download_file "$VALIDATOR_REPO_URL/scripts/generate-session-keys.sh" "scripts/generate-session-keys.sh" "Key generation script"; then
    chmod +x scripts/generate-session-keys.sh
fi

# Create simple validate.sh script
echo "📝 Creating validator management script..."
cat > validate.sh << 'EOF'
#!/bin/bash
# Simple Validator Management Script

CONFIG_FILE="config/validator.conf"
BINARY="bin/fennel-node"
if [ -f "bin/fennel-node.exe" ]; then
    BINARY="bin/fennel-node.exe"
fi

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
        
        # Download chainspec if needed
        if [ ! -f "config/staging-chainspec.json" ]; then
            echo "📥 Downloading staging chainspec..."
            curl -L "https://raw.githubusercontent.com/CorruptedAesthetic/fennel-solonet/main/chainspecs/staging/staging-raw.json" -o "config/staging-chainspec.json"
        else
            echo "✅ Using existing staging chainspec"
        fi
        
        # Start with basic config
        ./$BINARY \
            --chain "config/staging-chainspec.json" \
            --validator \
            --name "${VALIDATOR_NAME:-External-Validator}" \
            --base-path "${DATA_DIR:-./data}" \
            --port "${P2P_PORT:-30333}" \
            --rpc-port "${RPC_PORT:-9944}" \
            --prometheus-port "${PROMETHEUS_PORT:-9615}" \
            --bootnodes="/ip4/192.168.49.2/tcp/30604/p2p/12D3KooWRpzRTivvJ5ySvgbFnPeEE6rDhitQKL1fFJvvBGhnenSk" \
            --rpc-cors all \
            --rpc-methods safe
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
    
    *)
        echo "Usage: $0 {start|stop|status|restart|logs}"
        echo
        echo "Commands:"
        echo "  start   - Start the validator"
        echo "  stop    - Stop the validator" 
        echo "  status  - Check if validator is running"
        echo "  restart - Restart the validator"
        echo "  logs    - View validator logs"
        ;;
esac
EOF

chmod +x validate.sh
print_info "Validator management script created"

echo
echo "🧪 Testing binary compatibility..."
if [ -f "bin/fennel-node" ]; then
    if ./bin/fennel-node --help > /dev/null 2>&1; then
        print_info "Binary compatibility test passed"
    else
        print_warning "Binary may have compatibility issues - check ./validate.sh command for help"
    fi
else
    print_info "Binary will be tested when validator starts"
fi

echo
echo "📋 Network Configuration"
print_info "Auto-connects to bootnode: /ip4/192.168.49.2/tcp/30604/p2p/12D3KooWRpzRTivvJ5ySvgbFnPeEE6rDhitQKL1fFJvvBGhnenSk"
print_info "Chainspec auto-downloaded when needed"

echo
echo "🎉 Installation complete!"
echo
echo "Next steps (Simple 3-step process):"
echo "1. Setup: ./setup-validator.sh"
echo "2. Start: ./validate.sh start"  
echo "3. Generate keys: ./scripts/generate-session-keys.sh"
echo
echo "Then send us your session-keys.json file!"
echo
echo "Repository: $REPO_URL"
echo "Staging network - safe for learning!" 