#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/oci-cli-env.sh"

: "${FCOS_VERSION:?}"
: "${FCOS_BUILD_URL:?}"
: "${FCOS_SHA256:?}"
: "${FCOS_UNCOMPRESSED_SHA256:?}"
: "${FCOS_OBJECT_NAME:?}"
: "${OCI_NAMESPACE:?}"
: "${OCI_BUCKET:?}"

LOCAL="/tmp/fcos-${FCOS_VERSION}-oraclecloud.aarch64.qcow2"

curl -sfL -o "${LOCAL}.xz" "${FCOS_BUILD_URL}/${FCOS_OBJECT_NAME}.xz"
echo "${FCOS_SHA256}  ${LOCAL}.xz" | sha256sum -c -
xz -d "${LOCAL}.xz"
echo "${FCOS_UNCOMPRESSED_SHA256}  ${LOCAL}" | sha256sum -c -

oci os object put \
  --namespace "${OCI_NAMESPACE}" \
  --bucket-name "${OCI_BUCKET}" \
  --file "${LOCAL}" \
  --name "${FCOS_OBJECT_NAME}" \
  --force

rm -f "${LOCAL}"
