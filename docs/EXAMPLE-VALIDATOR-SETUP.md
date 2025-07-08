# 🎯 Complete Validator Setup Examples

This document shows real examples of setting up Fennel validators in different scenarios. Follow these examples step-by-step for a successful deployment.

## 📋 Example 1: Complete First-Time Setup (Beginner)

**Scenario**: Brand new user setting up their first validator on Ubuntu/Linux.

### Step 1: Download and Prepare
```bash
# Download the repository
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator

# Make scripts executable
chmod +x *.sh
```

### Step 2: Install Validator Software
```bash
./install.sh
```

**Expected Output:**
```
🚀 Fennel Validator Installation
================================
✅ Downloading Fennel validator binary...
✅ Setting up blockchain configuration...
✅ Creating directory structure...
✅ Installation complete!

Next step: Run ./setup-validator.sh to configure your validator
```

### Step 3: Configure Your Validator
```bash
./setup-validator.sh
```

**Example Interactive Session:**
```
⚙️  Fennel Validator Setup
==================================

🔧 Validator Configuration
Let's configure your Fennel validator...

❓ What should we call your validator?
Validator name (press Enter for External-Validator-ubuntu): MyCompany-Validator

🧪 Configuring for Fennel Staging Network
✅ Network configured: Fennel Staging

❓ Network port configuration:
P2P port (press Enter for 30333): [Enter]
RPC port (press Enter for 9944): [Enter]
Prometheus port (press Enter for 9615): [Enter]

Data directory (press Enter for ./data): [Enter]
ℹ️  Created data directory: ./data

❓ Would you like to configure advanced options? (y/n)
Configure advanced options (press Enter for no): n

💾 Saving Configuration
ℹ️  Configuration saved to config/validator.conf

🎉 Setup Complete!
Your Fennel validator is now configured:
• Name: MyCompany-Validator
• Network: staging
• Data directory: ./data
• P2P port: 30333
• RPC port: 9944
• Prometheus port: 9615

Next step: Run ./validate.sh start to start your validator
```

### Step 4: Start Your Validator
```bash
./validate.sh start
```

**Expected Output:**
```
🚀 Starting Fennel validator...
Network: staging
Validator: MyCompany-Validator
Data directory: ./data

🔄 Checking for chainspec updates...
✅ Updated to latest staging chainspec

🔧 Initializing validator...
✅ Network keys already exist

Command: ./bin/fennel-node --chain config/staging-chainspec.json --validator...

2025-07-07 19:30:15 Fennel Node
2025-07-07 19:30:15 ✌️  version 1.0.0-dev
2025-07-07 19:30:15 🏷  MyCompany-Validator
2025-07-07 19:30:16 📦 Highest known block at #150
2025-07-07 19:30:16 🔍 Discovered new external address for our node
2025-07-07 19:30:21 ⚙️  Syncing, target=#157 (5 peers)
```

### Step 5: Generate Session Keys
```bash
# Open a new terminal (leave validator running)
cd FennelValidator
./scripts/generate-session-keys.sh
```

**Expected Output:**
```
🔑 Fennel Validator Session Key Generation
=========================================

Checking validator status...
✅ Validator is running on port 9944

Generating session keys...
✅ Session keys generated successfully!

📁 Session keys saved to: validator-data/session-keys.json

Next step: Run ./tools/complete-registration.sh to finish setup
```

### Step 6: Complete Registration
```bash
./tools/complete-registration.sh
```

**Expected Output:**
```
🌱 Fennel Validator Registration Completion
==============================================

ℹ️  Reading existing session keys...
✅ Session keys found: validator-data/session-keys.json

🏦 Generating stash account...
✅ Stash account generated successfully!

ℹ️  Creating complete submission for Fennel Labs...
✅ Registration file created: validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt

🎉 REGISTRATION COMPLETE!

Next step: Send COMPLETE-REGISTRATION-SUBMISSION.txt to Fennel Labs
```

### Step 7: Submit to Fennel Labs
**Email the file** `validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt` to Fennel Labs.

**Congratulations! Your validator is now:**
- ✅ Running and syncing with the network
- ✅ Generating session keys
- ✅ Ready for network registration
- ✅ Configured with security best practices

---

## 📋 Example 2: Cloud Server Setup (AWS/DigitalOcean/Oracle Cloud)

**Scenario**: Setting up a validator on a cloud VPS for better uptime.

### Cloud Server Preparation
```bash
# Connect to your cloud instance
ssh user@your-server-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y git curl wget unzip

# Create validator user (optional but recommended)
sudo useradd -m -s /bin/bash validator
sudo usermod -aG sudo validator
sudo su - validator
```

### Firewall Configuration
```bash
# Configure UFW firewall
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 30333/tcp  # P2P port for validator
sudo ufw status
```

### Follow Standard Setup
```bash
# Clone repository
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator

# Follow the same steps as Example 1
./install.sh
./setup-validator.sh
./validate.sh start
./scripts/generate-session-keys.sh
./tools/complete-registration.sh
```

