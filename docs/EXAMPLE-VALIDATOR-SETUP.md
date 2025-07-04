# Example Validator Setup

This file shows exactly what happens when you set up a new validator using this repository.

## Fresh Setup Process

### 1. Clone and Install
```bash
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator
./install.sh
```

**What this does:**
- Downloads Fennel validator binary
- Downloads chain specification
- Sets up directory structure

### 2. Configure Your Validator
```bash
./setup-validator.sh
```

**Interactive configuration:**
- Validator name: e.g., "MyCompany-Validator"
- Network ports (defaults work for most)
- Data directory location
- Security settings

**Creates:**
- `config/validator.conf` with your settings

### 3. Secure Launch
```bash
./secure-launch.sh
```

**Security hardening applied:**
- Firewall rules (P2P open, RPC/metrics localhost-only)
- File permissions secured
- RPC methods set to safe
- Validator process started

### 4. Complete Registration
```bash
./complete-registration.sh
```

**Generates:**
- Session keys (for consensus participation)
- Stash account (for validator identity)
- `COMPLETE-REGISTRATION-SUBMISSION.txt` (send to Fennel Labs)
- `SESSION-SETKEYS-INSTRUCTIONS.txt` (your reference)

## Example Files Generated

After running the setup, you'll have these files:

```
FennelValidator/
├── config/
│   └── validator.conf              # Your validator settings
├── session-keys.json               # Your session keys (keep secure!)
├── stash-account.json              # Your stash account (keep secure!)
├── COMPLETE-REGISTRATION-SUBMISSION.txt    # Send to Fennel Labs
└── SESSION-SETKEYS-INSTRUCTIONS.txt        # Your reference
```

## Example Validator Names

Choose a unique name for your validator:
- `MyCompany-Validator`
- `University-Node-1`
- `Alice-Staging-Val`
- `PoweredByOrg-Validator`

## What Gets Sent to Fennel Labs

The `COMPLETE-REGISTRATION-SUBMISSION.txt` file contains:
- Your validator name
- Your stash account address
- Your session keys
- Registration instructions

**This is the only file you send to Fennel Labs.**

## Security Notes

- Keep `session-keys.json` and `stash-account.json` secure
- These files contain your validator identity
- Back them up in a safe location
- Never share the secret phrase publicly 