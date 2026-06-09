# =============================================================================
# Terraform state backend — platform-infra's own MinIO (S3-compatible)
# =============================================================================
# Bootstrap and credentials live in `../SECRETS_RUNBOOK.md` §5.
#
# Operator workflow:
#   cd terraform
#   terraform init \
#     -backend-config="access_key=$TF_BACKEND_ACCESS_KEY" \
#     -backend-config="secret_key=$TF_BACKEND_SECRET_KEY"
#
# State versioning is enabled on the bucket so prior states are recoverable.
# Native lockfile-based locking (Terraform 1.11+) is enabled via
# `use_lockfile = true` — no DynamoDB needed.
#
# Same-host caveat: state lives on the same Hetzner box as the platform.
# Protects against concurrent-apply races; does NOT protect against host
# failure. Matches the backup posture (see PRODUCTION_LAUNCH_PLAN.md §4).
# =============================================================================

terraform {
  backend "s3" {
    bucket = "platform-tfstate"
    key    = "platform-infra/terraform.tfstate"
    region = "us-east-1"   # MinIO ignores this but the provider requires it

    endpoints = {
      s3 = "http://platform-minio:9000"
    }

    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true

    # Terraform 1.11+ native lockfile locking — replaces DynamoDB.
    use_lockfile = true

    # Encryption-at-rest within MinIO. Bucket policy should also enforce SSE-S3.
    encrypt = true
  }
}
