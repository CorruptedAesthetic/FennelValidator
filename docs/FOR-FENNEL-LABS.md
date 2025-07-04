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

### Step 3: Bind Session Keys (Using Sudo)
```bash
# Use sudo to bind session keys to stash account
sudo.setKeys(stash_account, session_keys, proof)
```
- Automatically binds the provided session keys
- No need for validator to call session.setKeys() manually

### Step 4: Add to Validator Set (Using Sudo)
```bash
# Use sudo to add validator to active set
validatorManager.addValidator(stash_account)
```
- Validator joins active set immediately
- No era/session waiting required

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
   - **call: Call**: Select `[validator_pallet] → [add_validator_call]`
   - **validator**: `[stash_account_address_from_submission]`

4. **Submit:**
   - Click **"Submit Transaction"**
   - Sign and submit the transaction

*Note: Step 4 details depend on your specific validator management pallet - please check what validator pallets are available.*

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

#### **Step 4 Example (update with correct pallet):**
```
sudo.sudo(
  call: [validator_pallet].addValidator(
    validator: 5HgFtarhbicYc45S9vwSTqX8uStPzs7b1H7NnMF5MQ3xBRD9
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
2. **Pallet**: `session` (or `validatorSet`)
3. **Call**: `validators`
4. **Query** - Should include the new validator address in the list

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
1. **sudo.transfer()** - Fund stash account
2. **sudo.setKeys()** - Bind session keys to stash
3. **validatorManager.addValidator()** - Add to validator set

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
- Check that pallet names match your runtime (`validatorManager` vs `validator` etc.)

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