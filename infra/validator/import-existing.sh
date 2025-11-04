#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/terraform"
source .envrc

echo "Initializing Terraform..."
terraform init

# Get token
T=$(curl -s -d "client_id=$CONTABO_CLIENT_ID" -d "client_secret=$CONTABO_CLIENT_SECRET" \
    --data-urlencode "username=$CONTABO_API_USER" --data-urlencode "password=$CONTABO_API_PASSWORD" \
    -d 'grant_type=password' 'https://auth.contabo.com/auth/realms/contabo/protocol/openid-connect/token' | jq -r '.access_token')

# List instances
RESP=$(curl -s "https://api.contabo.com/v1/compute/instances" \
    -H "Authorization: Bearer $T" -H "x-request-id: $(uuidgen)")

echo ""
echo "Your instances:"
echo "$RESP" | jq -r '.data[]? | "\(.instanceId)  \(.displayName)  \(.ipConfig.v4.ip // "no-ip")"'

echo ""
read -p "Enter instance ID: " ID

terraform import contabo_instance.validator "$ID"

echo "✓ Imported ID $ID"
