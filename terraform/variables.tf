# ---------------------------------------------------------------------------
# Platform connection variables — read from environment (TF_VAR_*)
# or set via terraform.tfvars
# ---------------------------------------------------------------------------

variable "pg_host" {
  description = "Hostname / IP of platform-postgres (accessible from Terraform runner). Terraform runs on the host docker network on both dev and prod, so localhost + the compose-mapped port works in both environments."
  type        = string
  default     = "127.0.0.1"
}

variable "pg_port" {
  description = "External port of platform-postgres"
  type        = number
  default     = 5433
}

variable "pg_superuser" {
  description = "PostgreSQL superuser name"
  type        = string
  default     = "platform"
}

variable "pg_superpassword" {
  description = "PostgreSQL superuser password"
  type        = string
  sensitive   = true
}

variable "kc_admin_user" {
  description = "Keycloak bootstrap admin username"
  type        = string
  default     = "admin"
}

variable "kc_admin_password" {
  description = "Keycloak bootstrap admin password"
  type        = string
  sensitive   = true
}

variable "kc_url" {
  description = "Keycloak base URL (accessible from Terraform runner). Same default on dev + prod: terraform runs on the host, Keycloak is host-mapped to 8081."
  type        = string
  default     = "http://127.0.0.1:8081"
}

variable "minio_server" {
  description = "MinIO server address (host:port, accessible from Terraform runner). Compose maps 9000→9002 on the host on both dev and prod."
  type        = string
  default     = "127.0.0.1:9002"
}

variable "minio_root_user" {
  description = "MinIO root user"
  type        = string
  default     = "platform"
}

variable "minio_root_password" {
  description = "MinIO root password"
  type        = string
  sensitive   = true
}

variable "litellm_url" {
  description = "LiteLLM proxy base URL (accessible from Terraform runner). Compose maps 4000→4001 on the host on both dev and prod."
  type        = string
  default     = "http://127.0.0.1:4001"
}

variable "litellm_master_key" {
  description = "LiteLLM master key for virtual key management"
  type        = string
  sensitive   = true
}

variable "redis_host" {
  description = "Redis hostname (accessible from Terraform runner). Compose maps 6379→6380 on the host on both dev and prod."
  type        = string
  default     = "127.0.0.1"
}

variable "redis_port" {
  description = "Redis external port"
  type        = number
  default     = 6380
}

variable "redis_password" {
  description = "platform-redis password — embedded into per-project .env.platform REDIS_URL so consumers can authenticate"
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Platform MCP variables — secrets / config for the shared MCP tool server
# ---------------------------------------------------------------------------

variable "mcp_api_key" {
  description = "API key used by project services to authenticate against platform-mcp"
  type        = string
  sensitive   = true
}

variable "mcp_smtp_host" {
  description = "SMTP server hostname for platform-mcp email tool"
  type        = string
  default     = ""
}

variable "mcp_smtp_port" {
  description = "SMTP server port"
  type        = number
  default     = 587
}

variable "mcp_smtp_user" {
  description = "SMTP username"
  type        = string
  default     = ""
}

variable "mcp_smtp_password" {
  description = "SMTP password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "mcp_smtp_from" {
  description = "Default From address for platform-mcp emails"
  type        = string
  default     = "noreply@example.com"
}

variable "mcp_twilio_account_sid" {
  description = "Twilio Account SID for platform-mcp SMS tool"
  type        = string
  default     = ""
}

variable "mcp_twilio_auth_token" {
  description = "Twilio Auth Token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "mcp_twilio_phone_number" {
  description = "Twilio phone number (E.164 format) for platform-mcp SMS tool"
  type        = string
  default     = ""
}

variable "mcp_tavily_api_key" {
  description = "Tavily API key for platform-mcp web search / nearby places tool"
  type        = string
  sensitive   = true
  default     = ""
}

variable "domain" {
  description = "Root domain for the platform (e.g. latenightcraft.com)"
  type        = string
  default     = "latenightcraft.com"
}

variable "server_ip" {
  description = "Public IP of the server"
  type        = string
  default     = "178.156.235.155"
}

# ---------------------------------------------------------------------------
# Bootstrap admin user — auto-provisioned into the cue realm by
# cue/scripts/grant-admin.sh --bootstrap as the final step of FirstTimeSetup.
# Plumbed from platform-infra/.env BOOTSTRAP_ADMIN_* into cue's .env.platform
# (via the project module's env.tpl), then overlaid onto cue/.env by
# consume-platform.sh. Leave blank to skip bootstrap (e.g. on dev).
# ---------------------------------------------------------------------------
variable "bootstrap_admin_username" {
  description = "Username for the cue-web bootstrap admin (Keycloak username + cue.users.email)"
  type        = string
  default     = ""
}

variable "bootstrap_admin_email" {
  description = "Email for the bootstrap admin (defaults to username if it looks like an email)"
  type        = string
  default     = ""
}

variable "bootstrap_admin_password" {
  description = "Initial password for the bootstrap admin"
  type        = string
  sensitive   = true
  default     = ""
}

variable "bootstrap_admin_first_name" {
  description = "First name of the bootstrap admin"
  type        = string
  default     = ""
}

variable "bootstrap_admin_last_name" {
  description = "Last name of the bootstrap admin"
  type        = string
  default     = ""
}
