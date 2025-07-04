# Repository Organization

This document explains how the FennelValidator repository is organized for maximum simplicity and clarity.

## 🎯 Design Principles

1. **One Entry Point**: Users only need to know about `start.sh`
2. **Hidden Complexity**: All auxiliary scripts are in `tools/`
3. **Organized Data**: All validator files are in `validator-data/`
4. **Clear Documentation**: Docs are organized in `docs/`
5. **Automatic Everything**: Scripts handle all complex tasks

## 📁 Directory Structure

### Root Directory (What users see first)
- **`start.sh`** - The ONLY script users need to run
- **`install.sh`** - Installer (runs automatically)
- **`setup-validator.sh`** - Configuration (runs automatically)
- **`validate.sh`** - Core validator management (used by other scripts)
- **`README.md`** - Simple, clear instructions

### `/validator-data` - All validator files (secure)
- **`session-keys.json`** - Validator operational keys (600 permissions)
- **`stash-account.json`** - Main validator account (600 permissions)
- **`COMPLETE-REGISTRATION-SUBMISSION.txt`** - File to send to Fennel Labs
- **`complete-validator-setup-instructions.txt`** - Reference instructions
- **Directory permissions: 700** (owner access only)

### `/tools` - All utilities in one place
- **`quick-setup.sh`** - Complete setup process
- **`secure-launch.sh`** - Security hardening and launch
- **`validator-status.sh`** - Comprehensive status dashboard
- **`troubleshoot.sh`** - Diagnose and fix issues
- **`reset-validator.sh`** - Clean reset with backup
- **`complete-registration.sh`** - Generate registration files
- **`preflight-check.sh`** - System requirements check
- **`/internal`** - Helper scripts (users don't need to know about these)

### `/docs` - All documentation
- **`BEGINNERS-GUIDE.md`** - Step-by-step for new users
- **`FAQ.md`** - Common questions and answers
- **`EXAMPLE-VALIDATOR-SETUP.md`** - Shows what to expect
- **`FOR-FENNEL-LABS.md`** - Info for network operators
- **`README-DETAILED.md`** - Technical documentation
- **`ORGANIZATION.md`** - This file

### `/scripts` - Legacy compatibility
- **`generate-session-keys.sh`** - Redirect to new location
- **Purpose**: Maintains compatibility with old instructions

### Other Directories
- **`/config`** - Validator configuration (created during setup)
- **`/data`** - Blockchain data (created when running)
- **`/bin`** - Validator binary (created during install)

## 🚀 User Journey

1. User clones repository
2. User runs `./start.sh`
3. Script detects first run → runs complete setup automatically
4. User has running validator in ~5-10 minutes
5. For future use, `./start.sh` shows simple menu

## 🔧 Menu System

### Main Menu Options
```
Setup & Configuration:
  1) Complete Setup (new validators)
  2) Install Dependencies
  3) Setup/Reconfigure Validator
  4) Generate Keys & Complete Registration
  5) Re-generate Registration

Operations:
  6) Start Validator
  7) Stop Validator
  8) Restart Validator
  9) Check Status

Maintenance:
  10) Troubleshoot Issues
  11) Reset Validator
  12) View Logs
  13) System Check
```

## 🔒 Security Organization

### File Permissions
- **validator-data/**: 700 (owner access only)
- **All key files**: 600 (owner read/write only)
- **Scripts**: 755 (executable)
- **Configuration**: 644 (readable)

### Security Features
- Firewall automatically configured
- RPC/metrics secured to localhost only
- P2P port (30333) properly exposed
- All sensitive files excluded from version control

## 🛠️ For Developers

### Adding New Features
1. Keep `start.sh` simple - it's just a menu
2. Put new utilities in `/tools`
3. Put helper scripts in `/tools/internal`
4. Update paths if moving scripts
5. Keep user-facing messages friendly
6. Test the complete flow from a fresh clone

### Script Organization
- **User-facing scripts**: Root directory or `/tools`
- **Internal helpers**: `/tools/internal`
- **Documentation**: `/docs`
- **User data**: `/validator-data`

### Testing Changes
1. Test on fresh clone
2. Verify all menu options work
3. Check that file permissions are correct
4. Ensure security features work
5. Test troubleshooter functionality

## 📊 Information Flow

### First-Time Setup
```
start.sh → detects first run → quick-setup.sh → complete flow
```

### Regular Operations
```
start.sh → menu → appropriate tool → action completed
```

### Data Organization
```
User runs setup → files created in validator-data/ → files secured
```

## 🌟 User Experience Goals

1. **Simplicity**: One command does everything
2. **Clarity**: Clear messages and progress indicators
3. **Security**: Automatic security hardening
4. **Reliability**: Error handling and troubleshooting
5. **Organization**: All files in logical locations

## 📝 Documentation Strategy

### For Users
- **README.md**: Quick start instructions
- **BEGINNERS-GUIDE.md**: Detailed walkthrough
- **FAQ.md**: Common questions
- **EXAMPLE-VALIDATOR-SETUP.md**: What to expect

### For Operators
- **FOR-FENNEL-LABS.md**: Registration process
- **README-DETAILED.md**: Technical details

### For Developers
- **ORGANIZATION.md**: This file
- **Code comments**: In-line documentation

## 🔄 Maintenance Strategy

### Regular Updates
- Keep chainspec updated automatically
- Update documentation when process changes
- Test all flows with each update
- Maintain backward compatibility where possible

### User Support
- Integrated troubleshooter handles most issues
- Clear error messages with suggested fixes
- Comprehensive logging for debugging

## 🎯 Success Metrics

A successful organization achieves:
- ✅ Users can set up validators without technical knowledge
- ✅ One command handles all operations
- ✅ Files are automatically organized and secured
- ✅ Troubleshooting is automated
- ✅ Documentation is clear and up-to-date

---

This organization makes the FennelValidator repository accessible to both beginners and advanced users while maintaining security and reliability. 