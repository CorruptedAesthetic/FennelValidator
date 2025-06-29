#!/bin/bash
# Fennel Validator Installer
# Downloads and sets up everything needed to run a Fennel validator

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/CorruptedAesthetic/fennel-solonet"
RELEASES_URL="$REPO_URL/releases"
RAW_URL="https://raw.githubusercontent.com/CorruptedAesthetic/fennel-solonet/main"

echo -e "${BLUE}🧪 Fennel Staging Validator Installer${NC}"
echo "============================================"
echo -e "${GREEN}Safe learning environment - no financial risk!${NC}"
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
    local version=$(curl -s "$RELEASES_URL/latest" | grep -o 'tag/[^"]*' | cut -d'/' -f2 | head -1)
    if [ -z "$version" ]; then
        print_warning "Could not fetch latest version, using fallback"
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
        curl -L --progress-bar "$url" -o "$output"
    elif command -v wget > /dev/null; then
        wget --progress=bar "$url" -O "$output"
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
}

echo -e "\n${BLUE}🔍 Detecting system...${NC}"
PLATFORM=$(detect_platform)
VERSION=$(get_latest_version)
print_info "Platform: $PLATFORM"
print_info "Latest version: $VERSION"

echo -e "\n${BLUE}📦 Creating directory structure...${NC}"
mkdir -p bin config scripts docker docs
print_info "Directories created"

echo -e "\n${BLUE}⬇️  Downloading Fennel node binary...${NC}"
# Try to download from GitHub releases first
BINARY_NAME="fennel-node"
if [[ "$PLATFORM" == *"windows"* ]]; then
    BINARY_NAME="fennel-node.exe"
fi

DOWNLOAD_URL="$RELEASES_URL/download/$VERSION/$BINARY_NAME"
if curl -s --head "$DOWNLOAD_URL" | head -n 1 | grep -q "200 OK"; then
    download_file "$DOWNLOAD_URL" "bin/fennel-node$ext" "Fennel node binary"
else
    print_warning "Binary not available for $PLATFORM, will build from source"
    echo "# Build from source" > bin/README.md
    echo "Run: cargo build --release in the fennel-solonet repository" >> bin/README.md
    echo "Then copy target/release/fennel-node to this bin/ directory" >> bin/README.md
fi

if [ -f "bin/fennel-node$ext" ]; then
    chmod +x "bin/fennel-node$ext"
    print_info "Binary downloaded and made executable"
fi

echo -e "\n${BLUE}📋 Chainspec Configuration${NC}"
print_info "Chainspecs will be auto-downloaded from fennel-solonet when needed"
print_info "This ensures you always have the latest network configuration"

echo -e "\n${BLUE}📜 Downloading helper scripts...${NC}"
# Download the connection info script
download_file "$RAW_URL/../fennel-prod/scripts/staging/get-external-validator-info.sh" "scripts/get-connection-info.sh" "Connection info script"
chmod +x scripts/get-connection-info.sh

echo -e "\n${BLUE}📝 Creating configuration template...${NC}"
cat > config/validator-config.toml << 'EOF'
# Fennel Validator Configuration

[validator]
name = "External-Validator-{HOSTNAME}"
network = "staging"  # Options: staging, mainnet
data_dir = "./data"

[network]
port = 30333
rpc_port = 9944
prometheus_port = 9615

[security]
rpc_external = false  # Set to true only if needed
prometheus_external = false  # Set to true for monitoring
rpc_cors = "all"
rpc_methods = "safe"

[performance]
max_runtime_instances = 8
runtime_cache_size = 2
db_cache = 1024
state_cache_size = 67108864
EOF

print_info "Configuration template created"

echo -e "\n${BLUE}🐳 Creating Docker setup...${NC}"
cat > docker/docker-compose.yml << EOF
version: '3.8'

services:
  fennel-validator:
    image: ghcr.io/corruptedaesthetic/fennel-solonet:$VERSION
    container_name: fennel-validator
    ports:
      - "9944:9944"   # RPC (local only)
      - "9615:9615"   # Prometheus metrics
      - "30333:30333" # P2P
    volumes:
      - validator_data:/data
      - ../config:/config:ro
    command: >
      --chain /config/staging-chainspec.json
      --validator
      --name "External-Validator-Docker"
      --base-path /data
      --port 30333
      --rpc-port 9944
      --prometheus-port 9615
      --rpc-external
      --prometheus-external
      --rpc-cors all
      --rpc-methods safe
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"

volumes:
  validator_data:
EOF

print_info "Docker Compose configuration created"

echo -e "\n${GREEN}🎉 Installation complete!${NC}"
echo
echo "Next steps:"
echo "1. Run setup: ${BLUE}./setup-validator.sh${NC}"
echo "2. Start validator: ${BLUE}./validate.sh start${NC}"
echo
echo "For Docker users:"
echo "1. Configure: Edit config/validator-config.toml"
echo "2. Start: ${BLUE}cd docker && docker-compose up -d${NC}"
echo
echo "Repository: $REPO_URL"
echo "Version: $VERSION" 