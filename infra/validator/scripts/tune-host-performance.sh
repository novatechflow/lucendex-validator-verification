#!/bin/bash
set -euo pipefail

# Host Performance Tuning for XRPL Validator
# Reduces I/O pressure during sync

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "XRPL Validator Host Performance Tuning"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Reduce swappiness
log_info "1. Reducing swappiness (minimize swap usage)..."
CURRENT_SWAPPINESS=$(cat /proc/sys/vm/swappiness)
log_info "Current swappiness: ${CURRENT_SWAPPINESS}"

if [ "$CURRENT_SWAPPINESS" -gt 10 ]; then
    sysctl vm.swappiness=10
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    log_info "✓ Swappiness set to 10 (was ${CURRENT_SWAPPINESS})"
else
    log_info "✓ Swappiness already optimal (${CURRENT_SWAPPINESS})"
fi
echo ""

# 2. Check mount options
log_info "2. Checking filesystem mount options..."
MOUNT_INFO=$(mount | grep "on / type")
log_info "Root mount: ${MOUNT_INFO}"

if echo "$MOUNT_INFO" | grep -q "noatime"; then
    log_info "✓ noatime already enabled"
else
    log_warn "⚠️  noatime not enabled - reduces write overhead"
    log_warn "To enable: Add 'noatime' to /etc/fstab and remount"
    log_warn "Example: UUID=xxx / ext4 defaults,noatime 0 1"
fi
echo ""

# 3. Check storage type
log_info "3. Verifying storage type..."
DISK_TYPE=$(lsblk -d -o name,rota | grep vda | awk '{print $2}')
if [ "$DISK_TYPE" = "0" ]; then
    log_info "✓ Using SSD (rotation=0)"
else
    log_warn "⚠️  Disk may be HDD (rotation=${DISK_TYPE})"
fi
echo ""

# 4. I/O scheduler
log_info "4. Checking I/O scheduler..."
SCHEDULER=$(cat /sys/block/vda/queue/scheduler | grep -o '\[.*\]' | tr -d '[]')
log_info "Current scheduler: ${SCHEDULER}"

if [ "$SCHEDULER" = "none" ] || [ "$SCHEDULER" = "mq-deadline" ]; then
    log_info "✓ Optimal I/O scheduler for SSD"
else
    log_warn "⚠️  Consider switching to 'none' or 'mq-deadline' for SSD"
    log_warn "Command: echo none > /sys/block/vda/queue/scheduler"
fi
echo ""

# 5. Transparent Huge Pages
log_info "5. Checking Transparent Huge Pages..."
THP_STATUS=$(cat /sys/kernel/mm/transparent_hugepage/enabled | grep -o '\[.*\]' | tr -d '[]')
log_info "THP status: ${THP_STATUS}"

if [ "$THP_STATUS" = "never" ] || [ "$THP_STATUS" = "madvise" ]; then
    log_info "✓ THP optimized for database workloads"
else
    log_warn "⚠️  Consider disabling THP for better performance"
    log_warn "Command: echo never > /sys/kernel/mm/transparent_hugepage/enabled"
fi
echo ""

# 6. Summary
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ Host Performance Tuning Complete"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Applied Changes:"
echo "  • vm.swappiness=10 (persistent)"
echo ""
log_info "Recommendations:"
echo "  • Enable noatime in /etc/fstab (reduces writes)"
echo "  • Verify using local SSD (not networked storage)"
echo "  • Consider I/O scheduler tuning for SSDs"
echo ""
log_info "Next: Deploy updated Docker config and restart validator"
echo ""
