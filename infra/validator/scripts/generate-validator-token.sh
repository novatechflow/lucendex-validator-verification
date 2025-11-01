#!/bin/bash
set -euo pipefail

# Generate Validator Token (Production Method)
# Uses validator-keys tool - the ONLY secure method approved by XRPL
#
# Prerequisites:
# 1. Run build-validator-keys-tool.sh first
# 2. This script must be run on your LOCAL Mac (offline key generation)
#
# Security: Generates validator_token for [validator_token] section in rippled.cfg
# Master keys (validator-keys.json) stay OFFLINE and NEVER go to server

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
VALIDATOR_KEYS="${SCRIPT_DIR}/validator-keys-wrapper.sh"
KEYS_DIR="${HOME}/.validator-keys-secure"
DOMAIN="lucendex.com"

echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Production Validator Token Generator"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Docker image exists
if ! docker images validator-keys-builder:latest | grep -q validator-keys-builder; then
    log_error "validator-keys Docker image not found"
    log_info "Run build-validator-keys-tool.sh first to build the tool"
    exit 1
fi
log_info "✓ validator-keys Docker image found"

# Create secure keys directory
mkdir -p "${KEYS_DIR}"
chmod 700 "${KEYS_DIR}"
log_info "✓ Keys directory: ${KEYS_DIR}"
echo ""

# Check if keys already exist
if [ -f "${KEYS_DIR}/validator-keys.json" ]; then
    log_error "validator-keys.json already exists!"
    log_warn "To generate new keys, backup and remove existing file first:"
    log_info "  mv ${KEYS_DIR}/validator-keys.json ${KEYS_DIR}/validator-keys.json.backup.$(date +%Y%m%d)"
    exit 1
fi

# Step 1: Generate master validator keys
log_step "Generating master validator keys..."
log_warn "⚠️  CRITICAL: Master key will be saved to ${KEYS_DIR}/validator-keys.json"
log_warn "⚠️  This file must be backed up offline and encrypted!"
log_warn "⚠️  This file NEVER goes to the validator server!"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi
echo ""

cd "${KEYS_DIR}"
"${VALIDATOR_KEYS}" create_keys

if [ ! -f "validator-keys.json" ]; then
    log_error "Failed to create master keys"
    exit 1
fi
chmod 600 validator-keys.json

log_info "✓ Master keys created: ${KEYS_DIR}/validator-keys.json"
log_warn "⚠️  BACKUP THIS FILE TO ENCRYPTED OFFLINE STORAGE NOW!"
echo ""

# Step 2: Generate validator token
log_step "Generating validator token from master keys..."
echo ""

TOKEN_OUTPUT=$("${VALIDATOR_KEYS}" create_token --keyfile validator-keys.json)

echo "$TOKEN_OUTPUT"
echo ""

# Extract public key
PUBLIC_KEY=$(echo "$TOKEN_OUTPUT" | grep 'validator public key:' | awk '{print $NF}')

if [ -z "$PUBLIC_KEY" ]; then
    log_error "Failed to extract public key"
    exit 1
fi

log_info "✓ Validator token generated"
log_info "✓ Public key: ${PUBLIC_KEY}"
echo ""

# Step 3: Create config files
log_step "Creating configuration files..."

# Extract complete multi-line validator_token from output
# Start from [validator_token] line and get all base64 lines after it
VALIDATOR_TOKEN_SECTION=$(echo "$TOKEN_OUTPUT" | sed -n '/^\[validator_token\]/,/^$/p')

# rippled.cfg snippet - include complete multi-line token
cat > "${KEYS_DIR}/rippled-validator-config.txt" <<EOF
# Validator Token (auto-generated $(date +%Y-%m-%d))

${VALIDATOR_TOKEN_SECTION}
EOF

# xrp-ledger.toml
cat > "${KEYS_DIR}/xrp-ledger.toml" <<EOF
# Lucendex XRPL Validator Domain Verification
# Deploy to: https://${DOMAIN}/.well-known/xrp-ledger.toml

[[VALIDATORS]]
public_key = "${PUBLIC_KEY}"
network = "main"
owner_country = "MT"
server_country = "NL"
EOF

# Public key file
echo "${PUBLIC_KEY}" > "${KEYS_DIR}/public_key.txt"

log_info "✓ Configuration files created"
echo ""

# Step 4: Summary
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ Validator Token Generated Successfully!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

log_info "Files created in: ${KEYS_DIR}/"
echo ""
echo "  🔐 validator-keys.json           Master key (OFFLINE BACKUP - NEVER ON SERVER!)"
echo "  📄 rippled-validator-config.txt  Config for rippled.cfg"
echo "  📄 xrp-ledger.toml               Domain verification file"
echo "  📄 public_key.txt                Public key (safe to share)"
echo ""

log_warn "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_warn "CRITICAL SECURITY REQUIREMENTS"
log_warn "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ✅ validator_token (in rippled-validator-config.txt):"
echo "     → SAFE to put in rippled.cfg on server"
echo "     → Cannot be used to derive master key"
echo "     → Rotatable without changing master key"
echo ""
echo "  🔐 validator-keys.json (master key):"
echo "     → NEVER EVER put on validator server"
echo "     → NEVER commit to git"
echo "     → Backup to encrypted storage (USB + password manager)"
echo "     → Only needed for key rotation"
echo ""
echo "  ✅ public_key (${PUBLIC_KEY}):"
echo "     → SAFE to publish publicly"
echo "     → Use for UNL registration"
echo "     → Use in domain verification"
echo ""

