# 🌱 Fennel Validator

**Fennel Network validator deployment**

## 🚀 Quick Start

```bash
# 1. Clone this repository
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator

# 2A. First-time users: Run configuration wizard
./configure-deployment.sh

# 2B. Experienced users: Direct deployment (assumes ubuntu SSH user)
./fennel-bootstrap.sh YOUR_SERVER_IP

# 2C. With automatic stash account generation (includes subkey installation)
./fennel-bootstrap.sh YOUR_SERVER_IP -e generate_stash=true
```

**Benefits:**
- ✅ **Production-ready** - Uses Parity's battle-tested Ansible roles
- ✅ **Cloud-agnostic** - Works on any Linux server (AWS, GCP, Azure, bare metal)
- ✅ **Secure key management** - Keys generated inside the validator, never exposed
- ✅ **Optional stash account generation** - Auto-generate complete validator bundle
- ✅ **No restart required** - Dynamic validator registration
- ✅ **Professional monitoring** - Built-in metrics and logging
- ✅ **Configuration wizard** - Interactive setup for first-time users

### What Happens During Setup:
1. **Prerequisites Check** - Verifies Ansible, jq, and subkey are available
2. **Collection Install** - Downloads Parity's `paritytech.chain` collection
3. **Secure Key Generation** - Creates temporary keys locally for initial setup
4. **Validator Deployment** - Configures and starts validator with native binary
5. **Key Rotation** - Node generates fresh, secure keys internally
6. **Stash Account Generation** - (Optional) Creates funded account for validator
7. **Registration Prep** - Displays session key bundle for admin registration

**Total time:** 3-5 minutes | **Difficulty:** Professional | **Security:** Enterprise-grade

## 📚 Documentation

### For Operators
- **[OPERATOR-REQUIREMENTS.md](OPERATOR-REQUIREMENTS.md)** - What information you need about your server/cloud environment  
- **[PRODUCTION-DEPLOYMENT.md](PRODUCTION-DEPLOYMENT.md)** - Complete production deployment guide
- **[STEP_BY_STEP_INSTRUCTIONS.md](STEP_BY_STEP_INSTRUCTIONS.md)** - Complete step-by-step deployment guide

### Production Deployment
- **[Ansible Setup Guide](ansible/README.md)** - Complete Ansible deployment guide
- **[Validator Registration](docs/VALIDATOR-REGISTRATION.md)** - Registration process and troubleshooting
- **[Ansible Troubleshooting](docs/ANSIBLE-TROUBLESHOOTING.md)** - Common issues and solutions
- **[Architecture Overview](docs/CHAINSPEC-ANSIBLE-ARCHITECTURE.md)** - Technical architecture details

### Architecture
The Ansible-based deployment uses:
- **[Parity Technologies Ansible Collection](https://galaxy.ansible.com/ui/repo/published/paritytech/chain/)** - Battle-tested validator deployment
- **Native binary deployment** - Direct systemd service (no Docker required)
- **Secure key rotation** - In-node key generation with `author_rotateKeys`
- **ValidatorManager pallet** - Dynamic validator registration without network restart

## 🚀 Quick Commands

**One command deployment:** `./fennel-bootstrap.sh YOUR_SERVER_IP`

**Check validator status:**
```bash
ssh ubuntu@YOUR_SERVER_IP 'sudo systemctl status fennel-node'
ssh ubuntu@YOUR_SERVER_IP 'sudo journalctl -u fennel-node -f'
```

**Update validator:**
```bash
cd ansible/
# Edit validator.yml to update node_binary_version
ansible-playbook -i inventory validator.yml
```

## 🔍 Verification

Before deploying, verify your setup:

```bash
./verify-ansible-setup.sh
```

This checks all prerequisites and validates your configuration files.

---

**Ready to start?** Check out [STEP_BY_STEP_INSTRUCTIONS.md](STEP_BY_STEP_INSTRUCTIONS.md) for complete deployment guidance!

**Need help?** Review [OPERATOR-REQUIREMENTS.md](OPERATOR-REQUIREMENTS.md) for server requirements and [PRODUCTION-DEPLOYMENT.md](PRODUCTION-DEPLOYMENT.md) for detailed setup instructions.

## 🔑 Stash Account Options

### Option 1: Auto-Generate Stash Account (Easiest)
```bash
# Generates complete validator bundle with stash account
./configure-deployment.sh  # Select "Yes" for stash generation
# OR
cd ansible && ansible-playbook -i inventory validator.yml -e generate_keys=true -e generate_stash=true
```

**Requirements:** Uses Fennel binary (already deployed)
**Output:** Complete registration bundle with both stash address and session keys

### Option 2: Bring Your Own Stash Account (Manual)
```bash
# Generates only session keys
./configure-deployment.sh  # Select "No" for stash generation  
# OR
cd ansible && ansible-playbook -i inventory validator.yml -e generate_keys=true
```

**Requirements:** Only Ansible and jq
**Output:** Session keys only - you create your own funded stash account
