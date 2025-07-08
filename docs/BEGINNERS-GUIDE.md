# 🌱 Fennel Validator - Complete Beginners Guide

**Welcome to Fennel!** This guide will help you set up your validator step-by-step, even if you're new to blockchain technology.

## 🎯 What You'll Accomplish

By the end of this guide, you'll have:
- ✅ A running Fennel validator
- ✅ Session keys generated and ready
- ✅ Registration submitted to Fennel Labs
- ✅ Monitoring tools set up

**Time needed:** 30-45 minutes  
**Difficulty:** Beginner-friendly  
**Cost:** Free (staging network)

## 📋 Prerequisites

### Hardware Requirements
- **Operating System**: Linux, macOS, or Windows (with WSL2)
- **Memory**: 4GB RAM minimum (8GB recommended)
- **Storage**: 50GB free disk space (100GB recommended)
- **Internet**: Stable broadband connection (24/7 uptime recommended)
- **Network**: Ability to open port 30333 (for P2P connections)

### Skills Needed
- ✅ Basic command line usage (copy/paste commands)
- ✅ Ability to follow step-by-step instructions
- ✅ Basic understanding of file management

**Don't worry!** Our scripts handle all the complex blockchain setup automatically.

## 🚀 Complete Setup Process

### Step 1: Download the Repository

**Option A: Using Git (Recommended)**
```bash
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator
```

**Option B: Download ZIP**
1. Go to: https://github.com/CorruptedAesthetic/FennelValidator
2. Click "Code" → "Download ZIP"
3. Extract and open terminal in the FennelValidator folder

### Step 2: Run the Installation Script

```bash
chmod +x install.sh
./install.sh
```

**What this does:**
- Downloads the Fennel validator binary
- Sets up the blockchain configuration
- Prepares your system for validation

### Step 3: Configure Your Validator

```bash
./setup-validator.sh
```

**You'll be asked to configure:**
- **Validator Name**: Choose a unique name (e.g., "MyCompany-Validator")
- **Network Ports**: Use defaults (30333, 9944, 9615) unless you have conflicts
- **Data Directory**: Use default "./data" unless you want a custom location
- **Advanced Options**: Say "no" unless you need external access

### Step 4: Start Your Validator

```bash
./validate.sh start
```

**What happens:**
- Your validator connects to the Fennel staging network
- It begins syncing the blockchain (may take 15-30 minutes)
- Session keys are automatically generated
- The validator starts producing blocks

### Step 5: Generate Session Keys

```bash
./scripts/generate-session-keys.sh
```

**This creates:**
- `validator-data/session-keys.json` - Your validation keys
- Instructions for the next step

### Step 6: Complete Registration

```bash
./tools/complete-registration.sh
```

**This generates:**
- Your stash account (for receiving rewards)
- Complete registration file for Fennel Labs
- `COMPLETE-REGISTRATION-SUBMISSION.txt` file

### Step 7: Submit to Fennel Labs

**Send the file to Fennel Labs:**
1. Email: [Contact information will be provided]
2. Discord: [Community channel information]
3. Include: `validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt`

**Fennel Labs will:**
- Add your validator to the network
- Configure your session keys
- Enable you to start earning rewards

## 🔧 Managing Your Validator

### Check Status
```bash
./validate.sh status
```

### View Logs
```bash
./validate.sh logs
```

### Restart Validator
```bash
./validate.sh restart
```

### Stop Validator
```bash
./validate.sh stop
```

### Monitor Performance
```bash
./tools/validator-status.sh
```

## 🛡️ Security Best Practices

### Automatic Security (Built-in)
- ✅ **Firewall configured** - Only P2P port exposed
- ✅ **File permissions** - Session keys protected
- ✅ **Local RPC** - Web interface only accessible locally
- ✅ **Safe defaults** - All security options enabled

### Additional Recommendations
- **Keep software updated** - Run `./install.sh` monthly
- **Monitor regularly** - Check validator status daily
- **Backup keys** - Save `validator-data/` directory securely
- **Stable internet** - Ensure 24/7 connectivity for best rewards

## 📊 Monitoring Your Validator

### Quick Health Check
```bash
# Check if running
./validate.sh status

# View recent performance
./tools/validator-status.sh

# Check network connectivity
curl -s http://localhost:9944/health
```

### Understanding Output
- **Running**: Validator process is active
- **Syncing**: Downloading blockchain history
- **Validating**: Producing blocks and earning rewards
- **Peers**: Connected to other validators (should be 5+)

## 🎯 Troubleshooting Common Issues

### "No peers connected"
```bash
# Check firewall
sudo ufw status
sudo ufw allow 30333/tcp

# Restart validator
./validate.sh restart
```

### "Validator not syncing"
```bash
# Check logs for errors
./validate.sh logs

# Try troubleshooting script
./tools/troubleshoot.sh
```

