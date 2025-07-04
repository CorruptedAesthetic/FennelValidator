# For Fennel Labs - Validator Registration Process

This document explains what validators submit and what Fennel Labs needs to do.

## What Validators Submit

After running the setup scripts, validators send you a file called:
**`COMPLETE-REGISTRATION-SUBMISSION.txt`**

This file contains:

1. **Validator Information**
   - Validator Name (chosen by operator)
   - Setup Date
   - Network (Fennel Solonet)

2. **Stash Account** 
   - SS58 Address (e.g., `5HgFtar...`)
   - Secret Phrase (for validator's reference)

3. **Session Keys**
   - Combined hex string (128 characters)
   - Contains AURA key (first 64 chars) + GRANDPA key (last 64 chars)

4. **Security Status**
   - Confirms validator is running
   - Security hardening applied
   - Ready for registration

## Fennel Labs Registration Process

### Step 1: Review Submission
- Verify validator name is unique
- Check session keys format (should be 0x + 128 hex chars)
- Note the stash account address

### Step 2: Send Testnet Tokens
- Send testnet tokens to the provided stash account address
- Amount needed for:
  - Transaction fees for session.setKeys()
  - Validator bond (if required)

### Step 3: Wait for Validator to Call session.setKeys()
The validator will:
1. Import their stash account to Polkadot.js
2. Call `session.setKeys(keys, proof)`
   - keys: Their session keys
   - proof: 0x (empty)
3. Notify you when complete

### Step 4: Add to Validator Set
Using the validator manager pallet:
1. Add the stash account as a validator
2. The session keys are already bound via setKeys()
3. Validator joins active set in next era/session

## Technical Details

### Session Keys Structure
```
0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
  |---------------------------AURA KEY---------------------------||--------------------------GRANDPA KEY-------------------------|
```

### Validator Identity
- **Controller**: Not used (stash account controls everything)
- **Stash**: The main account that gets registered
- **Session Keys**: Operational keys for consensus

### Security Features Applied
Each validator has:
- Firewall configured (P2P open, RPC/metrics localhost only)
- Secure file permissions on keys
- RPC methods set to "safe"
- Automated setup reduces human error

## Troubleshooting

### Common Issues

**Session keys wrong format:**
- Should be exactly 128 hex characters (plus 0x prefix)
- First 64 chars = AURA, last 64 = GRANDPA

**Validator not producing blocks:**
- Check if session.setKeys() was called
- Verify validator is in active set
- Ensure they're synced to chain

**Connection issues:**
- Validators use port 30333 for P2P
- They auto-discover bootnodes from chainspec

## Contact

Validators are instructed to keep:
- `COMPLETE-REGISTRATION-SUBMISSION.txt` (what they send you)
- `SESSION-SETKEYS-INSTRUCTIONS.txt` (their reference)
- `session-keys.json` (their keys - kept secure)
- `stash-account.json` (their account - kept secure)

They can always regenerate the submission file by running:
```bash
./complete-registration.sh
``` 