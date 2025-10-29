#!/bin/bash
set -euo pipefail

# XRPL Validator Destroy Script
# Safely destroys validator infrastructure and cleans up resources

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"

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

get_validator_ip() {
    cd "${TERRAFORM_DIR}"
    terraform output -raw validator_ip 2>/dev/null || echo ""
}

check_deployment() {
    local ip=$(get_validator_ip)
    
    if [ -z "$ip" ]; then
        log_warn "No validator deployment found"
        return 1
    fi
    
    return 0
}

backup_validator_keys() {
    log_info "Backing up validator keys..."
    
    local ip=$(get_validator_ip)
    local backup_dir="${SCRIPT_DIR}/backups/final-$(date +%Y%m%d_%H%M%S)"
    
    mkdir -p "${backup_dir}"
    
    # Try to backup keys from server
    if scp -i "${TERRAFORM_DIR}/validator_ssh_key" \
           root@"${ip}":/opt/rippled/rippled.cfg \
           "${backup_dir}/rippled.cfg" 2>/dev/null; then
        log_info "✓ Configuration backed up to ${backup_dir}"
    else
        log_warn "Could not backup configuration from server"
    fi
    
    # Try to get validator keys
    if ssh -i "${TERRAFORM_DIR}/validator_ssh_key" root@"${ip}" \
           "docker exec rippled cat /var/lib/rippled/validator-keys.json" \
           > "${backup_dir}/validator-keys.json" 2>/dev/null; then
        log_info "✓ Validator keys backed up to ${backup_dir}"
    else
        log_warn "Could not backup validator keys"
    fi
    
    log_warn "IMPORTANT: Backup saved to ${backup_dir}"
    log_warn "Store these keys securely before destroying the validator!"
}

show_destruction_warning() {
    echo ""
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_error "⚠️  VALIDATOR DESTRUCTION WARNING"
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_warn "This will PERMANENTLY DELETE:"
    echo "  • Vultr VM and all data"
    echo "  • Validator keys (unless backed up)"
    echo "  • All validator history"
    echo "  • Firewall rules"
    echo "  • SSH keys"
    echo ""
    log_error "This action CANNOT be undone!"
    echo ""
}

confirm_destruction() {
    local validator_ip=$(get_validator_ip)
    
    echo "Validator IP: ${validator_ip}"
    echo ""
    
    log_warn "Type 'DESTROY' (all caps) to confirm destruction:"
    read -r confirmation
    
    if [ "$confirmation" != "DESTROY" ]; then
        log_info "Destruction cancelled"
        exit 0
    fi
    
    echo ""
    log_warn "Final confirmation. Type the validator IP to proceed:"
    read -r ip_confirmation
    
    if [ "$ip_confirmation" != "$validator_ip" ]; then
        log_error "IP mismatch. Destruction cancelled for safety."
        exit 1
    fi
}

destroy_infrastructure() {
    log_info "Destroying Vultr infrastructure..."
    
    cd "${TERRAFORM_DIR}"
    source .envrc 2>/dev/null || true
    
    terraform destroy -auto-approve
    
    log_info "✓ Infrastructure destroyed"
}

cleanup_local_files() {
    log_info "Cleaning up local artifacts..."
    
    # Clean Terraform state
    cd "${TERRAFORM_DIR}"
    rm -f terraform.tfstate*
    rm -f tfplan
    rm -rf .terraform
    rm -f .terraform.lock.hcl
    
    # Optionally remove SSH keys (ask user)
    if [ -f "${TERRAFORM_DIR}/validator_ssh_key" ]; then
        echo ""
        read -p "Remove local SSH keys? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "${TERRAFORM_DIR}/validator_ssh_key"
            rm -f "${TERRAFORM_DIR}/validator_ssh_key.pub"
            log_info "✓ SSH keys removed"
        else
            log_info "SSH keys kept"
        fi
    fi
    
    # Optionally remove .envrc (ask user)
    if [ -f "${TERRAFORM_DIR}/.envrc" ]; then
        echo ""
        read -p "Remove .envrc (contains API key)? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "${TERRAFORM_DIR}/.envrc"
            log_info "✓ .envrc removed"
        else
            log_info ".envrc kept"
        fi
    fi
    
    log_info "✓ Local cleanup complete"
}

show_completion() {
    echo ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "Validator Destruction Complete"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "All resources have been destroyed"
    echo ""
    
    if [ -d "${SCRIPT_DIR}/backups" ]; then
        log_warn "Backups are stored in: ${SCRIPT_DIR}/backups/"
        log_warn "Keep these backups secure!"
    fi
    
    echo ""
    log_info "To deploy a new validator:"
    log_info "  ./validator-deploy.sh"
    echo ""
}

main() {
    log_info "XRPL Validator Destruction Tool"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check if validator exists
    if ! check_deployment; then
        log_error "No validator deployment found"
        log_info "Nothing to destroy"
        exit 0
    fi
    
    # Show warning
    show_destruction_warning
    
    # Backup keys
    backup_validator_keys
    
    echo ""
    read -p "Backup complete. Continue with destruction? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Destruction cancelled"
        exit 0
    fi
    
    # Confirm destruction
    confirm_destruction
    
    # Destroy
    log_info "Beginning destruction..."
    destroy_infrastructure
    cleanup_local_files
    
    # Complete
    show_completion
}

main "$@"
