#!/bin/bash
# Oracle CLI Key Setup Script

echo "Setting up Oracle CLI keys..."

# Get the private key from user
echo "Please paste your private key (press Ctrl+D when done):"
echo "It should start with -----BEGIN PRIVATE KEY----- or -----BEGIN RSA PRIVATE KEY-----"
echo

# Read private key
PRIVATE_KEY=$(cat)

# Save private key
echo "$PRIVATE_KEY" > ~/.oci/private_key.pem
chmod 600 ~/.oci/private_key.pem

echo "Private key saved to ~/.oci/private_key.pem"

# Calculate fingerprint from the public key
PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0VMq0tGuJVffMrSdeqGi
UoxnXFLbYap2Xo7xy4nV0AiOuKIxubwUxDNxjEnTMofz8w51/o0yxbrTVqTLivvu
8JVZBZY7qqEY9NkQHmnVoz9f5K+IobN4rp5Vp9AEIkfWAfY3v0PUPl1NR4eocNwT
14Kk2rMMODJn/FPYDMM9B/zvZuow9BxRQ5xo7NppCLfeg066gLIxSLz/888aiQvY
JGIyZdxA0181ROBxeRy4JgxcCiuYQ0pJI0SmrPjIIgQwUwiVsH/zpWyFpGLvuHye
bJ0YT7wxxmRQ5Nf7boAlwkO6USXz1ARV0TEPKS9kvzcn9uYFOt9Cho4LRSSasFmU
RwIDAQAB
-----END PUBLIC KEY-----"

# Calculate fingerprint
echo "Calculating fingerprint..."
FINGERPRINT=$(echo "$PUBLIC_KEY" | openssl rsa -pubin -outform DER 2>/dev/null | openssl md5 -c | cut -d' ' -f2)

echo "Fingerprint: $FINGERPRINT"

# Update config file with fingerprint
sed -i "s/fingerprint=/fingerprint=$FINGERPRINT/" ~/.oci/config

echo "Oracle CLI configuration updated!"
echo "Configuration file: ~/.oci/config"
echo

# Test the configuration
echo "Testing Oracle CLI configuration..."
if oci iam region list > /dev/null 2>&1; then
    echo "✅ Oracle CLI is working correctly!"
else
    echo "❌ Oracle CLI configuration failed. Please check your keys."
fi 