#!/bin/bash
# Oracle Cloud Setup for Slowblock Validator
# This script sets up Oracle CLI, generates new API keys, and prepares for validator deployment

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_info() { echo -e "${GREEN}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_header() { echo -e "${BLUE}🔧 $1${NC}"; }

echo -e "${BLUE}☁️  Oracle Cloud Setup for Slowblock Validator${NC}"
echo "================================================"
echo

# Configuration
USER_OCID="ocid1.user.oc1..aaaaaaaa3xytd4n6givylbgpc7u45iygjotfmg23nknjouu3qa6wg65psiia"
TENANCY_OCID="ocid1.tenancy.oc1..aaaaaaaa5k2qvsstyoqy2zzwfiwpuq34kjny7yienfu2etriib3kxhzjdqpq"
REGION="us-ashburn-1"
VALIDATOR_NAME="slowblock"

print_header "Step 1: Generating New API Key Pair"

# Generate new API key pair
print_info "Generating new RSA key pair for Oracle Cloud API..."
openssl genrsa -out oci-config/private_key.pem 2048
chmod 600 oci-config/private_key.pem

# Generate public key
openssl rsa -pubout -in oci-config/private_key.pem -out oci-config/public_key.pem

print_info "✅ API key pair generated successfully"

print_header "Step 2: Calculating Fingerprint"

# Calculate fingerprint
FINGERPRINT=$(openssl rsa -pubout -outform DER -in oci-config/private_key.pem 2>/dev/null | openssl md5 -c | cut -d' ' -f2)
print_info "Fingerprint: $FINGERPRINT"

print_header "Step 3: Creating Oracle CLI Configuration"

# Update Oracle CLI config
cat > oci-config/config << EOF
[DEFAULT]
user=$USER_OCID
fingerprint=$FINGERPRINT
tenancy=$TENANCY_OCID
region=$REGION
key_file=~/.oci/private_key.pem
EOF

print_info "✅ Oracle CLI configuration created"

print_header "Step 4: Upload Public Key to Oracle Cloud"

echo
echo -e "${YELLOW}📋 IMPORTANT: You need to upload this public key to Oracle Cloud:${NC}"
echo "=============================================================="
cat oci-config/public_key.pem
echo "=============================================================="
echo
echo -e "${CYAN}Steps to upload the public key:${NC}"
echo "1. Go to Oracle Cloud Console (https://cloud.oracle.com)"
echo "2. Click on your user profile (top right) > User Settings"
echo "3. Go to 'API Keys' section"
echo "4. Click 'Add API Key'"
echo "5. Select 'Paste Public Key'"
echo "6. Copy and paste the key shown above"
echo "7. Click 'Add'"
echo

read -p "Press Enter after you've uploaded the public key to Oracle Cloud..."

print_header "Step 5: Testing Oracle CLI Configuration"

print_info "Testing Oracle CLI connectivity..."
if oci iam region list > /dev/null 2>&1; then
    print_info "✅ Oracle CLI is working correctly!"
else
    print_error "Oracle CLI test failed. Please check your configuration."
    exit 1
fi

print_header "Step 6: Evaluating Oracle Cloud Infrastructure"

# Check current instances
print_info "Checking your Oracle Cloud instances..."
echo
echo "Current instances:"
oci compute instance list --output table --query 'data[*].{Name:"display-name", State:"lifecycle-state", "Public IP":"public-ip"}' 2>/dev/null || print_warning "Could not list instances"

echo

print_header "Step 7: Preparing Validator Deployment"

print_info "Creating deployment summary for slowblock validator..."

cat > oracle-deployment-summary.txt << EOF
# Oracle Cloud Deployment Summary for Slowblock Validator
Date: $(date)

## Configuration
- Validator Name: $VALIDATOR_NAME
- Oracle Region: $REGION
- User OCID: $USER_OCID
- Tenancy OCID: $TENANCY_OCID

## Available Instances
fennel-validator-x86-1751682420 (Running)
fennel-validator-x86-1751682235 (Running)

## Network Configuration
- VCN: fennel-validator-vcn
- Subnet: fennel-validator-subnet
- Internet Gateway: fennel-validator-igw

## Next Steps
1. Choose target instance for slowblock validator
2. SSH into the instance
3. Run: ./oracle/oracle-cloud-deploy.sh
4. Configure firewall rules for port 30333 (P2P)
5. Start the validator and generate keys
6. Submit to Fennel Labs for network inclusion

## Validator Configuration
- Network: Fennel Solonet (Staging)
- Bootnodes: Auto-configured to connect to live network
- P2P Port: 30333
- RPC Port: 9944 (localhost only)
- Prometheus Port: 9615

## Commands to Run on Oracle Instance
cd /path/to/FennelValidator
./start.sh
# Follow the setup wizard to configure slowblock validator

EOF

print_info "✅ Deployment summary created: oracle-deployment-summary.txt"

print_header "Setup Complete!"

echo
print_info "Oracle Cloud setup for slowblock validator is complete!"
echo
echo -e "${CYAN}Next steps:${NC}"
echo "1. SSH into one of your Oracle Cloud instances"
echo "2. Clone/upload the FennelValidator repository"
echo "3. Run: ./oracle/oracle-cloud-deploy.sh"
echo "4. Configure the validator with name: $VALIDATOR_NAME"
echo "5. Connect to the live Fennel network"
echo
print_info "Your slowblock validator is ready for Oracle Cloud deployment!"

# Create instance connection helper
cat > connect-to-instance.sh << 'EOF'
#!/bin/bash
# Helper script to connect to Oracle Cloud instances

echo "Oracle Cloud Instance Connection Helper"
echo "======================================"
echo

# You'll need to update these with your actual instance IPs and SSH key
echo "Available instances:"
echo "1. fennel-validator-x86-1751682420"
echo "2. fennel-validator-x86-1751682235"
echo

echo "To connect, use:"
echo "ssh -i /path/to/your/ssh-key ubuntu@<INSTANCE_PUBLIC_IP>"
echo

echo "Instance IPs (get from Oracle Cloud Console):"
echo "- Check: Compute > Instances > [Select Instance] > Public IP"
EOF

chmod +x connect-to-instance.sh
print_info "Created connection helper: connect-to-instance.sh" 