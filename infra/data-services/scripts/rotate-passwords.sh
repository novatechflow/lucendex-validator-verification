#!/bin/bash
# Password Rotation Script for Lucendex Data Services
# Rotates all database passwords with minimal downtime

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

INSTANCE_IP=$1
SSH_KEY=$2
ENVRC_FILE=$3

if [ -z "$INSTANCE_IP" ] || [ -z "$SSH_KEY" ] || [ -z "$ENVRC_FILE" ]; then
    log_error "Usage: $0 <instance_ip> <ssh_key> <envrc_file>"
    exit 1
fi

log_info "Starting password rotation for data services"
log_warn "This will rotate all 4 database passwords"
log_warn "Indexer will restart (brief ~5 second interruption)"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Rotation cancelled"
    exit 0
fi

# Generate new passwords
log_info "Generating new passwords..."
NEW_POSTGRES=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)
NEW_INDEXER=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)
NEW_ROUTER=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)
NEW_API=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)

log_info "✓ New passwords generated"

# Display new passwords
echo ""
log_warn "🔐 NEW PASSWORDS (save these securely):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PostgreSQL: $NEW_POSTGRES"
echo "Indexer:    $NEW_INDEXER"
echo "Router:     $NEW_ROUTER"
echo "API:        $NEW_API"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Press Enter to apply rotation..."

# Update PostgreSQL passwords
log_info "Updating PostgreSQL passwords..."
ssh -i "$SSH_KEY" root@"$INSTANCE_IP" << EOF
docker exec lucendex-postgres psql -U postgres -d lucendex -c "ALTER ROLE postgres WITH PASSWORD '$NEW_POSTGRES';"
docker exec lucendex-postgres psql -U postgres -d lucendex -c "ALTER ROLE indexer_rw WITH PASSWORD '$NEW_INDEXER';"
docker exec lucendex-postgres psql -U postgres -d lucendex -c "ALTER ROLE router_ro WITH PASSWORD '$NEW_ROUTER';"
docker exec lucendex-postgres psql -U postgres -d lucendex -c "ALTER ROLE api_ro WITH PASSWORD '$NEW_API';"
EOF
log_info "✓ PostgreSQL passwords updated"

# Update .env file on VM
log_info "Updating /opt/lucendex/.env on VM..."
ssh -i "$SSH_KEY" root@"$INSTANCE_IP" << EOF
cat > /opt/lucendex/.env << 'ENVEOF'
# Database passwords (rotated $(date))
POSTGRES_PASSWORD=$NEW_POSTGRES
INDEXER_DB_PASSWORD=$NEW_INDEXER
ROUTER_DB_PASSWORD=$NEW_ROUTER
API_DB_PASSWORD=$NEW_API

# Indexer configuration
DATABASE_URL=postgres://indexer_rw:$NEW_INDEXER@localhost:5432/lucendex?sslmode=disable
RIPPLED_WS=ws://localhost:6006

# Router configuration (M1)
ROUTER_DB_URL=postgres://router_ro:$NEW_ROUTER@localhost:5432/lucendex?sslmode=require

# API configuration (M2)
API_DB_URL=postgres://api_ro:$NEW_API@localhost:5432/lucendex?sslmode=require
ENVEOF
chmod 600 /opt/lucendex/.env
EOF
log_info "✓ VM .env file updated"

# Regenerate SSL certificate
log_info "Regenerating SSL certificate..."
ssh -i "$SSH_KEY" root@"$INSTANCE_IP" << 'EOF'
docker exec lucendex-postgres sh -c '
  openssl req -new -newkey rsa:2048 -x509 -sha256 -days 365 -nodes \
    -subj "/C=MT/ST=Malta/L=Valletta/O=Lucendex/CN=postgres.lucendex.local" \
    -keyout /var/lib/postgresql/data/server.key \
    -out /var/lib/postgresql/data/server.crt && \
  chmod 600 /var/lib/postgresql/data/server.key && \
  chown postgres:postgres /var/lib/postgresql/data/server.*'
EOF
log_info "✓ SSL certificate regenerated"

# Restart PostgreSQL to load new cert
log_info "Restarting PostgreSQL..."
ssh -i "$SSH_KEY" root@"$INSTANCE_IP" "cd /opt/lucendex/docker && docker compose restart postgres"
sleep 5

# Restart indexer to pick up new passwords
log_info "Restarting indexer service..."
ssh -i "$SSH_KEY" root@"$INSTANCE_IP" "systemctl restart indexer"
sleep 2
log_info "✓ Indexer restarted with new passwords"

# Update local .envrc
log_info "Updating local .envrc..."

# Extract Vultr API key from existing .envrc
VULTR_KEY=$(grep "export VULTR_API_KEY=" "$ENVRC_FILE" | cut -d'"' -f2)

cat > "$ENVRC_FILE" << EOF
# Vultr API Configuration
# Password rotation: $(date)

export VULTR_API_KEY="$VULTR_KEY"
export TF_VAR_vultr_api_key="\${VULTR_API_KEY}"

# Database Passwords (rotated $(date))
export TF_VAR_postgres_password="$NEW_POSTGRES"
export TF_VAR_indexer_db_password="$NEW_INDEXER"
export TF_VAR_router_db_password="$NEW_ROUTER"
export TF_VAR_api_db_password="$NEW_API"

# Optional: Restrict SSH to your IP
# export TF_VAR_admin_ip="your.ip.address.here"

# Optional: Change region (default: Frankfurt)
# export TF_VAR_region="fra"

# Optional: Change environment
# export TF_VAR_environment="production"
EOF

chmod 600 "$ENVRC_FILE"
log_info "✓ Local .envrc updated"

# Verify indexer is running
sleep 3
log_info "Verifying indexer status..."
if ssh -i "$SSH_KEY" root@"$INSTANCE_IP" "systemctl is-active indexer" &> /dev/null; then
    log_info "✓ Indexer is running with new passwords"
else
    log_error "Indexer failed to start! Check logs: make indexer-logs"
    exit 1
fi

echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "🎉 Password Rotation Complete!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "All 4 database passwords have been rotated"
log_info "Indexer resumed automatically from last checkpoint"
log_info "Monitor: make indexer-logs"
echo ""
