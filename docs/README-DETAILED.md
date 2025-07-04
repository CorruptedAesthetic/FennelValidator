# 🌱 Fennel External Validator

**Join the Fennel Blockchain Network as a Validator**

Become part of the Fennel ecosystem by running a secure, professional validator node. This repository provides everything you need to set up, configure, and request admission to the Fennel solonet network.

## 📊 Process Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│ 1. Clone Repo   │ --> │ 2. Run start.sh  │ --> │ 3. Follow Setup │
│                 │     │                  │     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               |
                               v
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│ 6. Submit to    │ <-- │ 5. Files Ready   │ <-- │ 4. Setup        │
│ Fennel Labs     │     │ in validator-data│     │ Complete        │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

---

## 🚀 Ultra Quick Start (Recommended for Everyone)

**The simplest way to become a Fennel validator:**

```bash
# 1. Clone this repository
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator

# 2. Run the start script
./start.sh
```

**That's it!** The script will:
- ✅ Detect first-time setup automatically
- ✅ Guide you through each step interactively
- ✅ Apply security hardening automatically
- ✅ Generate all required keys and accounts
- ✅ Create submission file for Fennel Labs
- ✅ Provide clear next steps

**Total time:** 5-10 minutes

---

## 🔧 Alternative: Step-by-Step Manual Setup

**For those who want to run each step manually:**

```bash
# 1. Clone this repository
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator

# 2. Install Fennel validator
./install.sh

# 3. Configure your validator
./setup-validator.sh

# 4. Launch securely with security hardening
./tools/secure-launch.sh

# 5. Generate keys and complete registration
./tools/internal/generate-keys-with-restart.sh
```

**That's it!** Your validator is now running with security hardening, firewall configuration, and proper isolation.

### 🔒 Security Features (Automatic)
- ✅ **Firewall configured** - P2P port open, RPC/metrics secured to localhost only
- ✅ **File permissions secured** - Session keys and config files protected (600/700)
- ✅ **RPC methods secured** - Automatically set to 'safe' mode 
- ✅ **Process isolation** - Secure validator process management
- ✅ **Configuration validation** - Ensures proper setup before launch

### 🛠️ Management Commands
All management is available through the main menu:
```bash
./start.sh
```

Or individual commands:
```bash
# Basic Commands
./validate.sh status     # Check validator status
./validate.sh stop       # Stop validator
./validate.sh restart    # Restart validator
./validate.sh logs       # View logs

# Utility Commands  
./tools/validator-status.sh    # Comprehensive status dashboard
./tools/troubleshoot.sh        # Diagnose and fix common issues
./tools/reset-validator.sh     # Reset to clean state (with backup)
```

---

## 📁 File Organization

### Validator Data Directory
All your validator files are organized in `validator-data/`:
- **`session-keys.json`** - Your validator operational keys
- **`stash-account.json`** - Your main validator account
- **`COMPLETE-REGISTRATION-SUBMISSION.txt`** - File to send to Fennel Labs
- **`complete-validator-setup-instructions.txt`** - Your reference

### Security
- All key files have 600 permissions (owner read/write only)
- Directory has 700 permissions (owner access only)
- Files are excluded from version control

---

## 🔐 Security & Best Practices

### **Key Security**
- ✅ **Session keys** are generated locally and never transmitted
- ✅ **Network identity** is unique to your validator
- ✅ **Private keys** remain on your system only
- ✅ **Only public information** shared with Fennel Labs

### **Network Security**
- ✅ **Encrypted P2P** communication with other validators
- ✅ **Firewall configuration** applied automatically
- ✅ **Monitoring tools** for validator health
- ✅ **Automatic updates** for chain specifications

### **Operational Security**
- ✅ **Resource monitoring** to prevent overload
- ✅ **Log management** for troubleshooting
- ✅ **Graceful shutdown** procedures
- ✅ **Backup and recovery** documentation

---

## 🌐 Network Information

### **Fennel Solonet**
- **Purpose**: Production-ready blockchain network
- **Consensus**: AURA (block production) + GRANDPA (finality)
- **Block Time**: ~6 seconds
- **Network Type**: Proof of Authority (PoA)
- **Validator Admission**: Managed by Fennel core team

