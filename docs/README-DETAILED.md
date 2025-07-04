# 🌱 Fennel External Validator

**Join the Fennel Blockchain Network as a Validator**

Become part of the Fennel ecosystem by running a secure, professional validator node. This repository provides everything you need to set up, configure, and request admission to the Fennel solonet network.

## 📊 Process Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│ 1. Pre-flight   │ --> │ 2. Installation  │ --> │ 3. Configuration│
│    Check        │     │    & Setup       │     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               |
                               v
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│ 6. Submit to    │ <-- │ 5. Generate      │ <-- │ 4. Secure       │
│ Fennel Labs     │     │    Registration  │     │    Launch       │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

---

## 🚀 Ultra Quick Start (Recommended for Beginners)

**Perfect for those with minimal technical experience:**

```bash
# 1. Clone this repository
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator

# 2. Check your system is ready
./preflight-check.sh

# 3. Run the complete setup (interactive, ~5-10 minutes)
./quick-start.sh
```

**That's it!** The script will:
- ✅ Guide you through each step interactively
- ✅ Apply security hardening automatically
- ✅ Generate all required keys and accounts
- ✅ Create submission file for Fennel Labs
- ✅ Provide clear next steps

---

## 🔧 Step-by-Step Setup (Manual Control)

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
./secure-launch.sh

# 5. Complete registration (generates stash account and submission)
./complete-registration.sh
```

**That's it!** Your validator is now running with security hardening, firewall configuration, and proper isolation.

### 🔒 Security Features (Automatic)
- ✅ **Firewall configured** - P2P port open, RPC/metrics secured to localhost only
- ✅ **File permissions secured** - Session keys and config files protected (600/700)
- ✅ **RPC methods secured** - Automatically set to 'safe' mode 
- ✅ **Process isolation** - Secure validator process management
- ✅ **Configuration validation** - Ensures proper setup before launch

### 🛠️ Management Commands
```bash
# Basic Commands
./validate.sh status     # Check validator status
./validate.sh stop       # Stop validator
./validate.sh restart    # Restart validator
./validate.sh logs       # View logs

# Utility Commands
./validator-status.sh    # Comprehensive status dashboard
./troubleshoot.sh        # Diagnose and fix common issues
./reset-validator.sh     # Reset to clean state (with backup)
```

---

## 🔧 Manual Setup Guide

### Prerequisites
- **Linux/macOS/Windows** with Docker or Rust toolchain
- **Stable internet connection** (24/7 recommended for validators)
- **Minimum 4GB RAM, 50GB storage** (SSD recommended)
- **Open firewall port** (default: 30333)

### 🎯 **3-Step Validator Journey**

#### **Step 1: Setup Your Validator**
```bash
# Download and install
./install.sh

# Configure your validator
./setup-validator.sh

# Initialize (generates network identity)
./validate.sh init
```

#### **Step 2: Start Validating & Generate Keys**
```bash
# Start your validator node
./validate.sh start

# Generate session keys (automated - handles RPC switching)
./scripts/generate-session-keys-auto.sh

# Extract AccountId information for network operators
./scripts/get-account-id.sh
```

#### **Step 3: Setup Stash Account & Register**
```bash
# Generate a stash account for testing (or use existing)
./scripts/generate-stash-account.sh

# Follow instructions to call session.setKeys() via Polkadot.js Apps
# Then inform network operators with your stash account address
```

#### **Step 4: Request Network Admission**
```bash
# Submit validation request
./scripts/submit-validation-request.sh
```

**That's it!** Your validation request will be reviewed by the Fennel network administrators.

---

## 🤖 Enhanced Automation Features

This repository includes automated scripts that eliminate manual configuration:

### **🔑 Automated Session Key Generation**
- **`generate-session-keys-auto.sh`**: Automatically switches RPC methods, generates keys, and restores security
- **No manual RPC method switching required**
- **Automatic cleanup and security restoration**

### **🏦 Stash Account Management**
- **`generate-stash-account.sh`**: Creates a complete stash account setup for testing
- **`setup-stash-account.sh`**: Explains the stash account concept and requirements
- **Generates step-by-step instructions for `session.setKeys()` calls**

### **🔍 AccountId Extraction**
- **`get-account-id.sh`**: Automatically extracts AccountId from session keys
- **Works with both `subkey` and `fennel-node key inspect`**
- **Provides all formats needed by network operators**

### **📋 Complete Documentation Generation**
- **Automated creation of submission files**
- **Step-by-step instructions for network registration**
- **All necessary information in ready-to-send format**

---

## 🔐 Security & Best Practices

### **Key Security**
- ✅ **Session keys** are generated locally and never transmitted
- ✅ **Network identity** is unique to your validator
- ✅ **Private keys** remain on your system only
- ✅ **Secure key backup** instructions provided

### **Network Security**
- ✅ **Encrypted P2P** communication with other validators
- ✅ **Firewall configuration** guidance included
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

## 📋 Validator Management

### **Essential Commands**
```bash
./validate.sh status    # Check validator status
./validate.sh start     # Start validator
./validate.sh stop      # Stop validator gracefully
./validate.sh restart   # Restart validator
./validate.sh logs      # View detailed logs
./validate.sh update    # Update chain specification
```

### **Key Management (Enhanced Automation)**
```bash
# Automated session key generation (recommended)
./scripts/generate-session-keys-auto.sh     # Auto-handles RPC method switching
./scripts/get-account-id.sh                 # Extract AccountId from session keys

