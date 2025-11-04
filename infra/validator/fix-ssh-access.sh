#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/terraform"
source .envrc

# Get token
T=$(curl -s -d "client_id=$CONTABO_CLIENT_ID" -d "client_secret=$CONTABO_CLIENT_SECRET" \
    --data-urlencode "username=$CONTABO_API_USER" --data-urlencode "password=$CONTABO_API_PASSWORD" \
    -d 'grant_type=password' 'https://auth.contabo.com/auth/realms/contabo/protocol/openid-connect/token' | jq -r '.access_token')

# Get instance ID
ID=$(curl -s "https://api.contabo.com/v1/compute/instances" \
    -H "Authorization: Bearer $T" -H "x-request-id: $(uuidgen)" \
    | jq -r '.data[] | select(.displayName | contains("validator")) | .instanceId')

echo "Instance: $ID"

# Create SSH secret
SID=$(curl -s -X POST "https://api.contabo.com/v1/secrets" \
    -H "Authorization: Bearer $T" -H "x-request-id: $(uuidgen)" -H "Content-Type: application/json" \
    -d "{\"name\":\"ssh-fix-$(date +%s)\",\"type\":\"ssh\",\"value\":\"$(cat validator_ssh_key.pub)\"}" \
    | jq -r '.data[0].secretId')

echo "Secret: $SID"

# Reset password with SSH
curl -X POST "https://api.contabo.com/v1/compute/instances/$ID/actions/resetPassword" \
    -H "Authorization: Bearer $T" -H "x-request-id: $(uuidgen)" -H "Content-Type: application/json" \
    -d "{\"sshKeys\":[$SID]}" | jq

echo "✓ Done. Wait 2min then: make ssh"
