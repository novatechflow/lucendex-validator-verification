# Lucendex Architecture Constraints

## Core Design Principles

### Non-Custodial by Design
- Backend **never** sees private keys or seed phrases
- Wallets sign transactions client-side
- Relay (if enabled) only forwards signed blobs
- Quote binding ensures deterministic execution

### Deterministic Execution
- QuoteHash = blake2b-256(sorted quote params + fees + TTL)
- Quote embedded in XRPL transaction memo
- TTL enforced via LastLedgerSequence
- Router state must be reproducible from indexer snapshots

### Zero-Trust Architecture
- All inter-service traffic uses mTLS
- No implicit network trust
- Ed25519 request signing for partner API
- Replay protection via timestamp + request-id uniqueness

## Tech Stack Constraints

### Backend: Go
- **Required**: Go 1.21+
- **Stdlib-first**: Prefer stdlib over external dependencies
- **No frameworks**: Direct HTTP handlers, no web frameworks
- **No ORMs**: Direct SQL queries with `pgx` or `database/sql`
- **Concurrency**: Use channels and goroutines idiomatically
- **Error handling**: Explicit error returns, no panics in production code

### Database: PostgreSQL
- **Version**: PostgreSQL 15+
- **Access model**: Least-privilege roles per component
  - `indexer_rw`: Read/write for indexer
  - `router_ro`: Read-only for router
  - `api_ro`: Read-only for API handlers
- **Security**: Row-level security (RLS) for multi-tenant isolation
- **Schemas**: Separate schemas per domain (`core`, `metering`)
- **Audit**: `pgaudit` enabled for DDL/DML

### KV Store: Custom (Raft + TTL)
- In-process Go implementation
- Raft for consensus (if multi-node)
- TTL support for rate limiting and quote caching
- No Redis dependency in V1

### Frontend: React
- **Purpose**: Thin demo UI only (not production interface)
- **Static hosting**: Served via Caddy
- **No state management libraries**: Context API sufficient
- **No UI framework**: Plain React + CSS

## API Design

### Public Endpoints (`/public/*`)
- Read-only data and quote demos
- Global rate limits (no auth)
- No state-changing operations
- Examples: `/public/v1/pairs`, `/public/v1/quote`

### Partner Endpoints (`/partner/*`)
- Authenticated via Ed25519 request signing
- Per-partner quotas enforced in KV
- Usage metering written to `usage_events` table
- State-changing ops allowed (e.g., `/partner/v1/submit`)

### Quote Response Structure
```go
type QuoteResp struct {
    Route       Route
    Out         decimal.Decimal
    Price       decimal.Decimal
    Fees        Fees
    LedgerIndex uint32
    QuoteHash   [32]byte
    TTLLedgers  uint16
}

type Fees struct {
    RouterBps int
    EstOutFee decimal.Decimal
}
```

## Component Boundaries

### Indexer
- **Input**: XRPL ledger stream via WebSocket
- **Output**: Writes to PostgreSQL (`amm_pools`, `orderbook_state`)
- **State**: In-memory cache synced to DB
- **Dependencies**: `rippled` full-history node

### Router
- **Input**: Quote requests (token pair + amount)
- **Output**: Deterministic routes with QuoteHash
- **State**: Read-only access to indexer data
- **Logic**: AMM + orderbook pathfinding with routing fee injection

### API Layer
- **Input**: HTTP/JSON requests
- **Output**: JSON responses (quotes, orderbook, health)
- **Auth**: Ed25519 signature verification for partner endpoints
- **Rate limiting**: KV token bucket per partner/IP

### Relay (Optional)
- **Input**: Signed XRPL transaction blobs
- **Output**: Forwards to `rippled` submission endpoint
- **Security**: No transaction modification, signature validation only
- **Default**: Disabled (`RELAY_ENABLED=false`)

## XRPL Integration

### Node Requirements
- **API Node**: Low-latency read operations
- **Full-History Node**: Complete ledger history for indexer
- **Validator** (operated by Lucendex): Independent validation

### Transaction Flow
1. Client requests quote via API
2. Router computes best path + generates QuoteHash
3. Client receives quote with TTL
4. Client signs transaction (client-side) with QuoteHash in memo
5. Client submits directly to `rippled` OR via optional relay
6. Indexer observes transaction on ledger

## Infrastructure Requirements

### Deployment
- **Orchestration**: Kubernetes (K3s or managed)
- **CI/CD**: ArgoCD + GitHub Actions (GitOps)
- **Secrets**: HashiCorp Vault or environment injection
- **Monitoring**: Prometheus + Grafana
- **Logs**: Loki for centralized logging

### Networking
- **TLS**: Required for all external traffic
- **mTLS**: Required for inter-service communication
- **Ingress**: Cloudflare or Fly.io for edge + DDoS protection
- **Subnets**: Private subnets for database and internal services

## Scope Boundaries (V1)

### In Scope
- AMM + orderbook routing
- Deterministic quote binding
- Thin-trade demo UI
- Partner API with auth + quotas
- Circuit breakers for price anomalies

### Out of Scope
- No leverage or derivatives
- No custody services
- No proprietary token
- No liquidity mining incentives
- No cross-chain in V1
- No listing fees or launchpad features

## Performance Targets

- **Quote latency**: < 200ms p95
- **Indexer lag**: < 2 ledgers behind tip
- **API availability**: 99.9% uptime
- **Database queries**: < 50ms p95
- **Rate limits**: 100 req/min public, 1000 req/min partner (configurable)
