# For Fennel Labs - Validator Registration Process

This document explains what validators submit and what Fennel Labs needs to do.

## What Validators Submit

After running the setup scripts, validators send you a file called:
**`validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt`**

This file contains:

1. **Validator Information**
   - Validator Name (chosen by operator)
   - Setup Date
   - Network (Fennel Solonet)

2. **Stash Account Address** 
   - SS58 Address (e.g., `5HgFtar...`)
   - **Important:** Secret phrase is NOT included (kept private by validator)

3. **Session Keys**
   - Combined hex string (128 characters)
   - Contains AURA key (first 64 chars) + GRANDPA key (last 64 chars)

4. **Security Status**
   - Confirms validator is running
   - Security hardening applied
   - Ready for registration

## Fennel Labs Registration Process (Using Sudo)

### Step 1: Review Submission
- Verify validator name is unique
- Check session keys format (should be 0x + 128 hex chars)
- Note the stash account address

### Step 2: Fund Stash Account (Using Sudo)
```bash
# Use sudo to transfer tokens to the stash account
sudo.transfer(stash_account_address, amount)
```
- Amount needed for validator operations
- No need to coordinate with validator

**Via Polkadot.js Apps:**
1. Go to **Developer** → **Extrinsics**
2. **Using**: Select your sudo account (e.g., Alice)
3. **Submit the following extrinsic**: `sudo`
4. **Call**: `sudo`
5. **call: Call**: Select `balances → transfer`
6. **dest**: `[stash_account_address_from_submission]`
7. **value**: Recommended amount (e.g., 1000000000000 = 1 token with 12 decimals)
8. **Submit Transaction**

### Step 3: Bind Session Keys (Using Sudo)
```bash
# Use sudo to bind session keys to stash account
sudo.sudoAs(stash_account, session.setKeys(session_keys, proof))
```
- Automatically binds the provided session keys
- No need for validator to call session.setKeys() manually
- Uses `sudoAs` to execute the call AS the stash account

### Step 4: Add to Validator Set (Using Sudo)
```bash
# Use sudo to add validator to active set
sudo.sudo(validatorManager.addValidator(stash_account))
```
- Validator joins active set after next session rotation
- Session rotation occurs every 50 blocks (~10 minutes) in Fennel
- Uses the custom `validatorManager` pallet

## Detailed Polkadot.js Apps Instructions

### Prerequisites:
1. Connect to Fennel network via Polkadot.js Apps
2. Have sudo account (e.g., Alice) imported/available
3. Have validator's submission file with stash address and session keys

---

### **Step 3: Bind Session Keys via Polkadot.js Apps**

**Using Developer → Extrinsics:**

1. **Navigate to Extrinsics:**
   - Go to **Developer** → **Extrinsics**

2. **Configure the sudoAs Call:**
   - **Using**: Select your sudo account (e.g., Alice)
   - **Submit the following extrinsic**: `sudo`
   - **Call**: `sudoAs`

3. **Fill sudoAs Parameters:**
   - **Id: AccountId**: `[stash_account_address_from_submission]`
   - **call: Call**: Select `session → setKeys`

4. **Fill setKeys Parameters:**
   - **keys**: `0x[128_character_session_keys_from_submission]`
   - **proof**: `0x` (empty proof)

5. **Submit:**
   - Click **"Submit Transaction"**
   - Sign and submit the transaction

---

### **Step 4: Add to Validator Set via Polkadot.js Apps**

**Using Developer → Extrinsics:**

1. **Navigate to Extrinsics:**
   - Go to **Developer** → **Extrinsics**

2. **Configure the sudo Call:**
   - **Using**: Select your sudo account (e.g., Alice)
   - **Submit the following extrinsic**: `sudo`
   - **Call**: `sudo`

3. **Fill Parameters:**
   - **call: Call**: Select `validatorManager → registerValidators`
   - **validator (0: AccountId32)**: `[stash_account_address_from_submission]`

4. **Submit:**
   - Click **"Submit Transaction"**
   - Sign and submit the transaction

*Note: The Fennel network uses a custom `validatorManager` pallet for validator set management. The exact pallet name and parameter format should match what appears in your Polkadot.js Apps interface.*

---

### **Example with Real Data:**

