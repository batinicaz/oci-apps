#!/bin/bash
set -euo pipefail

echo "Downloading Tailscale..."
curl -fsSL https://pkgs.tailscale.com/stable/tailscale_latest_arm64.tgz -o /tmp/tailscale.tgz
tar -xzf /tmp/tailscale.tgz -C /tmp
cp /tmp/tailscale_*/tailscale /tmp/tailscale_*/tailscaled /usr/local/bin/
rm -rf /tmp/tailscale.tgz /tmp/tailscale_*
echo "Tailscale installed to /usr/local/bin/"

echo "Installing python3-pip..."
rpm-ostree install --apply-live python3-pip

echo "Installing OCI CLI and podman-compose..."
pip3 install --prefix=/usr/local oci-cli podman-compose

echo "Checking for OS updates..."
rpm-ostree upgrade || [[ $? -eq 77 ]]

echo "Removing openssh-server..."
rpm-ostree override remove openssh-server

echo "Rebooting to apply changes..."
systemctl reboot
