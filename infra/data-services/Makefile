# Makefile for Lucendex Data Services Management
# Provides commands for deployment, monitoring, and maintenance

.PHONY: help deploy destroy status logs ssh backup db-shell services restart indexer-deploy indexer-status indexer-logs rotate-passwords config-api config-history config-postgres

# Default target
help:
	@echo "Lucendex Data Services Management"
	@echo ""
	@echo "Available commands:"
	@echo "  make deploy       - Deploy data services infrastructure"
	@echo "  make destroy      - Destroy data services infrastructure"
	@echo "  make status       - Show status of all services"
	@echo "  make logs         - Tail logs from all services"
	@echo "  make ssh          - SSH into data services VM"
	@echo "  make backup       - Create backup of database"
	@echo "  make db-shell     - Open PostgreSQL shell"
	@echo "  make services     - List running services"
	@echo "  make restart      - Restart all services"
	@echo "  make sync-status-api     - Check rippled API sync status"
	@echo "  make sync-status-history - Check rippled history sync status"
	@echo "  make resources    - Show CPU and memory usage"

# Deploy infrastructure and services
deploy:
	@echo "Deploying data services..."
	@chmod +x data-services-deploy.sh
	@./data-services-deploy.sh

# Destroy infrastructure
destroy:
	@chmod +x data-services-destroy.sh
	@./data-services-destroy.sh

# Show service status
status:
	@echo "=== Data Services Status ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"cd /opt/lucendex/docker && docker compose ps"

# Tail logs (follow mode)
logs:
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"cd /opt/lucendex/docker && docker compose logs -f --tail=100"

# View last 100 lines without following
logs-tail:
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"cd /opt/lucendex/docker && docker compose logs --tail=100"

# Show PostgreSQL logs (for debugging)
logs-postgres:
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"docker logs lucendex-postgres 2>&1 | tail -100"

# SSH into VM
ssh:
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip)

# Create database backup
backup:
	@echo "Creating database backup..."
	@mkdir -p backups
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"docker exec lucendex-postgres pg_dump -U postgres lucendex" > backups/lucendex_$$(date +%Y%m%d_%H%M%S).sql
	@echo "✓ Backup created in backups/"

# Open PostgreSQL shell
db-shell:
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"docker exec -it lucendex-postgres psql -U postgres -d lucendex"

# List running services
services:
	@echo "=== Running Services ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# Stop all services
stop:
	@echo "Stopping all services..."
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"cd /opt/lucendex/docker && docker compose down"
	@echo "✓ Services stopped"

# Start all services
start:
	@echo "Starting all services..."
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"cd /opt/lucendex/docker && docker compose up -d"
	@echo "✓ Services started"

# Restart all services (soft restart, doesn't remount volumes)
restart:
	@echo "Restarting all services..."
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"cd /opt/lucendex/docker && docker compose restart"
	@echo "✓ Services restarted"

# Check rippled API sync status
sync-status-api:
	@echo "=== rippled API Sync Status ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		'docker exec lucendex-rippled-api rippled server_info | jq "{state: .result.info.server_state, ledgers: .result.info.complete_ledgers, peers: .result.info.peers, uptime: .result.info.uptime}"'

# Check rippled history sync status
sync-status-history:
	@echo "=== rippled Full-History Sync Status ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		'docker exec lucendex-rippled-history rippled server_info | jq "{state: .result.info.server_state, ledgers: .result.info.complete_ledgers, peers: .result.info.peers, uptime: .result.info.uptime}"'

# Show resource usage
resources:
	@echo "=== Resource Usage ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"echo '--- System ---' && free -h && echo '' && df -h / && echo '' && echo '--- Docker ---' && docker stats --no-stream"

