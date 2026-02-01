#!/bin/bash
set -euo pipefail

REPO_DIR="/opt/repo/oci-apps"
BRANCH="main"

cd "$REPO_DIR"
git fetch origin "$BRANCH"

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$BRANCH")

if [ "$LOCAL" != "$REMOTE" ]; then
  git pull --ff-only origin "$BRANCH"
fi
