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

## What You Get

After setup (~5-10 minutes), you'll have:
- ✅ A running validator node
- ✅ All required keys generated
- ✅ Security automatically configured
- ✅ Registration file ready for Fennel Labs

## Simple Commands

Just run `./start.sh` anytime to:
- Start/restart your validator
- Check status
- Generate registration
- View logs
- Access troubleshooting

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

1. Run `./start.sh` and choose "Advanced options" → "Troubleshoot"
2. Check [BEGINNERS-GUIDE.md](docs/BEGINNERS-GUIDE.md) for detailed instructions
3. See [FAQ.md](docs/FAQ.md) for common questions

## Important Files After Setup

After running setup, you'll have these important files:
- 📄 `COMPLETE-REGISTRATION-SUBMISSION.txt` - Send this to Fennel Labs
- 🔑 `session-keys.json` - Your validator keys (keep secure!)
- 🏦 `stash-account.json` - Your stash account (keep secure!)
- ⚙️ `config/validator.conf` - Your validator settings

## For Fennel Labs

Send them the file: **`COMPLETE-REGISTRATION-SUBMISSION.txt`**

They will:
1. Review your submission
2. Send you testnet tokens
3. Guide you through final registration

## ✨ Features

- **One-command setup** - Complete installation in ~5 minutes
- **Automatic dependency installation** - All required tools installed for you  
- **Secure by default** - Automatic firewall configuration
- **Built-in monitoring** - Real-time status dashboard
- **Easy troubleshooting** - Self-diagnosing issues
- **Clean reset** - Start fresh anytime with backup

## 📋 Prerequisites

The setup script will automatically install all required dependencies for you:
- Linux (Ubuntu/Debian recommended) or macOS
- 4GB+ RAM
- 50GB+ available disk space
- Internet connection

Required tools (automatically installed if missing):
- curl, wget, jq, git
- netstat, ps, and other system utilities
- UFW firewall (on Linux)

---

**Ready to validate?** Run `./start.sh` and let's begin! 🌱 