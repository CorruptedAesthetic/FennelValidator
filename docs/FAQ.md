# 🤔 Frequently Asked Questions - Fennel Validator

## 🚀 Getting Started

### Q: I'm completely new to blockchain. Can I still run a validator?
**A:** Absolutely! Our setup is designed for beginners:
1. Download the repository
2. Run `./install.sh`
3. Run `./setup-validator.sh`
4. Run `./validate.sh start`

Follow the prompts - everything is automated and explained step-by-step.

### Q: How long does the complete setup take?
**A:** 
- **Download & Install**: 5-10 minutes
- **Configuration**: 5 minutes (answering prompts)
- **Initial Sync**: 15-30 minutes (blockchain download)
- **Registration**: 5 minutes (generating files)

**Total**: About 45 minutes to fully operational validator.

### Q: What are the minimum system requirements?
**A:** 
- **OS**: Linux, macOS, or Windows (with WSL2)
- **CPU**: 2 cores minimum (any modern computer)
- **Memory**: 4GB RAM (8GB recommended)
- **Storage**: 50GB free space (SSD recommended)
- **Network**: Stable internet, port 30333 accessible

### Q: Is it safe for beginners?
**A:** Yes! Security is built-in:
- ✅ **Automatic firewall** configuration
- ✅ **File permissions** secured automatically
- ✅ **No manual key sharing** - Fennel Labs handles registration
- ✅ **Local-only RPC** access by default
- ✅ **Safe defaults** for all options

## 📦 Installation & Setup

### Q: Do I need to install anything before starting?
**A:** Minimal requirements (usually pre-installed):
- `curl` and `wget` for downloads
- `git` for repository cloning (optional)
- Internet connection

Our `install.sh` script handles everything else automatically.

### Q: Can I run multiple validators on the same machine?
**A:** Not recommended for beginners. Each validator needs:
- Unique ports (30333, 9944, 9615)
- Separate data directories
- Different validator names

Better to start with one validator and learn the basics first.

### Q: What if the installation fails?
**A:** 
1. **Check internet connection**: Download requires stable internet
2. **Run diagnostics**: `./tools/preflight-check.sh`
3. **Try again**: Most issues are temporary network problems
4. **Reset and retry**: `./tools/reset-validator.sh` then start over

### Q: How do I know if the installation worked?
**A:**
```bash
./validate.sh status
```
Should show "✅ Validator is running" if successful.

## 🔧 Configuration

### Q: What validator name should I choose?
**A:** Pick something unique and identifiable:
- ✅ **Good**: "Alice-Tech-Validator", "University-Blockchain-Lab"
- ❌ **Avoid**: Special characters, very long names, generic names like "Validator1"

### Q: Should I change the default ports?
**A:** For beginners, use defaults:
- **P2P Port**: 30333 (for connecting to other validators)
- **RPC Port**: 9944 (for local monitoring tools)
- **Metrics Port**: 9615 (for performance monitoring)

Only change if you get "port already in use" errors.

### Q: What's the difference between staging and mainnet?
**A:** 
- **Staging**: Learning environment, no real money, safe for testing
- **Mainnet**: Production network with real value (not available yet)

**Always start with staging** to learn validator operations safely.

## 🔑 Keys & Security

### Q: What are session keys and why do I need them?
**A:** Session keys are like your validator's ID card:
- **Generated automatically** during setup
- **Prove your validator's identity** to the network
- **Required for earning rewards**
- **Managed securely** by our scripts

### Q: Do I need to share my private keys with anyone?
**A:** **Never!** Our secure process:
1. ✅ **Keys generated locally** on your machine
2. ✅ **Only public information** shared with Fennel Labs
3. ✅ **Private keys stay private** and secured
4. ✅ **Fennel Labs uses admin powers** to register you

### Q: Where are my keys stored and how are they protected?
**A:** 
- **Location**: `validator-data/` directory
- **Permissions**: Read-only for your user account
- **Backup**: Copy this directory to secure storage
- **Protection**: Never uploaded or shared automatically

### Q: What if I lose my keys?
**A:** 
- **Session keys**: Can be regenerated with `./scripts/generate-session-keys.sh`
- **Stash account**: Can be recovered with seed phrase (saved securely)
- **Validator data**: Keep regular backups of `validator-data/` directory

## 🌐 Network & Connectivity

### Q: My validator shows "0 peers connected" - is this bad?
**A:** Yes, this indicates connectivity issues:
```bash
# Check firewall
sudo ufw allow 30333/tcp

# Restart validator
./validate.sh restart

# Run diagnostics
./tools/troubleshoot.sh
```

### Q: How many peers should I have connected?
**A:** 
- **Minimum**: 1-2 peers (validator will work)
- **Good**: 5-15 peers (recommended range)
- **Excellent**: 15+ peers (optimal connectivity)

