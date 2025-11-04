#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"

INSTANCE_ID=$(cd "$TERRAFORM_DIR" && terraform output -raw data_services_id 2>/dev/null || echo "unknown")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  Manual Destruction Required"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Contabo API doesn't support automated destroy."
echo ""
echo "Manual steps:"
echo "1. Go to https://my.contabo.com"
echo "2. Delete instance ID: $INSTANCE_ID"
echo ""
echo "Then clean local state:"
echo "  cd infra/data-services/terraform"
echo "  rm -rf .terraform* *.tfstate* tfplan data_services_ssh_key*"
echo ""
