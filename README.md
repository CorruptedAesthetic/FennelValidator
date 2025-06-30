# Fennel External Validator

Join the Fennel blockchain network as an external validator in **3 simple steps**!

## 🚀 Quick Start

### Prerequisites
- **Docker** (recommended) - for automatic binary extraction
- OR **Rust toolchain** - for building from source
- Linux, macOS, or Windows

### Simple 3-Step Process

#### Step 1: Download and Install
```bash
curl -sSL https://raw.githubusercontent.com/CorruptedAesthetic/FennelValidator/main/install.sh | bash
```

The installer will:
- ✅ Download validator scripts and management tools
- 🐳 Extract the `fennel-node` binary from Docker image (if Docker available)
- 📝 Create build instructions as fallback
- 🔧 Set up directory structure and configuration

#### Step 2: Setup and Start
```bash
./setup-validator.sh    # Configure your validator
./validate.sh start     # Start validating!
```

#### Step 3: Generate Session Keys
```bash
./scripts/generate-session-keys.sh
```

**Then send us your `session-keys.json` file!**

---

## 📋 What Happens During Installation

### Binary Acquisition
The installer tries multiple methods to get the `fennel-node` binary:

1. **GitHub Releases** (if pre-built binary available)
2. **Docker Extraction** (automatic if Docker is running)
   - Uses: `ghcr.io/corruptedaesthetic/fennel-solonet:sha-e73e4002862328f70a46ee64d8fd681d5ebccdd5`
3. **Build Instructions** (fallback for source compilation)

### Network Configuration  
- **Auto-connects** to staging bootnode: `/ip4/192.168.49.2/tcp/30604/p2p/12D3KooWRpzRTivvJ5ySvgbFnPeEE6rDhitQKL1fFJvvBGhnenSk`
- **Chainspec** auto-downloaded when starting validator
- **Staging network** - safe for learning and testing

---

## 🛠️ Management Commands

```bash
./validate.sh start     # Start validator
./validate.sh stop      # Stop validator  
./validate.sh status    # Check status
./validate.sh restart   # Restart validator
./validate.sh logs      # View logs
```

---

## 🆘 Troubleshooting

### Binary Not Found Error
```
❌ Fennel node binary not found!
Please run: ./install.sh first
```

**Solutions:**
1. **Install Docker**: `sudo apt install docker.io` (Ubuntu) or install Docker Desktop
2. **Re-run installer**: The installer will detect Docker and extract the binary
3. **Build from source**: Follow instructions in `bin/README.md`

### Docker Not Running
```
⚠️ Docker is installed but not running
```

**Solution:** Start Docker service:
```bash
sudo systemctl start docker    # Linux
# OR start Docker Desktop       # Windows/Mac
```

### Connection Issues
- Ensure firewall allows P2P port (default: 30333)
- Check network connectivity to bootnode IP: 192.168.49.2:30604

---

## 🌐 Network Information

- **Network**: Fennel Staging
- **Consensus**: AURA + GRANDPA  
- **Bootnode**: `/ip4/192.168.49.2/tcp/30604/p2p/12D3KooWRpzRTivvJ5ySvgbFnPeEE6rDhitQKL1fFJvvBGhnenSk`
- **Repository**: [fennel-solonet](https://github.com/CorruptedAesthetic/fennel-solonet)

---

**🧪 Staging Environment - Perfect for Learning!**

*Need help? Open an issue or contact the Fennel team.* 