# Fennel Validator Security Best Practices

Running a validator comes with security responsibilities. This guide covers essential security practices to protect your validator and the network.

## 🔑 Key Management

### Validator Keys

**Critical Security Rules:**
- ✅ **Generate keys locally** - Never share your seed phrase
- ✅ **Backup seed phrases securely** - Store offline in multiple locations
- ✅ **Use unique keys per network** - Don't reuse staging keys on mainnet
- ❌ **Never share keys** - Keys should never leave your control

```bash
# Keys are generated during setup
./setup-validator.sh

# Backup your seed phrase immediately when shown
# Store it in multiple secure locations (safe, password manager, etc.)
```

### Key Storage

**Best Practices:**
```bash
# Secure the keystore directory
chmod 700 data/chains/*/keystore
chown -R $USER:$USER data/chains/*/keystore

# Consider encrypted storage for production
# Use LUKS, eCryptfs, or similar for the data directory
```

## 🔒 Network Security

### Firewall Configuration

**Essential firewall rules:**
```bash
# Ubuntu/Debian with ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (change port if using non-standard)
sudo ufw allow 22/tcp

# Allow validator P2P port
sudo ufw allow 30333/tcp

# Optionally allow RPC (local only recommended)
# sudo ufw allow from 127.0.0.1 to any port 9944

# Optionally allow Prometheus (monitoring only)
# sudo ufw allow from YOUR_MONITORING_IP to any port 9615

# Enable firewall
sudo ufw enable
```

**CentOS/RHEL with firewalld:**
```bash
# Basic setup
sudo firewall-cmd --set-default-zone=drop
sudo firewall-cmd --zone=drop --add-service=ssh --permanent

# Allow P2P port
sudo firewall-cmd --zone=drop --add-port=30333/tcp --permanent

# Apply changes
sudo firewall-cmd --reload
```

### RPC Security

**Default Configuration (Recommended):**
- RPC bound to localhost only (`127.0.0.1:9944`)
- Safe RPC methods only
- No external access

**If External RPC is Required:**
```bash
# Use reverse proxy with authentication
# Example nginx config:
server {
    listen 443 ssl;
    server_name your-validator.example.com;
    
    # SSL configuration
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # Basic auth
    auth_basic "Validator RPC";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    location / {
        proxy_pass http://127.0.0.1:9944;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 🖥️ System Security

### Operating System

**Security Updates:**
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# CentOS/RHEL
sudo yum update -y
# or on newer versions:
sudo dnf update -y
```

**Disable Unnecessary Services:**
```bash
# Check running services
systemctl list-unit-files --state=enabled

# Disable unnecessary services (examples)
sudo systemctl disable cups
sudo systemctl disable bluetooth
sudo systemctl disable avahi-daemon
```

### User Security

**Create Dedicated User:**
```bash
# Create validator user (recommended for production)
sudo useradd -m -s /bin/bash validator
sudo usermod -aG sudo validator  # Only if sudo access needed

# Run validator as dedicated user
sudo -u validator ./validate.sh start
```

**SSH Security:**
```bash
# Edit /etc/ssh/sshd_config
sudo nano /etc/ssh/sshd_config

# Recommended settings:
# Port 2222  # Change default port
# PermitRootLogin no
# PasswordAuthentication no  # Use key-based auth only
# PubkeyAuthentication yes
# MaxAuthTries 3
# ClientAliveInterval 300
# ClientAliveCountMax 2

# Restart SSH
sudo systemctl restart sshd
```

## 🔐 Access Control

### File Permissions

**Secure Configuration Files:**
```bash
# Validator configuration
chmod 600 config/validator.conf
chown $USER:$USER config/validator.conf

# Binary files
chmod 755 bin/fennel-node*
chown $USER:$USER bin/fennel-node*

# Data directory
chmod 700 data/
chown -R $USER:$USER data/

# Scripts
chmod 755 *.sh scripts/*.sh
```

### Process Security

**Run with Minimal Privileges:**
```bash
# Create systemd service for production
sudo tee /etc/systemd/system/fennel-validator.service << EOF
[Unit]
Description=Fennel Validator
After=network.target

[Service]
Type=simple
User=validator
Group=validator
WorkingDirectory=/home/validator/FennelValidator
ExecStart=/home/validator/FennelValidator/validate.sh start
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/home/validator/FennelValidator/data

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable fennel-validator
sudo systemctl start fennel-validator
```

## 📊 Monitoring & Alerting

### Health Monitoring

