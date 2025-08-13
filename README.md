# 🌿 Fennel Validator Setup Guide

Hello! and welcome! This is a comprehensive guide to deploy a Fennel Validator. It is agnostic to any cloud platform. You can find more specialized instructions in the docker/docs folder for specific cloud providers.

This node is the foundation to sync, validate, and archive Whiteflag communications data. We will release instructions for deploying node infrastructure on other cloud providers, as well as for archives, RPCs, and other useful infrastructures. Stay tuned!


**Need help?** Please reach out to **info@fennellabs.com** with any problems that you may have.

## Quick executive summary

A validator host only needs four public inbound ports (22, 80, 443, 30333).

Docker publishes the JSON‑RPC server on **127.0.0.1:9944**; the node is started with `--rpc-external --rpc-cors all` so nginx (on the same VM, via the `docker0` bridge) can proxy WebSocket traffic over TLS. Because 9944 never leaves loop‑back, Unsafe RPC is invisible to the Internet. The rest of the guide covers OS prerequisites, Docker install, key generation, nginx + Certbot, and validator registration.

This guide provides a cloud-agnostic approach to deploying a Fennel validator with SSL/TLS termination. It includes specific fixes for common cloud networking issues and follows official Polkadot SDK best practices.

---

## 1 VM & network prerequisites

| Requirement | Typical pick | Why / doc |
| --- | --- | --- |
| OS | Ubuntu 22.04 LTS | Long‑term support |
| vCPU / RAM | ≥ 2 vCPU, 8 GB | Substrate baseline |
| Disk | 40 GB SSD | ≈1 GB/day growth |
| Public IP + DNS | `rpc.<your‑domain>` A/AAAA record | Needed for Let's Encrypt |

### 1.1 Generate SSH key pair (if needed)

```bash
# Generate a new SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/fennel_validator_key -C "fennel-validator-$(date +%Y%m%d)"

# Display public key for cloud provider console; write it down for VM SSH setup
cat ~/.ssh/fennel_validator_key.pub
```

Add the public key to your VM during creation or via your cloud provider's key management interface.

### 1.2 Create your VM instance

**Recommended specifications:**
- **OS**: Ubuntu 22.04 LTS
- **Instance Type**: 2+ vCPUs, 8GB+ RAM
- **Storage**: 50GB+ SSD (100GB+ recommended for long-term operation)
- **Network**: Assign a public IP address

### 1.3 Configure security groups/firewall rules

Ensure your cloud provider's security groups allow inbound traffic on:

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22 | TCP | Your IP | SSH access |
| 80 | TCP | 0.0.0.0/0 | Let's Encrypt ACME challenge |
| 443 | TCP | 0.0.0.0/0 | HTTPS/WSS for RPC |
| 30333 | TCP | 0.0.0.0/0 | P2P networking |

**Cloud-specific notes:**
- **AWS**: Configure Security Groups in EC2
- **GCP**: Configure Firewall Rules in VPC
- **Azure**: Configure Network Security Groups
- **Oracle Cloud**: Configure Security Lists in VCN
- **DigitalOcean**: Configure Firewalls


### 1.4 Connect to your VM and configure firewall

```bash
# Replace with your VM's public IP and SSH key path
ssh -i ~/.ssh/fennel_validator_key ubuntu@YOUR_VM_PUBLIC_IP

# Update system packages
sudo apt update && sudo apt upgrade -y

# Configure UFW (Ubuntu Firewall)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 30333/tcp
sudo ufw --force enable
sudo ufw status verbose
```

---

## 2 Install Docker Engine

```bash
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker $USER
sudo systemctl enable --now docker
```

**Important:** After running `usermod -aG docker $USER`, log out and log back in for the group membership to take effect. This allows running Docker commands without `sudo`. You can also start a new shell: `exec newgrp docker`

---

## 3 Directory layout & chainspec

```bash
sudo mkdir -p /opt/fennel/{db,specs}
sudo chown -R 1001:1001 /opt/fennel
curl -L \
  https://raw.githubusercontent.com/CorruptedAesthetic/fennel-solonet/main/chainspecs/production/production-raw.json \
  -o /opt/fennel/specs/production-raw.json
sudo chown 1001:1001 /opt/fennel/specs/production-raw.json
```

---

## 4 Generate your stash key (sr25519)

```bash
sudo docker run --rm parity/subkey:latest generate --scheme sr25519
```

Save the mnemonic **offline**; note the SS58 *stash* address.

---

## 5 Pre-provision Network Identity Key 


### Option A: Automated Key Generation (Recommended)

