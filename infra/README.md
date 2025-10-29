# Lucendex Infrastructure

Multi-component infrastructure for Lucendex XRPL DEX platform.

## Architecture Overview

Lucendex infrastructure consists of independent, deployable components:

```
infra/
├── validator/          # XRPL Validator (Lucendex-operated)
├── api-node/          # rippled API Node (future)
├── full-history-node/ # rippled Full-History (future)
├── backend/           # Go services (Router, Indexer, APIs) (future)
├── database/          # PostgreSQL cluster (future)
├── frontend/          # React demo UI (future)
└── monitoring/        # Prometheus + Grafana (future)
```

Each component is independently deployable with its own:
- Deployment script (`*-deploy.sh`)
- Update script (`*-update.sh`)
- Destroy script (`*-destroy.sh`)
- Terraform state
- Lifecycle management

## Current Components

### ✅ Validator (Ready)

XRPL validator for Lucendex network participation.

**Location:** `infra/validator/`

**Commands:**
```bash
cd validator
./validator-deploy.sh    # Deploy validator
./validator-update.sh    # Update config/keys/image
./validator-destroy.sh   # Safely destroy with backups
```

**Documentation:** [validator/QUICKSTART-VALIDATOR.md](validator/QUICKSTART-VALIDATOR.md)

**Features:**
- Terraform-based Vultr deployment
- Hardened Docker security
- Domain verification (Lucendex branding)
- Automated key generation
- UFW firewall + fail2ban
- Daily backups

**Cost:** ~$48/month

## Planned Components

### 🔜 API Node

rippled node for read operations (indexer, public API).

### 🔜 Full-History Node

rippled with complete ledger history for AMM/orderbook replay.

### 🔜 Backend Services

Go-based services:
- Public API (REST)
- Partner API (REST/gRPC with Ed25519 auth)
- Router/Pathfinder (deterministic quotes)
- Indexer (ledger stream processor)
- Relay (optional, signed blob forwarding)

### 🔜 Database

PostgreSQL cluster with:
- Separate schemas (core, metering)
- Row-level security (RLS)
- Postgres Operator for K8s

### 🔜 Custom KV Store

Go-based key-value store:
- Raft consensus
- TTL support for rate limiting
- Quote caching

### 🔜 Frontend

React-based thin-trade demo UI served via Caddy.

### 🔜 Monitoring

Prometheus + Grafana + Loki stack with AI-ops agents.

## Design Principles

Per `.clinerules/`:

✓ **Zero-trust**: mTLS, Ed25519 signing, no shared secrets  
✓ **Non-custodial**: Backend never sees private keys  
✓ **Deterministic**: QuoteHash binding, reproducible execution  
✓ **KISS**: stdlib-first, no frameworks, direct queries  
✓ **IaC**: Everything in Terraform, portable across clouds  
✓ **Security-first**: Hardened containers, minimal privileges  

## Infrastructure Philosophy

From `doc/operations.md`:

- **AI-Ops over Human-Ops**: Automated monitoring and recovery
- **Cloud-Native**: Kubernetes, portable across providers
- **Zero Lock-In**: Terraform + Helm, no cloud-proprietary APIs
- **Self-Healing**: Auto-remediation via health controllers
- **Minimal Headcount**: <1 FTE for entire stack

## Getting Started

1. **Deploy Validator** (current milestone)
   ```bash
   cd validator
   ./validator-deploy.sh
   ```

2. **Future: Deploy API Node**
   ```bash
   cd api-node
   ./api-node-deploy.sh
   ```

3. **Future: Deploy Backend Services**
   ```bash
   cd backend
   ./backend-deploy.sh
   ```

Each component can be deployed, updated, and destroyed independently.

## Security

- All secrets gitignored (`.envrc`, SSH keys, validator keys)
- Terraform state contains sensitive data - keep secure
- Each component runs in isolated environment
- mTLS between all services
- Regular key rotation (quarterly for validators)

## Cost Estimate (Full Stack)

Per `doc/operations.md`:

| Component       | Monthly Cost |
| --------------- | ------------ |
| Validator       | $48          |
| API Node        | $40          |
| Full-History    | $80          |
| Backend (K8s)   | $800         |
| Database        | $400         |
| Monitoring      | $100         |
| Object Storage  | $20          |
| **Total**       | **~$1,500**  |

With AI-ops: ~$2,200-2,700/month all-inclusive

Break-even: $1.25M/month trading volume @ 0.2% fee

## Documentation

- [Architecture](../doc/architecture.md) - System design
- [Operations](../doc/operations.md) - Ops philosophy, costs
- [Security](../doc/security.md) - Security requirements
- [Definition](../doc/definition.md) - Value proposition, scope

## Support

Internal documentation in `doc/` directory.
Cline rules in `.clinerules/` for AI-assisted development.
