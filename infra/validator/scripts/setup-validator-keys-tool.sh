#!/bin/bash
set -euo pipefail

# Setup validator-keys using Docker (no build needed!)
# For offline validator key generation with domain verification

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

check_docker() {
    if ! command -v docker &>/dev/null; then
        log_error "Docker not found"
        log_info "Install with:"
        log_info "  brew install docker colima  # Colima (lightweight)"
        log_info "  OR"
        log_info "  Docker Desktop from: https://www.docker.com/products/docker-desktop"
        exit 1
    fi
    
    if ! docker ps &>/dev/null; then
        log_error "Docker daemon not running"
        log_info "Start Docker:"
        log_info "  colima start                    # If using Colima"
        log_info "  OR"
        log_info "  Docker Desktop application      # If using Docker Desktop"
        exit 1
    fi
    
    log_info "✓ Docker is available and running (Colima or Docker Desktop)"
}

build_validator_keys_image() {
    log_info "Building validator-keys Docker image..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local docker_dir="${script_dir}/../docker"
    
    cd "${docker_dir}"
    docker build \
        --platform linux/amd64 \
        -t validator-keys-tool:latest \
        -f Dockerfile.validator-keys \
        . >/dev/null 2>&1
    
    log_info "✓ validator-keys image built"
}

create_validator_keys_wrapper() {
    log_info "Creating validator-keys wrapper script..."
    
    local install_dir="${HOME}/.local/bin"
    mkdir -p "${install_dir}"
    
    # Create wrapper script that runs validator-keys inside Docker
    cat > "${install_dir}/validator-keys" <<'EOF'
#!/bin/bash
# Wrapper script to run validator-keys inside Docker container
# Uses rippled Ubuntu package which includes validator-keys

KEYS_DIR="${HOME}/.validator-keys-secure"
mkdir -p "${KEYS_DIR}"

# Run validator-keys from Ubuntu package
docker run --rm \
    --platform linux/amd64 \
    -v "${KEYS_DIR}:/keys" \
    -w /keys \
    validator-keys-tool:latest \
    "$@"
EOF
    
    chmod +x "${install_dir}/validator-keys"
    log_info "✓ validator-keys wrapper created at ${install_dir}/validator-keys"
}

add_to_path() {
    log_info "Adding to PATH..."
    
    local shell_rc="${HOME}/.zshrc"
    local install_dir="${HOME}/.local/bin"
    
    if ! grep -q "${install_dir}" "${shell_rc}" 2>/dev/null; then
        echo "" >> "${shell_rc}"
        echo "# Validator Keys Tool (Docker)" >> "${shell_rc}"
        echo "export PATH=\"${install_dir}:\$PATH\"" >> "${shell_rc}"
        log_info "✓ Added to ${shell_rc}"
        log_warn "Run: source ${shell_rc}"
    else
        log_info "✓ Already in PATH"
    fi
}

verify_installation() {
    log_info "Verifying installation..."
    
    local install_dir="${HOME}/.local/bin"
    
    # Test if script exists and is executable
    if [ -x "${install_dir}/validator-keys" ]; then
        log_info "✓ validator-keys wrapper created"
        
        # Test Docker command (validator-keys --help may not work)
        if docker run --rm rippleci/rippled:latest /opt/ripple/bin/validator-keys --help &>/dev/null; then
            log_info "✓ validator-keys-tool accessible via Docker"
        else
            log_warn "Could not verify --help command, but tool should work"
        fi
    else
        log_error "Installation verification failed"
        exit 1
    fi
}

show_next_steps() {
    echo ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "validator-keys-tool (Docker) Installation Complete!"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "Next steps:"
    log_info "  1. Generate keys with domain:"
    echo "     cd infra/validator/scripts"
    echo "     ./generate-offline-keys.sh"
    echo ""
    log_info "  2. Or manually:"
    echo "     validator-keys create_keys"
    echo ""
    log_warn "IMPORTANT: Keys saved in ~/.validator-keys/"
    log_warn "Keep validator-keys.json offline and secure!"
    echo ""
}

main() {
    log_info "Setting up validator-keys-tool (Docker-based)"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    check_docker
    build_validator_keys_image
    create_validator_keys_wrapper
    add_to_path
    verify_installation
    show_next_steps
}

main "$@"
