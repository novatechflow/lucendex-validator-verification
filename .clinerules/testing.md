# Lucendex Testing Standards

## Core Testing Principles

### 1. Tests Are Mandatory
- Every exported function must have tests
- Every HTTP handler must have tests
- Every database query must have tests
- Code without tests will not be merged

### 2. Table-Driven Tests (Go Idiom)
```go
func TestQuoteHash(t *testing.T) {
    tests := []struct {
        name    string
        input   QuoteParams
        want    [32]byte
        wantErr bool
    }{
        {
            name: "valid quote",
            input: QuoteParams{
                In:      "XRP",
                Out:     "USD.rXYZ",
                Amount:  decimal.NewFromInt(100),
                Fees:    Fees{RouterBps: 20},
                TTL:     100,
            },
            want:    expectedHash,
            wantErr: false,
        },
        {
            name: "missing fees",
            input: QuoteParams{
                In:     "XRP",
                Out:    "USD.rXYZ",
                Amount: decimal.NewFromInt(100),
                TTL:    100,
            },
            want:    [32]byte{},
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ComputeQuoteHash(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("ComputeQuoteHash() error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            if got != tt.want {
                t.Errorf("ComputeQuoteHash() = %v, want %v", got, tt.want)
            }
        })
    }
}
```

### 3. Test Error Paths
- Don't just test happy paths
- Test invalid inputs, edge cases, boundary conditions
- Test timeout scenarios, connection failures, malformed data
- Example: test what happens when database is unavailable

### 4. Mock External Dependencies
```go
type MockRippled struct {
    SubmitFunc func(blob []byte) (string, error)
}

func (m *MockRippled) Submit(blob []byte) (string, error) {
    if m.SubmitFunc != nil {
        return m.SubmitFunc(blob)
    }
    return "", errors.New("not implemented")
}

func TestRelay(t *testing.T) {
    mock := &MockRippled{
        SubmitFunc: func(blob []byte) (string, error) {
            return "tx_hash_123", nil
        },
    }
    
    relay := NewRelay(mock)
    hash, err := relay.Forward(validBlob)
    // assertions...
}
```

### 5. Integration Tests (Separate)
- Unit tests in `*_test.go` alongside code
- Integration tests in `integration_test.go` with build tag
- Use `//go:build integration` tag
- Run with: `go test -tags=integration`

```go
//go:build integration

package api_test

func TestDatabaseConnection(t *testing.T) {
    db := setupTestDB(t)
    defer db.Close()
    
    // Test actual database queries
}
```

## Coverage Requirements

### Minimum Coverage
- **Critical paths**: 80% minimum (router, indexer, quote hash, auth)
- **API handlers**: 70% minimum
- **Utility functions**: 60% minimum
- **Overall project**: 70% target

### Check Coverage
```bash
go test -cover ./...
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## Security Testing

### Authentication Tests
```go
func TestEd25519Verification(t *testing.T) {
    tests := []struct {
        name       string
        signature  []byte
        publicKey  ed25519.PublicKey
        message    []byte
        wantValid  bool
    }{
        {
            name:      "valid signature",
            signature: validSig,
            publicKey: validPubKey,
            message:   canonicalRequest,
            wantValid: true,
        },
        {
            name:      "tampered message",
            signature: validSig,
            publicKey: validPubKey,
            message:   tamperedRequest,
            wantValid: false,
        },
        {
            name:      "wrong public key",
            signature: validSig,
            publicKey: wrongPubKey,
            message:   canonicalRequest,
            wantValid: false,
        },
    }
    // ...
}
```

### Rate Limit Tests
```go
func TestRateLimit(t *testing.T) {
    limiter := NewRateLimiter(100, time.Minute)
    
    // Test normal usage
    for i := 0; i < 100; i++ {
        if !limiter.Allow("partner_123") {
            t.Errorf("Request %d should be allowed", i)
        }
    }
    
    // Test quota exhaustion
    if limiter.Allow("partner_123") {
        t.Error("Request 101 should be rejected")
    }
    
    // Test quota reset after window
    time.Sleep(61 * time.Second) // Wait for window to expire
    if !limiter.Allow("partner_123") {
        t.Error("Request should be allowed after window reset")
    }
}
```

### QuoteHash Determinism
```go
func TestQuoteHashDeterminism(t *testing.T) {
    params := QuoteParams{
        In:     "XRP",
        Out:    "USD.rXYZ",
        Amount: decimal.NewFromFloat(100.5),
        Fees: Fees{
            RouterBps: 20,
            EstOutFee: decimal.NewFromFloat(0.1),
        },
        LedgerIndex: 12345,
        TTL:         100,
    }
    
    // Compute hash multiple times
    hash1 := ComputeQuoteHash(params)
    hash2 := ComputeQuoteHash(params)
    hash3 := ComputeQuoteHash(params)
    
    // Must be identical
    if hash1 != hash2 || hash2 != hash3 {
        t.Error("QuoteHash is not deterministic")
    }
    
    // Modify parameters slightly
    params.Fees.RouterBps = 21
    hash4 := ComputeQuoteHash(params)
    
    // Must differ
    if hash1 == hash4 {
        t.Error("QuoteHash did not change with different parameters")
    }
}
```

## HTTP Handler Tests

### Standard Pattern
```go
func TestQuoteHandler(t *testing.T) {
    tests := []struct {
        name           string
        method         string
        body           string
        mockRouter     *MockRouter
        wantStatus     int
        wantBodyFields []string
    }{
        {
            name:   "valid quote request",
            method: "POST",
            body:   `{"in":"XRP","out":"USD.rXYZ","amount":"100"}`,
            mockRouter: &MockRouter{
                QuoteFunc: func(in, out string, amt decimal.Decimal) (*Quote, error) {
                    return &Quote{Hash: [32]byte{1, 2, 3}}, nil
                },
            },
            wantStatus:     200,
            wantBodyFields: []string{"quote_hash", "ttl", "price"},
        },
        {
            name:       "invalid JSON",
            method:     "POST",
            body:       `{invalid}`,
            wantStatus: 400,
        },
        {
            name:       "wrong HTTP method",
            method:     "GET",
            wantStatus: 405,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            req := httptest.NewRequest(tt.method, "/quote", strings.NewReader(tt.body))
            rec := httptest.NewRecorder()
            
            handler := NewQuoteHandler(tt.mockRouter)
            handler.ServeHTTP(rec, req)
            
            if rec.Code != tt.wantStatus {
                t.Errorf("status = %d, want %d", rec.Code, tt.wantStatus)
            }
            
            // Verify response body fields if success
            if tt.wantStatus == 200 {
                var resp map[string]interface{}
                json.Unmarshal(rec.Body.Bytes(), &resp)
                for _, field := range tt.wantBodyFields {
                    if _, ok := resp[field]; !ok {
                        t.Errorf("missing field: %s", field)
                    }
                }
            }
        })
    }
}
```

## Database Tests

### Use Test Database
```go
func setupTestDB(t *testing.T) *sql.DB {
    db, err := sql.Open("postgres", "postgres://test:test@localhost:5433/testdb?sslmode=disable")
    if err != nil {
        t.Fatalf("failed to connect to test db: %v", err)
    }
    
    // Run migrations
    if err := runMigrations(db); err != nil {
        t.Fatalf("failed to run migrations: %v", err)
    }
    
    // Clean up on test completion
    t.Cleanup(func() {
        db.Exec("DROP SCHEMA public CASCADE; CREATE SCHEMA public;")
        db.Close()
    })
    
    return db
}

