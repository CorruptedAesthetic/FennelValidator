# Docker Deployment Troubleshooting

## Common Issues and Solutions

### 1. Docker Permission Denied
**Problem:** `docker: permission denied while trying to connect to the Docker daemon socket`

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, then test
docker run hello-world
```

### 2. Container Won't Start
**Problem:** Container exits immediately or fails to start

**Check logs:**
```bash
docker logs fennel-validator
```

**Common causes:**
- Invalid chainspec path
- Missing volumes
- Port conflicts
- Insufficient resources

**Solution:**
```bash
# Verify chainspec exists
ls -la config/fennel-staging.raw.json

# Check port usage
netstat -tuln | grep -E ':(30333|30334|9933|9944) '

# Ensure directories exist
mkdir -p validator-data config
```

### 3. RPC Connection Issues
**Problem:** Cannot connect to validator RPC

**Check RPC status:**
```bash
# Test local connection
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' \
  http://localhost:9933
```

**Solution:**
```bash
# Verify RPC ports are exposed
docker port fennel-validator

# Check firewall
sudo ufw status
sudo ufw allow 9933
sudo ufw allow 9944
```

### 4. Peer Connection Problems
**Problem:** Validator shows 0 peers

**Check network:**
```bash
# Test P2P port
telnet localhost 30333

# Check container networking
docker exec fennel-validator netstat -tuln
```

**Solution:**
```bash
# Verify P2P ports are open
sudo ufw allow 30333
sudo ufw allow 30334

# Check bootnode connectivity
curl -s https://raw.githubusercontent.com/CorruptedAesthetic/fennel-solonet/main/chainspecs/staging/staging-raw.json | jq '.bootNodes'
```

### 5. Sync Issues
**Problem:** Validator not syncing with network

**Check sync status:**
```bash
# Check sync progress
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_syncState", "params":[]}' \
  http://localhost:9933
```

**Solution:**
```bash
# Restart with fresh sync
docker stop fennel-validator
docker rm fennel-validator
rm -rf validator-data/chains/
# Re-run docker run command
```

### 6. Storage Issues
**Problem:** Disk space or permission errors

**Check storage:**
```bash
# Check disk usage
df -h
du -sh validator-data/

# Check permissions
ls -la validator-data/
```

**Solution:**
```bash
# Fix permissions
sudo chown -R $USER:$USER validator-data/
chmod -R 755 validator-data/

# Clean old data if needed
docker system prune -a
```

### 7. Memory Issues
**Problem:** Container killed due to OOM

**Check memory usage:**
```bash
# Monitor memory
docker stats fennel-validator

# Check system memory
free -h
```

**Solution:**
```bash
# Increase swap if needed
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Or restart with memory limit
docker run --memory=2g --memory-swap=4g [rest of command]
```

### 8. Image Pull Issues
**Problem:** Cannot pull Docker image

**Solution:**
```bash
# Check Docker Hub connectivity
docker pull hello-world

# Try different image tag
docker pull ghcr.io/corruptedaesthetic/fennel-solonet:main

# Check available tags
curl -s https://api.github.com/repos/CorruptedAesthetic/fennel-solonet/releases/latest | jq '.tag_name'
```

## Oracle Cloud Specific Issues

### 1. Port Access
**Problem:** Cannot access RPC from outside

**Solution:**
```bash
# Check Oracle Cloud Security List
# Add ingress rules for:
# - 30333/tcp (P2P)
# - 30334/tcp (P2P)  
# - 9933/tcp (RPC)
# - 9944/tcp (WebSocket)

# Also check local firewall
sudo ufw allow 9933
sudo ufw allow 9944
```

### 2. Instance Resources
**Problem:** Poor performance or crashes

**Solution:**
```bash
# Upgrade instance shape
# Recommended: VM.Standard.E2.1 (1 OCPU, 8GB RAM)
# Minimum: VM.Standard.E2.1.Micro (1 OCPU, 1GB RAM)

# Check current resources
nproc
free -h
df -h
```

### 3. Boot Volume Size
**Problem:** Running out of disk space

**Solution:**
```bash
# Expand boot volume in Oracle Cloud Console
# Then resize filesystem:
sudo growpart /dev/sda 1
sudo resize2fs /dev/sda1
```

## Health Check Script

Save this as `docker-health-check.sh`:

```bash
#!/bin/bash
# Docker Validator Health Check

echo "=== Docker Validator Health Check ==="
echo

# Check if container is running
if docker ps | grep -q fennel-validator; then
    echo "✅ Container is running"
else
    echo "❌ Container is not running"
    echo "Recent logs:"
    docker logs --tail 20 fennel-validator
    exit 1
fi

# Check RPC connectivity
if curl -s -m 5 -H "Content-Type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' \
    http://localhost:9933 > /dev/null; then
    echo "✅ RPC is accessible"
else
    echo "❌ RPC is not accessible"
fi

# Check peer count
PEERS=$(curl -s -H "Content-Type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' \
    http://localhost:9933 | jq '.result.peers // 0')

if [ "$PEERS" -gt 0 ]; then
    echo "✅ Connected to $PEERS peers"
else
    echo "❌ No peers connected"
fi

# Check sync status
SYNC_INFO=$(curl -s -H "Content-Type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "system_syncState", "params":[]}' \
    http://localhost:9933)

if echo "$SYNC_INFO" | jq -e '.result.currentBlock' > /dev/null; then
    CURRENT=$(echo "$SYNC_INFO" | jq '.result.currentBlock')
    HIGHEST=$(echo "$SYNC_INFO" | jq '.result.highestBlock')
    echo "✅ Sync status: $CURRENT / $HIGHEST"
else
    echo "❌ Cannot get sync status"
fi

# Check disk usage
DISK_USAGE=$(df -h validator-data/ | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    echo "✅ Disk usage: ${DISK_USAGE}%"
else
    echo "⚠️  Disk usage high: ${DISK_USAGE}%"
fi

# Check memory usage
MEMORY_USAGE=$(docker stats --no-stream --format "table {{.MemPerc}}" fennel-validator | tail -1 | sed 's/%//')
if [ "$MEMORY_USAGE" -lt 80 ]; then
    echo "✅ Memory usage: ${MEMORY_USAGE}%"
else
    echo "⚠️  Memory usage high: ${MEMORY_USAGE}%"
fi

echo
echo "=== Health Check Complete ==="
```

Make it executable:
```bash
chmod +x docker-health-check.sh
./docker-health-check.sh
```

## Quick Recovery Commands

### Restart Validator
```bash
docker restart fennel-validator
```

### Full Reset (Keeps Keys)
```bash
docker stop fennel-validator
docker rm fennel-validator
rm -rf validator-data/chains/
# Re-run docker run command
```

### Update to Latest
```bash
docker pull ghcr.io/corruptedaesthetic/fennel-solonet:latest
docker stop fennel-validator
docker rm fennel-validator
# Re-run docker run command
```

### Emergency Logs
```bash
# Last 100 lines
docker logs --tail 100 fennel-validator

# Follow logs in real-time
docker logs -f fennel-validator

# Save logs to file
docker logs fennel-validator > validator-logs-$(date +%Y%m%d).txt
```

## Getting Help

If you're still having issues:

1. **Run the health check script** above
2. **Save the output** from the health check
3. **Collect logs**: `docker logs fennel-validator > logs.txt`
4. **Check [FAQ.md](FAQ.md)** for common solutions
5. **Contact support** with the health check output and logs

Remember: Most issues are solved by restarting the container or checking firewall settings!