# Deploy indexer binary and systemd service
indexer-deploy:
	@echo "Building indexer binary..."
	@cd ../../backend && go build -o indexer ./cmd/indexer
	@echo "Copying indexer to VM..."
	@scp -i terraform/data_services_ssh_key ../../backend/indexer root@$$(cd terraform && terraform output -raw data_services_ip):/opt/lucendex/
	@echo "Copying systemd service..."
	@scp -i terraform/data_services_ssh_key docker/indexer.service root@$$(cd terraform && terraform output -raw data_services_ip):/etc/systemd/system/
	@echo "Enabling and starting indexer..."
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"systemctl daemon-reload && systemctl enable indexer && systemctl start indexer"
	@echo "✓ Indexer deployed and running"

# Check indexer status
indexer-status:
	@echo "=== Indexer Status ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"systemctl status indexer --no-pager"

# View indexer logs
indexer-logs:
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"tail -f /opt/lucendex/logs/indexer.log"

# Restart indexer
indexer-restart:
	@echo "Restarting indexer..."
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"systemctl restart indexer"
	@echo "✓ Indexer restarted"

# Rotate database passwords
rotate-passwords:
	@echo "Rotating database passwords..."
	@chmod +x scripts/rotate-passwords.sh
	@./scripts/rotate-passwords.sh \
		$$(cd terraform && terraform output -raw data_services_ip) \
		terraform/data_services_ssh_key \
		terraform/.envrc

# Show rippled API configuration
config-api:
	@echo "=== rippled API Configuration ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"cat /opt/lucendex/docker/rippled-api.cfg"

# Show rippled History configuration
config-history:
	@echo "=== rippled Full-History Configuration ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"cat /opt/lucendex/docker/rippled-history.cfg"

# Show PostgreSQL configuration
config-postgres:
	@echo "=== PostgreSQL Configuration ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"cat /opt/lucendex/docker/postgresql.conf"

# Show all configurations
config: config-api config-history config-postgres
	@echo ""
	@echo "✓ All configurations displayed above"

# Update rippled API configuration
update-config-api:
	@echo "Uploading rippled API configuration..."
	@scp -i terraform/data_services_ssh_key docker/rippled-api.cfg root@$$(cd terraform && terraform output -raw data_services_ip):/opt/lucendex/docker/
	@echo "✓ Configuration uploaded. Restart required: make restart"

# Update rippled History configuration
update-config-history:
	@echo "Uploading rippled History configuration..."
	@scp -i terraform/data_services_ssh_key docker/rippled-history.cfg root@$$(cd terraform && terraform output -raw data_services_ip):/opt/lucendex/docker/
	@echo "✓ Configuration uploaded. Restart required: make restart"

# Update PostgreSQL configuration
update-config-postgres:
	@echo "Uploading PostgreSQL configuration..."
	@scp -i terraform/data_services_ssh_key docker/postgresql.conf root@$$(cd terraform && terraform output -raw data_services_ip):/opt/lucendex/docker/
	@echo "✓ Configuration uploaded. Restart required: make restart"

# Update validators.txt
update-validators:
	@echo "Uploading validators.txt..."
	@scp -i terraform/data_services_ssh_key docker/validators.txt root@$$(cd terraform && terraform output -raw data_services_ip):/opt/lucendex/docker/
	@echo "✓ Validators list uploaded. Restart required: make restart"

# Production Diagnostics
validators-api:
	@echo "=== API Node Validators Status ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		'docker exec lucendex-rippled-api rippled validators | jq "{status: .result.validator_list.status, expiration: .result.validator_list.expiration, count: .result.validator_list.count, quorum: .result.validation_quorum}"'

validators-history:
	@echo "=== History Node Validators Status ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		'docker exec lucendex-rippled-history rippled validators | jq "{status: .result.validator_list.status, expiration: .result.validator_list.expiration, count: .result.validator_list.count, quorum: .result.validation_quorum}"'

peers-api:
	@echo "=== API Node Peers ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		'docker exec lucendex-rippled-api rippled peers | jq "{peer_count: (.result.peers | length), peers: [.result.peers[] | {address, version, uptime}]}"'

peers-history:
	@echo "=== History Node Peers ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		'docker exec lucendex-rippled-history rippled peers | jq "{peer_count: (.result.peers | length), peers: [.result.peers[] | {address, version, uptime}]}"'