### **Connection Details**
- **Network automatically discovers bootnodes**
- **Chain Spec**: Auto-downloaded from [fennel-solonet](https://github.com/CorruptedAesthetic/fennel-solonet)
- **Network ID**: `staging`

---

## 🎯 Registration Process

### **What You Do**
1. Run `./start.sh` (setup completes automatically)
2. Send `validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt` to Fennel Labs
3. Wait for confirmation

### **What Fennel Labs Does**
1. Reviews your submission
2. Funds your stash account with testnet tokens (using sudo)
3. Binds your session keys to your stash account (using sudo)
4. Adds your validator to the validator set (using sudo)
5. Confirms your validator is active

### **No Manual Steps Required**
- ❌ No manual session.setKeys() call needed
- ❌ No secret phrase sharing required
- ❌ No manual funding of accounts
- ✅ Fennel Labs handles everything via sudo privileges

### **Request Requirements**
- ✅ **Stable network connection** (>99% uptime expected)
- ✅ **Valid session keys** generated by your validator
- ✅ **Synchronized node** with current blockchain state
- ✅ **Commitment** to network participation and governance

---

## 🛠️ Advanced Configuration

### **Custom Network Settings**
```bash
# Edit configuration
nano config/validator.conf

# Available options:
VALIDATOR_NAME="Your-Validator-Name"
P2P_PORT=30333
RPC_PORT=9944
PROMETHEUS_PORT=9615
LOG_LEVEL=info
DATA_DIR=./data
```

### **Key Management**
All key management is handled through the main menu:
```bash
./start.sh
```

Available options:
- Generate new session keys
- Create new stash account
- Backup keys and configuration
- Restore from backup
- Reset validator completely

---

## 🆘 Troubleshooting

### **Using the Troubleshooter**
Run the integrated troubleshooter:
```bash
./start.sh
```
Choose "Troubleshoot" from the menu.

**The troubleshooter automatically:**
- Checks system requirements
- Verifies all dependencies
- Tests network connectivity
- Validates configuration files
- Checks key file permissions
- Diagnoses common issues
- Applies fixes where possible

### **Common Issues**

#### **Binary Not Found**
```
❌ Fennel node binary not found!
```
**Solution**: The troubleshooter will detect and fix this automatically.

#### **Network Connection Failed**
```
❌ Failed to connect to bootnodes
```
**Solution**: The troubleshooter will:
1. Check firewall settings
2. Verify port 30333 is open
3. Test network connectivity
4. Suggest fixes

#### **Key Generation Failed**
```
❌ Failed to generate session keys
```
**Solution**: The troubleshooter will:
1. Check if validator is running
2. Verify RPC access
3. Restart validator if needed
4. Retry key generation

### **Getting Help**

1. **Run troubleshooter**: `./start.sh` → Choose "Troubleshoot"
2. **Check logs**: `./start.sh` → Choose "View Logs"
3. **Status check**: `./start.sh` → Choose "Check Status"
4. **Reset if needed**: `./start.sh` → Choose "Reset Validator"

---

## 📊 Network Participation

### **Validator Responsibilities**
- 🔄 **Block Production**: Participate in consensus when selected
- 🏛️ **Governance**: Vote on network proposals and upgrades
- 🛡️ **Security**: Maintain high uptime and secure operations
- 🤝 **Community**: Engage with other validators and network governance

### **Rewards & Incentives**
- 💰 **Validation Rewards**: Earn tokens for successful block production
- 🎯 **Performance Bonuses**: Additional rewards for high uptime
- 🏆 **Governance Participation**: Rewards for active governance
- 📈 **Network Growth**: Benefit from network value appreciation

---

## 🔗 Resources

### **Documentation**
- [Fennel Protocol](https://github.com/CorruptedAesthetic/fennel-solonet) - Main protocol repository
- [Substrate Documentation](https://docs.substrate.io/) - Underlying blockchain framework
- [Polkadot.js Apps](https://polkadot.js.org/apps/) - Network interaction interface

### **Community**
- **Discord**: [Join Fennel Community](#) <!-- Add actual Discord link -->
- **Telegram**: [Fennel Validators](#) <!-- Add actual Telegram link -->
- **Forum**: [Fennel Governance](#) <!-- Add actual forum link -->

### **Support**
- **Technical Issues**: Run `./start.sh` → Choose "Troubleshoot"
- **Network Questions**: Contact the Fennel team
- **Emergency**: Use the emergency contact procedures

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📚 Documentation

- 📖 **[BEGINNERS-GUIDE.md](BEGINNERS-GUIDE.md)** - Step-by-step guide for non-technical users
- 📋 **[EXAMPLE-VALIDATOR-SETUP.md](EXAMPLE-VALIDATOR-SETUP.md)** - See exactly what happens during setup
- 🏢 **[FOR-FENNEL-LABS.md](FOR-FENNEL-LABS.md)** - Information for network operators
- ❓ **[FAQ.md](FAQ.md)** - Common questions and answers

---

## ⚡ Quick Reference

### **One Command to Rule Them All**
```bash
./start.sh
```

### **First Time Setup**
```bash
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator
./start.sh
```

### **Daily Operations**
```bash
./start.sh
```
- Check status
- View logs
- Troubleshoot issues
- Manage registration

### **File Locations**
- **Main menu**: `./start.sh`
- **Validator files**: `validator-data/`
- **Configuration**: `config/validator.conf`
- **Logs**: Use menu to view

---

**Ready to become a Fennel validator? Just run `./start.sh` and follow the prompts!** 🌱

*Questions? Use the troubleshooter or contact the Fennel team.* 