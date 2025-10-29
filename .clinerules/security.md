# Lucendex Security Requirements

## Zero-Trust Enforcement

### Network Layer
- **mTLS mandatory** for all inter-service communication
- No implicit network trust - private subnets + firewall per service
- TLS 1.3 minimum for external traffic
- Services run as non-root, read-only rootfs, seccomp enabled

### Authentication & Authorization
- **Ed25519 request signing** for partner API (no symmetric keys)
- Canonical request format: `METHOD + "\n" + PATH + "\n" + QUERY + "\n" + SHA256(body) + "\n" + TIMESTAMP`
- Replay protection: timestamp drift < 60s + request-id uniqueness in KV
- Optional mTLS for premium partners
- **2FA mandatory** for all admin/privileged access (FIDO2/WebAuthn preferred)

### API Security Model

#### Public Endpoints (`/public/*`)
- Read-only operations only
- Global rate limits via KV token bucket
- No authentication required
- Examples: quotes, orderbook, pairs

#### Partner Endpoints (`/partner/*`)
- Ed25519 signature verification required
- Per-partner quotas in KV
- Usage metering to `usage_events` table
- Headers required:
  ```
  X-Partner-Id: <uuid>
  X-Request-Id: <uuid>
  X-Timestamp: <rfc3339>
  X-Signature: base64(Ed25519.Sign(canonical_request))
  ```

## Database Security

### Access Control
- **Least-privilege roles**:
  - `indexer_rw`: Read/write for indexer only
  - `router_ro`: Read-only for router
  - `api_ro`: Read-only for API handlers
- Row-level security (RLS) for multi-tenant isolation
- Separate schemas per domain (`core`, `metering`)
- No superuser access from application code

### Encryption & Audit
- Full disk encryption (LUKS)
- TLS 1.3 for all client connections
- `password_encryption = 'scram-sha-256'`
- `pgaudit` enabled for DDL/DML operations
- WAL archiving for point-in-time recovery (PITR)

## Secrets Management

### Storage Rules
- **Never store**: private keys, seed phrases, user wallet secrets
- API keys stored as Ed25519 public keys only (no symmetric secrets)
- All secrets injected via HashiCorp Vault or sealed environment
- Rotation supported via versioned key table
- Recovery codes single-use and encrypted at rest

### Key Rotation
- Partner keys rotatable without downtime
- Revocation via `revoked` flag + short cache TTL
- Validator keys rotated quarterly
- TLS certificates auto-renewed via ACME

## Deterministic Execution Security

### Quote Binding
- `QuoteHash = blake2b-256(sorted_params + fees + TTL)`
- Quote hash embedded in XRPL transaction memo
- TTL enforced via `LastLedgerSequence`
- Fee injection included in hash (tamper-evident)
- Quotes must be reproducible from indexer state

### Transaction Validation
- Relay (if enabled) only forwards **signed blobs**
- No transaction modification by backend
- Signature validation before forwarding
- Quote hash mismatch = rejection
- Ledger index ≥ TTL = rejection

## Rate Limiting & Abuse Prevention

### Implementation
- KV token bucket per IP + per partner
- Circuit breakers for abnormal request spikes
- Fallback to read-only mode under attack
- Reject oversized payloads (max body size enforced)
- WAF rules at edge (Cloudflare/Fly.io)

### Partner Quotas
```go
key = fmt("rl:partner:%s:%d", partnerID, unixWindow)
count = KV.INCR(key)
if count == 1: KV.SET_TTL(key, windowSeconds)
if count > LIMIT(plan): reject 429
```

Plans: `free`, `pro`, `enterprise` with configurable limits

## Incident Response

### Detection
- Alert on anomalies: rippled lag, SLO breach, signature failures
- Synthetic canary checks every minute per critical market
- AI-ops agents monitor logs for patterns

### Response Flow
1. **Detect**: Anomaly alert triggers
2. **Contain**: Enable degraded mode, disable relay, restrict to read-only
3. **Preserve**: Snapshot logs, DB WAL, KV dump, node state
4. **Eradicate**: Patch/rollback, rotate compromised keys
5. **Recover**: Re-enable by tier (partners first, public last)
6. **Post-mortem**: Document timeline, root cause, control changes

### No Discretionary Actions
- Deterministic rules only
- No manual reimbursements or trade reversals
- Governance for rule changes only

## Compliance & Privacy

### Data Handling
- No PII persistence
- Metrics keyed by `partner_id` only (no user identifiers)
- Geofencing hook at API edge for sanctions compliance
- Audit logs retained per regulatory requirements

### Access Logging
- All admin actions logged with timestamp + actor
- Partner API calls logged with request-id for audit trail
- Database queries audited via `pgaudit`
- Logs encrypted at rest and in transit

## Infrastructure Hardening

### Container Security
- Immutable images (`FROM scratch` preferred)
- Image signing via cosign
- SBOM generated and published
- Dependency pinning + automated CVE scans
- No privileged containers

### Operational Security
- No SSH access (bastion with MFA only)
- CI/CD on separate network segment
- Secrets never in source code or logs
- State management via GitOps (ArgoCD)
- Terraform state encrypted and access-controlled

## STRIDE Threat Model

| Threat              | Example                       | Mitigation                                   |
| ------------------- | ----------------------------- | -------------------------------------------- |
| **Spoofing**        | Forged partner calls          | Ed25519 signing + mTLS + 2FA                 |
| **Tampering**       | Route/fee modified            | QuoteHash bound in memo + TLS/mTLS           |
| **Repudiation**     | Partner denies call           | Signed requests + audit log + request-id     |
| **Info Disclosure** | DB exfiltration               | FDE + least privilege + no PII               |
| **DoS**             | Flood quote/submit            | Per-partner rate limits + circuit breakers   |
| **Elevation**       | Lateral service movement      | mTLS per-service + no root + seccomp + SELinux |

## Security Testing Requirements

### Required Tests
- Signature verification bypass attempts
- Replay attack scenarios
- Rate limit enforcement
- QuoteHash tampering detection
- SQL injection prevention
- Authorization boundary tests
- TLS configuration validation

### Penetration Testing
- Quarterly external security audit
- Automated SAST/DAST in CI/CD
- Dependency vulnerability scanning
- Infrastructure configuration scanning