### Cloud-Specific Monitoring
```bash
# Set up monitoring script
crontab -e

# Add this line to check validator every 5 minutes:
*/5 * * * * cd /home/validator/FennelValidator && ./validate.sh status > /dev/null || ./validate.sh start
```

---

## 📋 Example 3: Windows (WSL2) Setup

**Scenario**: Running validator on Windows using Windows Subsystem for Linux.

### WSL2 Preparation
1. **Install WSL2** (if not already installed):
   - Open PowerShell as Administrator
   - Run: `wsl --install`
   - Restart computer

2. **Install Ubuntu**:
   ```powershell
   wsl --install -d Ubuntu
   ```

3. **Open Ubuntu terminal** and follow standard Linux setup:

### Standard Setup in WSL2
```bash
# Update Ubuntu
sudo apt update && sudo apt upgrade -y

# Clone and setup validator
git clone https://github.com/CorruptedAesthetic/FennelValidator.git
cd FennelValidator

# Follow standard setup process
./install.sh
./setup-validator.sh
./validate.sh start
```

### Windows-Specific Notes
- **Port forwarding**: Windows may require additional firewall configuration
- **Performance**: WSL2 performs very well for validator operations
- **Startup**: Consider setting validator to auto-start with Windows

---

## 📋 Example 4: Advanced Configuration

**Scenario**: Experienced user wanting custom configuration options.

### Custom Port Configuration
```bash
./setup-validator.sh
```

**Custom Configuration Example:**
```
❓ Network port configuration:
P2P port (press Enter for 30333): 30334          # Custom P2P port
RPC port (press Enter for 9944): 9945            # Custom RPC port  
Prometheus port (press Enter for 9615): 9616     # Custom metrics port

❓ Would you like to configure advanced options? (y/n): y

❓ Allow external RPC access?: n                   # Keep secure
❓ Allow external Prometheus metrics access?: y    # For monitoring
❓ Log verbosity level?: debug                     # More detailed logs
```

### Custom Data Directory
```bash
# Use external SSD for validator data
mkdir -p /mnt/ssd/fennel-data
./setup-validator.sh

# When asked for data directory:
Data directory (press Enter for ./data): /mnt/ssd/fennel-data
```

### Multiple Validators (Advanced)
```bash
# Create separate directories for each validator
mkdir validator1 validator2
cd validator1
git clone https://github.com/CorruptedAesthetic/FennelValidator.git .

# Configure with unique ports and names
./setup-validator.sh
# Name: Validator-1, Ports: 30333, 9944, 9615

cd ../validator2
git clone https://github.com/CorruptedAesthetic/FennelValidator.git .
./setup-validator.sh
# Name: Validator-2, Ports: 30334, 9945, 9616
```

---

## 🔧 Common Variations & Troubleshooting

### Variation: Using Different Validator Names
**Good Examples:**
- `Alice-University-Validator`
- `TechCorp-Staging-Node`
- `Community-Validator-01`

**Avoid:**
- Generic names like `validator` or `node1`
- Special characters: `@#$%^&*()`
- Very long names (>50 characters)

### Variation: Different Operating Systems

**Ubuntu/Debian:**
```bash
sudo apt update && sudo apt install -y git curl wget
```

**CentOS/RHEL:**
```bash
sudo yum update && sudo yum install -y git curl wget
```

**macOS:**
```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install git (if needed)
brew install git
```

### Troubleshooting Common Issues

**Issue: "Permission denied" when running scripts**
```bash
chmod +x *.sh
chmod +x scripts/*.sh
chmod +x tools/*.sh
```

**Issue: "Port already in use"**
```bash
# Check what's using the port
sudo netstat -tlnp | grep 30333

# Kill process if needed
sudo kill -9 <PID>

# Or use different ports in setup
```

**Issue: "No peers connected"**
```bash
# Check firewall
sudo ufw allow 30333/tcp

# Restart validator
./validate.sh restart

# Check logs
./validate.sh logs
```

**Issue: Validator stops unexpectedly**
```bash
# Check system resources
free -h
df -h

# Check for errors
./validate.sh logs

# Restart with monitoring
./validate.sh start
```

---

## ✅ Success Indicators

### Your setup is successful when you see:

1. **Installation Complete**:
   ```
   ✅ Installation complete!
   Next step: Run ./setup-validator.sh
   ```

2. **Configuration Saved**:
   ```
   ✅ Configuration saved to config/validator.conf
   ```

3. **Validator Running**:
   ```bash
   ./validate.sh status
   # Output: ✅ Validator is running
   ```

4. **Network Connectivity**:
   ```
   ⚙️  Syncing, target=#157 (5 peers)
   ```

5. **Session Keys Generated**:
   ```
   ✅ Session keys saved to: validator-data/session-keys.json
   ```

6. **Registration Ready**:
   ```
   ✅ Registration file created: COMPLETE-REGISTRATION-SUBMISSION.txt
   ```

### Next Steps After Successful Setup:
1. **Monitor regularly**: `./tools/validator-status.sh`
2. **Keep updated**: Run `./install.sh` monthly
3. **Join community**: Connect with other validators
4. **Learn more**: Read about blockchain validation concepts

**🎉 You're now a Fennel Network validator! Welcome to the community!**

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