# 🚀 Step-by-Step Fennel Validator Deployment with Ansible

Here's a complete guide to deploy a Fennel validator using Ansible from this repository.

## Prerequisites

Before starting, ensure you have:
- ✅ A Linux server (Ubuntu 20.04+ recommended) with SSH access
- ✅ Server IP address and SSH credentials  
- ✅ Local machine with required tools installed (see installation guide below)

### Local Machine Tool Installation

You need to install the following tools on your local machine (not the server):

#### 1. Install Ansible

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y ansible python3-pip
```

**macOS:**
```bash
# Using Homebrew
brew install ansible

# Or using pip
pip3 install ansible
```

**CentOS/RHEL/Fedora:**
```bash
# CentOS/RHEL 8+
sudo dnf install -y ansible

# Or using pip
pip3 install ansible
```

**Verify Installation:**
```bash
ansible --version
# Should show version 2.15.6 or higher
```

#### 2. Install jq (JSON processor)

**Ubuntu/Debian:**
```bash
sudo apt install -y jq
```

**macOS:**
```bash
brew install jq
```

**CentOS/RHEL/Fedora:**
```bash
sudo dnf install -y jq
```

**Verify Installation:**
```bash
jq --version
```

#### 3. Install subkey (Substrate key management tool)

**Option A: Install via Cargo (Recommended)**
```bash
# First install Rust if you don't have it
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install subkey
cargo install --git https://github.com/paritytech/substrate subkey --force
```

**Option B: Download pre-built binary**
```bash
# Download subkey v3.0.0 (compatible version)
curl -fSL -o subkey 'https://releases.parity.io/substrate/x86_64-debian%3Astretch/v3.0.0/subkey/subkey'
chmod +x subkey
sudo mv subkey /usr/local/bin/subkey
```

**Verify Installation:**
```bash
subkey --version
```

#### 4. Install Additional Tools

**SSH Client (usually pre-installed):**
```bash
# Verify SSH is available
ssh -V
```

**curl (for API calls):**
```bash
# Ubuntu/Debian
sudo apt install -y curl

# macOS (usually pre-installed)
# brew install curl

# CentOS/RHEL/Fedora
sudo dnf install -y curl
```

**git (for repository access):**
```bash
# Ubuntu/Debian
sudo apt install -y git

# macOS (usually pre-installed)
# brew install git

# CentOS/RHEL/Fedora
sudo dnf install -y git
```

#### 5. Verify All Tools

Run this command to verify all required tools are installed:
```bash
echo "Checking required tools..."
echo "Ansible: $(ansible --version | head -n1)"
echo "jq: $(jq --version)"
echo "subkey: $(subkey --version)"
echo "SSH: $(ssh -V)"
echo "curl: $(curl --version | head -n1)"
echo "git: $(git --version)"
```

**Expected Output:**
```
Checking required tools...
Ansible: ansible [core 2.15.6]
jq: jq-1.6
subkey: subkey 3.0.0
SSH: OpenSSH_8.9p1 Ubuntu-3ubuntu0.3, OpenSSL 3.0.2 15 Mar 2022
curl: curl 7.81.0 (x86_64-pc-linux-gnu)
git: git version 2.34.1
```

## Bare Metal Deployment Considerations

### Hardware Setup
- **Physical Access**: Ensure you have physical access to the server
- **Power Management**: Configure UPS and power management
- **Cooling**: Ensure adequate ventilation and temperature monitoring
- **Network**: Connect to stable internet with appropriate bandwidth

### Operating System Installation
```bash
# Recommended: Ubuntu 22.04 LTS Server
# Download from: https://ubuntu.com/download/server
# Install with:
# - OpenSSH server (for remote access)
# - Standard system utilities
# - No GUI (headless operation preferred)
```

### Network Configuration
```bash
# Configure static IP (recommended for production)
sudo nano /etc/netplan/01-netcfg.yaml

# Example configuration:
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

