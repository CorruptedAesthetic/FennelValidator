# Example Validator Setup

This file shows exactly what happens when you set up a new validator using this repository.

## Fresh Setup Process

### 1. Clone the Repository
```bash
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator
```

### 2. Run the Start Script
```bash
./start.sh
```

**What happens on first run:**
- Automatically detects this is your first time
- Runs complete setup process
- No additional commands needed

**Interactive setup includes:**
- Validator name: e.g., "MyCompany-Validator"
- Network configuration (defaults work for most)
- Security hardening
- Key generation
- Registration file creation

## Step-by-Step Process

### Installation & Configuration
The script automatically:
- Downloads Fennel validator binary
- Downloads chain specification
- Sets up directory structure
- Configures your validator settings

### Security Hardening
Automatically applies:
- Firewall rules (P2P port open, RPC/metrics localhost-only)
- File permissions secured (600 for keys)
- RPC methods set to safe mode
- Validator process isolation

### Key Generation
Creates:
- Session keys (for consensus operations)
- Stash account (for validator identity)
- All keys secured with proper permissions

### Registration Preparation
Generates:
- Complete registration file for Fennel Labs
- Reference instructions for your records

## Example Files Generated

After running the setup, you'll have these files:

```
FennelValidator/
├── config/
│   └── validator.conf                              # Your validator settings
├── validator-data/                                 # All validator files (secure!)
│   ├── session-keys.json                          # Your session keys
│   ├── stash-account.json                         # Your stash account
│   ├── COMPLETE-REGISTRATION-SUBMISSION.txt       # Send to Fennel Labs
│   └── complete-validator-setup-instructions.txt  # Your reference
├── data/                                          # Blockchain data
└── logs/                                          # Log files
```

## Example Validator Names

Choose a unique name for your validator:
- `MyCompany-Validator`
- `University-Node-1`
- `Alice-Staging-Val`
- `PoweredByOrg-Validator`

## What Gets Sent to Fennel Labs

The `validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt` file contains:
- Your validator name
- Your stash account address (public)
- Your session keys (public)
- Setup confirmation

**Important:** Only public information is shared. Your secret phrases remain private.

## Security Features

### Automatic Security Hardening
- ✅ UFW firewall configured
- ✅ Port 30333 open for P2P
- ✅ RPC/metrics secured to localhost only
- ✅ Session keys protected with 600 permissions
- ✅ Stash account secured with 600 permissions

### Safe Information Sharing
- ✅ Only public addresses and keys shared
- ✅ Secret phrases kept private
- ✅ No manual session.setKeys() required
- ✅ Fennel Labs handles registration via sudo

## Managing Your Validator

After setup, use the main menu for all operations:

```bash
./start.sh
```

**Available options:**
- Check validator status
- View logs
- Restart validator
- Generate new registration files
- Troubleshoot issues
- Reset validator (if needed)

## Registration Process

### What You Do
1. Run `./start.sh` (setup completes automatically)
2. Send `validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt` to Fennel Labs
3. Wait for confirmation

### What Fennel Labs Does
1. Reviews your submission
2. Funds your stash account with testnet tokens (using sudo)
3. Binds your session keys to your stash account (using sudo)
4. Adds your validator to the active set
5. Confirms your validator is active

### No Manual Steps Required
- ❌ No manual session.setKeys() call needed
- ❌ No secret phrase sharing required
- ❌ No manual funding of accounts
- ✅ Fennel Labs handles everything via sudo privileges

## File Locations

All sensitive files are organized in the `validator-data/` directory:
- **`session-keys.json`** - Your validator operational keys
- **`stash-account.json`** - Your main validator account
- **`COMPLETE-REGISTRATION-SUBMISSION.txt`** - File to send to Fennel Labs
- **`complete-validator-setup-instructions.txt`** - Your reference

## Backup Strategy

Keep secure backups of:
- Entire `validator-data/` directory
- Especially the secret phrase from your stash account
- Store in multiple secure locations

## Security Notes

- ✅ All keys generated locally
- ✅ Secret phrases never leave your system
- ✅ Only public information shared with network operators
- ✅ File permissions automatically secured
- ✅ Firewall automatically configured
- ✅ Process isolation applied

## Next Steps After Setup

1. **Send registration:** Email `validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt` to Fennel Labs
2. **Monitor status:** Use `./start.sh` → "Check Status"
3. **View logs:** Use `./start.sh` → "View Logs"
4. **Wait for confirmation:** Fennel Labs will confirm when you're registered
5. **Start earning:** Begin validating once added to the validator set! 