```bash
# Create the network directory structure and set ownership to your hardened UID
sudo mkdir -p /opt/fennel/db/chains/fennel_production/network
sudo chown -R 1001:1001 /opt/fennel

# Generate the node's libp2p key using subkey, which is an official Substrate tool.
sudo docker run --rm \
  --user 1001:1001 \
  -v /opt/fennel/db:/data \
  parity/subkey:latest \
  generate-node-key --file /data/chains/fennel_production/network/secret_ed25519

# Lock down permissions 
sudo chmod 600 /opt/fennel/db/chains/fennel_production/network/secret_ed25519

# Sanity check: file size (can be 32 bytes binary OR 64 hex chars)
sudo wc -c /opt/fennel/db/chains/fennel_production/network/secret_ed25519
# -> 32 (binary) or 64 (hex) - both are valid for --node-key-file

# Optional: list to confirm ownership is 1001:1001
sudo ls -la /opt/fennel/db/chains/fennel_production/network/

# Optional: Display the peer identifier (public key) for reference
sudo docker run --rm \
  -v /opt/fennel/db:/data \
  parity/subkey:latest \
  inspect-node-key --file /data/chains/fennel_production/network/secret_ed25519
```

### Option B: Use Existing Key

If you have an existing network key from a previous validator setup:

```bash
# Create network directory
sudo mkdir -p /opt/fennel/db/chains/fennel_production/network

# Copy your existing key (replace with your actual key)
echo "YOUR_EXISTING_KEY" | sudo tee /opt/fennel/db/chains/fennel_production/network/secret_ed25519

# Set proper permissions
sudo chmod 600 /opt/fennel/db/chains/fennel_production/network/secret_ed25519
sudo chown 1001:1001 /opt/fennel/db/chains/fennel_production/network/secret_ed25519
```

---

## 6 Run the validator container

```bash
sudo docker pull ghcr.io/corruptedaesthetic/fennel-solonet:fennel-node-0.6.2

sudo docker run -d --name fennel-validator \
  --user 1001:1001 \
  -p 30333:30333 \
  -p 127.0.0.1:9944:9944 \
  -v /opt/fennel/db:/data \
  -v /opt/fennel/specs:/specs:ro \
  ghcr.io/corruptedaesthetic/fennel-solonet:fennel-node-0.6.2 \
  --base-path /data \
  --chain /specs/production-raw.json \
  --validator \
  --node-key-file /data/chains/fennel_production/network/secret_ed25519 \
  --port 30333 \
  --rpc-port 9944 \
  --rpc-external \
  --rpc-cors all \
  --rpc-methods Unsafe \
  --rpc-rate-limit 100 \
  --pruning 1000 \
  --name fennel-docker-validator \
  --bootnodes /dns4/bootnode1.fennel.network/tcp/30333/p2p/12D3KooWFRgPPfukBwCKcw5BXdKwLwj15tHgEYpHyNdqownMTJ3d \
  --bootnodes /dns4/bootnode2.fennel.network/tcp/30333/p2p/12D3KooWHVkUjgF8zLY4Y8Cmf9kiJQE9THRkhovJPreHAqWjSNzH
```

**Single-line alternative (avoids line-continuation issues):**

```bash
sudo docker run -d --name fennel-validator --user 1001:1001 -p 30333:30333 -p 127.0.0.1:9944:9944 -v /opt/fennel/db:/data -v /opt/fennel/specs:/specs:ro ghcr.io/corruptedaesthetic/fennel-solonet:fennel-node-0.6.2 --base-path /data --chain /specs/production-raw.json --validator --node-key-file /data/chains/fennel_production/network/secret_ed25519 --port 30333 --rpc-port 9944 --rpc-external --rpc-cors all --rpc-methods Unsafe --rpc-rate-limit 100 --pruning 1000 --name fennel-docker-validator --bootnodes /dns4/bootnode1.fennel.network/tcp/30333/p2p/12D3KooWFRgPPfukBwCKcw5BXdKwLwj15tHgEYpHyNdqownMTJ3d --bootnodes /dns4/bootnode2.fennel.network/tcp/30333/p2p/12D3KooWHVkUjgF8zLY4Y8Cmf9kiJQE9THRkhovJPreHAqWjSNzH
```

**Key points:**
- `--node-key-file` uses the pre-provisioned key, preventing NetworkKeyNotFound errors
- `--user 1001:1001` ensures proper permissions
- `--pruning 1000` keeps only the last 1000 blocks to save disk space
- RPC is bound to loopback (127.0.0.1) for security