### Q: Can I run a validator behind a firewall/NAT?
**A:** Yes, but port 30333 must be accessible:
- **Home router**: Forward port 30333 to your validator machine
- **Corporate firewall**: Request port 30333 outbound access
- **Cloud hosting**: Ensure security groups allow port 30333

### Q: Why does initial sync take so long?
**A:** Your validator is downloading the entire blockchain history:
- **Staging network**: ~2-5GB of data
- **Speed depends on**: Internet connection and network traffic
- **Progress**: Check `./validate.sh logs` for sync status

## 💰 Rewards & Registration

### Q: When do I start earning rewards?
**A:** After completing registration:
1. **Generate keys**: `./scripts/generate-session-keys.sh`
2. **Complete registration**: `./tools/complete-registration.sh`
3. **Submit to Fennel Labs**: Send the generated file
4. **Wait for activation**: Fennel Labs adds you to validator set
5. **Start earning**: Once active in the validator set

### Q: How much can I earn as a validator?
**A:** 
- **Staging network**: No real monetary rewards (learning environment)
- **Future mainnet**: Rewards will depend on network economics
- **Purpose**: Focus on learning and contributing to network security

### Q: What information do I need to send to Fennel Labs?
**A:** Only public information automatically generated:
- Your validator's public address
- Session keys (public portion only)
- Validator name and configuration

**Never share**: Private keys, seed phrases, or passwords.

## 🛠️ Troubleshooting

### Q: My validator stopped working. What should I do?
**A:** Step-by-step diagnosis:
```bash
# Check if still running
./validate.sh status

# If stopped, restart
./validate.sh restart

# Check for errors
./validate.sh logs

# Run full diagnosis
./tools/troubleshoot.sh
```

### Q: How do I update my validator?
**A:** Simple update process:
```bash
# Stop validator
./validate.sh stop

# Update software
./install.sh

# Restart validator
./validate.sh start
```

### Q: Something went wrong. How do I start over?
**A:** Complete reset (keeps backups):
```bash
./tools/reset-validator.sh
```
Then follow the setup process again from the beginning.

### Q: How do I monitor my validator's performance?
**A:** Several monitoring options:
```bash
# Quick status
./validate.sh status

# Detailed information
./tools/validator-status.sh

# Real-time logs
./validate.sh logs

# Network health
curl -s http://localhost:9944/health
```

## 🏢 Advanced Questions

### Q: Can I run this on a VPS/cloud server?
**A:** Yes! Cloud hosting is often better for validators:
- **Advantages**: Better uptime, faster internet, dedicated resources
- **Popular providers**: AWS, Google Cloud, DigitalOcean, Oracle Cloud
- **Minimum specs**: 2 CPU, 4GB RAM, 50GB storage

### Q: Should I use Docker or run natively?
**A:** For beginners, our native setup is easier:
- **Native**: What our scripts use (recommended for beginners)
- **Docker**: Advanced users only (not officially supported)

### Q: How do I backup my validator?
**A:** Essential files to backup:
```bash
# Create backup
tar -czf validator-backup-$(date +%Y%m%d).tar.gz validator-data/ config/

# Store securely
# Copy to external drive, cloud storage, etc.
```

### Q: Can I migrate my validator to a different machine?
**A:** Yes, with careful steps:
1. **Stop old validator**: `./validate.sh stop`
2. **Backup data**: Copy `validator-data/` and `config/`
3. **Set up new machine**: Install FennelValidator
4. **Restore data**: Copy backed up directories
5. **Start new validator**: `./validate.sh start`

**Important**: Never run the same validator on multiple machines simultaneously!

## 🆘 Getting Help

### Q: Where can I get help if I'm stuck?
**A:** Multiple support channels:
1. **Built-in diagnostics**: `./tools/troubleshoot.sh`
2. **Documentation**: All files in `docs/` directory
3. **Community**: [Discord/forum links will be provided]
4. **GitHub Issues**: Report bugs and problems

### Q: How do I report a bug or suggestion?
**A:** 
1. **Check existing issues**: GitHub repository issues
2. **Run diagnostics**: Include output from `./tools/troubleshoot.sh`
3. **Describe problem**: What you expected vs what happened
4. **Environment details**: OS, specs, network setup

Remember: **No question is too basic!** The Fennel community is here to help you succeed as a validator.
**A:** Run `./start.sh` → Choose "Troubleshoot" - it will diagnose and fix common issues automatically.

### Q: Can I reconfigure my validator?
**A:** Yes! Run `./start.sh` → Choose "Setup/Reconfigure Validator"

### Q: How do I start over completely?
**A:** Run `./start.sh` → Choose "Reset Validator" - it will backup your keys and start fresh.

## Operational Questions

### Q: Do I need to keep my computer on 24/7?
**A:** Yes, validators should run continuously for best results.