**Given validator submission:**
- **Stash Address**: `5HgFtarhbicYc45S9vwSTqX8uStPzs7b1H7NnMF5MQ3xBRD9`
- **Session Keys**: `0xbc2212043bf2567c9f24cf920ba56bd18f29f13b445430a080747785062a8a5f61d0bdc34bcd679fe85409d4ba2da2f7d7215d2918d2b65e870915c710a18d48`

#### **Step 3 Complete Example:**
```
sudo.sudoAs(
  Id: 5HgFtarhbicYc45S9vwSTqX8uStPzs7b1H7NnMF5MQ3xBRD9,
  call: session.setKeys(
    keys: 0xbc2212043bf2567c9f24cf920ba56bd18f29f13b445430a080747785062a8a5f61d0bdc34bcd679fe85409d4ba2da2f7d7215d2918d2b65e870915c710a18d48,
    proof: 0x
  )
)
```

#### **Step 4 Example (updated for Fennel):**
```
sudo.sudo(
  call: validatorManager.registerValidators(
    validator (0: AccountId32): 5HgFtarhbicYc45S9vwSTqX8uStPzs7b1H7NnMF5MQ3xBRD9
  )
)
```

---

### **Verification Steps:**

#### **After Step 3 - Verify Session Keys Bound:**
1. Go to **Developer** → **Chain State**
2. **Pallet**: `session`
3. **Call**: `nextKeys`
4. **AccountId**: `[stash_account_address]`
5. **Query** - Should return the bound session keys

#### **After Step 4 - Verify Validator in Set:**
1. Go to **Developer** → **Chain State**
2. **Pallet**: `session`
3. **Call**: `validators`
4. **Query** - Should include the new validator address in the list

**Alternative verification:**
1. **Pallet**: `validatorManager`
2. **Call**: `validatorsToAdd` (if available)
3. **Query** - Check if validator is pending addition

---

### **⚠️ Important Notes:**

1. **Sudo Access Required** - Only accounts with sudo privileges can perform these operations
2. **Use sudoAs for Step 3** - This executes setKeys AS the stash account
3. **Use sudo for Step 4** - This adds the validator to the set
4. **Order Matters** - Step 3 (setKeys) must be completed before Step 4 (addValidator)
5. **Session Keys Format** - Must be exactly 128 hex characters (64 for AURA + 64 for GRANDPA)
6. **Network Connection** - Ensure Polkadot.js Apps is connected to the correct Fennel network endpoint
7. **Transaction Fees** - Ensure sudo account has sufficient balance for transaction fees

## Validator File Structure

Validators organize all files in `validator-data/` directory:
- **`session-keys.json`** - Their validator operational keys (kept private)
- **`stash-account.json`** - Their main validator account (kept private)
- **`COMPLETE-REGISTRATION-SUBMISSION.txt`** - What they send to you
- **`complete-validator-setup-instructions.txt`** - Their reference

## Security Improvements

### What's Shared vs. What's Private
**Shared with Fennel Labs (Public Information):**
- ✅ Stash account address
- ✅ Session keys 
- ✅ Validator name

**Kept Private by Validator:**
- ❌ Secret phrases
- ❌ Private keys
- ❌ Contents of stash-account.json

### Automated Security Features
Each validator has:
- Firewall configured (P2P open, RPC/metrics localhost only)
- Secure file permissions on keys (600/700)
- RPC methods set to "safe"
- Organized file structure in `validator-data/`

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

### Sudo Operations Required
All registration steps are handled via sudo:
1. **sudo.sudo(balances.transfer())** - Fund stash account
2. **sudo.sudoAs(stash, session.setKeys())** - Bind session keys to stash
3. **sudo.sudo(validatorManager.addValidator())** - Add to validator set

## Troubleshooting

### Common Issues

**Session keys wrong format:**
- Should be exactly 128 hex characters (plus 0x prefix)
- First 64 chars = AURA, last 64 = GRANDPA

**Validator not producing blocks:**
- Check if validator is in active set
- Verify session keys are properly bound
- Ensure they're synced to chain

**Connection issues:**
- Validators use port 30333 for P2P
- They auto-discover bootnodes from chainspec
- Should connect automatically

