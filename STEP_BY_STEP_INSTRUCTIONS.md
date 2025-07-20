# 🚀 Step-by-Step Fennel Validator Deployment with Ansible

Here's a complete guide to deploy a Fennel validator using Ansible from this repository.

## Prerequisites

Before starting, ensure you have:
- ✅ A Linux server (Ubuntu 20.04+ recommended) with SSH access
- ✅ Server IP address and SSH credentials  
- ✅ Ansible installed on your local machine
- ✅ `jq` and `subkey` tools available

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