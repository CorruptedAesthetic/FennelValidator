# 🌱 Fennel Validator - Beginners Guide

This guide is for people with minimal technical experience who want to run a Fennel validator.

## What is a Validator?

A validator is a computer that helps run the Fennel blockchain network by:
- ✓ Verifying transactions
- ✓ Creating new blocks
- ✓ Maintaining network security

As a validator, you'll earn rewards for helping secure the network!

## Prerequisites (What You Need)

### Hardware
- **Computer**: Linux or macOS (Windows with WSL2 also works)
- **Memory**: At least 4GB RAM
- **Storage**: At least 50GB free disk space
- **Internet**: Stable connection (24/7 uptime recommended)

### Basic Skills
- ✓ Opening a terminal/command line
- ✓ Copy and paste commands
- ✓ Following step-by-step instructions

That's it! The scripts handle all the complex parts.

## Step-by-Step Setup Process

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