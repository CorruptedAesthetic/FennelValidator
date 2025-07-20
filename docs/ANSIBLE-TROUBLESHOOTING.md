# Ansible Deployment Troubleshooting

## Common Issues and Solutions

### 1. Ansible Not Installed
**Problem:** `ansible-playbook: command not found`

**Solution:**
```bash
# Install Ansible on Ubuntu/Debian
sudo apt update && sudo apt install -y ansible

# Install Ansible on CentOS/RHEL
sudo yum install -y ansible

# Install Ansible on macOS
brew install ansible

# Verify installation
ansible --version
```

### 2. Missing Parity Collection
**Problem:** `couldn't resolve module/action 'paritytech.chain.node'`

**Solution:**
```bash
# Install the required collection
ansible-galaxy collection install paritytech.chain

# Verify installation
ansible-galaxy collection list paritytech.chain
```

### 3. SSH Connection Issues
**Problem:** Cannot connect to target server

**Check SSH connectivity:**
```bash
# Test SSH connection manually
ssh ubuntu@YOUR_SERVER_IP

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 700 ~/.ssh/
```

**Solution:**
```bash
# Verify inventory file has correct IP and user
cat ansible/inventory

# Test Ansible connectivity
ansible -i ansible/inventory fennel_validators -m ping

# If using password authentication
ansible -i ansible/inventory fennel_validators -m ping --ask-pass
```

### 4. Systemd Service Issues
**Problem:** Fennel service won't start or keeps failing

**Check service status:**
```bash
# Check service status
sudo systemctl status fennel-node

# View recent logs
sudo journalctl -u fennel-node -f

# Check if service file exists
ls -la /etc/systemd/system/fennel-node.service
```

**Solution:**
```bash
# Restart the service
sudo systemctl restart fennel-node

# If service file is corrupted, re-run Ansible
ansible-playbook -i ansible/inventory ansible/validator.yml

# Check for configuration errors
sudo systemctl daemon-reload
sudo systemctl enable fennel-node
```

### 5. Binary Download Issues
**Problem:** Cannot download fennel-node binary

**Check download:**
```bash
# Test manual download
curl -L -o fennel-node \
  https://github.com/CorruptedAesthetic/fennel-solonet/releases/download/fennel-node-0.5.9/fennel-node-linux-x86_64

# Check GitHub API rate limits
curl -s https://api.github.com/rate_limit
```

**Solution:**
```bash
# Verify checksum if downloaded manually
sha256sum fennel-node
# Compare with expected: 93c2651c55a5fdaa4ee6d5399b0e961a159235fde4f4fa75b384a0c1b13f03b5

# Re-run with verbose output
ansible-playbook -i ansible/inventory ansible/validator.yml -vvv
```

### 6. Chainspec Download Issues
**Problem:** Cannot download production chainspec

**Check chainspec:**
```bash
# Test manual download
curl -L -o production-raw.json \
  https://github.com/CorruptedAesthetic/fennel-solonet/releases/latest/download/production-raw.json

# Verify it's valid JSON
jq . production-raw.json
```

**Solution:**
```bash
# Check if file exists on server
ssh ubuntu@YOUR_SERVER_IP "ls -la /home/fennel/chainspecs/"

# Manually place chainspec if needed
scp production-raw.json ubuntu@YOUR_SERVER_IP:/home/fennel/chainspecs/
```

### 7. RPC Connection Issues
**Problem:** Cannot connect to validator RPC

**Check RPC status:**
```bash
# Test local connection from validator server
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' \
  http://localhost:9944

# Check if service is listening
sudo netstat -tulpn | grep :9944
```

**Solution:**
```bash
# Check firewall settings
sudo ufw status
sudo ufw allow 9944

# Verify service configuration
sudo journalctl -u fennel-node | grep -i rpc

# Check if RPC is enabled in startup command
sudo systemctl cat fennel-node
```

### 8. Peer Connection Problems
**Problem:** Validator shows 0 peers

**Check network connectivity:**
```bash
# Test P2P port
telnet localhost 30333

# Check peer count
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' \
  http://localhost:9944 | jq '.result.peers'
```

**Solution:**
```bash
# Verify P2P ports are open
sudo ufw allow 30333

# Check bootnode connectivity from chainspec
jq '.bootNodes' /home/fennel/chainspecs/production-raw.json

# Test bootnode reachability
nslookup bootnode1.fennel.network
```

