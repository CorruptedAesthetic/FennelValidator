# 🌱 Fennel Validator

**The simplest way to run a Fennel Network validator**

## 🚀 Quick Start (Just One Command!)

```bash
# 1. Clone this repository
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator

# 2. Run the start script
./start.sh
```

**That's it!** The script will guide you through everything. No technical knowledge required.

### What Happens During Setup:
1. **System Check** - Verifies your system meets requirements
2. **Dependency Installation** - Automatically installs required tools
3. **Validator Configuration** - You choose a name and basic settings
4. **Security Hardening** - Configures firewall and permissions
5. **Key Generation** - Creates your validator and stash account keys
6. **Registration Preparation** - Generates submission file for Fennel Labs

**Total time:** 5-10 minutes | **Difficulty:** Beginner-friendly

## What You Get

After setup (~5-10 minutes), you'll have:
- ✅ A running validator node
- ✅ All required keys generated
- ✅ Security automatically configured
- ✅ Registration file ready for Fennel Labs

## Simple Commands

**Everything through one command:** `./start.sh`

The interactive menu gives you access to:
- **🚀 Start/Setup** - First-time setup or start existing validator
- **📊 Check Status** - View validator health and performance
- **🔧 Troubleshoot** - Diagnose and fix common issues
- **📋 Generate Registration** - Create/recreate submission files
- **📱 View Logs** - Monitor validator activity in real-time
- **🔄 Restart** - Restart validator service
- **🛠️ Advanced Options** - Access all utility tools

**Pro tip:** Bookmark this command - it's the only one you'll need to remember!

## 📁 Clean & Simple Structure

```
FennelValidator/
│
├── 🟢 start.sh           # ← START HERE! The only script you need
│
├── Core Scripts (run automatically)
│   ├── install.sh        # Installs validator
│   ├── setup-validator.sh # Configures settings
│   └── validate.sh       # Manages validator
│
├── 📂 tools/             # Utilities (accessed via start.sh menu)
│   ├── quick-setup.sh    # Complete setup process
│   ├── secure-launch.sh  # Security hardening
│   ├── validator-status.sh # Status dashboard
│   ├── troubleshoot.sh   # Fix issues
│   ├── reset-validator.sh # Clean reset
│   └── internal/         # Helper scripts
│
├── 📂 config/            # Your settings (created during setup)
├── 📂 data/              # Blockchain data (created automatically)
└── 📂 docs/              # Documentation
    ├── FAQ.md            # Common questions
    ├── BEGINNERS-GUIDE.md # Step-by-step guide
    └── README-DETAILED.md # Technical details
```

## Need Help?

**Quick Solutions:**
1. **Run `./start.sh`** → Choose "🔧 Troubleshoot" for automatic diagnosis
2. **Check [FAQ.md](docs/FAQ.md)** → Answers to 50+ common questions
3. **Read [BEGINNERS-GUIDE.md](docs/BEGINNERS-GUIDE.md)** → Complete step-by-step walkthrough

**Still Stuck?**
- Run `./start.sh` → "Advanced Options" → "Reset Validator" (keeps backups)
- Check [EXAMPLE-VALIDATOR-SETUP.md](docs/EXAMPLE-VALIDATOR-SETUP.md) for real setup examples
- Review [README-DETAILED.md](docs/README-DETAILED.md) for technical details

**Remember:** The troubleshoot option fixes 90% of common issues automatically!

## Important Files After Setup

After running setup, you'll have these important files:
- 📄 `validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt` - Send this to Fennel Labs
- 🔑 `validator-data/session-keys.json` - Your validator keys (keep secure!)
- 🏦 `validator-data/stash-account.json` - Your stash account (keep secure!)
- ⚙️ `config/validator.conf` - Your validator settings

## For Fennel Labs

**What to Send:** Only the file `validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt`

**What They Do (Automatically):**
1. ✅ Review your validator submission
2. ✅ Fund your stash account with testnet tokens (via sudo)
3. ✅ Bind your session keys to your stash account (via sudo)
4. ✅ Add your validator to the active validator set (via sudo)
5. ✅ Confirm when your validator is active and earning rewards

**What You Do:** Nothing else! Your secret phrases stay private on your machine.

**Contact Methods:**
- Email: [Contact details will be provided]
- Discord: [Community channels will be provided]
- Include the complete registration file as attachment

**Response Time:** Typically 24-48 hours for registration processing.

## ✨ Features

- **🔧 One-command setup** - Complete installation in ~5 minutes
- **🤖 Automatic dependency installation** - All required tools installed automatically
- **🛡️ Secure by default** - Automatic firewall configuration and key protection
- **📊 Built-in monitoring** - Real-time status dashboard and performance metrics
- **🔍 Easy troubleshooting** - Self-diagnosing issues with automatic fixes
- **🔄 Clean reset** - Start fresh anytime with automatic backups
- **📱 Interactive menu** - Simple, user-friendly interface
- **🌍 Multi-platform** - Works on Linux, macOS, and Windows (WSL2)
- **☁️ Cloud-ready** - Perfect for VPS and dedicated server deployments
- **🔐 Privacy-first** - Your secret keys never leave your machine