**Pruning Options**: 
- `--pruning 1000` - Keep 1000 blocks (recommended for validators)
- `--pruning 500` - Keep 500 blocks (more aggressive pruning)
- `--pruning archive` - Keep all blocks (requires much more storage)

Monitor sync:

```bash
sudo docker logs -f fennel-validator | grep Imported
```

**Notes:**
- `--rpc-external` allows nginx (172.17.x.x) to connect; 9944 is still private because it is published only to loopback.
- `--rpc-cors all` removes the Origin check that otherwise returns 403 for WebSocket upgrades.

---

## 7 Configure DNS (Required for SSL)

Before setting up SSL, you need to point your domain to your VM's IP address.

### 7.1 Find your VM's public IP
```bash
curl -s ifconfig.me
```

### 7.2 Configure DNS records
Log into your domain registrar and add/update DNS records:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | `rpc` | `YOUR_VM_IP` | 300 |

**Example**: If your VM IP is `203.0.113.42`, create an A record:
- **Name**: `rpc`
- **Value**: `203.0.113.42`

### 7.3 Verify DNS propagation
```bash
# Replace with your actual domain
nslookup rpc.yourdomain.com
```

Wait for DNS propagation (5-30 minutes, up to 48 hours for full propagation).

---

## 8 nginx + Let's Encrypt

### 8.1 Install nginx and certbot
```bash
sudo apt install -y nginx certbot python3-certbot-nginx
```

### 8.2 Cloud-specific networking fixes

Some cloud providers have additional firewall layers that may block HTTP/HTTPS traffic. If you encounter "No route to host" or connection timeout errors:

#### For Oracle Cloud:
```bash
# Check current iptables rules
sudo iptables -L INPUT --line-numbers

# Add ACCEPT rules for ports 80,443,30333 before any REJECT rules
sudo iptables -I INPUT 5 -p tcp -m multiport --dports 80,443,30333 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Verify the fix
curl -I http://YOUR_VM_IP
```

#### For other cloud providers:
- **AWS**: Ensure Security Groups allow inbound traffic on ports 80/443
- **GCP**: Check VPC firewall rules and ensure default-allow-http/https tags are applied
- **Azure**: Verify Network Security Group rules allow HTTP/HTTPS traffic
- **DigitalOcean**: Check Firewall settings in control panel

### 8.3 Obtain SSL certificate
```bash
# Replace rpc.yourdomain.com with your actual domain
sudo certbot --nginx -d rpc.yourdomain.com -m your-email@example.com --agree-tos --redirect
```

**Note**: Replace `your-email@example.com` with your actual email address and `rpc.yourdomain.com` with your domain.

### 8.4 Create Fennel RPC configuration
```bash
# Replace rpc.yourdomain.com with your actual domain throughout this configuration
sudo tee /etc/nginx/conf.d/fennel.conf > /dev/null << 'EOF'
limit_req_zone $binary_remote_addr zone=rpc:10m rate=10r/s;

server {
    listen 443 ssl http2;
    server_name rpc.yourdomain.com;

    ssl_certificate     /etc/letsencrypt/live/rpc.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rpc.yourdomain.com/privkey.pem;

    location = /health {
        add_header Content-Type text/plain;
        return 200 "Fennel WebSocket RPC up\n";
    }

    location / {
        limit_req zone=rpc burst=20 nodelay;
        proxy_pass         http://127.0.0.1:9944;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection "Upgrade";
        proxy_set_header   Host $host;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
    }
}
EOF
```

### 8.5 Configure HTTP to HTTPS redirect
Ensure proper HTTP to HTTPS redirection while preserving the default server functionality:

```bash
# Backup the default configuration
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup

# Replace rpc.yourdomain.com with your actual domain
sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOF'
# Default server configuration
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    # Redirect your domain to HTTPS
    if ($host = rpc.yourdomain.com) {
        return 301 https://$host$request_uri;
    }

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF
```

**Important**: Replace `rpc.yourdomain.com` with your actual domain name in the redirect configuration above.

### 8.6 Test and reload nginx
```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## 9 Validation tests

```bash
# Test health endpoint (replace with your domain)
curl https://rpc.yourdomain.com/health

# Loop-back RPC (should work once validator is running)
curl -s -H 'content-type: application/json' \
     -d '{"id":1,"jsonrpc":"2.0","method":"system_chain","params":[]}' \
     http://127.0.0.1:9944

