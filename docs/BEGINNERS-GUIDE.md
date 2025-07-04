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

### Step 3: Check Your System

Run the pre-flight check:
```bash
./preflight-check.sh
```

This checks if your system is ready. If you see any ❌ marks:
- Follow the install hints shown
- Run the check again

### Step 4: Run the Quick Start

When all checks pass, run:
```bash
./quick-start.sh
```

**What happens:**
1. **System Check** - Verifies everything is ready
2. **Installation** - Downloads the validator software
3. **Configuration** - You'll choose a name for your validator
4. **Secure Launch** - Starts your validator with security
5. **Registration** - Creates files to send to Fennel Labs

**Time needed:** About 5-10 minutes

### Step 5: Follow the Prompts

The script will:
- Ask for your validator name (example: "MyCompany-Validator")
- Show progress at each step
- Ask you to press Enter to continue

**Tips:**
- For most questions, just press Enter to use defaults
- Choose a unique validator name
- Write down any secret phrases shown!

## After Setup - What You Get

### Important Files Created

1. **COMPLETE-REGISTRATION-SUBMISSION.txt**
   - Send this to Fennel Labs
   - Contains your validator information

2. **SESSION-SETKEYS-INSTRUCTIONS.txt**
   - Keep for your reference
   - Instructions for later steps

3. **session-keys.json**
   - Your validator's operational keys
   - Keep secure!

4. **stash-account.json**
   - Your validator's main account
   - Contains secret phrase - KEEP VERY SECURE!

### What to Do Next

1. **Send Registration to Fennel Labs**
   - Email: [contact info]
   - Attach: COMPLETE-REGISTRATION-SUBMISSION.txt

2. **Wait for Response**
   - Fennel Labs reviews your submission
   - They send testnet tokens to your account
   - They provide further instructions

3. **Complete Registration**
   - Follow SESSION-SETKEYS-INSTRUCTIONS.txt
   - Notify Fennel Labs when done

## Managing Your Validator

### Check if Running
```bash
./validate.sh status
```

### View Logs
```bash
./validate.sh logs
```

### Stop Validator
```bash
./validate.sh stop
```

### Restart Validator
```bash
./validate.sh restart
```

## Common Questions

### Q: Is this safe?
A: Yes! The scripts:
- Set up a firewall
- Secure your keys with proper permissions
- Only allow local access to sensitive functions

### Q: What if something goes wrong?
A: The scripts have error handling. If you see errors:
1. Read the error message
2. Check the troubleshooting section in README.md
3. Ask for help in the community

### Q: Do I need to keep my computer on?
A: Yes, validators should run 24/7 for best results. Consider using a dedicated machine or VPS.

### Q: What are session keys vs stash account?
- **Session Keys**: Used for validator operations (creating blocks)
- **Stash Account**: Your main account that holds funds and controls the validator

### Q: How do I backup my validator?
A: Keep safe copies of:
- `session-keys.json`
- `stash-account.json`
- The secret phrase from stash account

## Getting Help

If you need help:
1. Check EXAMPLE-VALIDATOR-SETUP.md for examples
2. Read the main README.md
3. Join the Fennel community channels
4. Open an issue on GitHub

## Security Tips

1. **Never share your secret phrase**
2. **Keep backups in a secure location**
3. **Don't run the validator as root user**
4. **Keep your system updated**

---

Ready to start? Go back to Step 1 and begin your validator journey! 🌱 