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

# Store the inventory filename for later use
INVENTORY_FILE=""

if [ -z "$SSH_KEY_PATH" ] && [ "$SSH_USER" == "ubuntu" ]; then
    # Simple case - default settings
    echo "Your deployment command:"
    echo -e "${GREEN}./fennel-bootstrap.sh $SERVER_IP${NC}"
    DEPLOYMENT_TYPE="bootstrap"
else
    # Need custom inventory
    echo "Creating custom inventory file for your configuration..."
    
    INVENTORY_FILE="custom-inventory-$(date +%Y%m%d-%H%M%S)"
    
    if [ -n "$SSH_KEY_PATH" ]; then
        expanded_key_path="${SSH_KEY_PATH/#\~/$HOME}"
        cat > "$INVENTORY_FILE" << EOF
[fennel_validators]
$SERVER_IP ansible_user=$SSH_USER ansible_ssh_private_key_file=$expanded_key_path
EOF
    else
        cat > "$INVENTORY_FILE" << EOF
[fennel_validators]
$SERVER_IP ansible_user=$SSH_USER
EOF
    fi
    
    echo "Custom inventory file created: $INVENTORY_FILE"
    echo
    echo "Your deployment commands:"
    echo -e "${GREEN}cd ansible/${NC}"
echo -e "${GREEN}ansible-playbook -i ../$INVENTORY_FILE validator.yml -e generate_keys=true${NC}"
    DEPLOYMENT_TYPE="ansible"
fi

echo
print_info "=== Stash Account Generation ==="
print_prompt "Would you like to auto-generate a stash account? (Y/n): "
read -r generate_stash

if [[ "$generate_stash" =~ ^[Nn] ]]; then
    STASH_OPTION=""
    print_info "Session keys only will be generated. You'll need to create your own stash account."
else
    STASH_OPTION="-e generate_stash=true"
    print_info "Complete validator bundle (stash account + session keys) will be generated."
fi

echo
print_info "=== Automatic Deployment Option ==="
print_prompt "Would you like to deploy the validator now? (Y/n): "
read -r deploy_now

if [[ ! "$deploy_now" =~ ^[Nn] ]]; then
    print_info "Starting automatic deployment..."
    
    if [ "$DEPLOYMENT_TYPE" == "bootstrap" ]; then
        # Use bootstrap script
        print_info "Running bootstrap deployment..."
        if ./fennel-bootstrap.sh "$SERVER_IP"; then
            print_success "Bootstrap deployment completed successfully!"
        else
            print_error "Bootstrap deployment failed. Please check the output above and try manual deployment."
            exit 1
        fi
    else
        # Use Ansible
        print_info "Checking Ansible requirements..."
        
        # Check if we're in the right directory
        if [ ! -d "ansible" ]; then
            print_error "ansible/ directory not found. Make sure you're in the FennelValidator root directory."
            exit 1
        fi
        
        # Check if requirements.yml exists
        if [ ! -f "ansible/requirements.yml" ]; then
            print_error "ansible/requirements.yml not found. Cannot install Ansible roles."
            exit 1
        fi
        
        # Install Ansible requirements
        print_info "Installing Ansible requirements..."
        if ! (cd ansible && ansible-galaxy install -r requirements.yml); then
            print_error "Failed to install Ansible requirements. Please check your Ansible installation."
            exit 1
        fi
        
        # Run the deployment
        print_info "Running Ansible deployment..."
        print_info "Command: ansible-playbook -i ../$INVENTORY_FILE validator.yml -e generate_keys=true $STASH_OPTION"
        
        if (cd ansible && ansible-playbook -i "../$INVENTORY_FILE" validator.yml -e generate_keys=true $STASH_OPTION); then
            print_success "Ansible deployment completed successfully!"
            echo
            print_info "🎉 Your Fennel validator has been deployed!"
            print_info "Please save any registration bundle information shown above."
        else
            print_error "Ansible deployment failed. Please check the output above."
            print_info "You can try running the deployment manually with:"
            print_info "cd ansible/"
            print_info "ansible-playbook -i ../$INVENTORY_FILE validator.yml -e generate_keys=true"
            exit 1
        fi
    fi
else
    print_info "Skipping automatic deployment."
fi

echo
print_info "=== Next Steps ==="

if [[ "$deploy_now" =~ ^[Nn] ]]; then
    echo "1. Review the firewall requirements in PRODUCTION-DEPLOYMENT.md"
    echo "2. Ensure ports 22, 30333, and 9615 are properly configured"
    echo "3. Run the deployment command shown above"
    echo "4. Follow the post-deployment instructions to register your validator"
else
    echo "1. If deployment was successful, your validator should now be running"
    echo "2. Check the validator status with: ssh $SSH_USER@$SERVER_IP 'sudo systemctl status fennel-node'"
    echo "3. View logs with: ssh $SSH_USER@$SERVER_IP 'sudo journalctl -u fennel-node -f'"
    echo "4. Register your validator using any registration bundle shown above"
fi

echo
print_success "Configuration complete! You're ready to deploy your Fennel validator."
