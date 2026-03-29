#!/usr/bin/env bash
set -euo pipefail

command -v oci >/dev/null || pip install -q oci-cli

export OCI_CLI_USER="${TF_VAR_oci_user_id:?}"
export OCI_CLI_FINGERPRINT="${TF_VAR_oci_fingerprint:?}"
export OCI_CLI_TENANCY="${TF_VAR_oci_tenancy_id:?}"
export OCI_CLI_REGION="${TF_VAR_oci_region:?}"
export OCI_CLI_KEY_CONTENT="${TF_VAR_oci_private_key:?}"

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
  --no-multipart

rm -f "${LOCAL}"
