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

### ✅ Data Services (M0 - 80% Complete)

Combined infrastructure for backend services.

**Location:** `data-services/`

**Status:** ✅ Code Complete, Ready to Deploy

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

### Validator Commands

```bash
cd infra/validator

make status            # Quick status
make sync-status       # Detailed sync info
make logs              # Follow logs
make logs-tail         # Last 100 lines
make health            # Health check
make peers             # Connected peers
make consensus         # Consensus participation
make resources         # CPU/memory usage
make backup            # Backup config
make restart           # Restart rippled
make ssh               # SSH into VM
make get-pubkey        # Show public key
```

### Data Services Commands

```bash
cd infra/data-services

make status            # Docker services status
make logs              # Follow all logs
make sync-api          # API node sync
make sync-history      # History node sync
make services          # List running containers
make resources         # Resource usage
make backup            # Database backup
make db-shell          # PostgreSQL shell
make restart           # Restart all services
make ssh               # SSH into VM

# Indexer specific
make indexer-deploy    # Deploy indexer
make indexer-status    # Service status
make indexer-logs      # Live logs
make indexer-restart   # Restart service
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
# Check everything
make status

# Watch indexer
make indexer-logs

# Check sync progress
make data-sync-history

# Backup database
make data-backup

# Restart if needed
make indexer-restart
```

### Troubleshooting

```bash
# Check indexer service
make indexer-status

# View errors
ssh into VM: make data-ssh
cat /opt/lucendex/logs/indexer.error.log

# Check rippled
make data-sync-api
make data-sync-history
make data-logs

# Check database
make data-db-shell
SELECT * FROM core.latest_checkpoint;
SELECT * FROM core.get_indexer_lag();

# Restart everything
make data-restart
make indexer-restart
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
