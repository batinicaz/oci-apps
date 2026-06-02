command -v oci >/dev/null || pip install -q oci-cli

export OCI_CLI_USER="${TF_VAR_oci_user_id:?}"
export OCI_CLI_FINGERPRINT="${TF_VAR_oci_fingerprint:?}"
export OCI_CLI_TENANCY="${TF_VAR_oci_tenancy_id:?}"
export OCI_CLI_REGION="${TF_VAR_oci_region:?}"
export OCI_CLI_KEY_CONTENT="${TF_VAR_oci_private_key:?}"
