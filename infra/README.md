# Lucendex Infrastructure

Unified infrastructure management for Lucendex XRPL DEX platform.

## Quick Start

### From Project Root (Recommended)

```bash
# Show all available commands
make help

# Deploy infrastructure
make data-deploy         # Deploy M0 infrastructure
make validator-deploy    # Deploy M4 validator

# Deploy indexer
make indexer-deploy      # Build, deploy, auto-start

# Monitor everything
make status              # All components
make indexer-logs        # Watch indexer process ledgers
```

### Alternative: Interactive Menu

```bash
./infra/deploy.sh        # Interactive menu with all options
```

### Alternative: Component-Specific

```bash
cd validator && make help              # Validator commands
cd data-services && make help          # Data services commands
```

## Architecture Overview

```
infra/
├── deploy.sh           # 🆕 Unified deployment wrapper
├── validator/          # ✅ XRPL Validator (deployed)
├── data-services/      # ✅ API + History + PostgreSQL (ready)
└── README.md          # This file
```

## Current Components

### ✅ Validator (M4 - Deployed)

XRPL validator for Lucendex network participation.

**Location:** `validator/`

**Status:** ✅ Deployed & Syncing

**Specs:**
- Provider: Vultr Amsterdam
- Size: 4 vCPU / 8GB RAM / 160GB SSD
- Cost: $48/month

**Key Features:**
- Terraform-based deployment
- Hardened Docker security
- Domain verification (lucendex.com)
- SHA256 image pinning
- Automated key generation
- UFW firewall + fail2ban

**Commands:**
```bash
cd validator
make status        # Check validator status
make logs          # View logs
make sync-status   # Check sync progress
make backup        # Create backup
make ssh           # SSH into validator
```

**Documentation:** [validator/QUICKSTART-VALIDATOR.md](validator/QUICKSTART-VALIDATOR.md)

### ✅ Data Services (M0 - Deployed & Syncing)

Combined infrastructure for backend services.

**Location:** `data-services/`

**Status:** ✅ Deployed 2025-11-01, Nodes Syncing

**Components:**
- rippled API Node (fast RPC)
- rippled Full-History Node (indexer feed)
- PostgreSQL 15 (database)
- Backend services (Go)

**Specs:**
- Provider: Vultr Frankfurt
- Size: 6 vCPU / 16GB RAM / 320GB SSD
- Cost: $96/month

**Key Features:**
- ✅ Terraform infrastructure
- ✅ Docker Compose orchestration
- ✅ PostgreSQL with RLS
- ✅ Database migrations (AMM pools, orderbook, checkpoints)
- ✅ Go WebSocket client (85% test coverage)
- ✅ Automated API key prompting
- ✅ Security hardening

**Commands:**
```bash
cd data-services
make deploy        # Deploy infrastructure
make status        # Service status
make logs          # Live logs
make sync-api      # API node sync
make sync-history  # History node sync
make backup        # Database backup
make ssh           # SSH into VM
```

**Documentation:** [doc/project_progress/M0_data_services.md](../doc/project_progress/M0_data_services.md)

## Unified Infrastructure Management

The new `deploy.sh` wrapper provides centralized management:

**Features:**
- 🎯 Single entry point for all infrastructure
- 📊 Status checking across components
- 🔄 Unified destruction workflow
- ☸️ K8s migration preparation
- 🤖 Interactive menu or CLI mode

**Interactive Mode:**
```bash
./deploy.sh

╔═══════════════════════════════════════════════════════════╗
║        Lucendex Infrastructure Deployment                 ║
║        Neutral, Non-Custodial XRPL DEX Aggregator        ║
╚═══════════════════════════════════════════════════════════╝

Available Components:
  1. Validator       - XRPL validator node (M4)
  2. Data Services   - API + History + PostgreSQL (M0)
  3. All Components  - Deploy everything
  4. Status Check    - Check all deployments
  5. Destroy         - Tear down infrastructure
  
  K. K8s Migration   - Prepare for Kubernetes (future)
  Q. Quit
```

