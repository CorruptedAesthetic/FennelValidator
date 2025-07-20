# 🚀 Production Deployment Guide

## Prerequisites

Ensure you have a Linux server (Ubuntu 20.04+, Debian 11+, or similar) with:
- **SSH access** with sudo privileges  
- **Internet connectivity** for downloading the Fennel binary
- **At least 2GB RAM** and 50GB storage
- **Open ports**: 30333 (P2P), 9615 (metrics), 9933 (RPC, localhost only)

### 🔥 Firewall Configuration

**Required Ports:**
- **SSH (22)**: For deployment and management
- **P2P (30333)**: For blockchain network communication
- **Metrics (9615)**: For monitoring (optional, can be localhost-only)

**Security Considerations:**
- **Port 9933** (RPC): Should NOT be exposed publicly - used only for key rotation during setup
- **Port 9944** (WebSocket): Not needed for validators

**Example Firewall Rules:**
```bash
# Ubuntu/Debian (ufw)
sudo ufw allow 22/tcp
sudo ufw allow 30333/tcp
sudo ufw allow 9615/tcp
sudo ufw enable

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --permanent --add-port=30333/tcp
sudo firewall-cmd --permanent --add-port=9615/tcp
sudo firewall-cmd --reload

# Cloud Provider Security Groups
# Ensure your cloud provider security group/firewall allows:
# - Inbound: 22 (your IP only), 30333 (0.0.0.0/0)
# - Outbound: 443, 80 (for downloads), 30333 (for P2P)
```

## Server IP Address Formats

The deployment script accepts several formats for your server address:

### IPv4 Address (Most Common)
```bash
./fennel-bootstrap.sh 192.168.1.100    # Local network
./fennel-bootstrap.sh 203.0.113.50     # Public IP
./fennel-bootstrap.sh 10.0.0.15        # Private cloud IP
```

### Domain Name/Hostname
```bash
./fennel-bootstrap.sh validator.example.com
./fennel-bootstrap.sh my-server.com  
./fennel-bootstrap.sh aws-instance.us-east-1.compute.amazonaws.com
```

### IPv6 Address (Advanced)
```bash
./fennel-bootstrap.sh 2001:db8::1
```

## Required Operator Information

### 🔧 Server Connection Details

The operator must provide **at minimum**:

| Information | Format | Example | Where to Specify |
|-------------|--------|---------|------------------|
| **Server IP/Hostname** | IPv4, IPv6, or FQDN | `203.0.113.50` | Command line: `./fennel-bootstrap.sh 203.0.113.50` |
| **SSH Username** | System user with sudo | `ubuntu`, `root`, `ec2-user` | See SSH User Configuration below |

### 🌩️ Cloud Provider Specifics

Different cloud providers have different default SSH users:

| Cloud Provider | Default SSH User | Typical Server IP Format |
|----------------|------------------|-------------------------|
| **AWS EC2** | `ubuntu`, `ec2-user`, `admin` | `54.123.45.67` or `ec2-*.compute.amazonaws.com` |
| **Google Cloud** | Your Google username | `35.123.45.67` or `instance-name.zone.c.project.com` |
| **Azure** | `azureuser` | `20.123.45.67` or `vm-name.region.cloudapp.azure.com` |
| **DigitalOcean** | `root` | `167.123.45.67` |
| **Oracle Cloud** | `ubuntu`, `opc` | `132.123.45.67` |
| **Vultr** | `root` | `149.123.45.67` |
| **Linode** | `root` | `172.123.45.67` |
| **Hetzner** | `root` | `95.123.45.67` |

### 🔑 SSH User Configuration

**Default**: The script assumes an `ubuntu` user with sudo privileges.

**For Different SSH Users:**

**Option 1: Modify Bootstrap Script (Simplest)**
Edit `fennel-bootstrap.sh` line 140 before running:
```bash
# Change this line in the script:
$SERVER_IP ansible_user=ubuntu

# To your SSH user:
$SERVER_IP ansible_user=root          # For DigitalOcean, Vultr, etc.
$SERVER_IP ansible_user=ec2-user      # For Amazon Linux
$SERVER_IP ansible_user=azureuser     # For Azure VMs
```

**Option 2: Custom Inventory File**
```bash
# Create custom inventory with your specific settings
cat > custom-inventory << EOF
[fennel_validators]
YOUR_SERVER_IP ansible_user=YOUR_SSH_USER ansible_ssh_private_key_file=~/.ssh/YOUR_KEY
EOF

# Run with custom inventory
cd ansible/
ansible-playbook -i ../custom-inventory validator.yml -e generate_keys=true
```

**Option 3: Environment Variables**
```bash
# Set SSH user as environment variable
export ANSIBLE_REMOTE_USER=root
./fennel-bootstrap.sh YOUR_SERVER_IP
```

## 📋 Pre-Deployment Checklist

Before running the deployment script, ensure you have:

### Server Information
- [ ] **Server IP/Hostname**: `_________________`
- [ ] **SSH Username**: `_________________` (e.g., ubuntu, root, ec2-user)
- [ ] **SSH Key Path**: `_________________` (e.g., ~/.ssh/id_rsa)
- [ ] **Cloud Provider**: `_________________` (AWS, GCP, Azure, DO, etc.)

