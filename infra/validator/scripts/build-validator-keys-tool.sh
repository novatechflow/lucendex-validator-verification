#!/bin/bash
set -euo pipefail

# Build validator-keys Tool using Docker (Production)
# Builds in Linux x86_64 container for maximum compatibility
# Extracts binary to use on M1 Mac (runs under Rosetta)
#
# This is the ONLY secure way to generate validator_token for rippled

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
DOCKER_DIR="${SCRIPT_DIR}/../docker"
INSTALL_DIR="${HOME}/.local/bin"
IMAGE_NAME="validator-keys-builder"

echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Build validator-keys Tool (Docker Method)"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check Docker
if ! docker ps &>/dev/null; then
    log_error "Docker not running. Start Docker and try again."
    exit 1
fi
log_info "✓ Docker is running"
echo ""

# Build Docker image
log_step "Building validator-keys in Docker (linux/amd64)..."
log_warn "This will take 10-15 minutes on first build..."
log_warn "Docker will download dependencies and compile from source"
echo ""

cd "${DOCKER_DIR}"
docker build \
    --platform linux/amd64 \
    -t ${IMAGE_NAME}:latest \
    -f Dockerfile.validator-keys \
    .

log_info "✓ Docker image built successfully"
echo ""

# Extract binary
log_step "Extracting validator-keys binary..."
mkdir -p "${INSTALL_DIR}"

# Create temporary container and copy binary
CONTAINER_ID=$(docker create --platform linux/amd64 ${IMAGE_NAME}:latest)
docker cp ${CONTAINER_ID}:/opt/ripple/bin/validator-keys "${INSTALL_DIR}/validator-keys"
docker rm ${CONTAINER_ID} >/dev/null

chmod +x "${INSTALL_DIR}/validator-keys"
log_info "✓ Binary extracted to ${INSTALL_DIR}/validator-keys"
echo ""

# Verify
log_step "Verifying binary..."
if "${INSTALL_DIR}/validator-keys" --help &>/dev/null; then
    log_info "✓ validator-keys working correctly (running under Rosetta on M1)"
else
    log_error "validator-keys verification failed"
    exit 1
fi
echo ""

# Summary
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ validator-keys Tool Built Successfully!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Installed at: ${INSTALL_DIR}/validator-keys"
log_info "Binary: linux/amd64 (runs under Rosetta on M1 Mac)"
echo ""
log_info "Next steps:"
echo "  1. Run: cd infra/validator/scripts"
echo "  2. Run: ./generate-validator-token.sh"
echo "  3. This will generate secure validator_token"
echo ""
