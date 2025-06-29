#!/bin/bash
# Fennel Validator Update Script
# Updates to the latest version from GitHub releases

set -e

CONFIG_FILE="../config/validator.conf"
REPO_URL="https://github.com/CorruptedAesthetic/fennel-solonet"
RELEASES_URL="$REPO_URL/releases"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    local status="$1"
    local message="$2"
    case $status in
        "ok") echo -e "${GREEN}✅ $message${NC}" ;;
        "warn") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "error") echo -e "${RED}❌ $message${NC}" ;;
        "info") echo -e "${BLUE}ℹ️  $message${NC}" ;;
    esac
}

# Detect platform
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case $arch in
        x86_64) arch="x64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) print_status "error" "Unsupported architecture: $arch"; exit 1 ;;
    esac
    
    case $os in
        linux) platform="linux-$arch" ;;
        darwin) platform="macos-$arch" ;;
        mingw*|cygwin*|msys*) platform="windows-$arch"; ext=".exe" ;;
        *) print_status "error" "Unsupported OS: $os"; exit 1 ;;
    esac
    
    echo "$platform"
}

# Get latest release version
get_latest_version() {
    local version=$(curl -s "$RELEASES_URL/latest" | grep -o 'tag/[^"]*' | cut -d'/' -f2 | head -1)
    if [ -z "$version" ]; then
        print_status "error" "Could not fetch latest version"
        exit 1
    else
        echo "$version"
    fi
}

# Get current version
get_current_version() {
    if [ -f "../bin/fennel-node" ]; then
        BINARY="../bin/fennel-node"
    elif [ -f "../bin/fennel-node.exe" ]; then
        BINARY="../bin/fennel-node.exe"
    else
        echo "unknown"
        return
    fi
    
    # Try to get version from binary
    VERSION_OUTPUT=$("$BINARY" --version 2>/dev/null || echo "")
    if [ -n "$VERSION_OUTPUT" ]; then
        echo "$VERSION_OUTPUT" | head -n 1
    else
        echo "unknown"
    fi
}

# Backup current binary
backup_binary() {
    print_status "info" "Creating backup of current binary..."
    
    if [ -f "../bin/fennel-node" ]; then
        cp "../bin/fennel-node" "../bin/fennel-node.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "ok" "Backup created"
    elif [ -f "../bin/fennel-node.exe" ]; then
        cp "../bin/fennel-node.exe" "../bin/fennel-node.exe.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "ok" "Backup created"
    else
        print_status "warn" "No current binary found to backup"
    fi
}

# Download new binary
download_binary() {
    local version="$1"
    local platform="$2"
    
    print_status "info" "Downloading Fennel node $version for $platform..."
    
    BINARY_NAME="fennel-node"
    if [[ "$platform" == *"windows"* ]]; then
        BINARY_NAME="fennel-node.exe"
        ext=".exe"
    fi
    
    DOWNLOAD_URL="$RELEASES_URL/download/$version/$BINARY_NAME"
    TEMP_FILE="/tmp/fennel-node-update$ext"
    
    if curl -L --progress-bar "$DOWNLOAD_URL" -o "$TEMP_FILE"; then
        # Verify download
        if [ -f "$TEMP_FILE" ] && [ -s "$TEMP_FILE" ]; then
            # Move to bin directory
            chmod +x "$TEMP_FILE"
            mv "$TEMP_FILE" "../bin/fennel-node$ext"
            print_status "ok" "Binary updated successfully"
            return 0
        else
            print_status "error" "Downloaded file is empty or invalid"
            rm -f "$TEMP_FILE"
            return 1
        fi
    else
        print_status "error" "Failed to download binary"
        return 1
    fi
}

