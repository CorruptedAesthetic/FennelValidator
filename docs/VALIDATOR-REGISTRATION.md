# Fennel Validator Registration Guide

This guide explains the complete validator registration process using the new Ansible-based setup.

## 🔄 Validator Registration Flow

### Overview

The Fennel network uses a secure two-step registration process:

1. **Operator Setup**: Deploy validator with temporary keys, then rotate to secure keys
2. **Admin Registration**: Fennel Labs admin registers the validator through the `validatorManager` pallet

### Benefits of This Approach

- ✅ **No secret key exposure** - Keys are generated securely on the validator node
- ✅ **No network restart required** - Validators are added dynamically
- ✅ **Simplified operator experience** - One command deployment
- ✅ **Cloud-agnostic** - Works on any Linux server

## 📋 Step-by-Step Process

### Step 1: Operator Deployment

The validator operator runs the bootstrap script:

```bash
./fennel-bootstrap.sh 198.51.100.7
```

**What happens internally:**
1. Script generates temporary dummy seeds locally
2. Ansible deploys the validator with these seeds
3. Node starts and syncs with the network
4. `author_rotateKeys` RPC call generates fresh, secure keys
5. Public session key bundle is displayed

### Step 2: Registration Submission

The operator receives output like this:

```
╭──────────────────────────────────────────────╮
│  SEND THIS TO FENNEL ADMIN:                  │
│  Stash  : 5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY │
│  Session: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef │
╰──────────────────────────────────────────────╯
```

**Operator must:**
1. Create a stash account with sufficient funds
2. Note the stash account's SS58 address
3. Send both the stash address and session key bundle to Fennel Labs

### Step 3: Admin Registration

Fennel Labs administrator executes:

```javascript
// 1. Fund the stash account (if needed)
api.tx.balances.transfer(stashAccount, minimumBond)

// 2. Set the session keys for the stash account
api.tx.sudo.sudoAs(
  stashAccount,
  api.tx.session.setKeys(sessionKeyBundle, "0x00")
)

// 3. Register the validator
api.tx.sudo.sudo(
  api.tx.validatorManager.registerValidators([stashAccount])
)
```

### Step 4: Activation

The validator becomes active in the next session rotation (typically ~10 minutes).

## 🔐 Security Model

### Key Security

| Key Type | Security Model |
|----------|----------------|
| **Temporary Seeds** | Generated locally, used only for initial node startup, immediately discarded |
| **Session Keys** | Generated securely inside the node's keystore, never exposed |
| **Node Key** | Generated locally, provides stable libp2p identity |
| **Stash Key** | Controlled by operator, used for economic security |

### Why This Is Secure

1. **No secret transmission** - Only public keys leave the validator
2. **Minimal exposure window** - Temporary keys exist only during setup
3. **Substrate-native generation** - Uses proven Substrate key generation
4. **Isolated keystore** - Keys stored in secure node keystore

## 📊 Validation Process

### Pre-Registration Checks

The `validatorManager` pallet validates:
- ✅ Session keys exist and are valid
- ✅ Keys match the expected format (128 bytes)
- ✅ Stash account has sufficient funds
- ✅ No duplicate registrations

### Post-Registration Verification

Operators can verify successful registration:

```bash
# Check if validator is in the active set
curl -H "Content-Type: application/json" \
  -d '{"id":1,"jsonrpc":"2.0","method":"session_getValidators","params":[]}' \
  http://localhost:9933

# Check validator status
curl -H "Content-Type: application/json" \
  -d '{"id":1,"jsonrpc":"2.0","method":"babe_epochAuthorship","params":[]}' \
  http://localhost:9933
```

## 🛠️ Troubleshooting Registration

### Common Issues

#### 1. Keys Not Generated
**Symptom:** No session key bundle displayed
**Solution:** 
```bash
# Check if node is running
sudo systemctl status fennel-node

# Check RPC is responding
curl -s http://localhost:9933 -d '{"jsonrpc":"2.0","id":1,"method":"system_health","params":[]}'
```

#### 2. Invalid Session Keys
**Symptom:** Registration fails with "Invalid session keys"
**Solution:**
- Ensure the 128-byte bundle is complete
- Verify the node is fully synced before key rotation

#### 3. Stash Account Issues
**Symptom:** Registration fails with account errors
**Solution:**
- Verify stash account has sufficient funds
- Check SS58 address format is correct

### Manual Key Rotation

If automatic key rotation fails:

```bash
# SSH to validator server
ssh ubuntu@your-validator-ip

# Manual rotation
curl -H "Content-Type: application/json" \
  -d '{"id":1,"jsonrpc":"2.0","method":"author_rotateKeys","params":[]}' \
  http://localhost:9933
```

## 📈 Best Practices

### For Operators

1. **Backup important data:**
   - Node key (for consistent peer ID)
   - Stash account keys
   - Server access credentials

2. **Monitor validator health:**
   - Set up log monitoring
   - Monitor block production
   - Watch for slash events

3. **Keep systems updated:**
   - Regular OS updates
   - Update validator binary when new versions release
   - Monitor Fennel network announcements

### For Admins

1. **Verify before registration:**
   - Confirm session keys are valid format
   - Check stash account exists and is funded
   - Verify operator identity

2. **Monitor network health:**
   - Track validator set changes
   - Monitor for misbehaviour
   - Coordinate network upgrades

## 🔄 Validator Updates

### Updating Node Version

When a new Fennel node version is released:

```bash
# Update the playbook configuration
vim ansible/validator.yml
# Change: node_binary_image: ghcr.io/corruptedaesthetic/fennel-solonet:fennel-node-0.5.8

# Deploy the update
cd ansible/
ansible-playbook -i inventory validator.yml
```

The validator will automatically restart with the new version.

### Key Rotation (if needed)

```bash
# Re-run with key generation
ansible-playbook -i inventory validator.yml -e "generate_keys=true"
```

Send the new session key bundle to Fennel Labs for update.

## 📞 Support

For registration issues or questions:

1. **Check validator logs:** `sudo journalctl -u fennel-node -f`
2. **Verify network connectivity:** Test RPC endpoints
3. **Contact Fennel Labs:** Provide validator logs and session key bundle
4. **Community support:** Join the Fennel validator community channels
