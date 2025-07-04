# Frequently Asked Questions

## General Questions

### Q: Do I need technical experience?
**A:** No! Just follow the prompts in `./start.sh`. Everything is automated.

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
- Limit RPC access to localhost only

## Setup Questions

### Q: What if something goes wrong during setup?
**A:** Run `./start.sh` → Choose option 6 → Then option a (Troubleshoot)

### Q: Can I reconfigure my validator?
**A:** Yes! Run `./start.sh` → Choose option 6 → Then option c (Reconfigure)

### Q: How do I start over completely?
**A:** Run `./start.sh` → Choose option 6 → Then option b (Reset)

## Operational Questions

### Q: Do I need to keep my computer on 24/7?
**A:** Yes, validators should run continuously for best results.

### Q: How do I check if my validator is running?
**A:** Run `./start.sh` → Choose option 2 (Check status)

### Q: How do I view logs?
**A:** Run `./start.sh` → Choose option 4 (View logs)

## Key Management

### Q: What's the difference between session keys and stash account?
**A:**
- **Session keys**: Used for validator operations (creating blocks)
- **Stash account**: Your main account that controls the validator

### Q: How do I backup my keys?
**A:** Keep safe copies of:
- `session-keys.json`
- `stash-account.json`
- The secret phrase from your stash account

### Q: What if I lose my keys?
**A:** You'll need to set up a new validator. Always keep backups!

## Registration Questions

### Q: What do I send to Fennel Labs?
**A:** Send the file: `COMPLETE-REGISTRATION-SUBMISSION.txt`

### Q: When will my validator be active?
**A:** After Fennel Labs:
1. Reviews your submission
2. Sends you testnet tokens
3. You complete session.setKeys()
4. They add you to the validator set

### Q: Do I need real money/tokens?
**A:** No, Fennel Labs will provide testnet tokens for registration.

## Troubleshooting

### Q: My validator won't start
**A:** Run the troubleshooter: `./start.sh` → option 6 → option a

### Q: No peers connected
**A:** This is normal for the first few minutes. If it persists:
- Check firewall settings
- Ensure port 30333 is open
- Wait for network sync

### Q: RPC not responding
**A:** The validator may still be starting. Wait 2-3 minutes and check again.

## Technical Issues

### What dependencies are required?

The validator requires several system tools, but don't worry - they're all installed automatically:
- **curl/wget** - For downloading files
- **jq** - For processing JSON data
- **git** - For version control
- **netstat** - For checking ports
- **UFW** - For firewall (Linux)

If any are missing, run option 2 from the main menu or:
```bash
./tools/install-dependencies.sh
```

### What if I'm missing dependencies?

The setup process automatically installs all required dependencies. If you encounter issues:

1. **From main menu**: Choose option 2 "Install Dependencies"
2. **Manual install**: Run `./tools/install-dependencies.sh`
3. **System-specific**:
   - Ubuntu/Debian: Uses `apt-get`
   - CentOS/RHEL: Uses `yum`
   - macOS: Uses `brew` (installs Homebrew if needed)

## Need More Help?

1. Check [BEGINNERS-GUIDE.md](BEGINNERS-GUIDE.md) for detailed instructions
2. See [README-DETAILED.md](README-DETAILED.md) for technical details
3. Run the troubleshooter: `./start.sh` → Advanced → Troubleshoot 