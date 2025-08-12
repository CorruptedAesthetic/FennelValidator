Welcome! The below step by step guide shows you how to deploy a fennel validator on docker on Oracle Cloud! 


## 1 Create & prepare your Oracle Cloud VM

### 1.1 Generate an SSH key on your laptop

```bash
ssh-keygen -t ed25519 -f ~/.ssh/fennel_oracle -C "fennel‑oracle"

```

### 1.2 Launch the instance

- **Shape**: VM.Standard.E4.Flex (2 OCPU ≈ 2 vCPU, 8 GB RAM).
- **Boot volume**: 200 GB.
- **VCN**: new or existing public subnet; leave MTU at 9000 (Oracle's jumbo frame).
- **Attach SSH key** in the wizard.

### 1.3 Add ingress rules to the VCN's security list

| Source CIDR | Protocol | Port(s) |
| --- | --- | --- |
| 0.0.0.0/0 | TCP | 22 |
| 0.0.0.0/0 | TCP | 80 |
| 0.0.0.0/0 | TCP | 443 |
| 0.0.0.0/0 | TCP | 30333 |

Leave egress "All → 0.0.0.0/0" (validators must sync blocks).

### 1.5 SSH into VM

ssh -i ~/.ssh/oracle_fennel_key ubuntu@157.151.245.110


### 1.5 Harden the host firewall (UFW)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22,80,443,30333/tcp
sudo ufw enable

```

UFW mirrors the same four ports and drops everything else.

---

## 2 Install Docker Engine on Ubuntu 22.04

```bash
sudo apt update
sudo apt install -y docker.io   
sudo usermod -aG docker $USER   # optional: run docker without sudo 
sudo systemctl enable --now docker

```

**Important:** After running `usermod -aG docker $USER`, log out and log back in for the group membership to take effect. This allows running Docker commands without `sudo`. You can also start a enw shell: exec newgrp docker

---

## 3 Filesystem layout & production chainspec

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

## 4.5 Pre-provision Network Identity Key 

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

## 5 Run the validator container

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

**Pruning Options**: The `--pruning 1000` flag keeps only the last 1000 blocks to save disk space. For validators, this is recommended. Other options:
- `--pruning 1000` - Keep 1000 blocks (recommended for validators)
- `--pruning 500` - Keep 500 blocks (more aggressive pruning)
- `--pruning archive` - Keep all blocks (requires much more storage)

Monitor sync:

```bash
sudo docker logs -f fennel-validator | grep Imported

```

---


## 6 Configure DNS (Required for SSL) -- alternatively, can port forward--see step 9

Before setting up SSL, you need to point your domain to your VM's IP address.

### 6.1 Find your VM's public IP
```bash
curl -s ifconfig.me
```

### 6.2 Configure DNS records
Log into your domain registrar and add/update DNS records:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | `rpc` | `YOUR_VM_IP` | 300 |

**Example**: If your VM IP is `157.11.5.3`, create an A record:
- **Name**: `rpc`
- **Value**: `157.11.5.3`

### 6.3 Verify DNS propagation
```bash
nslookup rpc.fennel.network
```

Wait for DNS propagation (5-30 minutes, up to 48 hours for full propagation).

### 6.4 Alternative: Use a different subdomain
If you already have services on this IP, consider using a different subdomain:
- `fennel-rpc.yourdomain.com`
- `validator.yourdomain.com`
- Or skip public RPC entirely and use SSH tunnel, port forwarding (see step 9)
---

## 7 Install nginx + Let's Encrypt TLS

### 7.1 Install nginx and certbot
```bash
sudo apt install -y nginx certbot python3-certbot-nginx
```

### 7.2 Fix iptables (if needed)
If you encounter "No route to host" errors, you may need to fix iptables rules:

```bash
# Check current iptables rules; ensure ACCEPT rules for ports 80,443,30333 before REJECT rule
sudo iptables -L INPUT --line-numbers

# Add ACCEPT rules for ports 80,443,30333 before REJECT rule (insert at line 5 on Oracle Cloud)
sudo iptables -I INPUT 5 -p tcp -m multiport --dports 80,443,30333 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Verify the fix
curl -I http://YOUR_VM_IP
```

### 7.3 Obtain SSL certificate
```bash
sudo certbot --nginx -d rpc2.fennel.network -m your-real-email@example.com --agree-tos --redirect
```

**Note**: Replace `your-real-email@example.com` with your actual email address and `rpc2.fennel.network` with your domain throughout terminal commands below. 


### 7.4 Create Fennel RPC configuration
```bash
sudo tee /etc/nginx/conf.d/fennel.conf > /dev/null << 'EOF'
limit_req_zone $binary_remote_addr zone=rpc:10m rate=10r/s;

server {
    listen 443 ssl http2;
    server_name rpc2.fennel.network;

    ssl_certificate     /etc/letsencrypt/live/rpc2.fennel.network/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rpc2.fennel.network/privkey.pem;

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

### 7.5 Configure HTTP to HTTPS redirect
Ensure proper HTTP to HTTPS redirection while preserving the default server functionality:

```bash
# Backup the default configuration
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup


sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOF'
# Default server configuration
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    # Redirect your domain to HTTPS
    if ($host = rpc2.fennel.network) {
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

**Important**: Replace `rpc2.fennel.network` with your actual domain name in the redirect configuration above.

### 7.6 Test and reload nginx
```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## 7 Validation tests

```bash
# Test health endpoint
curl https://rpc2.fennel.network/health

# loop‑back RPC (should work once validator is running)
curl -s -H 'content-type: application/json' \
     -d '{"id":1,"jsonrpc":"2.0","method":"system_chain","params":[]}' \
     http://127.0.0.1:9944

# secure WebSocket through nginx (once validator is running)
websocat wss://rpc2.fennel.network
> {"id":1,"jsonrpc":"2.0","method":"system_chain","params":[]}
< {"jsonrpc":"2.0","result":"Fennel Production Network","id":1}

# health endpoint for uptime monitors
curl -I https://rpc2.fennel.network/health  # HTTP/2 200

```

---

## 8 Rotate session keys & register
1. go to polkadot.js
2. click "Fennel Production Network" 
3. Scroll all the way down and click "development" 
4. click "custom end point" add "wss://rpc2.fennel.network" (or your own domain rpc), click "save" and "switch" in the upper right.
5. click Developer > RPC Calls. Create the setting: `author_rotateKeys` (copy session key hex).
6. Email stash SS58 (from step 4) + session key hex (from step 8) to [**info@fennellabs.com**](mailto:info@fennellabs.com). 

7. Fennel Labs will set you up as a validator. Add your stash ID to polkadot.js in the meantime. 

8. Setup polkadot developer signer extension

9. add your ss58 secret mneumonic to add your account using "import account from existing seed." Setup your name and intended password.

10. Connect this account and press submit. 

11. might have to refresh to see your account on polkadot.js 

---

## 9 Optional: developer tunnel

```bash
ssh -L 9944:localhost:9944 ubuntu@<VM-IP> -i ~/.ssh/fennel_oracle
# connect ws://localhost:9944 in Polkadot‑JS

```

SSH port‑forward lets you bypass TLS for local testing.

---

## 10 Ongoing maintenance

- **TLS renew:** `sudo certbot renew --dry-run` (cron montly).
- **Update node:** `docker pull`, stop, rm, re‑run.
- **Logs:** `docker logs fennel-validator | grep Imported`.
- **Fail2ban:** ban IPs with repeated 429 in `/var/log/nginx/access.log`.

---

### Port & security matrix (Oracle)

| Port | Bind | Oracle VCN | Purpose |
| --- | --- | --- | --- |
| 22 | 0.0.0.0 | **Allow** | SSH |
| 80 | 0.0.0.0 | **Allow** | ACME |
| 443 | 0.0.0.0 | **Allow** | WSS via nginx |
| 30333 | 0.0.0.0 | **Allow** | P2P |
| 9944 | 127.0.0.1 | **Deny** | Unsafe RPC (local only) |

With these Oracle‑flavoured steps you get a hardened validator—TLS‑secured, rate‑limited, and safe from public Unsafe RPC—ready to join Fennel Solonet.