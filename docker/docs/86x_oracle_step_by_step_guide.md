Welcome! The below step by step guide shows you how to deploy a fennel validator on docker on Oracle Cloud! 

## 1 Create & prepare your Oracle Cloud VM

### 1.1 Generate an SSH key on your laptop

```bash
ssh-keygen -t ed25519 -f ~/.ssh/fennel_oracle -C "fennel‑oracle"

```

Oracle Compute uses the public part (`.pub`) at launch.([Oracle Documentation](https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/securityrules.htm?utm_source=chatgpt.com))

### 1.2 Launch the instance

- **Shape**: VM.Standard.E4.Flex (2 OCPU ≈ 2 vCPU, 8 GB RAM).
- **Boot volume**: 200 GB.
- **VCN**: new or existing public subnet; leave MTU at 9000 (Oracle’s jumbo frame).
- **Attach SSH key** in the wizard.

### 1.3 Add ingress rules to the VCN’s security list

Oracle exposes a “Default Security List” per subnet. Add four **stateful** ingress rules:([Oracle Documentation](https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/securitylists.htm?utm_source=chatgpt.com), [Oracle Documentation](https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/creating-securitylist.htm?utm_source=chatgpt.com))

| Source CIDR | Protocol | Port(s) |
| --- | --- | --- |
| 0.0.0.0/0 | TCP | 22 |
| 0.0.0.0/0 | TCP | 80 |
| 0.0.0.0/0 | TCP | 443 |
| 0.0.0.0/0 | TCP | 30333 |

Leave egress “All → 0.0.0.0/0” (validators must sync blocks).

### 1.4 Harden the host firewall (UFW)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22,80,443,30333/tcp
sudo ufw enable

```

UFW mirrors the same four ports and drops everything else.([blog.nginx.org](https://blog.nginx.org/blog/rate-limiting-nginx?utm_source=chatgpt.com))

---

## 2 Install Docker Engine on Ubuntu 22.04

```bash
sudo apt update
sudo apt install -y docker.io   # Canonical‑maintained build
sudo usermod -aG docker $USER   # optional: run docker without sudo
sudo systemctl enable --now docker

```

Canonical’s `docker.io` auto‑updates via `apt`.([Docker Documentation](https://docs.docker.com/engine/install/ubuntu/?utm_source=chatgpt.com), [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04?utm_source=chatgpt.com))

---

## 3 Filesystem layout & production chainspec

```bash
sudo mkdir -p /opt/fennel/{db,specs}
sudo chown $USER:$USER /opt/fennel -R
curl -L \
  https://raw.githubusercontent.com/CorruptedAesthetic/fennel-solonet/main/chainspecs/production/production-raw.json \
  -o /opt/fennel/specs/production-raw.json

```

---

## 4 Generate your stash key (sr25519)

```bash
docker run --rm parity/subkey:latest generate --scheme sr25519

```

Save the mnemonic **offline**; note the SS58 *stash* address.

---

## 5 Run the validator container (Oracle flavour)

The single RPC server listens on 9944; we publish it **only to loop‑back** so the Internet never sees Unsafe RPC.

```bash
docker pull ghcr.io/corruptedaesthetic/fennel-solonet:fennel-node-0.5.9

sudo docker run -d --name fennel-validator \
  -p 30333:30333 \
  -p 127.0.0.1:9944:9944 \
  -v /opt/fennel/db:/data \
  -v /opt/fennel/specs:/specs \
  ghcr.io/corruptedaesthetic/fennel-solonet:fennel-node-0.5.9 \
  --base-path /data \
  --chain /specs/production-raw.json \
  --validator --sync warp \
  --port 30333 \
  --rpc-port 9944 \
  --rpc-external \                  
  --rpc-cors all \                  
  --rpc-methods Unsafe \
  --rpc-rate-limit 100 \
  --name fennel-docker-validator \
  --bootnodes /dns4/bootnode1.fennel.network/tcp/30333/p2p/12D3KooWFRgPPfukBwCKcw5BXdKwLwj15tHgEYpHyNdqownMTJ3d \
  --bootnodes /dns4/bootnode2.fennel.network/tcp/30333/p2p/12D3KooWHVkUjgF8zLY4Y8Cmf9kiJQE9THRkhovJPreHAqWjSNzH

```

`Unsafe` is acceptable because 9944 is loop‑back‑only.

Monitor sync:

```bash
docker logs -f fennel-validator | grep Imported

```

---

## 6 Install nginx + Let’s Encrypt TLS

```bash
sudo apt install -y nginx certbot python3-certbot-nginx
sudo certbot --nginx -d rpc.fennel.network -m you@example.com --agree-tos --redirect

```

Create `/etc/nginx/conf.d/fennel.conf`:

```
limit_req_zone $binary_remote_addr zone=rpc:10m rate=10r/s;

server {
    listen 443 ssl http2;
    server_name rpc.fennel.network;

    ssl_certificate     /etc/letsencrypt/live/rpc.fennel.network/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rpc.fennel.network/privkey.pem;

    location = /health {
        add_header Content-Type text/plain;
        return 200 "WebSocket RPC up\n";
    }

    location / {
        limit_req zone=rpc burst=20 nodelay;     # DoS guard :contentReference[oaicite:8]{index=8}
        proxy_pass         http://127.0.0.1:9944;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection "Upgrade"; # WS headers :contentReference[oaicite:9]{index=9}
        proxy_set_header   Host $host;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
    }
}

```

Enable:

```bash
sudo nginx -t && sudo systemctl reload nginx

```

Certbot sets up auto‑renew timers.([DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-22-04?utm_source=chatgpt.com))

---

## 7 Validation tests

```bash
# loop‑back RPC (should work)
curl -s -H 'content-type: application/json' \
     -d '{"id":1,"jsonrpc":"2.0","method":"system_chain","params":[]}' \
     http://127.0.0.1:9944

# secure WebSocket through nginx
websocat wss://rpc.fennel.network
> {"id":1,"jsonrpc":"2.0","method":"system_chain","params":[]}
< {"jsonrpc":"2.0","result":"Fennel Production Network","id":1}

# health endpoint for uptime monitors
curl -I https://rpc.fennel.network/health  # HTTP/2 200

```

---

## 8 Rotate session keys & register

1. Polkadot‑JS > Developer > RPC `author_rotateKeys` (copy hex).
2. Developer > Extrinsics `session.setKeys(keys,0x00)`.
3. After two sessions, confirm your peer ID in `session.validators`.
4. Email stash SS58 + session key hex to [**info@fennellabs.com**](mailto:info@fennellabs.com).

---

## 9 Optional: developer tunnel

```bash
ssh -L 9944:localhost:9944 ubuntu@<VM-IP> -i ~/.ssh/fennel_oracle
# connect ws://localhost:9944 in Polkadot‑JS

```

SSH port‑forward lets you bypass TLS for local testing.

---

## 10 Ongoing maintenance

- **TLS renew:** `sudo certbot renew --dry-run` (cron montly). ([DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-22-04?utm_source=chatgpt.com))
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