## Quick executive summary

A validator host only needs four public inbound ports (22, 80, 443, 30333).

Docker publishes the JSON‑RPC server on **127 .0 .0 .1 : 9944**; the node is started with `--rpc-external --rpc-cors all` so nginx (on the same VM, via the `docker0` bridge) can proxy WebSocket traffic over TLS.  Because 9944 never leaves loop‑back, Unsafe RPC is invisible to the Internet.  The rest of the guide covers OS prerequisites, Docker install, key generation, nginx + Certbot, and validator registration.([Polkadot Docs](https://docs.polkadot.com/infrastructure/running-a-node/setup-full-node/?utm_source=chatgpt.com), [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-20-04?utm_source=chatgpt.com), [nginx.org](https://nginx.org/en/docs/http/websocket.html?utm_source=chatgpt.com))

---

## 1 VM & network prerequisites

| Requirement | Typical pick | Why / doc |
| --- | --- | --- |
| OS | Ubuntu 22.04 LTS | Long‑term support |
| vCPU / RAM | ≥ 2 vCPU, 8 GB | Substrate baseline ([Polkadot Docs](https://docs.polkadot.com/infrastructure/running-a-node/setup-full-node/?utm_source=chatgpt.com)) |
| Disk | 40 GB SSD | ≈1 GB/day growth |
| Public IP + DNS | `rpc.<your‑domain>` A/AAAA record | Needed for Let’s Encrypt |

Open inbound **22, 80, 443, 30333** in your cloud firewall (AWS SG, Azure NSG, GCP VPC, DigitalOcean Firewall). Refer to the vendor docs for rule syntax.([AWS Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-rules-reference.html?utm_source=chatgpt.com), [AWS Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html?utm_source=chatgpt.com), [Microsoft Learn](https://learn.microsoft.com/en-us/azure/virtual-network/tutorial-filter-network-traffic?utm_source=chatgpt.com), [Microsoft Learn](https://learn.microsoft.com/en-us/answers/questions/1655870/trouble-opening-port-443-%28https%29-in-azure-despite?utm_source=chatgpt.com), [Google Cloud](https://cloud.google.com/sdk/gcloud/reference/compute/firewall-rules/create?utm_source=chatgpt.com), [Google Cloud](https://cloud.google.com/firewall/docs/using-firewalls?utm_source=chatgpt.com), [DigitalOcean Docs](https://docs.digitalocean.com/products/networking/firewalls/how-to/configure-rules/?utm_source=chatgpt.com))

On‑box, mirror those rules with UFW:

```bash
sudo ufw default deny incoming
sudo ufw allow 22,80,443,30333/tcp
sudo ufw enable

```

([DigitalOcean Docs](https://docs.digitalocean.com/products/networking/firewalls/how-to/configure-rules/?utm_source=chatgpt.com))

---

## 2 Install Docker Engine

```bash
sudo apt update
sudo apt install -y docker.io   # Ubuntu package
sudo usermod -aG docker $USER   # optional
sudo systemctl enable --now docker

```

Canonical’s `docker.io` package auto‑updates through `apt` and is supported for production.([Docker Documentation](https://docs.docker.com/engine/install/ubuntu/?utm_source=chatgpt.com))

---

## 3 Directory layout & chainspec

```bash
sudo mkdir -p /opt/fennel/{db,specs}
sudo chown $USER:$USER /opt/fennel -R
curl -L \
  https://raw.githubusercontent.com/CorruptedAesthetic/fennel-solonet/main/chainspecs/production/production-raw.json \
  -o /opt/fennel/specs/production-raw.json

```

---

## 4 Generate validator keys

```bash
docker run --rm parity/subkey:latest generate --scheme sr25519

```

Store the mnemonic offline; note the SS58 stash address—you’ll send it to Fennel Labs later.([Polkadot Docs](https://docs.polkadot.com/infrastructure/running-a-node/setup-full-node/?utm_source=chatgpt.com))

---

## 5 Run the validator (RPC bound to loop‑back)

```bash
sudo docker pull ghcr.io/corruptedaesthetic/fennel-solonet:fennel-node-0.5.9

sudo docker run -d --name fennel-validator \
  -p 30333:30333 \
  -p 127.0.0.1:9944:9944 \
  -v /opt/fennel/db:/data \
  -v /opt/fennel/specs:/specs \
  ghcr.io/corruptedaesthetic/fennel-solonet:fennel-node-0.5.9 \
  --base-path /data \
  --chain /specs/production-raw.json \
  --validator \
  --sync warp \
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

- `-rpc-external` allows nginx (172 .17 .x .x) to connect; 9944 is still private because it is published only to loop‑back.
- `-rpc-cors all` removes the Origin check that otherwise returns 403 for WebSocket upgrades.([guide.kusama.network](https://guide.kusama.network/docs/maintain-rpc?utm_source=chatgpt.com))

---

## 6 nginx + Let’s Encrypt

```bash
sudo apt install -y nginx certbot python3-certbot-nginx
sudo certbot --nginx -d rpc.<your-domain> -m you@example.com --agree-tos --redirect

```

Create `/etc/nginx/conf.d/fennel.conf`:

```
limit_req_zone $binary_remote_addr zone=rpc:10m rate=10r/s;

server {
    listen 443 ssl http2;
    server_name rpc.<your-domain>;

    ssl_certificate     /etc/letsencrypt/live/rpc.<your-domain>/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rpc.<your-domain>/privkey.pem;

    # simple health endpoint
    location = /health {
        add_header Content-Type text/plain;
        return 200 "WebSocket RPC up\n";
    }

    location / {
        limit_req zone=rpc burst=20 nodelay;
        proxy_pass         http://127.0.0.1:9944;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection upgrade;
        proxy_set_header   Host $host;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
    }
}

```

Reload nginx:

```bash
sudo nginx -t && sudo systemctl reload nginx

```

Upgrade headers and time‑outs follow nginx’s WebSocket guide.([nginx.org](https://nginx.org/en/docs/http/websocket.html?utm_source=chatgpt.com)) Certbot auto‑renews certificates.([DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-20-04?utm_source=chatgpt.com), [certbot.eff.org](https://certbot.eff.org/instructions?os=snap&ws=nginx&utm_source=chatgpt.com))

---

## 7 Validation

```bash
# RPC should be private
curl -m3 http://<VM-IP>:9944  # times out

# WebSocket should work
websocat wss://rpc.<your-domain>
> {"id":1,"jsonrpc":"2.0","method":"system_chain","params":[]}
< {"jsonrpc":"2.0","result":"Fennel Production Network","id":1}

# Health endpoint
curl -I https://rpc.<your-domain>/health  # HTTP/2 200

```

A blank/502 on the root URL (`/`) is normal; the node does not serve GET.

---

## 8 Rotate session keys & register

1. Polkadot‑JS > Developer > RPC `author_rotateKeys` → copy hex key.
2. Developer > Extrinsics `session.setKeys(keys, 0x00)` from stash.
3. Wait two sessions; confirm in `session.validators`.([Polkadot Docs](https://docs.polkadot.com/infrastructure/running-a-node/setup-full-node/?utm_source=chatgpt.com))
4. Email stash SS58 + session pubkey to [**info@fennellabs.com**](mailto:info@fennellabs.com).

---

## 9 Optional: local tunnel

```bash
ssh -L 9944:localhost:9944 ubuntu@<VM-IP>
# connect ws://localhost:9944 in Polkadot‑JS

```

---

## 10 Operations

- **TLS renew:** `certbot renew --dry-run` monthly cron.([DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-20-04?utm_source=chatgpt.com))
- **Node upgrade:** `docker pull` → stop → rm → re‑run.
- **Firewall:** keep only 22/80/443/30333 open (cloud + UFW).
- **fail2ban:** ban IPs that hit 429 in `/var/log/nginx/access.log`.

---

### Port & Security Matrix

| Port | Bind | Public? | Purpose |
| --- | --- | --- | --- |
| 22 | 0.0.0.0 | Yes | SSH |
| 30333 | 0.0.0.0 | Yes | P2P |
| 80 | 0.0.0.0 | Yes | ACME |
| 443 | 0.0.0.0 | Yes | WSS via nginx |
| 9944 | 127.0.0.1 | **No** | JSON‑RPC (Unsafe) |

---

### Final check

- `curl -s https://rpc.<your-domain>/health` → `WebSocket RPC up`
- `websocat wss://rpc.<your-domain>` → JSON response
- Block height in `docker logs -f fennel-validator | grep Imported` matches Explorer.

You now have a hardened Fennel validator that is TLS‑secured, rate‑limited, and keeps Unsafe RPC off the public Internet—all deployable on any cloud or bare‑metal host.