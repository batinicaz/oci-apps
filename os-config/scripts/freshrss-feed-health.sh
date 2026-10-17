#!/bin/bash
set -euo pipefail

DB="/opt/data/freshrss/config/users/zak@dcu.sh/db.sqlite"
SQLITE_IMAGE="docker.io/alpine/sqlite:3.51.2"
NAMESPACE="rss_feed_health"
CHUNK_SIZE=50
USER_AGENT="FreshRSS/1.30.0 (Linux; https://freshrss.org)"
IMDS="http://169.254.169.254/opc/v2/instance"

imds() {
    curl -fsS -H "Authorization: Bearer Oracle" "$IMDS/$1"
}

COMPARTMENT=$(imds compartmentId)
ENDPOINT="https://telemetry-ingestion.$(imds canonicalRegionName).$(imds regionInfo/realmDomainComponent)"
NOW=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

is_broken() {
    local response code body items stubs
    response=$(podman exec fulltextrss curl -sL -m 25 -A "$USER_AGENT" -w '\n%{http_code}' "$1" || true)
    code=${response##*$'\n'}
    body=${response%$'\n'*}
    items=$({ grep -o -E '<(item|entry)[[:space:]>]' <<< "$body" || true; } | wc -l)
    stubs=$({ grep -o 'unable to retrieve full-text content' <<< "$body" || true; } | wc -l)
    if [[ "$code" != "200" || "$items" -eq 0 || $((stubs * 2)) -ge "$items" ]]; then
        echo 1
    else
        echo 0
    fi
}

podman run --rm --log-driver none -v "$DB:/db.sqlite:ro,z" "$SQLITE_IMAGE" -separator $'\t' /db.sqlite \
    "SELECT id, name, url FROM feed WHERE ttl >= 0 ORDER BY id" |
while IFS=$'\t' read -r id name url; do
    feed="$id $name"
    jq -nc \
        --arg namespace "$NAMESPACE" \
        --arg compartment "$COMPARTMENT" \
        --arg feed "${feed:0:200}" \
        --arg timestamp "$NOW" \
        --argjson value "$(is_broken "${url//&amp;/&}")" \
        '{namespace: $namespace, compartmentId: $compartment, name: "feed_broken",
          dimensions: {feed: $feed}, datapoints: [{timestamp: $timestamp, value: $value}]}'
done > "$WORK/metrics.jsonl"

split -l "$CHUNK_SIZE" "$WORK/metrics.jsonl" "$WORK/chunk-"
for chunk in "$WORK"/chunk-*; do
    jq -sc . "$chunk" > "$chunk.json"
    oci monitoring metric-data post \
        --auth instance_principal \
        --endpoint "$ENDPOINT" \
        --metric-data "file://$chunk.json" \
        --query 'data."failed-metrics-count"' --raw-output
done