### "Cannot connect to RPC"
```bash
# Restart validator
./validate.sh restart

# Check if process is running
ps aux | grep fennel-node
```

### Need Help?
1. **Run diagnostics**: `./tools/troubleshoot.sh`
2. **Check FAQ**: `docs/FAQ.md`
3. **Community support**: [Discord/forum links]
4. **Reset if needed**: `./tools/reset-validator.sh`

### Step 1: Open Your Terminal

**On Linux/macOS:**
- Press `Ctrl+Alt+T` (Linux) or `Cmd+Space` and type "Terminal" (macOS)

**On Windows:**
- Install WSL2 first: https://docs.microsoft.com/en-us/windows/wsl/install
- Open "Ubuntu" from Start Menu

### Step 2: Download the Repository

Copy and paste this command:
```bash
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator
```

### Step 3: Start the Setup

Run the main start script:
```bash
./start.sh
```

**What happens:**
1. **First-time detection** - Automatically detects this is your first run
2. **Complete Setup** - Guides you through the entire process
3. **System Check** - Verifies everything is ready
4. **Installation** - Downloads the validator software
5. **Configuration** - You'll choose a name for your validator
6. **Secure Launch** - Starts your validator with security hardening
7. **Key Generation** - Creates your validator keys
8. **Registration** - Creates files to send to Fennel Labs

**Time needed:** About 5-10 minutes

### Step 4: Follow the Prompts

The script will:
- Ask for your validator name (example: "MyCompany-Validator")
- Show progress at each step
- Ask you to press Enter to continue

**Tips:**
- For most questions, just press Enter to use defaults
- Choose a unique validator name
- The script securely handles all keys and files

## After Setup - What You Get

### Important Files Created (in `validator-data/`)

1. **`COMPLETE-REGISTRATION-SUBMISSION.txt`**
   - Send this to Fennel Labs
   - Contains your validator information (public info only)

2. **`session-keys.json`**
   - Your validator's operational keys
   - Keep secure!

3. **`stash-account.json`**
   - Your validator's main account
   - Contains secret phrase - KEEP VERY SECURE!

4. **`complete-validator-setup-instructions.txt`**
   - Reference instructions for your setup

### What to Do Next

1. **Send Registration to Fennel Labs**
   - Email: [contact info]
   - Attach: `validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt`

2. **Wait for Confirmation**
   - Fennel Labs handles all registration steps using sudo privileges
   - No manual session.setKeys() call needed from you
   - They send confirmation when your validator is registered

3. **Start Validating**
   - Your validator is already running!
   - You'll start earning rewards once registered

## Managing Your Validator

All management is done through the main menu:

```bash
./start.sh
```

**Menu Options:**
- **Check Status** - See if your validator is running
- **View Logs** - Check validator activity
- **Troubleshoot** - Fix any issues
- **Restart** - Restart your validator
- **Generate Registration** - Create new registration files

## Common Questions

### Q: Is this safe?
A: Yes! The scripts:
- Set up a firewall automatically
- Secure your keys with proper permissions
- Only share public information with Fennel Labs
- Keep your secret phrases private

### Q: What if something goes wrong?
A: Run `./start.sh` and choose "Troubleshoot" from the menu. The system will:
1. Diagnose common issues
2. Suggest fixes
3. Apply repairs automatically where possible

### Q: Do I need to keep my computer on?
A: Yes, validators should run 24/7 for best results. Consider using a dedicated machine or VPS.

### Q: What's the difference between session keys and stash account?
- **Session Keys**: Used for validator operations (creating blocks)
- **Stash Account**: Your main account that controls the validator and holds funds

### Q: How do I backup my validator?
A: Keep safe copies of the entire `validator-data/` directory:
- `session-keys.json`
- `stash-account.json`
- The secret phrase from stash account

### Q: What information gets shared with Fennel Labs?
A: Only public information:
- Your stash account address
- Your session keys
- Your validator name
- **Your secret phrases stay private with you**

## Getting Help

If you need help:
1. Run `./start.sh` → choose "Troubleshoot"
2. Check FAQ.md for common questions
3. Read the detailed README-DETAILED.md
4. Join the Fennel community channels
5. Open an issue on GitHub

## Security Features (Automatic)

The setup automatically applies:
- ✅ **Firewall configuration** - P2P port open, RPC/metrics secured
- ✅ **File permissions** - All keys secured to 600 permissions
- ✅ **Process isolation** - Validator runs with proper security
- ✅ **Safe sharing** - Only public info shared with network operators

## One-Command Management

Remember, you only need to know one command:
```bash
./start.sh
```

This gives you access to everything:
- Setup and configuration
- Status monitoring
- Troubleshooting
- Registration management

---

Ready to start? Go back to Step 1 and begin your validator journey! 🌱 