**Automated Health Checks:**
```bash
# Create monitoring cron job
crontab -e

# Add health check every 5 minutes
*/5 * * * * /home/validator/FennelValidator/scripts/health-check.sh > /dev/null 2>&1 || echo "Validator health check failed" | mail -s "Validator Alert" admin@example.com
```

**Log Monitoring:**
```bash
# Monitor for critical errors
grep -i "panic\|fatal\|error" data/chains/*/network/*.log | tail -10

# Set up log rotation
sudo tee /etc/logrotate.d/fennel-validator << EOF
/home/validator/FennelValidator/data/chains/*/network/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 validator validator
}
EOF
```

### Security Monitoring

**Intrusion Detection:**
```bash
# Install fail2ban
sudo apt install fail2ban

# Configure for SSH
sudo tee /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh,2222  # Include your custom SSH port
EOF

sudo systemctl restart fail2ban
```

## 🛡️ Backup & Recovery

### Configuration Backup

**Automated Backups:**
```bash
# Create backup script
cat > backup-config.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/secure/backups/fennel-validator"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup configuration
cp config/validator.conf "$BACKUP_DIR/validator.conf.$DATE"

# Backup keystore (encrypted)
tar -czf "$BACKUP_DIR/keystore.$DATE.tar.gz" data/chains/*/keystore/

echo "Backup completed: $DATE"
EOF

chmod +x backup-config.sh

# Schedule daily backups
crontab -e
# Add: 0 2 * * * /home/validator/FennelValidator/backup-config.sh
```

### Disaster Recovery

**Recovery Plan:**
1. **Stop validator immediately** if compromised
2. **Secure seed phrases** from offline storage
3. **Rebuild on clean system**
4. **Restore configuration** from secure backup
5. **Re-import keys** using seed phrases
6. **Verify security** before restarting

## 🚨 Incident Response

### If Validator is Compromised

**Immediate Actions:**
```bash
# 1. Stop validator
./validate.sh stop
pkill -f fennel-node

# 2. Disconnect from network
sudo iptables -A INPUT -j DROP
sudo iptables -A OUTPUT -j DROP

# 3. Preserve evidence
cp -r data/ /secure/incident-$(date +%Y%m%d)/
cp config/ /secure/incident-$(date +%Y%m%d)/

# 4. Check for unauthorized changes
find . -mtime -1 -type f  # Files modified in last 24h
```

**Investigation:**
```bash
# Check system logs
sudo journalctl -u fennel-validator --since "24 hours ago"

# Check login history
last
sudo journalctl -u ssh --since "24 hours ago"

# Check network connections
netstat -tulpn
ss -tulpn
```

## 🔒 Production Hardening

### Additional Security Measures

**For High-Value Validators:**

1. **Hardware Security Modules (HSM)** for key storage
2. **Air-gapped key generation** environment
3. **Multi-signature** governance keys where applicable
4. **Professional security audit** of setup
5. **Dedicated hardware** (no shared hosting)
6. **Geographic distribution** of backup locations

**Network Isolation:**
```bash
# Consider running in isolated network segment
# Use VPN for management access
# Implement network monitoring (ntopng, etc.)
```

## 📋 Security Checklist

### Initial Setup
- [ ] Generated keys on secure, offline system
- [ ] Backed up seed phrases in multiple secure locations
- [ ] Configured firewall with minimal required ports
- [ ] Disabled unnecessary system services
- [ ] Created dedicated user account
- [ ] Secured file permissions
- [ ] Configured SSH with key-based authentication

### Ongoing Security
- [ ] Regular system updates applied
- [ ] Health monitoring configured
- [ ] Log monitoring and rotation setup
- [ ] Regular configuration backups
- [ ] Intrusion detection system active
- [ ] Security patches applied promptly
- [ ] Access logs reviewed regularly

### Emergency Preparedness
- [ ] Incident response plan documented
- [ ] Recovery procedures tested
- [ ] Emergency contacts defined
- [ ] Backup restoration verified
- [ ] Alternative infrastructure identified

## 🆘 Emergency Contacts

**If Security Incident Detected:**
1. **Immediate**: Stop validator and isolate system
2. **Report**: Create issue in [fennel-solonet repository](https://github.com/CorruptedAesthetic/fennel-solonet/issues)
3. **Document**: Preserve evidence and logs
4. **Rebuild**: Clean installation on secure system

Remember: **Security is an ongoing process, not a one-time setup**. Stay vigilant and keep your validator secure! 