# Apply configuration
sudo netplan apply
```

### Port Forwarding (Home Lab)
If running behind a router, configure port forwarding:
- **Port 30333** → Your validator server IP
- **Port 9615** → Your validator server IP (optional, for monitoring)

## Method 1: Configuration Wizard (Recommended for First-Time Users)

### Step 1: Navigate to Repository
```bash
cd /path/to/FennelValidator
```

### Step 2: Run Configuration Wizard
```bash
./configure-deployment.sh
```

The wizard will interactively prompt you for:
- Server IP address or hostname
- SSH username (e.g., `ubuntu`, `root`, `ec2-user`)
- SSH private key path
- Custom ports (if needed)

### Step 3: Deploy
The wizard will automatically run the Ansible playbook after configuration.

---

## Method 2: Quick Bootstrap (For Standard Setups)

### Step 1: Navigate to Repository
```bash
cd /path/to/FennelValidator
```

### Step 2: Run Bootstrap Script
```bash
./fennel-bootstrap.sh YOUR_SERVER_IP
```

**Example:**
```bash
./fennel-bootstrap.sh 54.123.45.67
```

**Assumptions:**
- SSH user is `ubuntu`
- SSH key is `~/.ssh/id_rsa` or available via SSH agent
- Standard ports (SSH: 22, P2P: 30333, Metrics: 9615)

---

## Method 3: Manual Ansible Deployment (Advanced)

### Step 1: Install Ansible Requirements
```bash
cd ansible/
ansible-galaxy install -r requirements.yml
```

### Step 2: Create Custom Inventory
```bash
# Create your inventory file
cat > my-inventory << EOF
[fennel_validators]
YOUR_SERVER_IP ansible_user=YOUR_SSH_USER ansible_ssh_private_key_file=~/.ssh/your-key.pem
EOF
```

**Real Examples:**
```bash
# AWS EC2 (Ubuntu)
cat > my-inventory << EOF
[fennel_validators]
54.123.45.67 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my-aws-key.pem
EOF

# DigitalOcean
cat > my-inventory << EOF
[fennel_validators]
164.123.45.67 ansible_user=root ansible_ssh_private_key_file=~/.ssh/do_key
EOF

# Google Cloud
cat > my-inventory << EOF
[fennel_validators]
35.123.45.67 ansible_user=myusername ansible_ssh_private_key_file=~/.ssh/gcp_key
EOF
```

### Step 3: Test Connection
```bash
ansible -i my-inventory fennel_validators -m ping
```

Expected output:
```
YOUR_SERVER_IP | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Step 4: Deploy Validator
```bash
ansible-playbook -i my-inventory validator.yml -e generate_keys=true
```

---

## What Happens During Deployment

### Phase 1: System Preparation
- ✅ Updates system packages
- ✅ Creates `fennel` user account
- ✅ Sets up directory structure (`/home/fennel/`)
- ✅ Configures firewall rules

### Phase 2: Binary Installation
- ✅ Downloads Fennel node binary (v0.5.9)
- ✅ Verifies checksum integrity
- ✅ Installs to `/usr/local/bin/fennel-node`
- ✅ Sets proper permissions

### Phase 3: Chain Configuration
- ✅ Downloads production chainspec
- ✅ Stores at `/home/fennel/chainspecs/production-raw.json`
- ✅ Configures node parameters

### Phase 4: Service Setup
- ✅ Creates systemd service file
- ✅ Starts `fennel-node` service
- ✅ Enables auto-start on boot
- ✅ Configures logging with journald

### Phase 5: Key Generation
- ✅ Generates secure session keys inside the node
- ✅ Extracts public keys via RPC
- ✅ Displays registration bundle

---

## Post-Deployment Steps

### Step 1: Verify Service Status
```bash
ssh YOUR_SSH_USER@YOUR_SERVER_IP "sudo systemctl status fennel-node"
```

### Step 2: Check Logs
```bash
ssh YOUR_SSH_USER@YOUR_SERVER_IP "sudo journalctl -u fennel-node -f"
```

### Step 3: Verify Network Connectivity
```bash
ssh YOUR_SSH_USER@YOUR_SERVER_IP "curl -H 'Content-Type: application/json' -d '{\"id\":1, \"jsonrpc\":\"2.0\", \"method\": \"system_health\", \"params\":[]}' http://localhost:9944"
```

### Step 4: Get Session Keys
The deployment will display a registration bundle like:
```
====================================
🔑 VALIDATOR REGISTRATION BUNDLE
====================================
Validator Address: 5G7XdKB...
Session Keys: 0x123abc...
Node Key: /home/fennel/.local/share/fennel-node/chains/fennel/network/secret_ed25519
====================================
```

### Step 5: Register with Fennel Labs
Provide the registration bundle to Fennel Labs administrators for validator activation.

---

## Monitoring Your Validator

### Check Service Health
```bash
ssh YOUR_SSH_USER@YOUR_SERVER_IP "sudo systemctl is-active fennel-node"
```

### View Live Logs
```bash
ssh YOUR_SSH_USER@YOUR_SERVER_IP "sudo journalctl -u fennel-node -f --since '10 minutes ago'"
```

