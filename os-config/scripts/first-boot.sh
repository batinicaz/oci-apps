#!/bin/bash
set -euo pipefail

echo "Downloading Tailscale..."
curl -fsSL https://pkgs.tailscale.com/stable/tailscale_latest_arm64.tgz -o /tmp/tailscale.tgz
tar -xzf /tmp/tailscale.tgz -C /tmp
cp /tmp/tailscale_*/tailscale /tmp/tailscale_*/tailscaled /usr/local/bin/
rm -rf /tmp/tailscale.tgz /tmp/tailscale_*
echo "Tailscale installed to /usr/local/bin/"

echo "Installing podman-compose and uv..."
rpm-ostree install --apply-live podman-compose uv

echo "Installing oci-cli via uv..."
uv python install 3.13
UV_TOOL_BIN_DIR=/usr/local/bin uv tool install --python 3.13 oci-cli

echo "Checking for OS updates..."
rpm-ostree upgrade || [[ $? -eq 77 ]]

echo "Removing openssh-server..."
rpm-ostree override remove openssh-server

echo "Rebooting to apply changes..."
systemctl reboot
