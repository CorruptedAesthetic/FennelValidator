#!/bin/bash
# Fennel Validator Installer - Fixed for Oracle Cloud
# Simple, reliable setup for staging network

set -e

echo "🚀 Fennel Validator Installer (Oracle Cloud Optimized)"
echo "=================================================="
echo "Simple setup for Fennel staging network"
echo

# Function to print status
print_info() { echo "✅ $1"; }
print_warning() { echo "⚠️  $1"; }
print_error() { echo "❌ $1"; }

# Get absolute path of script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔍 Detecting system..."
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case $ARCH in
    x86_64) ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) print_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

PLATFORM="$OS-$ARCH"
print_info "Platform: $PLATFORM"

echo
echo "📦 Creating directory structure..."
mkdir -p bin scripts config validator-data tools/internal tools/bin logs
print_info "Directory structure created"

# Since we're in the cloned repo, make sure all scripts are executable
echo
echo "🔧 Setting up scripts..."
for script in setup-validator.sh validate.sh start.sh; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        print_info "$script ready"
    fi
done

# Make all .sh files in subdirectories executable
find scripts tools -name "*.sh" -type f 2>/dev/null | while read script; do
    chmod +x "$script" 2>/dev/null || true
done
print_info "All scripts configured"

echo
echo "⬇️  Downloading Fennel node binary..."

# Download the latest release
RELEASES_URL="https://api.github.com/repos/CorruptedAesthetic/fennel-solonet/releases/latest"
BINARY_DOWNLOADED=false

# Try to get latest release info
if command -v curl >/dev/null 2>&1; then
    echo "📡 Checking latest release..."
    RELEASE_INFO=$(curl -s "$RELEASES_URL" 2>/dev/null)
    
    if [ -n "$RELEASE_INFO" ]; then
        # Extract download URL for fennel-node asset
        DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*fennel-node[^"]*"' | head -1 | cut -d'"' -f4)
        
        if [ -n "$DOWNLOAD_URL" ]; then
            ASSET_NAME=$(basename "$DOWNLOAD_URL")
            echo "📦 Downloading: $ASSET_NAME"
            
            if curl -L "$DOWNLOAD_URL" -o "bin/$ASSET_NAME" 2>/dev/null; then
                echo "📂 Extracting binary..."
                cd bin
                
                # Handle different archive types
                if [[ "$ASSET_NAME" == *.tgz ]] || [[ "$ASSET_NAME" == *.tar.gz ]]; then
                    tar -xzf "$ASSET_NAME" 2>/dev/null
                    # Find and move the binary
                    if [ -f "fennel-node" ]; then
                        chmod +x "fennel-node"
                        rm -f "$ASSET_NAME"
                        BINARY_DOWNLOADED=true
                    else
                        # Look for binary in subdirectories
                        FOUND_BINARY=$(find . -name "fennel-node" -type f 2>/dev/null | head -1)
                        if [ -n "$FOUND_BINARY" ]; then
                            mv "$FOUND_BINARY" "fennel-node"
                            chmod +x "fennel-node"
                            rm -f "$ASSET_NAME"
                            BINARY_DOWNLOADED=true
                        fi
                    fi
                elif [[ "$ASSET_NAME" == *.zip ]]; then
                    if command -v unzip >/dev/null 2>&1; then
                        unzip -q "$ASSET_NAME"
                        if [ -f "fennel-node" ]; then
                            chmod +x "fennel-node"
                            rm -f "$ASSET_NAME"
                            BINARY_DOWNLOADED=true
                        fi
                    fi
                else
                    # Assume it's a direct binary
                    mv "$ASSET_NAME" "fennel-node"
                    chmod +x "fennel-node"
                    BINARY_DOWNLOADED=true
                fi
                
                cd ..
                
                if [ "$BINARY_DOWNLOADED" = true ]; then
                    print_info "Fennel binary downloaded and ready"
                fi
            fi
        fi
    fi
fi

# If download failed, try Docker extraction
if [ "$BINARY_DOWNLOADED" = false ] && command -v docker >/dev/null 2>&1; then
    print_warning "Binary download failed, trying Docker extraction..."
    
    DOCKER_IMAGE="ghcr.io/corruptedaesthetic/fennel-solonet:latest"
    echo "🐳 Extracting from Docker image..."
    
    # Try to extract binary from Docker image
    if docker pull "$DOCKER_IMAGE" >/dev/null 2>&1; then
        CONTAINER_ID=$(docker create "$DOCKER_IMAGE" 2>/dev/null)
        if [ -n "$CONTAINER_ID" ]; then
            # Try common binary locations
            for path in "/usr/local/bin/fennel-node" "/usr/bin/fennel-node" "/fennel-node"; do
                if docker cp "$CONTAINER_ID:$path" "bin/fennel-node" 2>/dev/null; then
                    chmod +x "bin/fennel-node"
                    BINARY_DOWNLOADED=true
                    break
                fi
            done
            docker rm "$CONTAINER_ID" >/dev/null 2>&1
            
            if [ "$BINARY_DOWNLOADED" = true ]; then
                print_info "Binary extracted from Docker image"
            fi
        fi
    fi
fi

# If all else fails, provide build instructions
if [ "$BINARY_DOWNLOADED" = false ]; then
    print_warning "Could not download pre-built binary"
    echo "📝 Creating build instructions..."
    
    cat > bin/BUILD_INSTRUCTIONS.md << 'EOF'
# Build Fennel Node from Source

## Requirements
- Rust toolchain (install from https://rustup.rs/)
- Git

## Steps
1. Clone the source repository:
   ```bash
   git clone https://github.com/CorruptedAesthetic/fennel-solonet.git
   cd fennel-solonet
   ```

2. Build the binary:
   ```bash
   cargo build --release
   ```

3. Copy the binary:
   ```bash
   cp target/release/fennel-node ../bin/
   ```

## Alternative: Use Docker
```bash
# Install Docker, then re-run this installer
./install.sh
```
EOF
    
    print_info "Build instructions created in bin/BUILD_INSTRUCTIONS.md"
    echo
    echo "🔧 To continue without a binary:"
    echo "   1. Follow the build instructions in bin/BUILD_INSTRUCTIONS.md"
    echo "   2. Or install Docker and re-run this script"
    echo "   3. Then run: ./start.sh"
fi

echo
echo "📥 Downloading chainspec..."
CHAINSPEC_URL="https://raw.githubusercontent.com/CorruptedAesthetic/fennel-solonet/main/chainspecs/staging/staging-raw.json"
if curl -L "$CHAINSPEC_URL" -o "config/fennel-staging.raw.json" 2>/dev/null; then
    print_info "Staging chainspec downloaded as fennel-staging.raw.json"
else
    print_warning "Chainspec download failed - will retry when starting validator"
fi

echo
echo "🎉 Installation complete!"
echo
echo "📋 Next steps:"
if [ "$BINARY_DOWNLOADED" = true ]; then
    echo "1. Configure: ./setup-validator.sh"
    echo "2. Start: ./validate.sh start"
    echo "3. Generate keys: ./scripts/generate-session-keys.sh"
else
    echo "1. Build or obtain fennel-node binary (see bin/BUILD_INSTRUCTIONS.md)"
    echo "2. Configure: ./setup-validator.sh"
    echo "3. Start: ./validate.sh start"
fi
echo
echo "🔧 Or use the all-in-one command: ./start.sh"
echo
print_info "Ready for Oracle Cloud deployment!"
