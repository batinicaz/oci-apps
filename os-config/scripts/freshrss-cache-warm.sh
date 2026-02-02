#!/bin/bash
set -euo pipefail

DATA_DIR="/opt/data/freshrss/config/users"
SQLITE_IMAGE="docker.io/alpine/sqlite:3.51.2"

get_feeds() {
    find "$DATA_DIR" -maxdepth 2 -name 'db.sqlite' ! -path '*/_/*' -print0 2>/dev/null | \
    while IFS= read -r -d '' db; do
        podman run --rm -v "${db}:/db.sqlite:ro,z" "$SQLITE_IMAGE" \
            /db.sqlite "SELECT url FROM feed WHERE url LIKE '%makefulltextfeed%'" 2>/dev/null || true
    done
}

FEEDS=$(get_feeds | sort -u | grep '^http' || true)
[[ -z "$FEEDS" ]] && { echo "No fulltextrss feeds found"; exit 0; }

echo "Warming $(wc -l <<< "$FEEDS") feeds..."

for _ in {1..30}; do
    podman exec fulltextrss curl -sf http://localhost/index.php >/dev/null 2>&1 && break
    sleep 1
done

xargs -P5 -I{} podman exec fulltextrss curl -sm120 "{}" -o /dev/null 2>/dev/null <<< "$FEEDS" || true

echo "Done"
