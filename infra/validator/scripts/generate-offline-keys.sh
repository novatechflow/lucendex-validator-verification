#!/bin/bash
set -euo pipefail

# Generate XRPL validator keys with domain attestation
# Runs OFFLINE on your Mac - never exposes master keys to server
# Uses Docker-based validator-keys tool

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

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    if ! command -v docker &>/dev/null; then
        log_error "Docker not found"
        log_info "Install: brew install docker colima"
        exit 1
    fi
    
    if ! docker ps &>/dev/null; then
        log_error "Docker not running"
        log_info "Start: colima start"
        exit 1
    fi
    
    # Check if validator-keys wrapper exists
    if [ ! -f "${HOME}/.local/bin/validator-keys" ]; then
        log_warn "validator-keys wrapper not found"
        log_info "Running setup..."
        "$(dirname "$0")/setup-validator-keys-tool.sh"
        export PATH="${HOME}/.local/bin:$PATH"
    fi
    
    log_info "✓ Prerequisites OK"
}

check_existing_keys() {
    if [ -f "${KEYS_DIR}/validator-keys.json" ]; then
        log_warn "Existing validator keys found in ${KEYS_DIR}"
        echo ""
        read -p "Use existing keys to generate attestation? (Y/n): " -r
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log_warn "Aborting. Remove ${KEYS_DIR} to generate new keys."
            exit 1
        fi
        return 0
    fi
    return 1
}

create_new_keys() {
    log_step "Creating new validator keys..."
    
    mkdir -p "${KEYS_DIR}"
    cd "${KEYS_DIR}"
    
    # Generate new keys
    validator-keys create_keys
    
    if [ ! -f "validator-keys.json" ]; then
        log_error "Key generation failed"
        exit 1
    fi
    
    log_info "✓ Keys generated"
}

generate_attestation() {
    log_step "Generating domain attestation for ${DOMAIN}..."
    
    cd "${KEYS_DIR}"
    
    # Run set_domain and capture output
    output=$(validator-keys set_domain "${DOMAIN}" --keyfile validator-keys.json 2>&1)
    
    # Extract attestation (hex string after "Attestation: ")
    attestation=$(echo "$output" | grep "Attestation:" | awk '{print $2}')
    
    if [ -z "$attestation" ]; then
        log_error "Failed to extract attestation"
        echo "$output"
        exit 1
    fi
    
    # Extract public key
    pubkey=$(echo "$output" | grep "Master public key:" | awk '{print $4}')
    
    # Extract validator token (multi-line base64)
    # The token section starts after "Validator Token:" and ends at next section or EOF
    token=$(echo "$output" | sed -n '/^Validator Token:/,/^$/p' | tail -n +2 | grep -v '^$')
    
    # Save extracted values
    echo "$attestation" > attestation.txt
    echo "$pubkey" > public_key.txt
    
    # Save validator token with proper formatting
    cat > validator_token.txt <<EOF
[validator_token]
$token
EOF
    
    log_info "✓ Attestation generated"
    log_info "Public Key: ${pubkey}"
    log_info "Attestation: ${attestation:0:32}..."
}

create_toml_file() {
    log_step "Creating xrp-ledger.toml..."
    
    local pubkey=$(cat "${KEYS_DIR}/public_key.txt")
    local attestation=$(cat "${KEYS_DIR}/attestation.txt")
    
    cat > "${KEYS_DIR}/xrp-ledger.toml" <<EOF
# Lucendex XRPL Validator Domain Verification
# Deploy to: https://lucendex.com/.well-known/xrp-ledger.toml

[[VALIDATORS]]
public_key = "${pubkey}"
attestation = "${attestation}"
network = "main"
owner_country = "MT"
server_country = "NL"

[[PRINCIPALS]]
name = "Lucendex"
domain = "lucendex.com"
EOF
    
    log_info "✓ xrp-ledger.toml created"
}

show_summary() {
    echo ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "✅ Validator Keys Generated with Domain Attestation"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "Keys saved to: ${KEYS_DIR}"
    echo ""
    log_info "Files created:"
    echo "  📄 validator-keys.json    - Master key (KEEP OFFLINE!)"
    echo "  📄 public_key.txt         - Public validator key"
    echo "  📄 attestation.txt        - Domain attestation hex"
    echo "  📄 validator_token.txt    - For rippled.cfg"
    echo "  📄 xrp-ledger.toml        - Ready for hosting"
    echo ""
    log_info "Public Key:"
    cat "${KEYS_DIR}/public_key.txt"
    echo ""
    log_info "Attestation:"
    cat "${KEYS_DIR}/attestation.txt" | head -c 64
    echo "..."
    echo ""
    log_warn "⚠️  SECURITY: Never upload validator-keys.json to server!"
    log_warn "⚠️  Backup validator-keys.json to encrypted storage"
    echo ""
    log_info "Next steps:"
    echo "  1. Deploy attestation: cd ../.. && ./validator-attestation.sh"
    echo "  2. Verify: curl https://lucendex.com/.well-known/xrp-ledger.toml"
    echo ""
}

main() {
    log_info "XRPL Validator Offline Key Generation"
    log_info "Domain: ${DOMAIN}"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    check_prerequisites
    
    if check_existing_keys; then
        log_info "Using existing keys"
    else
        create_new_keys
    fi
    
    generate_attestation
    create_toml_file
    show_summary
}

main "$@"
