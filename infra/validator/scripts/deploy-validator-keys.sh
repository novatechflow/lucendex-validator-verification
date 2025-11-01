#!/bin/bash
set -euo pipefail

# Automated Validator Key Deployment
# Zero manual steps - fully automated deployment

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATOR_DIR="$(dirname "$SCRIPT_DIR")"
KEYS_DIR="${HOME}/.validator-keys-secure"

echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Automated Validator Key Deployment"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check keys exist
if [ ! -f "${KEYS_DIR}/rippled-validator-config.txt" ]; then
    log_error "Keys not found. Run generate-validator-token.sh first"
    exit 1
fi

PUBLIC_KEY=$(cat "${KEYS_DIR}/public_key.txt")
log_info "Deploying validator with public key: ${PUBLIC_KEY}"
echo ""

# Step 1: Update rippled.cfg
log_step "Updating rippled.cfg..."
RIPPLED_CFG="${VALIDATOR_DIR}/docker/rippled.cfg"

# Remove old validation sections
sed -i.backup '/^\[validation_seed\]/,/^$/d' "$RIPPLED_CFG" 2>/dev/null || true
sed -i.backup '/^\[validator_token\]/,/^$/d' "$RIPPLED_CFG" 2>/dev/null || true

# Append new validator_token
echo "" >> "$RIPPLED_CFG"
cat "${KEYS_DIR}/rippled-validator-config.txt" >> "$RIPPLED_CFG"

log_info "✓ rippled.cfg updated"

# Step 2: Update xrp-ledger.toml
log_step "Updating xrp-ledger.toml..."
TOML_FILE="${VALIDATOR_DIR}/lucendex-validator-verification/.well-known/xrp-ledger.toml"
cp "${KEYS_DIR}/xrp-ledger.toml" "$TOML_FILE"
log_info "✓ xrp-ledger.toml updated"

# Step 3: Deploy to validator
log_step "Deploying to validator server..."
cd "${VALIDATOR_DIR}"

log_info "Stopping validator..."
make stop || true
sleep 3

log_info "Uploading new configuration..."
make update-config

log_info "Starting validator with new keys..."
make start
sleep 5

log_info "✓ Validator restarted"

# Step 4: Check status
log_step "Checking validator status..."
make sync-status

# Step 5: Push to GitHub
log_step "Pushing TOML to GitHub..."
VERIFICATION_DIR="${VALIDATOR_DIR}/lucendex-validator-verification"

if [ -d "${VERIFICATION_DIR}/.git" ]; then
    cd "${VERIFICATION_DIR}"
    git add .well-known/xrp-ledger.toml
    if git commit -m "security: update validator public key ${PUBLIC_KEY} - $(date +%Y-%m-%d)"; then
        git push
        log_info "✓ TOML pushed to GitHub"
        log_warn "Cloudflare Pages will auto-deploy in ~30 seconds"
    else
        log_warn "No changes to commit"
    fi
else
    log_warn "Git repo not initialized - skipping GitHub push"
fi

echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ Deployment Complete!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_warn "Public Key: ${PUBLIC_KEY}"
echo ""
log_info "Monitor validator:"
echo "  cd infra/validator"
echo "  make logs-tail"
echo "  make sync-status"
echo ""
log_info "Verify domain (wait 30s for Cloudflare):"
echo "  curl https://lucendex.com/.well-known/xrp-ledger.toml"
echo ""