**CLI Mode:**
```bash
./deploy.sh all              # Deploy everything
./deploy.sh validator        # Validator only
./deploy.sh data-services    # Data services only
./deploy.sh status           # Check status
./deploy.sh destroy          # Destroy all
./deploy.sh k8s             # K8s migration prep
```

## Backend Code

**Location:** `../backend/`

**Status:** 🟡 40% Complete (XRPL client done, parsers pending)

**Structure:**
```
backend/
├── go.mod, go.sum           # ✅ Dependencies
├── cmd/indexer/             # ⏳ Entry point (pending)
├── internal/
│   ├── xrpl/               # ✅ WebSocket client (tested)
│   ├── parser/             # ⏳ Transaction parsers (pending)
│   └── store/              # ⏳ Database layer (pending)
└── db/migrations/           # ✅ Schema migrations
    ├── 001_amm_pools.sql
    ├── 002_orderbook_state.sql
    └── 003_ledger_checkpoints.sql
```

**Test Coverage:** ~85% (exceeds 70% target)

**Test Command:**
```bash
make test              # From project root
make backend-cover     # With HTML coverage report
```

## CLI Reference

### Global Commands (from project root)

**Deployment:**
```bash
make deploy            # Deploy all infrastructure
make validator-deploy  # Deploy validator (M4)
make data-deploy       # Deploy data services (M0)
make indexer-deploy    # Build & deploy indexer
```

**Monitoring:**
```bash
make status            # Check all components
make validator-status  # Validator status
make validator-sync    # Validator sync progress
make data-status       # Data services status
make data-sync-api     # API node sync
make data-sync-history # History node sync
make indexer-status    # Indexer service status
make indexer-logs      # Watch indexer (live)
```

**Operations:**
```bash
make validator-logs    # Validator logs
make data-logs         # All data service logs
make data-db-shell     # PostgreSQL shell
make validator-backup  # Backup validator config
make data-backup       # Backup database
make indexer-restart   # Restart indexer
make test              # Run all backend tests
```

**Shortcuts:**
```bash
make v-status          # = make validator-status
make v-logs            # = make validator-logs  
make v-sync            # = make validator-sync
make d-status          # = make data-status
make d-logs            # = make data-logs
make d-sync            # = make data-sync-api
make b-test            # = make backend-test
make b-build           # = make backend-build
```

### Validator Commands (Monitoring - from root)

```bash
# Read-only monitoring (safe to run from project root)
make validator-status              # Enhanced status with detailed metrics
make validator-sync                # Detailed sync progress
make validator-validators          # UNL status (35 validators)
make validator-peers               # Show peer connections
make validator-consensus           # Consensus participation
make validator-ledger-status       # Current + closed ledger
make validator-logs                # Follow logs (live)
make validator-logs-tail           # Last 100 lines
make validator-logs-startup        # First 200 lines
make validator-keys                # Show public key
make validator-config              # View full rippled.cfg
make validator-version             # rippled version
make validator-info                # Deployment info
make validator-resources           # CPU/memory/disk usage
make validator-updates             # Check system updates
make validator-firewall-status     # UFW status
make validator-test-connectivity   # Test peer port 51235
make validator-verify-backup       # Verify latest backup
make validator-verify-image        # Verify Docker image SHA256
make validator-backup              # Create backup
make validator-ssh                 # SSH into VM
```

### Validator Admin Commands (require cd infra/validator/)

**⚠️ Destructive operations - require explicit cd for safety:**

```bash
cd infra/validator

# Admin-only commands
make enable-validation     # Uncomment [validator_token], deploy, restart
make disable-validation    # Comment [validator_token], deploy, restart  
make wipe-ledger-db        # Nuclear: wipe DB and resync
make update-config         # Deploy rippled.cfg changes
make restart               # Restart rippled
make stop                  # Stop rippled
make start                 # Start rippled
```

