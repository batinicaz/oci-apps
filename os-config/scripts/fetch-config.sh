#!/bin/bash
set -euo pipefail

MAX_ATTEMPTS=20
DELAY=30
BUCKET_NAME="$1"
BUCKET_NAMESPACE="$2"
TEMP_DIR="/tmp/oci-config-download"
REPO_URL="https://github.com/batinicaz/oci-apps.git"
REPO_DIR="/opt/repo/oci-apps"
REPO_BRANCH="main"

download_with_retries() {
  local prefix=$1
  local dest=$2
  local attempt=1

  mkdir -p "$dest"
  rm -rf "$TEMP_DIR"
  mkdir -p "$TEMP_DIR"

  while (( attempt <= MAX_ATTEMPTS )); do
    echo "Attempt $attempt/$MAX_ATTEMPTS: Downloading $prefix to $dest"

    set +e
    oci os object bulk-download \
      --auth instance_principal \
      --namespace "$BUCKET_NAMESPACE" \
      --bucket-name "$BUCKET_NAME" \
      --prefix "$prefix" \
      --download-dir "$TEMP_DIR" \
      --overwrite
    local status=$?
    set -e

    if [ $status -eq 0 ]; then
      if [ -d "$TEMP_DIR/$prefix" ]; then
        cp -r "$TEMP_DIR/$prefix"* "$dest/"
      fi
      rm -rf "$TEMP_DIR"
      return 0
    fi

    if (( attempt >= MAX_ATTEMPTS )); then
      echo "Failed after $MAX_ATTEMPTS attempts"
      exit 1
    fi

    echo "Download failed, retrying in ${DELAY}s..."
    sleep $DELAY
    (( attempt++ ))
  done
}

echo "Fetching configuration from OCI bucket..."

download_with_retries "config/quadlets/" "/etc/containers/systemd"
download_with_retries "config/systemd/" "/etc/systemd/system"
download_with_retries "config/infisical-config/" "/root/.config/infisical"
download_with_retries "config/traefik-config/" "/root/.config/traefik"
download_with_retries "config/autorestic-config/" "/root/.config/autorestic"

echo "Cloning application repository..."
mkdir -p "$(dirname "$REPO_DIR")"
git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"
ln -s "$REPO_DIR/containers" /opt/containers

restorecon -R /etc/containers/systemd
restorecon -R /etc/systemd/system

systemctl daemon-reload

systemctl enable --now \
  freshrss.path \
  planka.path \
  nitter.path \
  redlib.path \
  languagetool.path \
  app-backup.timer \
  app-prune.timer \
  gitops-sync.timer

# LanguageTool has no Infisical secrets, so unlike other services it won't be
# triggered by a .path unit watching /opt/secrets/*.env. Start it directly.
# --no-block is required: languagetool.service requires ghcr-login.service,
# which waits on fetch-bootstrap-secrets.service, which waits on this script
# to finish. Blocking here would deadlock the boot chain.
systemctl enable --now --no-block languagetool.service

echo "Configuration fetch complete"
