# Configuration Directory

This directory contains validator configuration files. Most files are generated automatically during setup.

## Files

### Generated during setup:
- `validator.conf` - Main validator configuration

### Downloaded fresh each time:
- `staging-chainspec.json` - Latest staging network chainspec (auto-downloaded)
- `mainnet-chainspec.json` - Latest mainnet chainspec (auto-downloaded when available)

### Pre-configured:
- `validator-config.toml` - Configuration template (created by install.sh)

## Always Up-to-Date

**Chainspecs are automatically downloaded** from the main [fennel-solonet repository](https://github.com/CorruptedAesthetic/fennel-solonet) every time you start the validator, ensuring you always have the latest network configuration.

## Security Note

**Never commit `validator.conf` to version control** - it may contain sensitive paths and configuration details. 