**Typical workflow:**
```bash
# Initial deploy (tracking mode)
make validator-deploy

# After sync complete
cd infra/validator
make enable-validation      # Activate validation

# If stuck
make wipe-ledger-db        # Nuclear option

# For maintenance
make disable-validation    # Switch to tracking
# ... maintenance ...
make enable-validation     # Re-activate
```

### Data Services Commands

```bash
cd infra/data-services

# Core Operations
make status            # Docker services status
make logs              # Follow all logs (live)
make logs-tail         # Last 100 lines (static)
make sync-api          # API node sync status
make sync-history      # History node sync status
make services          # List running containers
make resources         # CPU/memory/disk usage
make backup            # Database backup
make db-shell          # PostgreSQL shell
make restart           # Restart all services
make ssh               # SSH into VM

# Production Diagnostics (NEW)
make health-check      # Comprehensive health scan
make validators-api    # Check API node UNL status
make validators-history # Check history node UNL status
make peers-api         # Show API node peers
make peers-history     # Show history node peers
make db-health         # Database health + table sizes
make disk-space        # Check disk usage (all nodes)
make network-test      # Test connectivity (ports 51234-51236)
make logs-api          # API node logs only
make logs-history      # History node logs only
make logs-postgres     # PostgreSQL logs only
make logs-errors       # Recent errors across all services

# Indexer Operations
make indexer-deploy    # Build, deploy, auto-start
make indexer-status    # Systemd service status
make indexer-logs      # Live logs (follow mode)
make indexer-restart   # Restart indexer service
```

### Backend Commands

```bash
# From project root
make backend-test      # Run tests
make backend-cover     # Coverage report (HTML)
make backend-build     # Build indexer binary

# From backend/ directory
cd backend
go test ./... -v -cover
go build ./cmd/indexer
```

## Production Monitoring

### Quick Health Check

```bash
# Single command to check everything
make data-health-check

# Expected output:
# ✓ All containers running
# ✓ API node: tracking (or syncing)
# ✓ History node: tracking (or syncing)  
# ✓ UNL: active, 35 validators
# ✓ Database: 3+ tables
# ✓ Disk: < 80% used
```

### Monitoring Sync Progress

```bash
# Watch API node sync (256 ledgers, ~2-4 hours)
watch -n 30 'make data-sync-api'

# Watch history node sync (full backfill, ~12-24 hours)
watch -n 60 'make data-sync-history'

# Check all nodes at once
make sync-status
```

### Checking for Issues

```bash
# Recent errors across all services
make data-logs-errors

# Verify UNL is loading (should show 35 validators)
make data-validators-api

# Check peer connectivity (should show 10+ peers)
make data-peers-api

# Monitor disk space (history node will grow to ~150-200GB)
make data-disk-space

# Database health
make data-db-health
```

## Complete Workflow

### Initial Deployment

```bash
# 1. Deploy data services infrastructure
make data-deploy
# Prompts for: Vultr API key, database passwords
# Creates: VM, rippled nodes, PostgreSQL

# 2. Wait for rippled to sync (6-12 hours)
make data-sync-history

# 3. Deploy indexer (automated)
make indexer-deploy
# Builds binary, copies to VM, installs systemd service, starts

# 4. Monitor
make indexer-logs       # Watch processing
make data-db-shell      # Query data: SELECT * FROM core.amm_pools;
```

### Daily Operations

```bash
# Morning health check
make data-health-check

# Monitor indexer processing
make indexer-logs

# Check sync status
make sync-status

# Backup database (automated, but manual available)
make data-backup

# Check for errors
make data-logs-errors

# Monitor disk space (especially history node)
make data-disk-space
```

### Troubleshooting

