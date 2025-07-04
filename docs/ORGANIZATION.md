# Repository Organization

This document explains how the FennelValidator repository is organized for maximum simplicity and clarity.

## 🎯 Design Principles

1. **One Entry Point**: Users only need to know about `start.sh`
2. **Hidden Complexity**: All auxiliary scripts are in `tools/`
3. **Clear Documentation**: Docs are organized in `docs/`
4. **Automatic Everything**: Scripts handle all complex tasks

## 📁 Directory Structure

### Root Directory (What users see first)
- **`start.sh`** - The ONLY script users need to run
- **`install.sh`** - Installer (runs automatically)
- **`setup-validator.sh`** - Configuration (runs automatically)
- **`validate.sh`** - Core validator management (used by other scripts)
- **`README.md`** - Simple, clear instructions

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
- **`FAQ.md`** - Common questions and answers
- **`BEGINNERS-GUIDE.md`** - Step-by-step for new users
- **`EXAMPLE-VALIDATOR-SETUP.md`** - Shows what to expect
- **`FOR-FENNEL-LABS.md`** - Info for network operators
- **`README-DETAILED.md`** - Technical documentation

### Other Directories
- **`/config`** - Validator configuration (created during setup)
- **`/data`** - Blockchain data (created when running)
- **`/bin`** - Validator binary (created during install)

## 🚀 User Journey

1. User clones repository
2. User runs `./start.sh`
3. Script detects first run → runs complete setup
4. User has running validator in ~5-10 minutes
5. For future use, `./start.sh` shows simple menu

## 🛠️ For Developers

If you need to modify scripts:
- Keep `start.sh` simple - it's just a menu
- Put new utilities in `/tools`
- Update paths if moving scripts
- Keep user-facing messages friendly
- Test the complete flow from a fresh clone 