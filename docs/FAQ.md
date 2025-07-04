# Frequently Asked Questions

## General Questions

### Q: Do I need technical experience?
**A:** No! Just run `./start.sh` and follow the interactive prompts. Everything is automated.

### Q: How long does setup take?
**A:** About 5-10 minutes for the complete setup.

### Q: What are the system requirements?
**A:** 
- Linux or macOS (Windows with WSL2)
- 4GB RAM minimum
- 50GB free disk space
- Stable internet connection

### Q: Is it safe?
**A:** Yes! The scripts automatically:
- Configure firewall rules
- Secure your keys with proper permissions
- Only share public information with Fennel Labs
- Keep your secret phrases private

## Setup Questions

### Q: How do I set up a validator?
**A:** Just run `./start.sh` - it detects first-time setup and guides you through everything.

### Q: What if something goes wrong during setup?
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