```bash
# Comprehensive Health Check (NEW - Use this first!)
make data-health-check
# Shows: Container status, sync state, UNL status, DB tables, disk usage

# Check specific issues
make data-validators-api      # Verify UNL loaded correctly
make data-peers-api           # Check peer connectivity
make data-disk-space          # Monitor disk usage
make data-logs-errors         # Recent errors across all services

# Detailed Node Status
make data-sync-api            # API node sync progress
make data-sync-history        # History node sync progress
make data-logs-api            # API node specific logs
make data-logs-history        # History node specific logs

# Database Diagnostics
make data-db-health           # Table sizes + PostgreSQL version
make data-db-shell            # Interactive SQL
# Inside shell:
SELECT * FROM core.latest_checkpoint;
SELECT * FROM core.get_indexer_lag();

# Indexer Troubleshooting
make indexer-status           # Systemd status
make indexer-logs             # Live log following
ssh into VM: make data-ssh
cat /opt/lucendex/logs/indexer.error.log

# Network Connectivity
make data-network-test        # Test RPC + peer ports

# Restart Services
make data-restart             # All containers
make indexer-restart          # Indexer only
```

## Design Principles

Per `.clinerules/`:

✓ **Zero-trust**: mTLS, Ed25519 signing, no shared secrets  
✓ **Non-custodial**: Backend never sees private keys  
✓ **Deterministic**: QuoteHash binding, reproducible execution  
✓ **Go stdlib-first**: No frameworks, direct SQL queries  
✓ **Unit tests mandatory**: Table-driven, 80%+ coverage  
✓ **Security-first**: Hardened containers, minimal privileges  

## K8s Migration Path

Current deployment uses Vultr VMs with manual scaling.  
Future deployment will use Kubernetes for auto-scaling.

**Checklist** (run `./deploy.sh k8s` for details):
- [ ] Convert Docker Compose to K8s manifests/Helm
- [ ] Set up persistent volumes for PostgreSQL
- [ ] Configure ingress for rippled endpoints
- [ ] Implement horizontal pod autoscaling
- [ ] Set up monitoring (Prometheus + Grafana)
- [ ] Configure secrets management
- [ ] Set up CI/CD pipeline (ArgoCD)

## Cost Breakdown

### Current Costs

| Component | Monthly Cost | Status |
|-----------|--------------|--------|
| Validator | $48 | ✅ Running |
| **Total** | **$48** | Active |

### After M0 Deployment

| Component | Monthly Cost | Status |
|-----------|--------------|--------|
| Validator | $48 | ✅ Running |
| Data Services | $96 | ✅ Ready |
| **Total** | **$144** | M0 Complete |

### Full Stack (M0-M5)

| Component | Monthly Cost | Milestone |
|-----------|--------------|-----------|
| Validator | $48 | M4 |
| Data Services | $96 | M0 |
| Monitoring | $12 | M1 |
| Object Storage | $10 | M2 |
| CDN/Edge | $0-20 | M2 |
| **Total** | **$166-186** | Production |

## Security

Per `doc/security.md`:

- ✅ All secrets gitignored (`.envrc`, SSH keys)
- ✅ Terraform state secured
- ✅ mTLS for inter-service communication
- ✅ Least-privilege database roles
- ✅ Row-level security (RLS) enabled
- ✅ Automated security updates
- ✅ SHA256 image pinning

## Documentation

- [Project Status](../doc/PROJECT_STATUS.md) - Overall progress
- [Architecture](../doc/architecture.md) - System design
- [Security](../doc/security.md) - Security requirements
- [Operations](../doc/operations.md) - Ops philosophy
- [M0 Progress](../doc/project_progress/M0_data_services.md) - Current milestone
- [M4 Progress](../doc/project_progress/M4_validator.md) - Validator details

## Development Standards

All code follows `.clinerules/`:

- **testing.md**: Table-driven tests, 80%+ coverage
- **architecture.md**: Go stdlib-first, no frameworks
- **security.md**: Zero-trust, mTLS, Ed25519 auth
- **rules.md**: KISS, evidence-based, unit tests mandatory

## Support

- **Internal Docs:** `doc/` directory
- **AI Dev Rules:** `.clinerules/` directory
- **GitHub:** git@github.com:2pk03/XRPL-DEX.git
- **Validator Status:** `cd validator && make sync-status`

---

**Note:** This is a living infrastructure. Components are deployed incrementally per milestone (M0-M5).
