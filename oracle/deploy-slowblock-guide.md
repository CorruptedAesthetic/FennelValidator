# 🚀 Deploy Slowblock Validator on Oracle Cloud

## Step 1: Get Instance Public IP

1. **Go to Oracle Cloud Console:** https://cloud.oracle.com
2. **Navigate to:** Compute → Instances
3. **Select your instance:** `fennel-validator-x86-1751682420` or `fennel-validator-x86-1751682235`
4. **Copy the Public IP address**

## Step 2: Configure Security List (Firewall)

### Oracle Cloud Console (Required)
1. **Navigate to:** Networking → Virtual Cloud Networks
2. **Select:** `fennel-validator-vcn`
3. **Click:** `fennel-validator-subnet`
4. **Click:** "Default Security List for fennel-validator-vcn"
5. **Click:** "Add Ingress Rules"
6. **Add this rule:**
   - **Source CIDR:** `0.0.0.0/0`
   - **IP Protocol:** `TCP`
   - **Destination Port Range:** `30333`
   - **Description:** `Fennel P2P`

## Step 3: Connect to Your Instance

```bash
# Get your SSH key (you should have this from when you created the instance)
ssh -i /path/to/your/ssh-key ubuntu@YOUR_INSTANCE_PUBLIC_IP
```

## Step 4: Upload FennelValidator Repository

**Option A: Clone from GitHub**
```bash
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator
```

**Option B: Upload via SCP**
```bash
# From your local machine:
scp -r -i /path/to/your/ssh-key FennelValidator ubuntu@YOUR_INSTANCE_PUBLIC_IP:~/
```

## Step 5: Deploy Slowblock Validator

**On your Oracle Cloud instance:**

```bash
cd FennelValidator

# 1. Configure firewall on the instance
sudo apt-get update
sudo apt-get install -y iptables-persistent

# Open P2P port (30333)
sudo iptables -I INPUT 5 -p tcp --dport 30333 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Save firewall rules
sudo netfilter-persistent save

# 2. Update validator configuration
# Edit config/validator.conf to set VALIDATOR_NAME="slowblock"
nano config/validator.conf
```

**Update config/validator.conf:**
```bash
VALIDATOR_NAME="slowblock"
NETWORK="staging"
CHAINSPEC="staging-chainspec.json"
DATA_DIR="./data"
P2P_PORT="30333"
RPC_PORT="9944"
PROMETHEUS_PORT="9615"
RPC_EXTERNAL="false"
PROMETHEUS_EXTERNAL="false"
LOG_LEVEL="info"
BOOTNODE=""
REPO_URL="https://github.com/CorruptedAesthetic/fennel-solonet"
```

## Step 6: Install and Start Validator

```bash
# Install the validator
./install.sh

# Configure the validator
./setup-validator.sh

# Start the validator
./start.sh
```

**Follow the interactive setup:**
1. Choose "Complete Setup"
2. Set validator name as: `slowblock`
3. Use default ports (30333, 9944, 9615)
4. Choose staging network
5. Generate session keys

## Step 7: Generate Session Keys

```bash
# Generate keys for network submission
./scripts/generate-session-keys.sh
```

This will create:
- `validator-data/session-keys.json`
- `validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt`

## Step 8: Submit to Fennel Labs

Send the `COMPLETE-REGISTRATION-SUBMISSION.txt` file to Fennel Labs for network inclusion.

## Step 9: Monitor Your Validator

```bash
# Check validator status
./validate.sh status

# View logs
./validate.sh logs

# Check network connectivity
curl -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' http://localhost:9944
```

## Expected Network Connection

Your slowblock validator will automatically connect to:
- **Bootnode 1:** `135.18.208.132:30333`
- **Bootnode 2:** `132.196.191.14:30333`
- **Live Fennel Network:** Staging environment with other validators

## Troubleshooting

### No Peers Connected
1. Check firewall rules (both Oracle Cloud and instance)
2. Verify P2P port 30333 is open
3. Check network connectivity to bootnodes

### Validator Not Syncing
1. Check logs: `./validate.sh logs`
2. Restart validator: `./validate.sh restart`
3. Ensure latest chainspec: `./validate.sh update-chainspec`

### Performance Issues
1. Monitor system resources: `htop`
2. Check disk space: `df -h`
3. Consider upgrading from free tier if needed

## Next Steps After Deployment

1. **Monitor:** Keep an eye on validator performance
2. **Backup:** Save your session keys securely
3. **Update:** Keep validator software updated
4. **Network:** Participate in governance once active

Your slowblock validator will be ready to join the live Fennel solochain network! 🌱 