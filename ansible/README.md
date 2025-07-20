# Fennel Validator Ansible Setup

This directory contains the Ansible-based setup for Fennel validators using Parity Technologies' proven methodology through the `paritytech.chain` Galaxy collection.

## 🚀 Quick Start

### Prerequisites

Ensure you have these installed on your local machine:
- **Ansible** (2.9 or higher)
- **jq** (for JSON processing)
- **Rust toolchain** (for subkey utility)

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y ansible jq
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# CentOS/RHEL
sudo yum install -y ansible jq
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# macOS
brew install ansible jq
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
```

### One-Command Setup

```bash
# From the FennelValidator root directory
./fennel-bootstrap.sh <YOUR_SERVER_IP>

# Example:
./fennel-bootstrap.sh 198.51.100.7
```

That's it! The script will:
1. Generate secure temporary keys
2. Install the Ansible collection
3. Deploy and configure your validator
4. Rotate to fresh, secure keys
5. Display the session key bundle for registration

## 📁 Directory Structure

```
ansible/
├── requirements.yml        # Pins paritytech.chain >=1.10.0
├── validator.yml          # Main playbook
├── inventory.example      # Sample inventory file
└── group_vars/
    └── all.yml            # Default variables
```

## 🔧 Manual Setup (Advanced)

If you prefer manual control:

### 1. Install the Collection

```bash
cd ansible/
ansible-galaxy collection install -r requirements.yml
```

### 2. Create Inventory File

```bash
# Copy and customize the example
cp inventory.example inventory

# Edit to add your server(s)
# Format: IP_ADDRESS ansible_user=SSH_USERNAME
echo "198.51.100.7 ansible_user=ubuntu" > inventory
```

### 3. Configure Variables

Edit `group_vars/all.yml` or use environment variables:

```bash
export AURA_SEED="0x1234..."
export GRANDPA_SEED="0x5678..."
export NODE_KEY="0x9abc..."
export NODE_NAME="my-fennel-validator"
```

### 4. Run the Playbook

```bash
# Basic run
ansible-playbook -i inventory validator.yml

# With key generation
ansible-playbook -i inventory validator.yml -e "generate_keys=true"

# With custom variables
ansible-playbook -i inventory validator.yml \
  -e "aura_seed=0x..." \
  -e "grandpa_seed=0x..." \
  -e "node_key=0x..."
```

## 🔐 Security Best Practices

### Using Ansible Vault

For production deployments, encrypt sensitive data:

```bash
# Encrypt a seed
ansible-vault encrypt_string '0x1234567890abcdef...' --name 'aura_seed'

# Add to group_vars/all.yml
aura_seed: !vault |
    $ANSIBLE_VAULT;1.1;AES256
    66386439653...

# Run with vault password
ansible-playbook -i inventory validator.yml --ask-vault-pass
```

### Environment Variables

The playbook automatically reads from environment variables:
- `AURA_SEED` - Aura consensus key seed
- `GRANDPA_SEED` - GRANDPA finality key seed  
- `NODE_KEY` - Libp2p network identity key
- `NODE_NAME` - Human-readable validator name

## 🔍 Verification

### Check Service Status

```bash
# On the validator server
sudo systemctl status fennel-node
sudo journalctl -u fennel-node -f
```

### Verify Key Rotation

After deployment with `generate_keys=true`, the playbook will display:
```
╭──────────────────────────────────────────────╮
│  SEND THIS TO FENNEL ADMIN:                  │
│  Stash  : <YOUR-SS58-STASH>                  │
│  Session: 0x1234567890abcdef...               │
╰──────────────────────────────────────────────╯
```

## 🔄 Updates

### Update Node Version

Edit `validator.yml` and change:
```yaml
node_binary_image: ghcr.io/corruptedaesthetic/fennel-solonet:fennel-node-0.5.8
```

Then re-run the playbook:
```bash
ansible-playbook -i inventory validator.yml
```

### Update Ansible Collection

```bash
ansible-galaxy collection install -r requirements.yml --force
```

## 🌐 Multi-Server Deployment

To deploy across multiple servers, add them to your inventory:

```ini
[fennel_validators]
validator1.example.com ansible_user=ubuntu
validator2.example.com ansible_user=ubuntu
198.51.100.7 ansible_user=root
```

Each validator will get unique keys automatically.

## 🔧 Troubleshooting

### Connection Issues

```bash
# Test connection
ansible -i inventory fennel_validators -m ping

# Skip host key checking
export ANSIBLE_HOST_KEY_CHECKING=False
```

### Docker Issues

```bash
# On the validator server
sudo docker ps
sudo docker logs fennel-node
```

### Key Generation Issues

Ensure `subkey` is installed:
```bash
cargo install --git https://github.com/paritytech/substrate subkey --force
```

## 📚 Additional Resources

- [Parity Ansible Collection Documentation](https://galaxy.ansible.com/ui/repo/published/paritytech/chain/docs/)
- [Substrate Key Management](https://docs.substrate.io/fundamentals/accounts-addresses-keys/)
- [Ansible Vault Guide](https://docs.ansible.com/ansible/latest/vault_guide/vault.html)