db-health:
	@echo "=== Database Health Check ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		'docker exec lucendex-postgres psql -U postgres -d lucendex -c "SELECT version();" && echo "" && docker exec lucendex-postgres psql -U postgres -d lucendex -c "SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'"'"'.'"'"'||tablename)) AS size FROM pg_tables WHERE schemaname = '"'"'public'"'"' ORDER BY pg_total_relation_size(schemaname||'"'"'.'"'"'||tablename) DESC;"'

disk-space:
	@echo "=== Disk Space Check ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"df -h / && echo '' && echo '=== API Node DB ===' && du -sh /var/lib/rippled/api/db/ 2>/dev/null || echo 'Not found' && echo '' && echo '=== History Node DB ===' && du -sh /var/lib/rippled/history/db/ 2>/dev/null || echo 'Not found'"

network-test:
	@echo "=== Network Connectivity Test ==="
	@echo "Testing API node RPC (port 51234)..."
	@curl -s --max-time 5 http://$$(cd terraform && terraform output -raw data_services_ip):51234 -X POST -H "Content-Type: application/json" -d '{"method":"server_info"}' | jq '.result.info.server_state' || echo "❌ API RPC not reachable"
	@echo ""
	@echo "Testing peer ports..."
	@nc -zv $$(cd terraform && terraform output -raw data_services_ip) 51235 2>&1 | grep -q succeeded && echo "✓ API peer port 51235 open" || echo "❌ API peer port 51235 closed"
	@nc -zv $$(cd terraform && terraform output -raw data_services_ip) 51236 2>&1 | grep -q succeeded && echo "✓ History peer port 51236 open" || echo "❌ History peer port 51236 closed"

health-check:
	@echo "╔════════════════════════════════════════════════════════════════╗"
	@echo "║          Lucendex Data Services - Health Check                ║"
	@echo "╚════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "=== Container Status ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"docker ps --format 'table {{.Names}}\t{{.Status}}' --filter name=lucendex"
	@echo ""
	@echo "=== API Node Sync ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		'docker exec lucendex-rippled-api rippled server_info 2>/dev/null | jq -r ".result.info | \"State: \(.server_state)\nLedgers: \(.complete_ledgers)\nPeers: \(.peers)\nUptime: \(.uptime)s\""'
	@echo ""
	@echo "=== History Node Sync ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		'docker exec lucendex-rippled-history rippled server_info 2>/dev/null | jq -r ".result.info | \"State: \(.server_state)\nLedgers: \(.complete_ledgers)\nPeers: \(.peers)\nUptime: \(.uptime)s\""'
	@echo ""
	@echo "=== Validator List Status ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		'docker exec lucendex-rippled-api rippled validators 2>/dev/null | jq -r ".result.validator_list | \"Status: \(.status)\nExpiration: \(.expiration)\nCount: \(.count)\""'
	@echo ""
	@echo "=== Database ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		'docker exec lucendex-postgres psql -U postgres -d lucendex -t -c "SELECT COUNT(*) FROM pg_tables WHERE schemaname = '"'"'public'"'"';" 2>/dev/null | xargs -I{} echo "Tables: {}"'
	@echo ""
	@echo "=== Disk Usage ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"df -h / | tail -1 | awk '{print \"Root: \"\$$3\" used of \"\$$2\" (\"\$$5\")\"}'"
	@echo ""
	@echo "✓ Health check complete"

logs-api:
	@echo "=== API Node Logs (last 50 lines) ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"docker logs --tail 50 lucendex-rippled-api 2>&1"

logs-history:
	@echo "=== History Node Logs (last 50 lines) ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		"docker logs --tail 50 lucendex-rippled-history 2>&1"

logs-errors:
	@echo "=== Recent Errors (all services) ==="
	@ssh -i terraform/data_services_ssh_key root@$$(cd terraform && terraform output -raw data_services_ip) \
		'docker logs lucendex-rippled-api 2>&1 | grep -i error | tail -20 && echo "" && docker logs lucendex-rippled-history 2>&1 | grep -i error | tail -20 && echo "" && docker logs lucendex-postgres 2>&1 | grep -i error | tail -20'
