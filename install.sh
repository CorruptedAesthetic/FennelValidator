#!/bin/bash
# Fennel Validator Installer - Simple 3-Step Setup
# Downloads and sets up everything needed for external validators

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/CorruptedAesthetic/fennel-solonet"
RELEASES_URL="$REPO_URL/releases"
VALIDATOR_REPO_URL="https://raw.githubusercontent.com/CorruptedAesthetic/FennelValidator/main"

echo -e "${BLUE}🧪 Fennel External Validator Installer${NC}"
echo "====================================="
echo -e "${GREEN}Simple 3-step setup for staging network${NC}"
echo

# Function to print status
print_info() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
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
    
    echo -e "${BLUE}⬇️  Downloading $description...${NC}"
    if command -v curl > /dev/null; then
        curl -L --progress-bar "$url" -o "$output" 2>/dev/null
    elif command -v wget > /dev/null; then
        wget --progress=bar "$url" -O "$output" 2>/dev/null
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
}

echo -e "\n${BLUE}🔍 Detecting system...${NC}"
PLATFORM=$(detect_platform)
VERSION=$(get_latest_version)
print_info "Platform: $PLATFORM"
print_info "Version: $VERSION"

echo -e "\n${BLUE}📦 Creating directory structure...${NC}"
mkdir -p bin scripts
print_info "Essential directories created"

echo -e "\n${BLUE}⬇️  Downloading Fennel node binary...${NC}"
# Try to download from GitHub releases first
BINARY_NAME="fennel-node"
if [[ "$PLATFORM" == *"windows"* ]]; then
    BINARY_NAME="fennel-node.exe"
fi

DOWNLOAD_URL="$RELEASES_URL/download/$VERSION/$BINARY_NAME"
if curl -s --head "$DOWNLOAD_URL" 2>/dev/null | head -n 1 | grep -q "200 OK"; then
    download_file "$DOWNLOAD_URL" "bin/fennel-node$ext" "Fennel node binary"
    chmod +x "bin/fennel-node$ext"
    print_info "Binary downloaded and made executable"
else
    print_warning "Binary not available for $PLATFORM"
    echo "# Build from source" > bin/README.md
    echo "Run: cargo build --release in the fennel-solonet repository" >> bin/README.md
    echo "Then copy target/release/fennel-node to this bin/ directory" >> bin/README.md
    print_info "Build instructions created in bin/README.md"
fi

echo -e "\n${BLUE}📜 Downloading validator scripts...${NC}"
# Download setup script
download_file "$VALIDATOR_REPO_URL/setup-validator.sh" "setup-validator.sh" "Setup script"
chmod +x setup-validator.sh

# Download key generation script  
download_file "$VALIDATOR_REPO_URL/scripts/generate-session-keys.sh" "scripts/generate-session-keys.sh" "Key generation script"
chmod +x scripts/generate-session-keys.sh

# Create simple validate.sh script
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
                    http://localhost:${RPC_PORT:-9944} | grep -o '"peers":[0-9]*' || echo "RPC not accessible"
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

echo -e "\n${BLUE}📋 Network Configuration${NC}"
print_info "Auto-connects to bootnode: /ip4/192.168.49.2/tcp/30604/p2p/12D3KooWRpzRTivvJ5ySvgbFnPeEE6rDhitQKL1fFJvvBGhnenSk"
print_info "Chainspec auto-downloaded from fennel-solonet when needed"

echo -e "\n${GREEN}🎉 Installation complete!${NC}"
echo
echo -e "${BLUE}Next steps (Simple 3-step process):${NC}"
echo -e "1. Setup: ${GREEN}./setup-validator.sh${NC}"
echo -e "2. Start: ${GREEN}./validate.sh start${NC}"  
echo -e "3. Generate keys: ${GREEN}./scripts/generate-session-keys.sh${NC}"
echo
echo -e "${YELLOW}Then send us your session-keys.json file!${NC}"
echo
echo "Repository: $REPO_URL"
echo "Staging network - safe for learning!" 