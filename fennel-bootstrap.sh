#!/usr/bin/env bash
# fennel-bootstrap.sh - Bootstrap a Fennel validator with secure key generation
# Usage: ./fennel-bootstrap.sh <server-ip> [additional ansible args]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if IP provided
if [ $# -lt 1 ]; then
    print_error "Usage: $0 <server-ip> [additional ansible args]"
    print_info "Example: $0 198.51.100.7"
    print_info "Example: $0 198.51.100.7 --check"
    exit 1
fi

SERVER_IP="$1"
shift || true

print_info "Fennel Validator Bootstrap Script"
print_info "================================="
print_info "Server IP: $SERVER_IP"
echo

# Check prerequisites
print_info "Checking prerequisites..."

# Check if ansible is installed
if ! command -v ansible-playbook >/dev/null 2>&1; then
    print_error "Ansible is not installed. Please install it first:"
    echo "  Ubuntu/Debian: sudo apt update && sudo apt install -y ansible"
    echo "  CentOS/RHEL: sudo yum install -y ansible"
    echo "  macOS: brew install ansible"
    exit 1
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    print_error "jq is not installed. Please install it first:"
    echo "  Ubuntu/Debian: sudo apt update && sudo apt install -y jq"
    echo "  CentOS/RHEL: sudo yum install -y jq"
    echo "  macOS: brew install jq"
    exit 1
fi

# Check if subkey is available or cargo is installed for building it
if ! command -v subkey >/dev/null 2>&1; then
    print_warning "subkey not found. Checking for cargo to install it..."
    if ! command -v cargo >/dev/null 2>&1; then
        print_error "Neither subkey nor cargo found. Please install Rust and Cargo:"
        echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        echo "  source ~/.cargo/env"
        exit 1
    fi
    
    print_info "Installing subkey..."
    cargo install --git https://github.com/paritytech/substrate subkey --force
    
    # Add cargo bin to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
fi

print_success "Prerequisites check passed!"
echo

# Generate temporary keys
print_info "Generating temporary keys for initial setup..."

# Generate Aura key (sr25519)
AURA_JSON=$(subkey generate --scheme sr25519 --output-type json)
AURA=$(echo "$AURA_JSON" | jq -r .secretSeed | sed 's/^0x//')
if [ -z "$AURA" ] || [ "$AURA" = "null" ]; then
    print_error "Failed to generate Aura key"
    print_info "Debug: $AURA_JSON"
    exit 1
fi

# Generate GRANDPA key (ed25519)  
GRAN_JSON=$(subkey generate --scheme ed25519 --output-type json)
GRAN=$(echo "$GRAN_JSON" | jq -r .secretSeed | sed 's/^0x//')
if [ -z "$GRAN" ] || [ "$GRAN" = "null" ]; then
    print_error "Failed to generate Grandpa key"
    print_info "Debug: $GRAN_JSON"
    exit 1
fi

# Generate node key
NODE=$(subkey generate-node-key | sed 's/^0x//')
if [ -z "$NODE" ]; then
    print_error "Failed to generate node key"
    exit 1
fi

print_success "Temporary keys generated successfully!"
print_info "Aura key: 0x${AURA:0:16}..."
print_info "Grandpa key: 0x${GRAN:0:16}..."
print_info "Node key: 0x${NODE:0:16}..."
echo

# Check if ansible directory exists
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ANSIBLE_DIR="$SCRIPT_DIR/ansible"

if [ ! -d "$ANSIBLE_DIR" ]; then
    print_error "Ansible directory not found at $ANSIBLE_DIR"
    print_info "Please ensure you're running this script from the FennelValidator root directory"
    exit 1
fi

# Install Ansible collection if not already present
print_info "Installing Ansible collection..."
cd "$ANSIBLE_DIR"

if [ ! -f "requirements.yml" ]; then
    print_error "requirements.yml not found in $ANSIBLE_DIR"
    exit 1
fi

ansible-galaxy collection install -r requirements.yml --force
print_success "Ansible collection installed!"
echo

# Create temporary inventory file
TEMP_INVENTORY=$(mktemp)
cat > "$TEMP_INVENTORY" << EOF
[fennel_validators]
$SERVER_IP ansible_user=ubuntu
EOF

print_info "Created temporary inventory for server: $SERVER_IP"
echo

# Run the playbook with generated keys
print_info "Running Ansible playbook with generated keys..."
print_warning "Keys will be rotated automatically after node startup for security"
echo

print_info "Ansible command will be:"
print_info "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i temp_inventory validator.yml -e generate_keys=true ..."
echo

ANSIBLE_HOST_KEY_CHECKING=False \
AURA_SEED="0x${AURA}" \
GRANDPA_SEED="0x${GRAN}" \
NODE_KEY="0x${NODE}" \
ansible-playbook -i "$TEMP_INVENTORY" validator.yml \
  -e "generate_keys=true" \
  -e "aura_seed=0x${AURA}" \
  -e "grandpa_seed=0x${GRAN}" \
  -e "node_key=0x${NODE}" \
  "$@"

PLAYBOOK_EXIT_CODE=$?

# Clean up temporary files
rm -f "$TEMP_INVENTORY"

# Clear sensitive variables from memory
unset AURA GRAN NODE

if [ $PLAYBOOK_EXIT_CODE -eq 0 ]; then
    print_success "Validator setup completed successfully!"
    echo
    print_info "✅ Validator deployment completed:"
    print_info "  • Session keys: Generated via author_rotateKeys"
    print_info "  • Network key: Auto-generated by Substrate"
    print_info "  • Stash account: Optional (use -e generate_stash=true to auto-generate)"
    echo
    print_info "📧 Next steps:"
    print_info "1. Note the session keys displayed above"
    print_info "2. Create stash account OR use auto-generated one (if enabled)"
    print_info "3. Send stash address & session keys to Fennel Labs"
    print_info "4. Registration info saved at: /home/fennel/validator-registration-bundle.txt"
    echo
    print_info "🔍 To check validator status:"
    print_info "  ssh ubuntu@$SERVER_IP 'sudo systemctl status fennel-node'"
    echo
    print_info "📋 To view logs:"
    print_info "  ssh ubuntu@$SERVER_IP 'sudo journalctl -u fennel-node -f'"
    echo
    print_info "🔒 Stash account mnemonic securely saved at:"
    print_info "  ssh ubuntu@$SERVER_IP 'sudo cat /home/fennel/stash-account.json'"
else
    print_error "Validator setup failed! Check the output above for details."
    exit $PLAYBOOK_EXIT_CODE
fi