### 9. Key Generation Issues
**Problem:** Session keys not generated or registration fails

**Check key status:**
```bash
# Verify keys were generated
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "author_hasSessionKeys", "params":["0x...your_session_keys..."]}' \
  http://localhost:9944
```

**Solution:**
```bash
# Manually generate new session keys
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"author_rotateKeys","params":[],"id":1}' \
  http://localhost:9944

# Save the returned keys for validator registration
# Keys format: 0x[64-char-hex-string]
```

## Cloud Provider Specific Issues

### 1. Port Access
**Problem:** Cannot access RPC from outside

**Solution:**
```bash
# Check cloud provider firewall/security group settings
# Add ingress rules for:
# - 30333/tcp (P2P)
# - 9944/tcp (RPC)
# - 9615/tcp (Prometheus metrics)

# Also check local firewall
sudo ufw allow 30333
sudo ufw allow 9944
sudo ufw allow 9615
```

### 2. Instance Resources
**Problem:** Poor performance or service crashes

**Solution:**
```bash
# Check current resources
nproc           # CPU cores
free -h         # Memory usage
df -h           # Disk space

# Recommended minimum:
# - 2+ CPU cores
# - 4+ GB RAM  
# - 200+ GB storage

# Monitor validator resource usage
top -p $(pgrep fennel-node)
```

### 3. Storage Issues
**Problem:** Running out of disk space

**Check storage:**
```bash
# Check validator data size
sudo du -sh /var/lib/fennel/

# Check available space
df -h /var/lib/fennel/
```

**Solution:**
```bash
# Expand storage volume in your cloud provider console
# Then resize filesystem:
sudo growpart /dev/sda 1
sudo resize2fs /dev/sda1

# Or clean old chain data (CAUTION: Will re-sync)
sudo systemctl stop fennel-node
sudo rm -rf /var/lib/fennel/chains/*/db/
sudo systemctl start fennel-node
```

## Health Check Script

Save this as `ansible-health-check.sh`:

```bash
#!/bin/bash
# Ansible Validator Health Check

echo "=== Ansible Validator Health Check ==="
echo

# Check if systemd service is running
if systemctl is-active --quiet fennel-node; then
    echo "✅ Systemd service is running"
    
    # Get service status
    STATUS=$(systemctl show fennel-node --property=ActiveState --value)
    UPTIME=$(systemctl show fennel-node --property=ActiveEnterTimestamp --value)
    echo "   Status: $STATUS"
    echo "   Started: $UPTIME"
else
    echo "❌ Systemd service is not running"
    echo "Service status:"
    systemctl status fennel-node --no-pager -l
    exit 1
fi

# Check if binary exists and is executable
if [ -x "/usr/local/bin/fennel-node" ]; then
    echo "✅ Binary is installed and executable"
    VERSION=$(/usr/local/bin/fennel-node --version 2>/dev/null | head -1)
    echo "   Version: $VERSION"
else
    echo "❌ Binary not found or not executable"
fi

# Check if chainspec exists
if [ -f "/home/fennel/chainspecs/production-raw.json" ]; then
    echo "✅ Chainspec file exists"
    SIZE=$(stat -f%z "/home/fennel/chainspecs/production-raw.json" 2>/dev/null || stat -c%s "/home/fennel/chainspecs/production-raw.json")
    echo "   Size: ${SIZE} bytes"
else
    echo "❌ Chainspec file not found"
fi

# Check RPC connectivity
if curl -s -m 5 -H "Content-Type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' \
    http://localhost:9944 > /dev/null; then
    echo "✅ RPC is accessible"
else
    echo "❌ RPC is not accessible"
fi

# Check peer count
PEERS=$(curl -s -m 5 -H "Content-Type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' \
    http://localhost:9944 | jq '.result.peers // 0' 2>/dev/null)

if [ "$PEERS" -gt 0 ] 2>/dev/null; then
    echo "✅ Connected to $PEERS peers"
else
    echo "❌ No peers connected (or RPC error)"
fi

# Check sync status
SYNC_INFO=$(curl -s -m 5 -H "Content-Type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "system_syncState", "params":[]}' \
    http://localhost:9944 2>/dev/null)

if echo "$SYNC_INFO" | jq -e '.result.currentBlock' > /dev/null 2>&1; then
    CURRENT=$(echo "$SYNC_INFO" | jq '.result.currentBlock' 2>/dev/null)
    HIGHEST=$(echo "$SYNC_INFO" | jq '.result.highestBlock' 2>/dev/null)
    echo "✅ Sync status: $CURRENT / $HIGHEST"
else
    echo "❌ Cannot get sync status"
fi

# Check disk usage for validator data
if [ -d "/var/lib/fennel" ]; then
    DISK_USAGE=$(df -h /var/lib/fennel | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -lt 80 ] 2>/dev/null; then
        echo "✅ Disk usage: ${DISK_USAGE}%"
    else
        echo "⚠️  Disk usage high: ${DISK_USAGE}%"
    fi
else
    echo "❌ Validator data directory not found"
fi

# Check memory usage
if command -v pgrep >/dev/null && pgrep fennel-node >/dev/null; then
    PID=$(pgrep fennel-node)
    if [ -f "/proc/$PID/status" ]; then
        MEMORY_KB=$(grep VmRSS /proc/$PID/status | awk '{print $2}')
        MEMORY_MB=$((MEMORY_KB / 1024))
        echo "✅ Memory usage: ${MEMORY_MB} MB"
        
        if [ "$MEMORY_MB" -gt 2048 ]; then
            echo "⚠️  High memory usage detected"
        fi
    fi
else
    echo "❌ Cannot find fennel-node process"
fi

# Check ports are listening
if netstat -tuln 2>/dev/null | grep -q ":30333 "; then
    echo "✅ P2P port (30333) is listening"
else
    echo "❌ P2P port (30333) not listening"
fi

if netstat -tuln 2>/dev/null | grep -q ":9944 "; then
    echo "✅ RPC port (9944) is listening"
else
    echo "❌ RPC port (9944) not listening"
fi

echo
echo "=== Health Check Complete ==="
```

