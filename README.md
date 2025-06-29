# Fennel Validator - Staging

**🧪 Learn Fennel validation in a safe, no-risk environment**

Perfect for partners new to blockchain validation. Learn, experiment, and master validator operations without financial risk.

## 🚀 Quick Start

### Prerequisites
- Linux, macOS, or Windows
- 2+ CPU cores, 4GB+ RAM, 50GB+ storage
- Internet connection

### 🚀 **Quick Start (3 Commands)**

```bash
# 1. Download and install
curl -sSL https://raw.githubusercontent.com/CALLSHIFT/FennelValidatorStaging/main/install.sh | bash

# 2. Configure your validator (interactive setup)
./setup-validator.sh

# 3. Start validating on staging network
./validate.sh start
```

**That's it!** You're now running a Fennel validator on the staging network.

### 🎓 **After Mastering Staging**

Ready for production? Check out [FennelValidatorProduction](../FennelValidatorProduction/) *(under development)*

## 📋 What This Does

- ✅ Downloads the latest Fennel validator software
- ✅ Auto-downloads latest chainspec from [fennel-solonet](https://github.com/CorruptedAesthetic/fennel-solonet)
- ✅ Automatically configures network connection  
- ✅ Generates secure validator keys
- ✅ Sets up monitoring and health checks  
- ✅ Starts your validator with optimal settings

## 🔧 Management Commands

```bash
# Check validator status
./validate.sh status

# Stop validator
./validate.sh stop

# Restart validator (auto-updates chainspec)
./validate.sh restart

# View logs
./validate.sh logs

# Manually update chainspec from fennel-solonet
./validate.sh update-chainspec

# Check network health
./scripts/health-check.sh

# Update to latest version
./scripts/update-validator.sh
```

## 🧪 **Staging Network Focus**

This repository is **exclusively for staging validation**:

- **✅ Perfect for Learning**: No financial risk, experiment freely
- **✅ Real Network Experience**: Connect to actual staging blockchain
- **✅ Full Feature Set**: All validator functionality without the stakes
- **✅ Safe Environment**: Make mistakes, learn, and improve
- **✅ Auto-Updates**: Automatically gets latest network configuration

**🎯 Goals:**
- Learn validator operations
- Practice emergency procedures  
- Test your infrastructure
- Build confidence before production

**🔄 Smart Update Behavior:**
- **Staging**: Auto-updates chainspec for latest testing environment
- **Production**: Would require manual coordination (see [FennelValidatorProduction](../FennelValidatorProduction/))

## 📊 Monitoring

Once running, you can monitor your validator:

- **Status**: `./validate.sh status`
- **Metrics**: `http://localhost:9615/metrics`
- **RPC**: `http://localhost:9944` (local only)
- **Logs**: `./validate.sh logs`

## 🆘 Support

- **📖 How Updates Work**: See [docs/simple-updates.md](docs/simple-updates.md) - **Start here!** Simple explanation of network updates
- **Troubleshooting**: See [docs/troubleshooting.md](docs/troubleshooting.md) - Common issues and solutions  
- **Security Guide**: See [docs/security-best-practices.md](docs/security-best-practices.md) - Security for staging
- **Learning Exercises**: See [docs/learning-exercises.md](docs/learning-exercises.md) - Hands-on practice scenarios
- **Learning Pathway**: See [STAGING_TO_PRODUCTION.md](STAGING_TO_PRODUCTION.md) - Complete learning guide
- **Issues**: Create an issue in this repository for support

## 🚀 Strategic Vision

- **🗺️ Governance Roadmap**: See [GOVERNANCE_ROADMAP.md](GOVERNANCE_ROADMAP.md) - Evolution from centralized to decentralized network management

## 🔒 Security

This validator setup follows security best practices:
- Keys are generated locally and never transmitted
- Firewall rules are automatically configured
- Read-only RPC access by default
- Isolated data storage

---

**Need help?** The setup process is interactive and will guide you through each step. If you encounter issues, check the troubleshooting guide or create an issue. 