### Network Access
- [ ] **SSH Connection Tested**: Can you `ssh user@server-ip`?
- [ ] **Sudo Access Confirmed**: Can the SSH user run `sudo` commands?
- [ ] **Internet Connectivity**: Server can download from GitHub/internet?
- [ ] **Firewall Configured**: Ports 22, 30333, 9615 accessible as needed?

### Local Machine Setup
- [ ] **Ansible Installed**: `ansible --version` shows 2.9+?
- [ ] **jq Installed**: `jq --version` works?
- [ ] **Rust/Cargo Installed**: `cargo --version` works?
- [ ] **Git Repository Cloned**: You have the FennelValidator repo?

### Test Connection
```bash
# Test SSH access
ssh YOUR_SSH_USER@YOUR_SERVER_IP "echo 'Connection successful'"

# Test sudo access
ssh YOUR_SSH_USER@YOUR_SERVER_IP "sudo echo 'Sudo access confirmed'"

# Test Ansible connectivity (after creating inventory)
echo "YOUR_SERVER_IP ansible_user=YOUR_SSH_USER" > test-inventory
ansible -i test-inventory all -m ping
```

## One-Command Deployment

```bash
# From your local machine (not the server)
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator

# Deploy to your server
./fennel-bootstrap.sh YOUR_SERVER_IP
```

Replace `YOUR_SERVER_IP` with your actual server IP address.

## What Happens During Deployment

1. **Prerequisites Check** (30 seconds)
   - Verifies Ansible, jq, and subkey are available
   - Installs missing tools if needed

2. **Secure Key Generation** (10 seconds)
   - Generates temporary Aura/GRANDPA seeds locally
   - Creates node key for consistent libp2p identity
   - Keys are used only for initial setup

3. **Server Configuration** (2-3 minutes)
   - Downloads Fennel binary (.tgz) and verifies checksum
   - Creates system user and directories
   - Installs systemd service configuration
   - Injects temporary keys to bootstrap keystore

4. **Service Startup** (30 seconds)
   - Starts fennel-node service
   - Node begins syncing with network
   - Downloads and applies chainspec

5. **Key Rotation** (10 seconds)
   - Calls `author_rotateKeys` RPC endpoint
   - Node generates fresh, secure keys internally
   - Displays 128-byte session key bundle

## After Deployment

You'll see output like this:
```
╭──────────────────────────────────────────────╮
│  SEND THIS TO FENNEL ADMIN:                  │
│  Stash  : <YOUR-SS58-STASH>                  │
│  Session: 0x1234567890abcdef...               │
╰──────────────────────────────────────────────╯
```

## Registration Process

1. **Create Stash Account**
   - Use Polkadot.js wallet or subkey
   - Fund with minimum required amount
   - Note the SS58 address

2. **Submit to Fennel Labs**
   - Send both stash address and session key bundle
   - Wait for confirmation of registration

3. **Validator Activation**
   - Your validator will be active in next session (~10 minutes)
   - Monitor logs to confirm block production

## Monitoring Your Validator

```bash
# Check service status
ssh YOUR_USER@YOUR_SERVER_IP 'sudo systemctl status fennel-node'

# View real-time logs
ssh YOUR_USER@YOUR_SERVER_IP 'sudo journalctl -u fennel-node -f'

# Check metrics
curl http://YOUR_SERVER_IP:9615/metrics | grep substrate_block_height
```

## Updates

When new Fennel versions are released:

```bash
# Edit ansible/validator.yml to update the version
vim ansible/validator.yml
# Change: node_binary: https://github.com/.../fennel-node-0.5.8.tgz

# Deploy update
cd ansible/
ansible-playbook -i inventory validator.yml
```

## Troubleshooting

### Node Won't Start
```bash
# Check logs for errors
sudo journalctl -u fennel-node -n 50

# Verify binary integrity
sha256sum /usr/local/bin/fennel-node
```

### Key Rotation Failed
```bash
# Check if RPC is responding
curl -s http://localhost:9933 -d '{"jsonrpc":"2.0","id":1,"method":"system_health","params":[]}'

# Manual key rotation
curl -H "Content-Type: application/json" \
  -d '{"id":1,"jsonrpc":"2.0","method":"author_rotateKeys","params":[]}' \
  http://localhost:9933
```

### Sync Issues
```bash
# Check network connectivity
curl -s http://localhost:9933 -d '{"jsonrpc":"2.0","id":1,"method":"system_networkState","params":[]}'

# Check peer count
curl -s http://localhost:9933 -d '{"jsonrpc":"2.0","id":1,"method":"system_health","params":[]}' | jq .result.peers
```

## Security Best Practices

- ✅ **Firewall**: Only allow SSH (22), P2P (30333), and metrics (9615)
- ✅ **SSH Keys**: Use key-based authentication, disable password login
- ✅ **Updates**: Keep OS packages updated regularly
- ✅ **Monitoring**: Set up alerts for validator downtime
- ✅ **Backups**: Backup your stash account keys (not validator keys)

## Support

- **Logs**: Always include systemd logs when requesting help
- **Configuration**: Share your inventory/variables (redact secrets)
- **Community**: Join Fennel validator channels for support
- **Documentation**: Refer to docs/ directory for detailed guides

## Production Checklist

Before going live:

- [ ] Server meets minimum requirements  
- [ ] SSH access configured and tested
- [ ] Firewall rules properly configured
- [ ] Stash account created and funded
- [ ] Validator name chosen
- [ ] Monitoring/alerting set up
- [ ] Emergency procedures documented