Make it executable:
```bash
chmod +x ansible-health-check.sh
./ansible-health-check.sh
```

## Quick Recovery Commands

### Restart Validator Service
```bash
sudo systemctl restart fennel-node
```

### Check Service Logs
```bash
# View recent logs
sudo journalctl -u fennel-node -n 50

# Follow logs in real-time
sudo journalctl -u fennel-node -f

# Save logs to file
sudo journalctl -u fennel-node --since "1 hour ago" > validator-logs-$(date +%Y%m%d).txt
```

### Re-run Ansible Deployment
```bash
# Re-deploy with same configuration
ansible-playbook -i ansible/inventory ansible/validator.yml

# Re-deploy with verbose output for debugging
ansible-playbook -i ansible/inventory ansible/validator.yml -vvv

# Re-deploy and force handlers to run
ansible-playbook -i ansible/inventory ansible/validator.yml --force-handlers
```

### Reset Chain Data (Full Re-sync)
```bash
# Stop service
sudo systemctl stop fennel-node

# Remove chain database (keeps keys)
sudo rm -rf /var/lib/fennel/chains/*/db/

# Start service (will re-sync from genesis)
sudo systemctl start fennel-node

# Monitor sync progress
sudo journalctl -u fennel-node -f
```

### Generate New Session Keys
```bash
# Generate new keys via RPC
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"author_rotateKeys","params":[],"id":1}' \
  http://localhost:9944

# The response contains your new session keys for validator registration
```

### Emergency Diagnostics
```bash
# Check Ansible inventory
cat ansible/inventory

# Test Ansible connectivity
ansible -i ansible/inventory fennel_validators -m ping

# Check binary version
/usr/local/bin/fennel-node --version

# Check chainspec validity
jq . /home/fennel/chainspecs/production-raw.json | head

# Check system resources
free -h && df -h && nproc

# Check network connectivity to bootnodes
nslookup bootnode1.fennel.network
telnet bootnode1.fennel.network 30333
```

## Getting Help

If you're still having issues:

1. **Run the health check script** above: `./ansible-health-check.sh`
2. **Save the output** from the health check
3. **Collect logs**: `sudo journalctl -u fennel-node --since "1 hour ago" > logs.txt`
4. **Check [FAQ.md](FAQ.md)** for common solutions
5. **Review [PRODUCTION-DEPLOYMENT.md](../PRODUCTION-DEPLOYMENT.md)** for deployment guide
6. **Contact support** with the health check output and logs

Remember: Most issues are solved by restarting the systemd service or re-running the Ansible playbook!
