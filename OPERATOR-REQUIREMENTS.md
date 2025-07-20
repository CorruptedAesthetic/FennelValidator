# 📋 Operator Information Requirements

This document outlines what information operators need to provide about their cloud/VM environment for Fennel Validator deployment.

## Required Information

### 1. Server Connection Details

| Field | Description | Examples | Required |
|-------|-------------|----------|----------|
| **Server IP/Hostname** | Your server's address | `203.0.113.50`, `validator.example.com` | ✅ Yes |
| **SSH Username** | User account with sudo privileges | `ubuntu`, `root`, `ec2-user`, `azureuser` | ✅ Yes |
| **SSH Private Key** | Path to SSH private key | `~/.ssh/id_rsa`, `~/.ssh/my-key.pem` | ⚠️ If not using default |

### 2. Network Configuration

| Field | Description | Default | Required |
|-------|-------------|---------|----------|
| **SSH Port** | SSH service port | `22` | ⚠️ If non-standard |
| **P2P Port** | Blockchain network port | `30333` | ⚠️ If custom |
| **Metrics Port** | Monitoring port | `9615` | ⚠️ If custom |

## Where to Provide Information

### Method 1: Configuration Wizard (Recommended)
```bash
./configure-deployment.sh
```
The wizard will interactively prompt for all required information and validate your configuration.

### Method 2: Bootstrap Script (Simple Case)
```bash
./fennel-bootstrap.sh YOUR_SERVER_IP
```
**Assumptions:**
- SSH user is `ubuntu`
- SSH key is `~/.ssh/id_rsa` or available via SSH agent
- Standard ports (22, 30333, 9615)

### Method 3: Custom Inventory File (Advanced)
```bash
# Create custom inventory
cat > custom-inventory << EOF
[fennel_validators]
YOUR_SERVER_IP ansible_user=YOUR_SSH_USER ansible_ssh_private_key_file=~/.ssh/your-key.pem
EOF

# Deploy with custom inventory
cd ansible/
ansible-playbook -i ../custom-inventory validator.yml -e generate_keys=true
```

## Cloud Provider Defaults

### Amazon Web Services (AWS)
- **SSH User**: `ubuntu` (Ubuntu AMI), `ec2-user` (Amazon Linux), `admin` (Debian)
- **SSH Key**: EC2 Key Pair (.pem file)
- **Server IP**: Public IPv4 or public DNS name
- **Example**: `ec2-user@ec2-203-0-113-50.compute-1.amazonaws.com`

### Google Cloud Platform (GCP)
- **SSH User**: Your Google account username
- **SSH Key**: Automatically managed or custom key
- **Server IP**: External IP address
- **Example**: `myusername@203.0.113.50`

### Microsoft Azure
- **SSH User**: `azureuser` (default) or custom username
- **SSH Key**: Azure SSH key or custom key
- **Server IP**: Public IP or FQDN
- **Example**: `azureuser@myvm.westus.cloudapp.azure.com`

### DigitalOcean
- **SSH User**: `root`
- **SSH Key**: DigitalOcean SSH key
- **Server IP**: Droplet IP address
- **Example**: `root@203.0.113.50`

### Oracle Cloud Infrastructure (OCI)
- **SSH User**: `ubuntu` or `opc`
- **SSH Key**: OCI SSH key
- **Server IP**: Public IP address
- **Example**: `ubuntu@203.0.113.50`

### Vultr
- **SSH User**: `root`
- **SSH Key**: Vultr SSH key
- **Server IP**: Instance IP address
- **Example**: `root@203.0.113.50`

### Linode
- **SSH User**: `root`
- **SSH Key**: Linode SSH key
- **Server IP**: Linode IP address
- **Example**: `root@203.0.113.50`

### Hetzner Cloud
- **SSH User**: `root`
- **SSH Key**: Hetzner SSH key
- **Server IP**: Server IP address
- **Example**: `root@203.0.113.50`

## Pre-Deployment Validation

Before running deployment, test your connection:

```bash
# Test SSH access
ssh YOUR_SSH_USER@YOUR_SERVER_IP "echo 'Connection successful'"

# Test sudo access (should not prompt for password)
ssh YOUR_SSH_USER@YOUR_SERVER_IP "sudo echo 'Sudo access confirmed'"

# Test internet connectivity
ssh YOUR_SSH_USER@YOUR_SERVER_IP "curl -s https://github.com >/dev/null && echo 'Internet access confirmed'"
```

## Network Requirements

### Firewall Configuration
Your server must allow these connections:

| Port | Direction | Purpose | Source/Destination |
|------|-----------|---------|-------------------|
| `22` | Inbound | SSH Management | Your IP only |
| `30333` | Inbound/Outbound | Blockchain P2P | `0.0.0.0/0` |
| `9615` | Inbound | Metrics (optional) | Monitoring systems |
| `80/443` | Outbound | Downloads | `0.0.0.0/0` |

### Cloud Provider Firewall Examples

**AWS Security Groups:**
```bash
# Inbound rules
ssh-access: 22/tcp from YOUR_IP/32
p2p-network: 30333/tcp from 0.0.0.0/0
metrics: 9615/tcp from monitoring-subnet

# Outbound rules
all-traffic: all from 0.0.0.0/0
```

**GCP Firewall Rules:**
```bash
gcloud compute firewall-rules create fennel-validator \
  --allow tcp:22,tcp:30333,tcp:9615 \
  --source-ranges YOUR_IP/32,0.0.0.0/0 \
  --target-tags fennel-validator
```

**Azure Network Security Group:**
```bash
# Inbound security rules
Priority 100: SSH (22) from YOUR_IP
Priority 200: P2P (30333) from Internet
Priority 300: Metrics (9615) from VNet
```

## Information NOT Required

The following are automatically handled by the deployment:

- ❌ **Fennel binary download** - Automatically downloaded and verified
- ❌ **Systemd configuration** - Created automatically
- ❌ **User account creation** - Uses existing SSH user
- ❌ **Directory structure** - Created automatically
- ❌ **Validator keys** - Generated securely on the node
- ❌ **Chainspec download** - Fetched automatically
- ❌ **Node configuration** - Applied from template

## Troubleshooting Common Issues

### SSH Key Issues
```bash
# Wrong key permissions
chmod 600 ~/.ssh/your-key.pem

# SSH agent not running
eval $(ssh-agent)
ssh-add ~/.ssh/your-key.pem
```

### Username Issues
```bash
# Check what users exist on the server
ssh root@YOUR_SERVER_IP "cat /etc/passwd | grep -E '/bin/(bash|sh)'"

# Common usernames by distribution
# Ubuntu: ubuntu
# CentOS: centos
# Amazon Linux: ec2-user
# Debian: admin
```

### Network Issues
```bash
# Test port connectivity
telnet YOUR_SERVER_IP 22

# Check firewall status
ssh YOUR_SSH_USER@YOUR_SERVER_IP "sudo ufw status"
ssh YOUR_SSH_USER@YOUR_SERVER_IP "sudo firewall-cmd --list-all"
```

## Security Best Practices

1. **Use SSH keys**, not passwords
2. **Restrict SSH access** to your IP only
3. **Use non-root users** with sudo when possible
4. **Keep SSH keys secure** and backed up
5. **Monitor SSH logs** for unauthorized attempts
6. **Use bastion hosts** for production deployments
7. **Enable 2FA** on cloud provider accounts


