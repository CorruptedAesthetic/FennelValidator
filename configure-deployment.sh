#!/usr/bin/env bash
# configure-deployment.sh - Interactive configuration wizard for Fennel Validator deployment
# This script helps operators gather and validate their environment information

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_prompt() { echo -e "${CYAN}[INPUT]${NC} $1"; }

echo -e "${BLUE}"
cat << 'EOF'
╭─────────────────────────────────────────────────────────────╮
│                                                             │
│   🚀 Fennel Validator Deployment Configuration Wizard      │
│                                                             │
│   This wizard will help you gather the information needed  │
│   to deploy your Fennel validator.                         │
│                                                             │
╰─────────────────────────────────────────────────────────────╯
EOF
echo -e "${NC}"

# Function to prompt for input with validation
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local validation_func="${3:-}"
    local example="${4:-}"
    
    while true; do
        if [ -n "$example" ]; then
            print_prompt "$prompt (e.g., $example): "
        else
            print_prompt "$prompt: "
        fi
        read -r input
        
        if [ -z "$input" ]; then
            print_error "This field is required. Please enter a value."
            continue
        fi
        
        if [ -n "$validation_func" ] && ! $validation_func "$input"; then
            continue
        fi
        
        eval "$var_name='$input'"
        break
    done
}

# Validation functions
validate_ip_or_hostname() {
    local input="$1"
    # Basic validation - could be IP or hostname
    if [[ "$input" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || \
       [[ "$input" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] || \
       [[ "$input" =~ ^[a-zA-Z0-9-]+$ ]]; then
        return 0
    else
        print_error "Please enter a valid IP address or hostname"
        return 1
    fi
}

validate_ssh_user() {
    local input="$1"
    if [[ "$input" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        return 0
    else
        print_error "Please enter a valid SSH username (letters, numbers, underscore, hyphen)"
        return 1
    fi
}

validate_file_path() {
    local input="$1"
    # Expand tilde
    expanded_path="${input/#\~/$HOME}"
    if [ -f "$expanded_path" ]; then
        return 0
    else
        print_error "File not found: $expanded_path"
        return 1
    fi
}

# Start configuration
echo
print_info "Let's gather information about your server and environment..."
echo

# Server details
print_info "=== Server Information ==="
prompt_input "Enter your server IP address or hostname" SERVER_IP validate_ip_or_hostname "203.0.113.50 or validator.example.com"
prompt_input "Enter SSH username for your server" SSH_USER validate_ssh_user "ubuntu, root, ec2-user"

# SSH key (optional)
echo
print_prompt "Do you want to specify a custom SSH private key? (y/N): "
read -r use_custom_key
if [[ "$use_custom_key" =~ ^[Yy] ]]; then
    prompt_input "Enter path to your SSH private key" SSH_KEY_PATH validate_file_path "~/.ssh/id_rsa"
else
    SSH_KEY_PATH=""
fi

# Cloud provider (for reference)
echo
print_info "=== Cloud Provider Information (Optional) ==="
print_prompt "Which cloud provider are you using? (aws/gcp/azure/oracle/digitalocean/other/skip): "
read -r cloud_provider

# Oracle Cloud specific guidance
if [[ "$cloud_provider" =~ ^[Oo]racle ]]; then
    print_info "Oracle Cloud detected!"
    echo
    print_info "🏛️  For Oracle Cloud-specific setup, use our dedicated tools:"
    print_info "• Complete Oracle Cloud automation: ./oracle-cloud/setup-oracle-validator.sh"
    print_info "• Budget optimization guide: ./oracle-cloud/docs/QUICK-BUDGET-SETUP.md"
    print_info "• Migration from Docker: ./oracle-cloud/docs/ORACLE-DOCKER-MIGRATION.md"
    echo
    print_prompt "Do you want to use the Oracle Cloud automated setup instead? (Y/n): "
    read -r use_oracle_setup
    
    if [[ ! "$use_oracle_setup" =~ ^[Nn] ]]; then
        print_info "Launching Oracle Cloud automated setup..."
        exec ./oracle-cloud/setup-oracle-validator.sh
        exit 0
    fi
    
    print_info "Continuing with general cloud setup..."
    print_info "Common Oracle Cloud SSH users:"
    print_info "  - opc (Oracle Linux)"
    print_info "  - ubuntu (Ubuntu instances)"
    print_info "  - centos (CentOS instances)"
    echo
fi

# Test connection
echo
print_info "=== Connection Test ==="
print_prompt "Would you like to test the SSH connection now? (Y/n): "
read -r test_connection

if [[ ! "$test_connection" =~ ^[Nn] ]]; then
    print_info "Testing SSH connection to $SSH_USER@$SERVER_IP..."
    
    ssh_cmd="ssh"
    if [ -n "$SSH_KEY_PATH" ]; then
        expanded_key_path="${SSH_KEY_PATH/#\~/$HOME}"
        ssh_cmd="ssh -i $expanded_key_path"
    fi
    
    if $ssh_cmd -o ConnectTimeout=10 -o BatchMode=yes "$SSH_USER@$SERVER_IP" "echo 'SSH connection successful'" 2>/dev/null; then
        print_success "SSH connection successful!"
        
        # Test sudo
        print_info "Testing sudo access..."
        if $ssh_cmd -o ConnectTimeout=10 -o BatchMode=yes "$SSH_USER@$SERVER_IP" "sudo -n echo 'Sudo access confirmed'" 2>/dev/null; then
            print_success "Sudo access confirmed!"
        else
            print_warning "Sudo access test failed. You may need to enter a password during deployment."
        fi
    else
        print_error "SSH connection failed. Please check your server IP, username, and SSH key."
        print_info "You can still proceed with the configuration, but fix SSH access before deploying."
    fi
fi

# Generate configuration
echo
print_info "=== Configuration Summary ==="
cat << EOF
Server IP/Hostname: $SERVER_IP
SSH Username: $SSH_USER
SSH Key Path: ${SSH_KEY_PATH:-"Default (~/.ssh/id_rsa or SSH agent)"}
Cloud Provider: ${cloud_provider:-"Not specified"}
EOF

# Generate deployment commands
echo
print_info "=== Deployment Commands ==="

if [ -z "$SSH_KEY_PATH" ] && [ "$SSH_USER" == "ubuntu" ]; then
    # Simple case - default settings
    echo "Your deployment command:"
    echo -e "${GREEN}./fennel-bootstrap.sh $SERVER_IP${NC}"
else
    # Need custom inventory
    echo "Creating custom inventory file for your configuration..."
    
    inventory_content="[fennel_validators]"
    if [ -n "$SSH_KEY_PATH" ]; then
        expanded_key_path="${SSH_KEY_PATH/#\~/$HOME}"
        inventory_content="$inventory_content\n$SERVER_IP ansible_user=$SSH_USER ansible_ssh_private_key_file=$expanded_key_path"
    else
        inventory_content="$inventory_content\n$SERVER_IP ansible_user=$SSH_USER"
    fi
    
    cat > "custom-inventory-$(date +%Y%m%d-%H%M%S)" << EOF
$inventory_content
EOF
    
    echo "Custom inventory file created: custom-inventory-$(date +%Y%m%d-%H%M%S)"
    echo
    echo "Your deployment commands:"
    echo -e "${GREEN}cd ansible/${NC}"
    echo -e "${GREEN}ansible-playbook -i ../custom-inventory-$(date +%Y%m%d-%H%M%S) validator.yml -e generate_keys=true${NC}"
fi

echo
print_info "=== Next Steps ==="

if [[ "$cloud_provider" =~ ^[Oo]racle ]]; then
    print_info "Oracle Cloud Setup:"
    echo "1. For comprehensive Oracle Cloud automation, consider:"
    echo "   ./oracle-cloud/setup-oracle-validator.sh"
    echo
    echo "2. Or continue with manual setup:"
    echo "   • Ensure your Oracle Cloud instance is configured properly"
    echo "   • Configure Security Lists (firewall) for ports 22, 30333, 9615"
    echo "   • See ./oracle-cloud/docs/ for detailed Oracle Cloud guides"
    echo
    echo "3. Run the deployment command shown above"
    echo
    echo "4. Register your validator using the generated keys"
    echo
    print_info "📚 Oracle Cloud specific guides:"
    echo "   • ./oracle-cloud/docs/ORACLE-INTEGRATION.md - Complete setup"
    echo "   • ./oracle-cloud/docs/ORACLE-SINGLE-VALIDATOR-GUIDE.md - Budget optimization"
    echo "   • ./oracle-cloud/docs/ORACLE-DOCKER-MIGRATION.md - Migration guidance"
else
    echo "1. Review the firewall requirements in PRODUCTION-DEPLOYMENT.md"
    echo "2. Ensure ports 22, 30333, and 9615 are properly configured"
    echo "3. Run the deployment command shown above"
    echo "4. Follow the post-deployment instructions to register your validator"
fi

echo
print_success "Configuration complete! You're ready to deploy your Fennel validator."
