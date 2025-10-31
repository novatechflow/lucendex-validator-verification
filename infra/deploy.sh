#!/bin/bash
# Lucendex Unified Infrastructure Deployment
# Manages deployment of validator, data-services, and future K8s migration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

show_banner() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        Lucendex Infrastructure Deployment                 ║
║        Neutral, Non-Custodial XRPL DEX Aggregator        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo ""
}

show_menu() {
    echo "Available Components:"
    echo ""
    echo "  1. Validator       - XRPL validator node (M4)"
    echo "  2. Data Services   - API + History + PostgreSQL (M0)"
    echo "  3. All Components  - Deploy everything"
    echo "  4. Status Check    - Check all deployments"
    echo "  5. Destroy         - Tear down infrastructure"
    echo ""
    echo "  K. K8s Migration   - Prepare for Kubernetes (future)"
    echo "  Q. Quit"
    echo ""
}

deploy_validator() {
    log_step "Deploying XRPL Validator..."
    cd "${SCRIPT_DIR}/validator"
    ./validator-deploy.sh
    cd "${SCRIPT_DIR}"
    log_info "✓ Validator deployment complete"
}

deploy_data_services() {
    log_step "Deploying Data Services..."
    cd "${SCRIPT_DIR}/data-services"
    ./data-services-deploy.sh
    cd "${SCRIPT_DIR}"
    log_info "✓ Data services deployment complete"
}

check_status() {
    log_step "Checking Infrastructure Status..."
    echo ""
    
    # Check validator
    if [ -d "${SCRIPT_DIR}/validator/terraform" ]; then
        cd "${SCRIPT_DIR}/validator"
        if [ -f "terraform/terraform.tfstate" ]; then
            log_info "Validator: Deployed"
            make status 2>/dev/null || true
        else
            log_warn "Validator: Not deployed"
        fi
        cd "${SCRIPT_DIR}"
    fi
    
    echo ""
    
    # Check data services
    if [ -d "${SCRIPT_DIR}/data-services/terraform" ]; then
        cd "${SCRIPT_DIR}/data-services"
        if [ -f "terraform/terraform.tfstate" ]; then
            log_info "Data Services: Deployed"
            make status 2>/dev/null || true
        else
            log_warn "Data Services: Not deployed"
        fi
        cd "${SCRIPT_DIR}"
    fi
}

destroy_infrastructure() {
    log_warn "WARNING: This will destroy ALL infrastructure!"
    read -p "Type 'DESTROY' to confirm: " confirm
    
    if [ "$confirm" != "DESTROY" ]; then
        log_info "Destruction cancelled"
        return 0
    fi
    
    log_step "Destroying infrastructure..."
    
    # Destroy data services first
    if [ -f "${SCRIPT_DIR}/data-services/terraform/terraform.tfstate" ]; then
        log_info "Destroying data services..."
        cd "${SCRIPT_DIR}/data-services"
        make destroy
        cd "${SCRIPT_DIR}"
    fi
    
    # Destroy validator
    if [ -f "${SCRIPT_DIR}/validator/terraform/terraform.tfstate" ]; then
        log_info "Destroying validator..."
        cd "${SCRIPT_DIR}/validator"
        make destroy
        cd "${SCRIPT_DIR}"
    fi
    
    log_info "✓ Infrastructure destroyed"
}

prepare_k8s() {
    log_step "Kubernetes Migration Preparation"
    echo ""
    log_info "Current deployment: Vultr VMs (manual scaling)"
    log_info "Target deployment: Kubernetes (auto-scaling)"
    echo ""
    log_info "K8s Migration Checklist:"
    echo "  [ ] Convert Docker Compose to K8s manifests/Helm charts"
    echo "  [ ] Set up persistent volumes for PostgreSQL"
    echo "  [ ] Configure ingress for rippled endpoints"
    echo "  [ ] Implement horizontal pod autoscaling"
    echo "  [ ] Set up monitoring (Prometheus + Grafana)"
    echo "  [ ] Configure secrets management (sealed-secrets/Vault)"
    echo "  [ ] Set up CI/CD pipeline (ArgoCD)"
    echo ""
    log_warn "K8s migration is planned for post-MVP"
    log_info "Current Vultr deployment supports M0-M3"
    echo ""
    read -p "Press Enter to continue..."
}

main() {
    show_banner
    
    while true; do
        show_menu
        read -p "Select option: " choice
        echo ""
        
        case $choice in
            1)
                deploy_validator
                ;;
            2)
                deploy_data_services
                ;;
            3)
                log_step "Deploying All Components..."
                deploy_validator
                echo ""
                deploy_data_services
                log_info "✓ All components deployed"
                ;;
            4)
                check_status
                ;;
            5)
                destroy_infrastructure
                ;;
            [Kk])
                prepare_k8s
                ;;
            [Qq])
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid option"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
        show_banner
    done
}

# Handle non-interactive mode
if [ $# -gt 0 ]; then
    case $1 in
        validator)
            deploy_validator
            ;;
        data-services)
            deploy_data_services
            ;;
        all)
            deploy_validator
            deploy_data_services
            ;;
        status)
            check_status
            ;;
        destroy)
            destroy_infrastructure
            ;;
        k8s)
            prepare_k8s
            ;;
        *)
            echo "Usage: $0 {validator|data-services|all|status|destroy|k8s}"
            exit 1
            ;;
    esac
else
    main
fi
