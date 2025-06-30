# Fennel External Validator - Simple Setup

**🧪 Join the Fennel staging network in 3 simple steps**

## Prerequisites
- Linux, macOS, or Windows
- 2+ CPU cores, 4GB+ RAM, 20GB+ storage

## 🚀 Quick Setup (3 Steps)

### Step 1: Download and Install
```bash
# Download installer
curl -sSL https://raw.githubusercontent.com/CorruptedAesthetic/fennel-prod/main/FennelValidator/install.sh | bash

# Make scripts executable
chmod +x *.sh scripts/*.sh
```

### Step 2: Setup and Start
```bash
# Configure your validator
./setup-validator.sh

# Start validator (connects to network)
./validate.sh start
```

### Step 3: Generate Keys and Send Info
```bash
# Generate session keys
./scripts/generate-session-keys.sh

# This creates: session-keys.json with your validator info
```

**That's it!** Send us your `session-keys.json` file and we'll add you to the validator set.

## 📋 What to Send Us

After Step 3, send us the contents of `session-keys.json`:

```json
{
    "session_keys": "0x...",
    "aura_key": "0x...",
    "grandpa_key": "0x...",
    "validator_name": "Your-Validator-Name"
}
```

## 🔧 Network Connection

Your validator automatically connects to:
- **Bootnode**: `/ip4/192.168.49.2/tcp/30604/p2p/12D3KooWRpzRTivvJ5ySvgbFnPeEE6rDhitQKL1fFJvvBGhnenSk`
- **Chainspec**: Auto-downloaded from fennel-solonet

## ✅ Verify Setup

Check your validator is working:
```bash
# Check status
./validate.sh status
# Should show: connected to network, syncing blocks

# Check keys
cat session-keys.json
# Should show your generated keys
```

## 📞 Next Steps

1. **Setup**: Complete the 3 steps above
2. **Send**: Email/message us your `session-keys.json` content  
3. **Wait**: We add you to validator set via Polkadot.js Apps
4. **Validate**: You start producing blocks!

## 🆘 Simple Commands

```bash
# Check if running
./validate.sh status

# View logs
./validate.sh logs

# Restart if needed
./validate.sh restart

# Stop validator
./validate.sh stop
```

---

**🧪 Staging Network** - Safe for learning, no financial risk! 