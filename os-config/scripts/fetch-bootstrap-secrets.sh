#!/bin/bash
set -euo pipefail

# Fetch secrets using instance principal (no credentials needed)
CLIENT_ID=$(oci secrets secret-bundle get \
  --auth instance_principal \
  --secret-id "$VAULT_SECRET_ID_CLIENT_ID" \
  --query 'data."secret-bundle-content".content' \
  --raw-output | base64 -d)

CLIENT_SECRET=$(oci secrets secret-bundle get \
  --auth instance_principal \
  --secret-id "$VAULT_SECRET_ID_CLIENT_SECRET" \
  --query 'data."secret-bundle-content".content' \
  --raw-output | base64 -d)

RESTIC_PASSWORD=$(oci secrets secret-bundle get \
  --auth instance_principal \
  --secret-id "$VAULT_SECRET_ID_RESTIC_PASSWORD" \
  --query 'data."secret-bundle-content".content' \
  --raw-output | base64 -d)

# Validate secrets were fetched
if [[ -z "$CLIENT_ID" || -z "$CLIENT_SECRET" || -z "$RESTIC_PASSWORD" ]]; then
    echo "Failed to fetch secrets from OCI Vault" >&2
    exit 1
fi

# Write to memory-backed tmpfs with secure permissions from the start
umask 077
mkdir -p /run/secrets
echo -n "$CLIENT_ID" > /run/secrets/infisical-client-id
echo -n "$CLIENT_SECRET" > /run/secrets/infisical-client-secret

echo "$RESTIC_PASSWORD" > /run/secrets/restic-password

echo "Starting infisical-agent..."
systemctl start --no-block infisical-agent.service

echo "Starting Traefik..."
systemctl start --no-block traefik.service