# Update chainspecs
update_chainspecs() {
    print_status "info" "Updating chainspecs from fennel-solonet repository..."
    
    RAW_URL="https://raw.githubusercontent.com/CorruptedAesthetic/fennel-solonet/main"
    
    # Update staging chainspec (always available)
    print_status "info" "Downloading latest staging chainspec..."
    if curl -s --max-time 30 "$RAW_URL/chainspecs/staging/staging-raw.json" -o "../config/staging-chainspec.json.tmp"; then
        if [ -s "../config/staging-chainspec.json.tmp" ]; then
            # Verify it's valid JSON
            if jq empty "../config/staging-chainspec.json.tmp" 2>/dev/null; then
                mv "../config/staging-chainspec.json.tmp" "../config/staging-chainspec.json"
                print_status "ok" "Staging chainspec updated to latest version"
            else
                rm -f "../config/staging-chainspec.json.tmp"
                print_status "warn" "Downloaded staging chainspec is invalid JSON"
            fi
        else
            rm -f "../config/staging-chainspec.json.tmp"
            print_status "warn" "Downloaded staging chainspec is empty"
        fi
    else
        rm -f "../config/staging-chainspec.json.tmp"
        print_status "warn" "Could not download staging chainspec from fennel-solonet"
    fi
    
    # Update mainnet chainspec if available
    print_status "info" "Checking for mainnet chainspec..."
    if curl -s --head --max-time 10 "$RAW_URL/chainspecs/mainnet/mainnet-raw.json" | head -n 1 | grep -q "200 OK"; then
        print_status "info" "Downloading latest mainnet chainspec..."
        if curl -s --max-time 30 "$RAW_URL/chainspecs/mainnet/mainnet-raw.json" -o "../config/mainnet-chainspec.json.tmp"; then
            if [ -s "../config/mainnet-chainspec.json.tmp" ]; then
                # Verify it's valid JSON
                if jq empty "../config/mainnet-chainspec.json.tmp" 2>/dev/null; then
                    mv "../config/mainnet-chainspec.json.tmp" "../config/mainnet-chainspec.json"
                    print_status "ok" "Mainnet chainspec updated to latest version"
                else
                    rm -f "../config/mainnet-chainspec.json.tmp"
                    print_status "warn" "Downloaded mainnet chainspec is invalid JSON"
                fi
            else
                rm -f "../config/mainnet-chainspec.json.tmp"
                print_status "warn" "Downloaded mainnet chainspec is empty"
            fi
        else
            rm -f "../config/mainnet-chainspec.json.tmp"
            print_status "warn" "Could not download mainnet chainspec"
        fi
    else
        print_status "info" "Mainnet chainspec not yet available in fennel-solonet"
    fi
}

# Check if validator is running
check_validator_status() {
    if pgrep -f "fennel-node.*--validator" > /dev/null; then
        return 0  # Running
    else
        return 1  # Not running
    fi
}

# Main update process
main() {
    echo -e "${BLUE}🔄 Fennel Validator Update${NC}"
    echo "============================="
    
    # Check current status
    CURRENT_VERSION=$(get_current_version)
    print_status "info" "Current version: $CURRENT_VERSION"
    
    # Get latest version
    print_status "info" "Checking for updates..."
    LATEST_VERSION=$(get_latest_version)
    print_status "info" "Latest version: $LATEST_VERSION"
    
    # Compare versions (simple string comparison)
    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
        print_status "ok" "Already up to date!"
        exit 0
    fi
    
    # Detect platform
    PLATFORM=$(detect_platform)
    print_status "info" "Platform: $PLATFORM"
    
    # Check if validator is running
    WAS_RUNNING=false
    if check_validator_status; then
        WAS_RUNNING=true
        print_status "warn" "Validator is currently running"
        
        # Ask user if they want to continue
        echo
        echo "To update, the validator needs to be stopped temporarily."
        read -p "Continue with update? [y/N]: " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "info" "Update cancelled"
            exit 0
        fi
        
        # Stop validator
        print_status "info" "Stopping validator..."
        ../validate.sh stop
        sleep 3
        
        if check_validator_status; then
            print_status "error" "Failed to stop validator"
            exit 1
        fi
        
        print_status "ok" "Validator stopped"
    fi
    
    # Backup current binary
    backup_binary
    
    # Download new binary
    if download_binary "$LATEST_VERSION" "$PLATFORM"; then
        print_status "ok" "Binary update completed"
    else
        print_status "error" "Binary update failed"
        
        # Restore from backup if available
        BACKUP_FILE=$(ls ../bin/fennel-node.backup.* 2>/dev/null | tail -n 1)
        if [ -n "$BACKUP_FILE" ]; then
            print_status "info" "Restoring from backup..."
            cp "$BACKUP_FILE" "../bin/fennel-node"
            print_status "ok" "Backup restored"
        fi
        
        exit 1
    fi
    
    # Update chainspecs
    update_chainspecs
    
    # Verify new binary works
    print_status "info" "Verifying new binary..."
    NEW_VERSION=$(get_current_version)
    if [ -n "$NEW_VERSION" ] && [ "$NEW_VERSION" != "unknown" ]; then
        print_status "ok" "New version verified: $NEW_VERSION"
    else
        print_status "warn" "Could not verify new binary version"
    fi
    
    # Restart validator if it was running
    if [ "$WAS_RUNNING" = true ]; then
        print_status "info" "Restarting validator..."
        sleep 2
        
        if ../validate.sh start > /dev/null 2>&1; then
            sleep 3
            if check_validator_status; then
                print_status "ok" "Validator restarted successfully"
            else
                print_status "warn" "Validator may not have started properly"
                print_status "info" "Check with: ../validate.sh status"
            fi
        else
            print_status "warn" "Failed to restart validator automatically"
            print_status "info" "Start manually with: ../validate.sh start"
        fi
    fi
    
    echo
    print_status "ok" "Update completed!"
    echo
    echo "Updated from: $CURRENT_VERSION"
    echo "Updated to: $LATEST_VERSION"
    echo
    if [ "$WAS_RUNNING" = true ]; then
        echo "Run '../validate.sh status' to check validator status"
    else
        echo "Run '../validate.sh start' to start your validator"
    fi
}

# Run main function
main "$@" 