log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Next Steps (Manual Deployment)"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Update rippled.cfg:"
echo "   • Edit: infra/validator/docker/rippled.cfg"
echo "   • Remove any [validation_seed] section"
echo "   • Add content from: ${KEYS_DIR}/rippled-validator-config.txt"
echo ""
echo "2. Update domain verification:"
echo "   • Copy: ${KEYS_DIR}/xrp-ledger.toml"
echo "   • To: infra/validator/lucendex-validator-verification/.well-known/xrp-ledger.toml"
echo ""
echo "3. Deploy configuration:"
echo "   cd infra/validator"
echo "   make update-config    # Upload new rippled.cfg with validator_token"
echo "   make restart          # Restart validator with new keys"
echo ""
echo "4. Verify validation:"
echo "   make sync-status      # Should show 'proposing' state"
echo "   make logs-tail        # Check for validation messages"
echo ""
echo "5. Push domain verification to GitHub:"
echo "   git add lucendex-validator-verification/.well-known/xrp-ledger.toml"
echo "   git commit -m 'security: update validator public key'"
echo "   git push              # Cloudflare auto-deploys"
echo ""

log_warn "Public Key: ${PUBLIC_KEY}"
log_info "Validator token generated successfully!"
echo ""

# Step 5: Automated deployment
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Automated Deployment"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_step "Would you like to automatically deploy these keys?"
log_warn "This will:"
echo "  1. Update rippled.cfg with [validator_token]"
echo "  2. Update xrp-ledger.toml with new public key"
echo "  3. Stop validator"
echo "  4. Upload new config"
echo "  5. Start validator"
echo ""
read -p "Deploy now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    VALIDATOR_DIR="$(dirname "$SCRIPT_DIR")"
    
    log_step "Updating rippled.cfg..."
    # Add validator_token section to rippled.cfg
    RIPPLED_CFG="${VALIDATOR_DIR}/docker/rippled.cfg"
    
    # Remove any existing [validation_seed] or [validator_token] sections
    if grep -q '^\[validation_seed\]' "$RIPPLED_CFG"; then
        log_warn "Removing old [validation_seed] section from rippled.cfg"
        # Remove [validation_seed] and the line after it
        sed -i.backup '/^\[validation_seed\]/,/^$/d' "$RIPPLED_CFG"
    fi
    
    if grep -q '^\[validator_token\]' "$RIPPLED_CFG"; then
        log_warn "Removing old [validator_token] section from rippled.cfg"
        # Remove [validator_token] and the line after it
        sed -i.backup '/^\[validator_token\]/,/^$/d' "$RIPPLED_CFG"
    fi
    
    # Append new validator_token section
    echo "" >> "$RIPPLED_CFG"
    echo "# Validator Token (auto-generated $(date +%Y-%m-%d))" >> "$RIPPLED_CFG"
    cat "${KEYS_DIR}/rippled-validator-config.txt" >> "$RIPPLED_CFG"
    
    log_info "✓ rippled.cfg updated with [validator_token]"
    
    log_step "Updating xrp-ledger.toml..."
    TOML_FILE="${VALIDATOR_DIR}/lucendex-validator-verification/.well-known/xrp-ledger.toml"
    cp "${KEYS_DIR}/xrp-ledger.toml" "$TOML_FILE"
    log_info "✓ xrp-ledger.toml updated with new public key"
    
    log_step "Deploying to validator..."
    cd "${VALIDATOR_DIR}"
    
    # Stop validator
    log_info "Stopping validator..."
    make stop || true
    sleep 3
    
    # Upload new config
    log_info "Uploading new configuration..."
    make update-config
    
    # Start validator
    log_info "Starting validator with new keys..."
    make start
    sleep 5
    
    # Check status
    log_info "Checking validator status..."
    make sync-status
    
    log_info "✓ Deployment complete!"
    echo ""
    
    log_step "Pushing TOML to GitHub (Cloudflare auto-deploys)..."
    VERIFICATION_DIR="${VALIDATOR_DIR}/lucendex-validator-verification"
    
    if [ -d "${VERIFICATION_DIR}/.git" ]; then
        cd "${VERIFICATION_DIR}"
        git add .well-known/xrp-ledger.toml
        if git commit -m "security: update validator public key - $(date +%Y-%m-%d)"; then
            git push
            log_info "✓ TOML pushed to GitHub"
            log_warn "Cloudflare Pages will auto-deploy in ~30 seconds"
        else
            log_warn "No changes to commit (TOML already up to date)"
        fi
    else
        log_error "GitHub repo not initialized at ${VERIFICATION_DIR}"
        log_warn "Manual push required:"
        echo "     cd ${VERIFICATION_DIR}"
        echo "     git add .well-known/xrp-ledger.toml"
        echo "     git commit -m 'security: update validator public key'"
        echo "     git push"
    fi
    
    echo ""
    log_warn "Next steps:"
    echo "  1. Monitor validator: make logs-tail"
    echo "  2. Verify domain: curl https://lucendex.com/.well-known/xrp-ledger.toml"
    echo "  3. Wait ~30s for Cloudflare deployment"
    echo ""
else
    log_info "Skipping automated deployment"
    echo ""
    log_info "Manual deployment steps provided above"
    echo ""
fi