## 🎖️ Why Choose FennelValidator?

**For Beginners:**
- No blockchain knowledge required
- Step-by-step guided setup
- Built-in security best practices
- Comprehensive troubleshooting

**For Experienced Users:**
- Clean, maintainable code
- Modular architecture
- Advanced customization options
- Professional monitoring tools

**For Production:**
- Battle-tested deployment scripts
- Automatic failover handling
- Performance optimization
- Enterprise-grade security

## 📋 Prerequisites

**System Requirements:**
- **OS**: Linux (Ubuntu/Debian recommended), macOS, or Windows with WSL2
- **CPU**: 2+ cores (any modern processor)
- **RAM**: 4GB minimum (8GB recommended for better performance)
- **Storage**: 50GB+ available disk space (SSD recommended)
- **Network**: Stable internet connection (24/7 uptime recommended)
- **Ports**: Ability to open port 30333 (for P2P connections)

**Auto-Installed Dependencies:**
The setup script will automatically install all required tools:
- `curl`, `wget`, `jq`, `git` - For downloading and processing
- `netstat`, `ps` - For system monitoring
- `ufw` - For firewall management (Linux only)

**No manual installation needed!** The script handles everything automatically.

## 💻 Platform-Specific Setup

### Ubuntu/Debian Linux (Recommended)
```bash
# Most straightforward - everything works out of the box
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator
./start.sh
```

### macOS
```bash
# May need to install Xcode command line tools
xcode-select --install
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator
./start.sh
```

### Windows (WSL2)
```bash
# First install WSL2 and Ubuntu
wsl --install -d Ubuntu
# Then in Ubuntu terminal:
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator
./start.sh
```

### Cloud Servers (VPS/Oracle/AWS/etc.)
```bash
# Great for 24/7 uptime - same setup process
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator
./start.sh
```

## 🚨 Security & Best Practices

**Built-in Security Features:**
- ✅ **Firewall Auto-Configuration** - Only necessary ports exposed
- ✅ **File Permissions** - All keys secured with 600 permissions
- ✅ **Local RPC Access** - Web interfaces only accessible locally
- ✅ **Process Isolation** - Validator runs with minimal privileges

**What You Should Do:**
- 🔐 **Backup Your Keys** - Copy `validator-data/` to secure storage
- 🌐 **Use Stable Internet** - Ensure 24/7 connectivity for best rewards
- 🔄 **Regular Updates** - Run `./start.sh` monthly for updates
- 📊 **Monitor Performance** - Check validator status daily

**What You Should NEVER Do:**
- ❌ Don't share your secret phrases or seed words
- ❌ Don't run validator on multiple machines simultaneously
- ❌ Don't expose RPC ports to the internet
- ❌ Don't skip backups of your validator-data directory

## 🔧 Managing Your Validator

**Daily Operations:**
```bash
./start.sh                    # Access all functions
```

**Quick Status Check:**
```bash
./start.sh                    # → Choose "📊 Check Status"
```

**View Live Logs:**
```bash
./start.sh                    # → Choose "📱 View Logs"
```

**Restart After Issues:**
```bash
./start.sh                    # → Choose "🔄 Restart"
```

**Fix Problems:**
```bash
./start.sh                    # → Choose "🔧 Troubleshoot"
```

## 🎯 What Success Looks Like

**After Setup Complete:**
- ✅ Validator process running (`ps aux | grep fennel-node`)
- ✅ Connected to 5+ peers
- ✅ Syncing or fully synced with network
- ✅ Session keys generated and saved
- ✅ Registration file created for Fennel Labs
- ✅ Firewall configured and active

**After Fennel Labs Registration:**
- ✅ Validator active in validator set
- ✅ Producing blocks and earning rewards
- ✅ Appearing in network telemetry
- ✅ Stable uptime and performance

**Performance Indicators:**
- **Peer Count:** 5-15+ connected peers
- **Block Production:** Regular block authoring
- **Finalization:** Participating in GRANDPA consensus
- **Uptime:** 99%+ availability

---

## 🌟 Ready to Start?

**New to blockchain?** Start with our [BEGINNERS-GUIDE.md](docs/BEGINNERS-GUIDE.md)

**Ready to dive in?** Run these commands:
```bash
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator
./start.sh
```

**Need help?** Check our [FAQ.md](docs/FAQ.md) - we've answered 50+ common questions!

---

**Let's build the future of decentralized networks together!** 🌱🚀