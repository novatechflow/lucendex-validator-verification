#!/bin/bash
set -euo pipefail

# Generate XRPL validator keys offline with domain verification
# SECURITY: Run this on your local Mac, NOT on the server

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

DOMAIN="lucendex.com"
KEYS_DIR="${HOME}/.validator-keys"
KEYS_FILE="${KEYS_DIR}/validator-keys.json"

check_tool() {
    if ! command -v validator-keys &> /dev/null; then
        log_error "validator-keys tool not found"
        log_info "Install it first:"
        log_info "  ./setup-validator-keys-tool.sh"
        log_info "  source ~/.zshrc"
        exit 1
    fi
    
    log_info "✓ validator-keys tool found"
}

create_keys_directory() {
    mkdir -p "${KEYS_DIR}"
    chmod 700 "${KEYS_DIR}"
    log_info "✓ Keys directory: ${KEYS_DIR}"
}

generate_keys() {
    log_info "Generating validator keys with domain: ${DOMAIN}"
    echo ""
    
    # Generate master keys
    validator-keys create_keys
    
    log_info "✓ Master keys generated"
}

set_domain() {
    log_info "Setting domain and generating attestation..."
    
    # Set domain to get attestation - output to file for parsing
    local output_file="${KEYS_DIR}/domain_output.txt"
    validator-keys set_domain "${DOMAIN}" > "${output_file}" 2>&1
    
    cat "${output_file}"
    
    # Extract key info from output
    local pubkey=$(grep 'validator public key:' "${output_file}" | awk '{print $NF}')
    local attestation=$(grep 'attestation=' "${output_file}" | sed 's/.*attestation="//' | sed 's/".*//' | tr -d ' \n\t')
    
    if [ -z "$pubkey" ]; then
        log_error "Failed to extract validator public key"
        exit 1
    fi
    
    # Save to files
    echo "$pubkey" > "${KEYS_DIR}/public_key.txt"
    echo "$attestation" > "${KEYS_DIR}/attestation.txt"
    
    # Extract validator token section
    sed -n '/\[validator_token\]/,/^$/p' "${output_file}" > "${KEYS_DIR}/validator_token.txt"
    
    # Clean up temp file
    rm -f "${output_file}"
    
    log_info "✓ Domain attestation generated"
    log_info "✓ Public key: ${pubkey}"
}

create_toml_template() {
    log_info "Creating xrp-ledger.toml with attestation..."
    
    local pubkey=$(cat "${KEYS_DIR}/public_key.txt")
    local attestation=$(cat "${KEYS_DIR}/attestation.txt")
    
    cat > "${KEYS_DIR}/xrp-ledger.toml" <<EOF
# Lucendex XRPL Validator Domain Verification
# Production configuration with cryptographic attestation

[[VALIDATORS]]
public_key = "${pubkey}"
attestation = "${attestation}"
network = "main"
owner_country = "MT"
server_country = "NL"
EOF
    
    log_info "✓ xrp-ledger.toml created with attestation"
}

show_summary() {
    echo ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "🎉 Production Validator Keys Generated!"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "Files created in: ${KEYS_DIR}/"
    echo "  • validator-keys.json    (MASTER KEY - keep offline!)"
    echo "  • public_key.txt         (share publicly)"
    echo "  • attestation.txt        (cryptographic proof)"
    echo "  • validator_token.txt    (for rippled.cfg)"
    echo "  • xrp-ledger.toml        (with attestation)"
    echo ""
    log_warn "CRITICAL SECURITY:"
    log_warn "  • NEVER upload validator-keys.json to server!"
    log_warn "  • NEVER commit validator-keys.json to git!"
    log_warn "  • Backup to encrypted storage!"
    echo ""
    log_info "Public Key (for UNL registration):"
    cat "${KEYS_DIR}/public_key.txt"
    echo ""
    log_info "Next Steps:"
    log_info "  Run: cd .. && ./validator-attestation.sh"
    log_info "  This will:"
    log_info "    • Update validator with new token"
    log_info "    • Push xrp-ledger.toml to GitHub/Cloudflare"
    log_info "    • Enable production attestation"
    echo ""
}

main() {
    log_info "Production Validator Key Generation with Attestation"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    check_tool
    create_keys_directory
    generate_keys
    set_domain
    create_toml_template
    show_summary
}

main "$@"

</final_file_content>

IMPORTANT: For any future changes to this file, use the final_file_content shown above as your reference. This content reflects the current state of the file, including any auto-formatting (e.g., if you used single quotes but the formatter converted them to double quotes). Always base your SEARCH/REPLACE operations on this final version to ensure accuracy.

<environment_details>
# Visual Studio Code Visible Files
infra/validator/scripts/generate-offline-keys.sh

# Visual Studio Code Open Tabs
infra/validator/validator-destroy.sh
infra/README.md
infra/validator/QUICKSTART-VALIDATOR.md
infra/validator/DOMAIN-VERIFICATION.md
.gitignore
infra/validator/validator-attestation.sh
infra/validator/scripts/setup-validator-keys-tool.sh
infra/validator/scripts/generate-offline-keys.sh
infra/validator/docker/rippled.cfg
infra/validator/scripts/setup-vm.sh
infra/validator/validator-deploy.sh
infra/validator/validator-update.sh
infra/validator/Makefile

# Current Time
10/29/2025, 4:21:42 PM (Europe/Malta, UTC+1:00)

# Context Window Usage
367,049 / 1,000K tokens used (37%)

# Current Mode
ACT MODE

main "$@"