# Stash account management
./scripts/setup-stash-account.sh            # Explain stash account setup
./scripts/generate-stash-account.sh         # Generate stash account for testing

# Legacy manual scripts
./scripts/generate-session-keys.sh          # Manual session key generation
./scripts/backup-keys.sh                    # Backup validator keys
./scripts/restore-keys.sh                   # Restore from backup
./scripts/rotate-session-keys.sh            # Rotate existing keys
```

### **Network Operations**
```bash
./scripts/health-check.sh              # Comprehensive health check
./scripts/peer-info.sh                 # Show connected peers
./scripts/sync-status.sh               # Check synchronization
./scripts/performance-metrics.sh       # Performance statistics
```

---

## 🎯 Validation Request Process

### **What Happens When You Submit**

1. **Automated Validation**
   - System checks your validator configuration
   - Verifies network connectivity and sync status
   - Validates session key format and security

2. **Security Review**
   - Network administrators review your request
   - Validator identity and reputation assessment
   - Technical configuration verification

3. **Network Admission**
   - Upon approval, your validator is added to the active set
   - You'll receive confirmation and monitoring access
   - Begin earning validation rewards and network participation

### **Request Requirements**
- ✅ **Stable network connection** (>99% uptime expected)
- ✅ **Valid session keys** generated by your validator
- ✅ **Synchronized node** with current blockchain state
- ✅ **Contact information** for network communications
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

### **Monitoring Integration**
```bash
# Enable Prometheus metrics
./scripts/setup-monitoring.sh

# Configure external monitoring
./scripts/configure-grafana.sh

# Set up alerting
./scripts/setup-alerts.sh
```

### **Performance Optimization**
```bash
# Optimize for your hardware
./scripts/optimize-performance.sh

# Configure resource limits
./scripts/set-resource-limits.sh

# Enable fast sync (for new validators)
./scripts/enable-fast-sync.sh
```

---

## 🆘 Troubleshooting

### **Common Issues**

#### **Binary Not Found**
```
❌ Fennel node binary not found!
```
**Solution**: Run the installer first
```bash
./install.sh
```

#### **Network Connection Failed**
```
❌ Failed to connect to bootnodes
```
**Solutions**:
1. Check firewall: `sudo ufw allow 30333/tcp`
2. Verify connectivity: `./scripts/test-connectivity.sh`
3. Check port availability: `netstat -ln | grep :30333`

#### **Sync Issues**
```
⚠️ Node not synchronized
```
**Solutions**:
1. Wait for initial sync (can take 30-60 minutes)
2. Check peers: `./scripts/peer-info.sh`
3. Restart with fast sync: `./validate.sh restart --fast-sync`

#### **Key Generation Failed**
```
❌ Failed to generate session keys
```
**Solutions**:
1. Ensure validator is running: `./validate.sh status`
2. Check RPC access: `curl -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' http://localhost:9944`
3. Restart validator: `./validate.sh restart`

### **Getting Help**

1. **Check logs**: `./validate.sh logs`
2. **Run diagnostics**: `./scripts/diagnose.sh`
3. **Contact support**: Include diagnostics output
4. **Community**: Join the Fennel validator community

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

### **Network Governance**
- 🗳️ **Proposal Voting**: Participate in network decision-making
- 💡 **Improvement Proposals**: Submit network enhancements
- 🔧 **Technical Upgrades**: Vote on protocol improvements
- 🌍 **Community Building**: Help grow the Fennel ecosystem

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
- **Technical Issues**: Open an issue in this repository
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

## 🛠️ Utility Scripts

- **`./preflight-check.sh`** - Validate system requirements before setup
- **`./quick-start.sh`** - Complete setup in one command (recommended)
- **`./validator-status.sh`** - Comprehensive status dashboard
- **`./troubleshoot.sh`** - Automatically diagnose and fix issues
- **`./reset-validator.sh`** - Reset validator to clean state

---

## ⚡ Quick Links

- 🚀 **[Quick Start](#-ultra-quick-start-recommended-for-beginners)** - Get started in 5 minutes
- 🔐 **[Security Guide](#-security--best-practices)** - Secure your validator
- 🎯 **[Submit Request](#-validation-request-process)** - Join the network
- 🆘 **[Get Help](#-troubleshooting)** - Troubleshooting guide

---

**Ready to become a Fennel validator? Let's get started!** 🌱

*Questions? Contact the Fennel team or open an issue in this repository.* 