func TestInsertPartner(t *testing.T) {
    db := setupTestDB(t)
    
    partner := Partner{
        ID:   uuid.New(),
        Name: "Test Partner",
        Plan: "pro",
    }
    
    err := InsertPartner(db, partner)
    if err != nil {
        t.Fatalf("InsertPartner failed: %v", err)
    }
    
    // Verify insertion
    var count int
    err = db.QueryRow("SELECT COUNT(*) FROM partners WHERE id = $1", partner.ID).Scan(&count)
    if err != nil {
        t.Fatalf("query failed: %v", err)
    }
    if count != 1 {
        t.Errorf("expected 1 partner, got %d", count)
    }
}
```

## Benchmarks (When Needed)

### Performance-Critical Functions
```go
func BenchmarkComputeQuoteHash(b *testing.B) {
    params := QuoteParams{
        In:     "XRP",
        Out:    "USD.rXYZ",
        Amount: decimal.NewFromInt(100),
        Fees:   Fees{RouterBps: 20},
        TTL:    100,
    }
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        ComputeQuoteHash(params)
    }
}
```

## Test Organization

### Directory Structure
```
backend/
├── router/
│   ├── router.go
│   ├── router_test.go          # Unit tests
│   └── integration_test.go     # Integration tests (build tag)
├── api/
│   ├── handlers.go
│   ├── handlers_test.go
│   └── middleware_test.go
└── testutil/
    ├── mocks.go                # Shared mock implementations
    └── fixtures.go             # Test data fixtures
```

### Test Naming
- Test functions: `Test<FunctionName>`
- Benchmark functions: `Benchmark<FunctionName>`
- Example functions: `Example<FunctionName>`

## CI/CD Integration

### GitHub Actions Workflow
```yaml
- name: Run tests
  run: |
    go test -v -race -coverprofile=coverage.out ./...
    go tool cover -func=coverage.out

- name: Check coverage
  run: |
    coverage=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | sed 's/%//')
    if (( $(echo "$coverage < 70" | bc -l) )); then
      echo "Coverage $coverage% is below 70%"
      exit 1
    fi
```

## Common Anti-Patterns to Avoid

### ❌ Don't Do This
```go
// Testing implementation details instead of behavior
func TestRouterInternalState(t *testing.T) {
    router := NewRouter()
    if router.cache == nil {
        t.Error("cache should be initialized")
    }
}

// Brittle tests coupled to exact error messages
if err.Error() != "invalid token pair" {
    t.Error("wrong error message")
}
```

### ✅ Do This Instead
```go
// Test observable behavior
func TestRouterQuote(t *testing.T) {
    router := NewRouter()
    quote, err := router.Quote("XRP", "USD.rXYZ", decimal.NewFromInt(100))
    if err != nil {
        t.Errorf("Quote failed: %v", err)
    }
    if quote.Price.IsZero() {
        t.Error("expected non-zero price")
    }
}

// Test error types, not messages
if !errors.Is(err, ErrInvalidPair) {
    t.Errorf("expected ErrInvalidPair, got %v", err)
}
```

## Summary

1. Write tests for every exported function
2. Use table-driven tests
3. Test error paths and edge cases
4. Mock external dependencies
5. Maintain minimum 70% coverage
6. Security-critical code requires 80%+ coverage
7. Run tests in CI/CD pipeline
8. Keep tests simple and focused