### Check Peer Connections
```bash
ssh YOUR_SSH_USER@YOUR_SERVER_IP "curl -s -H 'Content-Type: application/json' -d '{\"id\":1, \"jsonrpc\":\"2.0\", \"method\": \"system_networkState\", \"params\":[]}' http://localhost:9944"
```

### Monitor Metrics (if enabled)
```bash
curl http://YOUR_SERVER_IP:9615/metrics
```

---

## Bare Metal Specific Troubleshooting

### Hardware Issues
```bash
# Check system resources
htop                    # CPU and memory usage
df -h                   # Disk space
sudo smartctl -a /dev/sda  # Disk health (if smartmontools installed)

# Check temperature (if sensors available)
sudo apt install lm-sensors
sensors

# Check power supply
sudo dmesg | grep -i power
```

### Network Issues (Bare Metal)
```bash
# Check network connectivity
ip addr show            # Network interfaces
ip route show           # Routing table
ping -c 4 8.8.8.8      # Internet connectivity
nslookup google.com     # DNS resolution

# Check port forwarding
sudo netstat -tulpn | grep :30333
telnet localhost 30333  # Test local port
```

### Power Management
```bash
# Check UPS status (if available)
sudo apt install apcupsd
apcaccess status

# Configure automatic shutdown on power failure
sudo nano /etc/apcupsd/apcupsd.conf
```

## Troubleshooting Common Issues

### SSH Connection Issues
```bash
# Test SSH access
ssh -v YOUR_SSH_USER@YOUR_SERVER_IP

# Check SSH key permissions
chmod 600 ~/.ssh/your-key.pem
```

### Ansible Connection Issues
```bash
# Verbose output
ansible-playbook -i my-inventory validator.yml -e generate_keys=true -vvv

# Test specific connection
ansible -i my-inventory fennel_validators -m setup
```

### Service Issues
```bash
# Check service status
ssh YOUR_SSH_USER@YOUR_SERVER_IP "sudo systemctl status fennel-node"

# Restart service
ssh YOUR_SSH_USER@YOUR_SERVER_IP "sudo systemctl restart fennel-node"

# Check configuration
ssh YOUR_SSH_USER@YOUR_SERVER_IP "sudo cat /etc/systemd/system/fennel-node.service"
```

---

## Security Best Practices

1. **Firewall Configuration**
   - Only allow SSH from your IP
   - Open P2P port (30333) to public
   - Restrict metrics port (9615) to monitoring systems

2. **SSH Security**
   - Use SSH keys, not passwords
   - Disable root SSH login
   - Use non-standard SSH ports if possible

3. **Key Management**
   - Session keys are generated securely on the node
   - Never expose private keys
   - Backup important configuration files

4. **Monitoring**
   - Regularly check validator status
   - Monitor system resources
   - Set up alerting for service failures

---

## Cloud Provider Specific Examples

### Amazon Web Services (AWS)
```bash
# Example inventory for AWS EC2
[fennel_validators]
ec2-54-123-45-67.compute-1.amazonaws.com ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my-aws-key.pem

# Or using IP directly
54.123.45.67 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my-aws-key.pem
```

### Google Cloud Platform (GCP)
```bash
# Example inventory for GCP
[fennel_validators]
35.123.45.67 ansible_user=myusername ansible_ssh_private_key_file=~/.ssh/gcp_key
```

### Microsoft Azure
```bash
# Example inventory for Azure
[fennel_validators]
myvm.westus.cloudapp.azure.com ansible_user=azureuser ansible_ssh_private_key_file=~/.ssh/azure_key
```

### DigitalOcean
```bash
# Example inventory for DigitalOcean
[fennel_validators]
164.123.45.67 ansible_user=root ansible_ssh_private_key_file=~/.ssh/do_key
```

---

## Common Server IP Examples

Remember to replace the documentation example IP `203.0.113.50` with your actual server IP:

- **AWS EC2**: `54.123.45.67` or `ec2-54-123-45-67.compute-1.amazonaws.com`
- **Google Cloud**: `35.123.45.67`
- **Azure**: `20.123.45.67` or `myvm.region.cloudapp.azure.com`
- **DigitalOcean**: `164.123.45.67`
- **Vultr**: `149.123.45.67`
- **Linode**: `172.123.45.67`
- **Hetzner**: `116.123.45.67`

Your cloud provider dashboard will show the actual IP address assigned to your server instance.

---

This completes the comprehensive deployment guide. Choose the method that best fits your experience level and requirements!