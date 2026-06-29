variable "project_name" {
  description = "Unique identifier for the project (lowercase, hyphens ok). Used as DB name, KC realm, MinIO prefix."
  type        = string
}

variable "project_display_name" {
  description = "Human-readable project name shown in Keycloak UI"
  type        = string
  default     = ""
}

variable "domain" {
  description = "Project subdomain (e.g. cue.yourdomain.com) — for Caddy routing"
  type        = string
}

variable "app_base_url" {
  description = "Full base URL of the project's frontend app (for Keycloak CORS + redirect)"
  type        = string
}

variable "redis_db" {
  description = "Redis logical DB number for this project (2–15; 0=reserved, 1=LiteLLM)"
  type        = number

  validation {
    condition     = var.redis_db >= 2 && var.redis_db <= 15
    error_message = "Redis DB must be between 2 and 15 (0=reserved, 1=LiteLLM cache)."
  }
}

variable "redis_password" {
  description = "platform-redis password (matches PLATFORM_REDIS_PASSWORD on the platform-infra .env). Embedded into the generated .env.platform's REDIS_URL so consumers can authenticate."
  type        = string
  sensitive   = true
}

variable "litellm_budget_tokens" {
  description = "Monthly LLM token budget for this project (integer token count)"
  type        = number
  default     = 2000000
}

variable "litellm_url" {
  description = "LiteLLM proxy URL accessible from Terraform runner"
  type        = string
  default     = "http://localhost:4001"
}

variable "litellm_master_key" {
  description = "LiteLLM master key for virtual key generation"
  type        = string
  sensitive   = true
}

variable "api_container_port" {
  description = "Internal port of the project's API container (for Caddy routing)"
  type        = number
  default     = 8000
}

# ---------------------------------------------------------------------------
# Bootstrap admin user — optional. When username is set, the BOOTSTRAP_ADMIN_*
# block is rendered into the project's .env.platform so consume-platform.sh
# can overlay it onto the project's .env, where scripts/grant-admin.sh
# --bootstrap reads it via get_env. Leaving username blank skips the block
# entirely — the consumer-side bootstrap step is a no-op when unset.
# ---------------------------------------------------------------------------
variable "bootstrap_admin_username" {
  description = "Bootstrap admin Keycloak username (also stored as cue.users.email). Empty = skip."
  type        = string
  default     = ""
}

variable "bootstrap_admin_email" {
  description = "Bootstrap admin email (defaults to username if blank and username looks like an email)"
  type        = string
  default     = ""
}

variable "bootstrap_admin_password" {
  description = "Bootstrap admin initial password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "bootstrap_admin_first_name" {
  description = "Bootstrap admin first name"
  type        = string
  default     = ""
}

variable "bootstrap_admin_last_name" {
  description = "Bootstrap admin last name"
  type        = string
  default     = ""
}
