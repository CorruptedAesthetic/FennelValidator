#!/usr/bin/env bash
# verify-ansible-setup.sh - Verify the Ansible setup is correct

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

echo "Fennel Validator Ansible Setup Verification"
echo "==========================================="
echo

# Check if we're in the right directory
if [ ! -f "fennel-bootstrap.sh" ]; then
    print_error "Must be run from FennelValidator root directory"
    exit 1
fi

print_info "Checking Ansible setup files..."

# Check if ansible directory exists
if [ ! -d "ansible" ]; then
    print_error "ansible/ directory not found"
    exit 1
fi
print_success "ansible/ directory exists"

# Check required files
REQUIRED_FILES=(
    "ansible/requirements.yml"
    "ansible/validator.yml"
    "ansible/inventory.example"
    "ansible/group_vars/all.yml"
    "ansible/README.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "$file exists"
    else
        print_error "$file missing"
        exit 1
    fi
done

# Check bootstrap script
if [ -x "fennel-bootstrap.sh" ]; then
    print_success "fennel-bootstrap.sh is executable"
else
    print_error "fennel-bootstrap.sh is not executable"
    print_info "Run: chmod +x fennel-bootstrap.sh"
    exit 1
fi

echo
print_info "Checking prerequisites..."

# Check for ansible
if command -v ansible-playbook >/dev/null 2>&1; then
    ANSIBLE_VERSION=$(ansible-playbook --version | head -n1 | awk '{print $2}')
    print_success "Ansible found (version: $ANSIBLE_VERSION)"
else
    print_error "Ansible not found"
    print_info "Install with: sudo apt install -y ansible"
fi

# Check for jq
if command -v jq >/dev/null 2>&1; then
    JQ_VERSION=$(jq --version)
    print_success "jq found ($JQ_VERSION)"
else
    print_error "jq not found"
    print_info "Install with: sudo apt install -y jq"
fi

# Check for cargo/rust
if command -v cargo >/dev/null 2>&1; then
    CARGO_VERSION=$(cargo --version)
    print_success "Cargo found ($CARGO_VERSION)"
else
    print_error "Cargo not found"
    print_info "Install Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
fi

# Check for subkey
if command -v subkey >/dev/null 2>&1; then
    print_success "subkey found"
else
    print_warning "subkey not found (will be installed automatically)"
fi

echo
print_info "Validating Ansible files..."

# Check requirements.yml syntax
if ansible-galaxy collection list paritytech.chain >/dev/null 2>&1; then
    print_success "paritytech.chain collection already installed"
else
    print_warning "paritytech.chain collection not installed (will be installed automatically)"
fi

# Check validator.yml syntax
cd ansible/
if ansible-playbook --syntax-check validator.yml >/dev/null 2>&1; then
    print_success "validator.yml syntax is valid"
else
    print_error "validator.yml has syntax errors"
    ansible-playbook --syntax-check validator.yml
    exit 1
fi

echo
print_info "Setup verification complete!"
echo
print_success "✅ Your Fennel Validator Ansible setup is ready!"
echo
print_info "Next steps:"
print_info "1. Ensure you have a Linux server with SSH access"
print_info "2. Run: ./fennel-bootstrap.sh YOUR_SERVER_IP"
print_info "3. Follow the registration process in docs/VALIDATOR-REGISTRATION.md"
echo
print_info "For more information, see ansible/README.md"