# Secure WebSocket through nginx (once validator is running)
# Install websocat if needed: curl -L https://github.com/vi/websocat/releases/latest/download/websocat-linux64 -o /usr/local/bin/websocat && chmod +x /usr/local/bin/websocat
websocat wss://rpc.yourdomain.com
> {"id":1,"jsonrpc":"2.0","method":"system_chain","params":[]}
< {"jsonrpc":"2.0","result":"Fennel Production Network","id":1}

# Health endpoint for uptime monitors
curl -I https://rpc.yourdomain.com/health  # HTTP/2 200
```

A blank/502 on the root URL (`/`) is normal; the node does not serve GET.

---

## 10 Rotate session keys & register

1. Go to [Polkadot.js Apps](https://polkadot.js.org/apps/)
2. Click "Fennel Production Network" 
3. Scroll all the way down and click "development" 
4. Click "custom endpoint" add `wss://rpc.yourdomain.com` (replace with your domain), click "save" and "switch" in the upper right.
5. Click Developer > RPC Calls. Create the setting: `author_rotateKeys` (copy session key hex).
6. Email stash SS58 (from step 4) + session key hex (from step 5) to [**info@fennellabs.com**](mailto:info@fennellabs.com). 
7. Fennel Labs will set you up as a validator. Add your stash ID to polkadot.js in the meantime. 
8. Setup Polkadot developer signer extension
9. Add your ss58 secret mnemonic to add your account using "import account from existing seed." Setup your name and intended password.
10. Connect this account and press submit. 
11. Might have to refresh to see your account on polkadot.js

---

## 11 Optional: Developer tunnel

If you prefer to skip the SSL setup and work locally:

```bash
# Replace with your VM's IP and SSH key path
ssh -L 9944:localhost:9944 ubuntu@YOUR_VM_IP -i ~/.ssh/fennel_validator_key

# Then connect to ws://localhost:9944 in Polkadot‑JS
```

SSH port‑forward lets you bypass TLS for local testing.

---

## 12 Ongoing maintenance

- **TLS renewal:** `sudo certbot renew --dry-run` (set up monthly cron job)
- **Update node:** `docker pull`, stop, rm, re‑run with latest image
- **Monitor logs:** `docker logs fennel-validator | grep Imported`
- **Security:** Consider fail2ban to ban IPs with repeated 429 errors in `/var/log/nginx/access.log`
- **Backup:** Regularly backup your stash key mnemonic and `/opt/fennel/db` directory

---

## Troubleshooting

### Common Issues

1. **"No route to host" errors**
   - Check cloud provider security groups/firewall rules
   - For Oracle Cloud: Add iptables ACCEPT rules before REJECT rules
   - Verify UFW rules with `sudo ufw status verbose`

2. **SSL certificate issues**
   - Ensure DNS propagation is complete: `nslookup your-domain.com`
   - Check Let's Encrypt rate limits
   - Verify nginx configuration: `sudo nginx -t`

3. **Validator not syncing**
   - Check container logs: `sudo docker logs fennel-validator`
   - Verify P2P port 30333 is accessible
   - Ensure sufficient disk space

4. **WebSocket connection failures**
   - Test local RPC first: `curl http://127.0.0.1:9944`
   - Check nginx proxy configuration
   - Verify SSL certificate is valid

### Performance Optimization

- Monitor disk usage: `df -h /opt/fennel`
- Adjust pruning settings based on available storage
- Consider using SSD storage for better performance
- Set up log rotation for Docker containers

---

## Security & Port Matrix

| Port | Bind Address | Cloud Firewall | Purpose |
|------|-------------|----------------|---------|
| 22 | 0.0.0.0 | **Allow** | SSH access |
| 80 | 0.0.0.0 | **Allow** | ACME challenge, HTTP→HTTPS redirect |
| 443 | 0.0.0.0 | **Allow** | HTTPS/WSS via nginx |
| 30333 | 0.0.0.0 | **Allow** | P2P networking |
| 9944 | 127.0.0.1 | **Block** | Unsafe RPC (local only) |

---

## Final check

- `curl -s https://rpc.yourdomain.com/health` → `Fennel WebSocket RPC up`
- `websocat wss://rpc.yourdomain.com` → JSON response
- Block height in `docker logs -f fennel-validator | grep Imported` matches network

You now have a hardened Fennel validator that is:
- ✅ **TLS-secured** with Let's Encrypt certificates
- ✅ **Rate-limited** to prevent abuse
- ✅ **Cloud-agnostic** - works on any major cloud provider
- ✅ **Secure** - Unsafe RPC kept off the public Internet
- ✅ **Production-ready** with proper monitoring and maintenance procedures

This guide provides a robust foundation for deploying Fennel validators across different cloud providers while maintaining security best practices and SSL/TLS termination.
