#!/bin/bash
# Lucendex Data Services Destruction Script
# Safely destroys data services infrastructure with backups

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
log_warn "╔═══════════════════════════════════════════════════════════╗"
log_warn "║  WARNING: Data Services Infrastructure Destruction       ║"
log_warn "╚═══════════════════════════════════════════════════════════╝"
echo ""
log_warn "This will permanently delete:"
log_warn "  - Data Services VM"
log_warn "  - All rippled data (API + History nodes)"
log_warn "  - PostgreSQL database"
log_warn "  - All indexed AMM pools and orderbook data"
echo ""
log_info "Backups will be created automatically before destruction"
echo ""

# Confirm destruction
read -p "Type 'DESTROY' to confirm: " confirm
if [ "$confirm" != "DESTROY" ]; then
    log_info "Destruction cancelled"
    exit 0
fi

# Create backup directory
BACKUP_DIR="backups/destroy_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

log_info "Creating backup before destruction..."

# Backup database if VM is accessible
if [ -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
    INSTANCE_IP=$(cd "$TERRAFORM_DIR" && terraform output -raw data_services_ip 2>/dev/null || echo "")
    
    if [ -n "$INSTANCE_IP" ]; then
        log_info "Backing up database..."
        ssh -i "$TERRAFORM_DIR/data_services_ssh_key" root@"$INSTANCE_IP" \
            "docker exec lucendex-postgres pg_dump -U postgres lucendex" > "$BACKUP_DIR/database.sql" 2>/dev/null || \
            log_warn "Could not backup database (VM may be unreachable)"
        
        log_info "Backing up configurations..."
        scp -i "$TERRAFORM_DIR/data_services_ssh_key" root@"$INSTANCE_IP":/opt/lucendex/docker/*.cfg "$BACKUP_DIR/" 2>/dev/null || \
            log_warn "Could not backup configs"
        
        scp -i "$TERRAFORM_DIR/data_services_ssh_key" root@"$INSTANCE_IP":/opt/lucendex/.env "$BACKUP_DIR/.env" 2>/dev/null || \
            log_warn "Could not backup .env"
    fi
fi

# Backup Terraform state
log_info "Backing up Terraform state..."
cp -r "$TERRAFORM_DIR"/*.tfstate* "$BACKUP_DIR/" 2>/dev/null || true
cp "$TERRAFORM_DIR/.envrc" "$BACKUP_DIR/.envrc" 2>/dev/null || true

log_info "✓ Backups saved to $BACKUP_DIR"

# Destroy infrastructure
log_warn "Destroying infrastructure..."
cd "$TERRAFORM_DIR"

# Source .envrc if it exists (needed for terraform variables)
if [ -f ".envrc" ]; then
    source .envrc
fi

terraform destroy -auto-approve

log_info "✓ Infrastructure destroyed"

echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "🎉 Data Services Destroyed Successfully"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Backups saved to: $BACKUP_DIR"
log_info "  - database.sql"
log_info "  - Configuration files"
log_info "  - Terraform state"
log_info "  - .envrc (passwords)"
echo ""
log_warn "To redeploy: make data-deploy"
echo ""