**Polkadot.js Apps Issues:**
- Ensure connected to correct Fennel network endpoint
- Verify sudo account has sufficient balance
- Check that pallet names match your runtime (`validatorManager` is correct for Fennel)
- Session rotation occurs every 50 blocks (~10 minutes) - validators join after next rotation
- Verify the exact pallet methods in your Polkadot.js Apps interface

## Communication with Validators

### What to Tell Validators
"Thank you for your submission. We will:
1. Review your validator registration
2. Fund your stash account with testnet tokens
3. Bind your session keys using sudo privileges
4. Add you to the validator set
5. Confirm when your validator is active

No additional action required from you - we handle everything via sudo!"

### Files Validators Keep
Validators are instructed to keep:
- `validator-data/COMPLETE-REGISTRATION-SUBMISSION.txt` (what they send you)
- `validator-data/session-keys.json` (their keys - kept secure)
- `validator-data/stash-account.json` (their account - kept secure)
- `validator-data/complete-validator-setup-instructions.txt` (their reference)

## Validator Management

### Regenerating Registration
Validators can always regenerate their submission by running:
```bash
./start.sh
```
Then choosing "Generate Keys & Complete Registration" or "Re-generate Registration"

### Checking Validator Status
Validators can check their status using:
```bash
./start.sh
```
Then choosing "Check Status"

### Troubleshooting Issues
Validators have an integrated troubleshooter:
```bash
./start.sh
```
Then choosing "Troubleshoot Issues"

## Advantages of This Process

1. **Security**: Secret phrases never leave validator's system
2. **Simplicity**: No manual session.setKeys() calls needed
3. **Reliability**: Sudo operations are atomic and reliable
4. **User-friendly**: Validators only need to run one command
5. **Organized**: All files in dedicated `validator-data/` directory

## Contact Information

For questions about this process:
- Technical issues: Direct validators to use their troubleshooter
- Registration questions: Contact Fennel Labs admin team
- Process improvements: Submit feedback to repository

## 🔧 Alternative: Using RPC Calls (Advanced)

For automation or if Polkadot.js Apps interface is unavailable, you can use direct RPC calls:

### Step 2: Fund Stash Account (RPC)
```bash
# Using curl to make RPC call
curl -H "Content-Type: application/json" -d '{
  "id": 1,
  "jsonrpc": "2.0",
  "method": "author_submitExtrinsic",
  "params": ["0x..."] // Signed extrinsic hex
}' http://localhost:9944
```

### Step 3: Bind Session Keys (RPC)
```bash
# Submit sudoAs(stash, session.setKeys()) extrinsic
curl -H "Content-Type: application/json" -d '{
  "id": 1,
  "jsonrpc": "2.0",
  "method": "author_submitExtrinsic",
  "params": ["0x..."] // Signed sudoAs extrinsic hex
}' http://localhost:9944
```

### Step 4: Add to Validator Set (RPC)
```bash
# Submit sudo(validatorManager.addValidator()) extrinsic
curl -H "Content-Type: application/json" -d '{
  "id": 1,
  "jsonrpc": "2.0",
  "method": "author_submitExtrinsic",
  "params": ["0x..."] // Signed sudo extrinsic hex
}' http://localhost:9944
```

*Note: RPC method requires constructing and signing extrinsics manually. Use Polkadot.js Apps for simpler workflow.*

---

## 🔄 **Alternative Methods for Adding Validators**

### **Method 1: Current Method (Recommended)**
```bash
sudo.sudo(validatorManager.registerValidators(validator))
```

### **Method 2: Direct Session Management**
```bash
# If validatorManager is not available
sudo.sudo(session.forceNewSession())  # After binding keys
```

### **Method 3: Batch Operation**
```bash
# Combine multiple operations
sudo.sudo(utility.batch([
  session.setKeys(keys, proof),
  validatorManager.registerValidators(validator)
]))
```

### **Method 4: Check Available Pallets**
To see what methods are available in your runtime:
1. Go to **Developer** → **Chain State**
2. Check available pallets: `session`, `validatorManager`, `staking`, `collective`
3. Go to **Developer** → **Extrinsics**
4. Explore available calls for each pallet

**Note: Stick with `validatorManager.registerValidators` unless you have specific requirements for alternative methods.**