#!/bin/bash
set -euo pipefail

REPO_DIR="/opt/repo/oci-apps"
BRANCH="main"
HC_ENV="/opt/secrets/healthcheck-urls.env"

cd "$REPO_DIR"
git fetch origin "$BRANCH"

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$BRANCH")

if [ "$LOCAL" != "$REMOTE" ]; then
  if ! git pull --ff-only origin "$BRANCH" 2>/dev/null; then
    echo "Fast-forward failed, local has diverged from origin/$BRANCH. Resetting." >&2
    git reset --hard "origin/$BRANCH"
  fi
fi

if [ -f "$HC_ENV" ]; then
  source "$HC_ENV"
  if [ -n "${HC_GITOPS_URL:-}" ]; then
    curl -fsS -m 10 --retry 5 -o /dev/null "$HC_GITOPS_URL" || true
  fi
fi
