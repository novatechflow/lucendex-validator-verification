#!/bin/bash
set -euo pipefail

# XRPL Validator Key Generation Guide
# This script helps generate validator keys securely

echo "========================================"
echo "XRPL Validator Key Generation"
echo "========================================"
echo ""
echo "SECURITY WARNING:"
echo "For production validators, keys should be generated OFFLINE"
echo "on an air-gapped machine, not on the server."
echo ""
echo "This script is for:"
echo "  1. Development/testing environments"
echo "  2. Guidance on the key generation process"
echo ""

read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Generating validator keys..."
echo ""

# Check if rippled container is running
if ! docker ps | grep -q rippled; then
    echo "Error: rippled container is not running"
    echo "Start it with: docker-compose up -d"
    exit 1
fi

# Generate keys
echo "Running validator-keys tool..."
docker exec rippled /opt/ripple/bin/validator-keys create_keys

echo ""
echo "========================================"
echo "IMPORTANT: Save These Keys Securely!"
echo "========================================"
echo ""
echo "The validator-keys tool has output:"
echo "  1. Public Key (validator_public_key) - Share this for UNL inclusion"
echo "  2. Validator Token - Add to rippled.cfg [validator_token] section"
echo ""
echo "Next Steps:"
echo "  1. Copy the validator token from above"
echo "  2. Edit /opt/rippled/rippled.cfg"
echo "  3. Replace the [validator_token] placeholder with your token"
echo "  4. Restart rippled: docker-compose restart"
echo ""
echo "Backup Instructions (CRITICAL):"
echo "  1. Store validator public key in secure vault"
echo "  2. Store validator token separately (encrypted)"
echo "  3. Never commit keys to git"
echo "  4. Rotate token quarterly (recommended)"
echo ""
echo "For Production:"
echo "  - Generate keys on an air-gapped machine"
echo "  - Transfer only the validator token to server via secure channel"
echo "  - Keep master key offline at all times"
echo ""

# Provide helper commands
echo "========================================"
echo "Helper Commands:"
echo "========================================"
echo ""
echo "View generated keys file:"
echo "  docker exec rippled cat /var/lib/rippled/validator-keys.json"
echo ""
echo "Edit rippled config:"
echo "  vim /opt/rippled/rippled.cfg"
echo ""
echo "Restart after config update:"
echo "  cd /opt/rippled && docker-compose restart"
echo ""
echo "Verify validator is running:"
echo "  docker exec rippled /opt/ripple/bin/rippled server_info"
echo ""
