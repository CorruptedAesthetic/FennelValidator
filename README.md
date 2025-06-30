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

#### Step 2: Setup and Initialize
```bash
./setup-validator.sh    # Configure your validator
./validate.sh init      # Initialize and generate network keys
```

**Important**: Run `init` first to generate network keys before starting!

#### Step 3: Start and Generate Session Keys
```bash
./validate.sh start     # Start validating!
./scripts/generate-session-keys.sh    # Generate session keys
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
./validate.sh init      # Initialize validator (generate network keys) - Run this first!
./validate.sh start     # Start validator
./validate.sh stop      # Stop validator  
./validate.sh status    # Check status
./validate.sh restart   # Restart validator
./validate.sh logs      # View logs
```

**First Time Setup Workflow:**
1. `./setup-validator.sh` - Configure your validator
2. `./validate.sh init` - Generate network keys 
3. `./validate.sh start` - Start validating
4. `./scripts/generate-session-keys.sh` - Generate session keys

---

## 🆘 Troubleshooting

### P2P Port Configuration
When asked for P2P port during setup:

**Default (Recommended): 30333**
- Press Enter to accept default
- Standard blockchain P2P port
- Usually available on most systems

**When to use different port:**
- Port 30333 is already in use
- Running multiple validators on same machine
- Corporate firewall blocks standard ports
- Personal security preference

**Common alternatives:** 30334, 30335, 30336
**Avoid these ports:** 9944 (RPC), 8080 (web), 22 (SSH)

**Firewall setup:**
```bash
# Allow your chosen P2P port
sudo ufw allow 30333/tcp
# Check port availability  
netstat -ln | grep :30333
```

### Binary Not Found Error
```
❌ Fennel node binary not found!
Please run: ./install.sh first
```

**Solutions:**
1. **Install Docker**: `sudo apt install docker.io` (Ubuntu) or install Docker Desktop
2. **Re-run installer**: The installer will detect Docker and extract the binary
3. **Build from source**: Follow instructions in `bin/README.md`

### Network Key Error
```
Error: NetworkKeyNotFound("./data/chains/custom/network/secret_ed25519")
```

**Solution:** Initialize the validator first:
```bash
./validate.sh init      # Generate network keys first
./validate.sh start     # Then start the validator
```

This generates the P2P network identity keys that your validator needs to connect to the network.

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
- **Bootnodes**: Automatically discovered from chainspec
  - `bootnode1.fennel.network:30333`
  - `bootnode2.fennel.network:30333`
- **Repository**: [fennel-solonet](https://github.com/CorruptedAesthetic/fennel-solonet)

---

**🧪 Staging Environment - Perfect for Learning!**

*Need help? Open an issue or contact the Fennel team.* 