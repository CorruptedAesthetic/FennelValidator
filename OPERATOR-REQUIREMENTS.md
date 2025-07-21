# 📋 Operator Information Requirements

This document outlines what information operators need to provide about their cloud/VM environment for Fennel Validator deployment.

## Server Requirements

### Minimum Hardware Specifications

| Resource | Minimum | Recommended | Production |
|----------|---------|-------------|------------|
| **CPU** | 2 vCPUs | 4 vCPUs | 8+ vCPUs |
| **RAM** | 4 GB | 8 GB | 16+ GB |
| **Storage** | 100 GB SSD | 200 GB SSD | 500+ GB SSD |
| **Network** | 100 Mbps | 1 Gbps | 1+ Gbps |

### Cloud Provider VM Recommendations

#### Amazon Web Services (AWS)
- **Minimum**: `t3.medium` (2 vCPU, 4 GB RAM)
- **Recommended**: `t3.large` (2 vCPU, 8 GB RAM) or `c5.large` (2 vCPU, 4 GB RAM)
- **Production**: `c5.xlarge` (4 vCPU, 8 GB RAM) or `c5.2xlarge` (8 vCPU, 16 GB RAM)
- **Storage**: EBS gp3 (100+ GB)

#### Google Cloud Platform (GCP)
- **Minimum**: `e2-medium` (2 vCPU, 4 GB RAM)
- **Recommended**: `e2-standard-2` (2 vCPU, 8 GB RAM) or `n2-standard-2` (2 vCPU, 8 GB RAM)
- **Production**: `n2-standard-4` (4 vCPU, 16 GB RAM) or `n2-standard-8` (8 vCPU, 32 GB RAM)
- **Storage**: Standard Persistent Disk (100+ GB)

#### Microsoft Azure
- **Minimum**: `Standard_B2s` (2 vCPU, 4 GB RAM)
- **Recommended**: `Standard_D2s_v3` (2 vCPU, 8 GB RAM) or `Standard_D4s_v3` (4 vCPU, 16 GB RAM)
- **Production**: `Standard_D8s_v3` (8 vCPU, 32 GB RAM) or `Standard_E4s_v3` (4 vCPU, 32 GB RAM)
- **Storage**: Premium SSD (100+ GB)

#### DigitalOcean
- **Minimum**: Basic Droplet ($12/month - 2 vCPU, 2 GB RAM)
- **Recommended**: Regular Droplet ($24/month - 2 vCPU, 4 GB RAM) or ($48/month - 4 vCPU, 8 GB RAM)
- **Production**: Regular Droplet ($96/month - 8 vCPU, 16 GB RAM)
- **Storage**: SSD Block Storage (100+ GB)

#### Oracle Cloud Infrastructure (OCI)
- **Minimum**: VM.Standard.E3.Flex (2 OCPU, 8 GB RAM)
- **Recommended**: VM.Standard.E4.Flex (2 OCPU, 16 GB RAM) or (4 OCPU, 32 GB RAM)
- **Production**: VM.Standard.E4.Flex (8 OCPU, 64 GB RAM) or BM.Standard.E4.128 (128 GB RAM)
- **Storage**: Block Volume (100+ GB)

#### Vultr
- **Minimum**: Cloud Compute ($12/month - 2 vCPU, 4 GB RAM)
- **Recommended**: Cloud Compute ($24/month - 2 vCPU, 8 GB RAM) or ($48/month - 4 vCPU, 16 GB RAM)
- **Production**: Cloud Compute ($96/month - 8 vCPU, 32 GB RAM)
- **Storage**: Block Storage (100+ GB)

#### Linode
- **Minimum**: Shared CPU ($12/month - 2 vCPU, 4 GB RAM)
- **Recommended**: Shared CPU ($24/month - 2 vCPU, 8 GB RAM) or ($48/month - 4 vCPU, 16 GB RAM)
- **Production**: Dedicated CPU ($96/month - 4 vCPU, 16 GB RAM)
- **Storage**: Block Storage (100+ GB)

#### Hetzner Cloud
- **Minimum**: CX21 (2 vCPU, 4 GB RAM, €5.83/month)
- **Recommended**: CX31 (2 vCPU, 8 GB RAM, €8.70/month) or CX41 (4 vCPU, 16 GB RAM, €13.92/month)
- **Production**: CX51 (8 vCPU, 32 GB RAM, €27.84/month)
- **Storage**: Block Storage (100+ GB)

### Operating System Requirements

- **Recommended**: Ubuntu 22.04 LTS or Ubuntu 20.04 LTS
- **Alternative**: Debian 11+, CentOS 8+, RHEL 8+
- **Architecture**: x86_64 (AMD64)
- **Kernel**: Linux 5.4+ (for Ubuntu 20.04+)

### Storage Considerations

- **Type**: SSD storage (NVMe preferred for production)
- **Performance**: Minimum 3000 IOPS for production workloads
- **Growth**: Plan for 2-3x storage growth over time
- **Backup**: Consider automated backups for production validators

### Cost Considerations

| Tier | Monthly Cost Range | Use Case |
|------|-------------------|----------|
| **Budget** | $12-24/month | Testing, development, small validators |
| **Standard** | $24-96/month | Most production validators |
| **Performance** | $96-300+/month | High-performance, enterprise validators |

### Performance Expectations

- **Block Production**: 99%+ uptime for production validators
- **Network Sync**: Should sync within 24-48 hours from genesis
- **Memory Usage**: 2-4 GB RAM under normal load, 6-8 GB during sync
- **CPU Usage**: 10-30% average, spikes during block production
- **Disk I/O**: Moderate during sync, low during normal operation

### Scaling Considerations

- **Start Small**: Begin with minimum specs and scale up as needed
- **Monitor Resources**: Use cloud provider monitoring tools
- **Auto-scaling**: Consider for production environments with variable load
- **Geographic Distribution**: Multiple validators across regions for redundancy

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


