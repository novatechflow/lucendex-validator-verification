#!/bin/bash
set -euo pipefail

# Deploy domain-enabled validator token to server
# This updates the running validator with the token that includes domain=lucendex.com

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_DIR="${HOME}/.validator-keys-secure"
DOMAIN="lucendex.com"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

log_info "Deploy Domain-Enabled Validator Token"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if validator token exists
if [ ! -f "${KEYS_DIR}/validator_token.txt" ]; then
    log_error "No validator_token.txt found in ${KEYS_DIR}"
    log_error "Run: make validator-setup-domain first"
    exit 1
fi

# Get validator IP
cd "${SCRIPT_DIR}/../terraform"
VALIDATOR_IP=$(terraform output -raw validator_ip 2>/dev/null)
if [ -z "$VALIDATOR_IP" ]; then
    log_error "Could not get validator IP from Terraform"
    exit 1
fi

log_info "Validator IP: ${VALIDATOR_IP}"
log_info "Domain: ${DOMAIN}"
echo ""

# Read the validator token
log_step "Reading validator token from offline keys..."
TOKEN=$(cat "${KEYS_DIR}/validator_token.txt")
PUBKEY=$(cat "${KEYS_DIR}/public_key.txt")

log_info "✓ Token loaded"
log_info "Public Key: ${PUBKEY}"
echo ""

# Backup current config
log_step "Backing up current rippled.cfg..."
ssh -i ../terraform/validator_ssh_key root@"${VALIDATOR_IP}" \
    "cp /opt/validator/config/rippled.cfg /opt/validator/config/rippled.cfg.backup-domain-$(date +%Y%m%d_%H%M%S)"
log_info "✓ Backup created"
echo ""

# Remove old validator token section
log_step "Updating rippled.cfg with domain-enabled token..."
ssh -i ../terraform/validator_ssh_key root@"${VALIDATOR_IP}" \
    "sed -i '/^# Validator Configuration/,/^$/d; /^\[validator_token\]/,/^$/d' /opt/validator/config/rippled.cfg"

# Append new validator token
ssh -i ../terraform/validator_ssh_key root@"${VALIDATOR_IP}" "cat >> /opt/validator/config/rippled.cfg << 'EOFCONFIG'

# Validator Configuration (Production - with domain=${DOMAIN})
${TOKEN}
EOFCONFIG
"

log_info "✓ rippled.cfg updated"
echo ""

# Restart validator
log_step "Restarting validator..."
ssh -i ../terraform/validator_ssh_key root@"${VALIDATOR_IP}" \
    "cd /opt/validator && docker compose restart"

log_info "✓ Validator restarted"
log_info "Waiting for rippled to come online..."
sleep 30
echo ""

# Verify domain is set
log_step "Verifying domain in manifest..."
VALIDATOR_INFO=$(ssh -i ../terraform/validator_ssh_key root@"${VALIDATOR_IP}" \
    "docker exec rippled /opt/ripple/bin/rippled validator_info" 2>/dev/null || echo "")

if echo "$VALIDATOR_INFO" | grep -q '"domain" : "lucendex.com"'; then
    log_info "✅ Domain verified in manifest!"
    echo "$VALIDATOR_INFO" | grep '"domain"'
else
    log_warn "⚠️  Domain not yet visible in manifest"
    log_info "This may take a few seconds to propagate"
fi

echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ Domain-Enabled Token Deployed!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Next steps:"
echo "  1. Verify domain: make validator-verify-domain"
echo "  2. Check manifest: ssh to validator and run:"
echo "     docker exec rippled /opt/ripple/bin/rippled validator_info"
echo ""