### Q: How do I check if my validator is running?
**A:** Run `./start.sh` → Choose "Check Status"

### Q: How do I view logs?
**A:** Run `./start.sh` → Choose "View Logs"

### Q: How do I restart my validator?
**A:** Run `./start.sh` → Choose "Restart Validator"

## Key Management

### Q: What's the difference between session keys and stash account?
**A:**
- **Session keys**: Used for validator operations (creating blocks, consensus)
- **Stash account**: Your main account that controls the validator and receives rewards

### Q: Where are my keys stored?
**A:** All keys are securely stored in the `validator-data/` directory:
- `session-keys.json` - Your validator operational keys
- `stash-account.json` - Your main validator account

### Q: How do I backup my keys?
**A:** Keep secure backups of the entire `validator-data/` directory, especially:
- The secret phrase from your stash account
- Store in multiple secure locations

### Q: What if I lose my keys?
**A:** You'll need to set up a new validator. Always keep backups!

## Registration Questions

### Q: What do I send to Fennel Labs?
**A:** Send only one file: `validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt`

### Q: What information gets shared with Fennel Labs?
**A:** Only public information:
- Your stash account address
- Your session keys
- Your validator name
- **Your secret phrases stay private with you**

### Q: Do I need to call session.setKeys() manually?
**A:** No! Fennel Labs handles all registration steps using sudo privileges:
- They fund your stash account
- They bind your session keys
- They add you to the validator set

### Q: When will my validator be active?
**A:** After Fennel Labs:
1. Reviews your submission
2. Processes your registration (all handled via sudo)
3. Confirms your validator is active

### Q: Do I need real money/tokens?
**A:** No, Fennel Labs will provide testnet tokens and handle all funding.

## File Organization

### Q: Where are all my validator files?
**A:** All validator files are organized in the `validator-data/` directory:
- `session-keys.json` - Your validator keys
- `stash-account.json` - Your main account
- `COMPLETE-REGISTRATION-SUBMISSION.txt` - File to send to Fennel Labs
- `complete-validator-setup-instructions.txt` - Your reference

### Q: Can I move the validator-data directory?
**A:** It's not recommended. The scripts expect files in this location. If you must move it, update all references in the scripts.

## Troubleshooting

### Q: My validator won't start
**A:** Run `./start.sh` → Choose "Troubleshoot" - it will diagnose and fix the issue.

### Q: No peers connected
**A:** This is normal for the first few minutes. If it persists:
- Check that port 30333 is open
- The troubleshooter will check this automatically

### Q: RPC not responding
**A:** The validator may still be starting. Wait 2-3 minutes and check status again.

### Q: I see permission errors
**A:** Run `./start.sh` → Choose "Troubleshoot" - it will fix file permissions automatically.

## Technical Questions

### Q: What dependencies are required?
**A:** The setup automatically installs all required dependencies:
- **curl/wget** - For downloading files
- **jq** - For processing JSON data
- **git** - For version control
- **netstat** - For checking ports
- **UFW** - For firewall (Linux)

### Q: What if I'm missing dependencies?
**A:** The setup process handles this automatically. If you encounter issues:
1. Run `./start.sh` → Choose "Install Dependencies"
2. The system will detect your OS and install what's needed

### Q: What ports does the validator use?
**A:**
- **30333** - P2P communication (open to internet)
- **9944** - RPC (localhost only)
- **9615** - Prometheus metrics (localhost only)

## Security Questions

### Q: How secure is the setup?
**A:** Very secure! The setup automatically:
- Configures UFW firewall
- Secures all key files with 600 permissions
- Only exposes necessary ports
- Keeps RPC and metrics localhost-only

### Q: What information is safe to share?
**A:** Safe to share:
- ✅ Your stash account address
- ✅ Your session keys
- ✅ Your validator name

Never share:
- ❌ Your secret phrases
- ❌ Contents of stash-account.json
- ❌ Private keys

### Q: How do I know my setup is secure?
**A:** Run `./start.sh` → Choose "Check Status" - it shows your security status.

## One-Command Management

### Q: What's the main command I need to remember?
**A:** Just remember: `./start.sh`

This single command gives you access to:
- Initial setup
- Status monitoring
- Troubleshooting
- Registration management
- All maintenance tasks

### Q: Do I need to learn multiple commands?
**A:** No! The menu system handles everything. You only need to know `./start.sh`.

## Need More Help?

1. **Troubleshoot**: Run `./start.sh` → Choose "Troubleshoot"
2. **Documentation**: Check [BEGINNERS-GUIDE.md](BEGINNERS-GUIDE.md) for step-by-step instructions
3. **Technical details**: See [README-DETAILED.md](README-DETAILED.md) for advanced information
4. **Examples**: Review [EXAMPLE-VALIDATOR-SETUP.md](EXAMPLE-VALIDATOR-SETUP.md) to see what to expect 