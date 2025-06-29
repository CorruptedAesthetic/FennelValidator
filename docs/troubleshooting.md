# Fennel Validator Troubleshooting Guide

This guide helps resolve common issues when running a Fennel validator.

## Quick Diagnostic Commands

```bash
# Check validator status
./validate.sh status

# Run comprehensive health check
./scripts/health-check.sh

# View recent logs
./validate.sh logs

# Show the exact command being used
./validate.sh command
```

## Common Issues

### 1. Validator Won't Start

**Symptoms:**
- `./validate.sh start` fails immediately
- "Configuration not found" error

**Solutions:**
```bash
# Make sure setup was completed
ls config/validator.conf

# If missing, run setup again
./setup-validator.sh

# Check if binary exists
ls bin/fennel-node*

# If missing, reinstall
./install.sh
```

### 2. No Network Peers

**Symptoms:**
- Health check shows "0 peers connected"
- Node appears isolated

**Solutions:**
```bash
# Check network connectivity
ping google.com

# Verify firewall allows P2P port (default 30333)
sudo ufw status
sudo ufw allow 30333

# For staging network, verify bootnode connection
./scripts/get-connection-info.sh

# Restart with fresh network discovery
./validate.sh stop
rm -rf data/chains/*/network
./validate.sh start
```

### 3. Node Not Syncing

**Symptoms:**
- Health check shows "Node is still syncing" for extended period
- Block height not increasing

**Solutions:**
```bash
# Check if connected to network
./scripts/health-check.sh

  # Update to latest chainspec from fennel-solonet
  ./validate.sh update-chainspec
  
  # Verify correct chainspec
  jq '.name' config/staging-chainspec.json
  
  # For staging, should show: "Custom"

# Restart validator
./validate.sh restart
```

### 4. RPC Connection Refused

**Symptoms:**
- Health check fails with "RPC endpoint not responding"
- `curl` commands to localhost:9944 fail

**Solutions:**
```bash
# Check if validator is actually running
ps aux | grep fennel-node

# Verify RPC port configuration
grep RPC_PORT config/validator.conf

# Check port availability
netstat -tulpn | grep :9944

# If port conflict, reconfigure
./setup-validator.sh  # Choose different RPC port
```

### 5. Out of Disk Space

**Symptoms:**
- "No space left on device" error
- Health check shows high disk usage

**Solutions:**
```bash
# Check disk usage
df -h

# Clean up old logs (if safe to do)
find data/ -name "*.log" -mtime +7 -delete

# Clean up old backups
ls bin/fennel-node.backup.*
rm bin/fennel-node.backup.* # (keep most recent one)

# Move data directory to larger disk
./validate.sh stop
mv data /path/to/larger/disk/
# Edit config/validator.conf to update DATA_DIR
./validate.sh start
```

### 6. Permission Denied Errors

**Symptoms:**
- "Permission denied" when starting
- Cannot write to data directory

**Solutions:**
```bash
# Check file permissions
ls -la bin/fennel-node*
ls -la data/

# Fix binary permissions
chmod +x bin/fennel-node*

# Fix data directory permissions
chmod -R 755 data/
chown -R $USER:$USER data/

# If running as different user
sudo chown -R validator:validator data/
```

### 7. Port Already in Use

**Symptoms:**
- "Address already in use" error
- Cannot bind to port

**Solutions:**
```bash
# Find what's using the port
sudo lsof -i :30333  # P2P port
sudo lsof -i :9944   # RPC port
sudo lsof -i :9615   # Prometheus port

# Kill conflicting process if safe
sudo kill <PID>

# Or reconfigure ports
./setup-validator.sh  # Choose different ports
```

### 8. Key Generation Issues

**Symptoms:**
- Setup fails during key generation
- "Invalid seed phrase" error

**Solutions:**
```bash
# Test binary works
bin/fennel-node* --version

# Generate keys manually
bin/fennel-node* key generate --scheme sr25519

# If binary is corrupted, reinstall
rm bin/fennel-node*
./install.sh
```

## Network-Specific Issues

### Staging Network

```bash
# Get current staging network info
./scripts/get-connection-info.sh

# Update to latest chainspec from fennel-solonet repository
./validate.sh update-chainspec

# Verify chainspec name
jq '.name' config/staging-chainspec.json
# Should be: "Custom"

# Note: Chainspecs are automatically updated each time you start the validator
# This ensures you always have the latest network configuration
```

## Performance Issues

### High CPU Usage

```bash
# Check resource usage
top -p $(pgrep fennel-node)

# Reduce parallel runtime instances
# Edit config/validator.conf and reduce performance settings
# Then restart: ./validate.sh restart
```

### High Memory Usage

```bash
# Check memory usage
free -h
ps aux | grep fennel-node | awk '{print $6}'

# Reduce cache sizes in validator.conf:
# - db_cache (default: 1024)
# - state_cache_size (default: 67108864)
# - runtime_cache_size (default: 2)
```

## Data Recovery

### Corrupt Database

```bash
# Stop validator
./validate.sh stop

# Backup current data (optional)
cp -r data data.backup.$(date +%Y%m%d)

# Remove database (will resync from network)
rm -rf data/chains/*/db

# Restart (will resync)
./validate.sh start
```

### Lost Configuration

```bash
# Restore from backup if available
ls config/validator.conf.backup*

# Or reconfigure
./setup-validator.sh
```

## Logging and Monitoring

### Enable Debug Logging

```bash
# Edit config/validator.conf
# Change: LOG_LEVEL="info"
# To: LOG_LEVEL="debug"

# Restart validator
./validate.sh restart

# View detailed logs
./validate.sh logs
```

### Monitor Performance

```bash
# Check Prometheus metrics
curl http://localhost:9615/metrics | grep substrate_block_height
curl http://localhost:9615/metrics | grep substrate_network_peers

# Monitor system resources
htop
iotop  # If available
```

## Getting Help

### Information to Provide

When asking for help, please provide:

```bash
# System information
uname -a
cat /etc/os-release

# Validator configuration
cat config/validator.conf

# Health check output
./scripts/health-check.sh

# Recent logs (last 50 lines)
./validate.sh logs | tail -50

# Network connectivity
./scripts/get-connection-info.sh
```

### Where to Get Help

- **GitHub Issues**: [fennel-solonet repository](https://github.com/CorruptedAesthetic/fennel-solonet/issues)
- **Configuration Issues**: Re-run `./setup-validator.sh`
- **Network Issues**: Check the staging network status first

### Emergency Recovery

If validator is completely broken:

```bash
# Stop everything
./validate.sh stop
pkill -f fennel-node

# Backup important data
cp -r data data.emergency.backup
cp config/validator.conf config/validator.conf.backup

# Clean install
rm -rf bin/* config/*.json
./install.sh
./setup-validator.sh

# Restore data if needed
# (Only if you're sure it's not corrupted)
```

## Prevention

### Regular Maintenance

```bash
# Weekly health checks
./scripts/health-check.sh

# Monthly updates
./scripts/update-validator.sh

# Monitor disk space
df -h data/

# Backup configuration
cp config/validator.conf config/validator.conf.backup.$(date +%Y%m%d)
```

### Monitoring Setup

Consider setting up monitoring:
- Prometheus metrics collection
- Disk space alerts
- Process monitoring (systemd, supervisor, etc.)
- Log rotation

This keeps your validator running smoothly and helps catch issues early. 