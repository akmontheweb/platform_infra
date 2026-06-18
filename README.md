# platform-infra

Shared infrastructure stack — Postgres (with pgvector + wal-g), Keycloak,
Redis, MinIO, LiteLLM, Caddy, Prometheus + Grafana + Alertmanager, Jaeger,
and a custom MCP service. Provisioned via Docker Compose; per-project
namespaces (DB role, Keycloak realm, MinIO bucket, LiteLLM virtual key)
are created with Terraform.

Cue and any other applications run as siblings of this repo and reach the
platform services over the external Docker network `platform-infra_default`.

## Layout

- `docker-compose.yml` — the stack. All services use `container_name:
  platform-{name}` so dependents have stable DNS.
- `services/` — locally-built images (postgres, keycloak-postgres,
  alertmanager, backup, mcp).
- `infra/` — config-only mounts (caddy, grafana, otel, prometheus,
  alertmanager templates, keycloak realm exports, litellm config).
- `terraform/` — providers (Postgres, Keycloak, MinIO) + per-project
  modules under `terraform/projects/`.
- `scripts/` — operator scripts: SOPS bootstrap, migration helpers,
  restore drills, and the production deploy entry point (`deploy.sh`).
- `.env` — cleartext local secrets, gitignored.
- `.env.production.enc` — SOPS-encrypted production secrets, committed.
- `keys/prod-age.txt` — age private key for SOPS, gitignored.

## Local development

```bash
make secrets-install      # installs sops + age into ~/.local/bin
make secrets-keygen       # one-time: generates keys/prod-age.txt
cp .env.example .env      # fill in <CHANGE_ME> values with openssl rand -hex
make up                   # docker compose up -d
make ps                   # health status (keycloak takes ~60s)
make provision PROJECT=cue   # terraform-provision the Cue namespace
```

See `SECRETS_RUNBOOK.md` for the full SOPS workflow,
`BACKUP_RUNBOOK.md` for backup/restore, and `ALERTING_RUNBOOK.md` for
the alerting stack.

## Production deployment

Deployment is driven by **GitHub Actions → SSH → `scripts/deploy.sh`** —
the same shape Cue uses. There are no automatic triggers; every deploy
is a manual `workflow_dispatch` run from the Actions tab.

Secrets and `.env` files **stay on the server**, never in GitHub.

### One-time setup

1. In GitHub → repo Settings → **Environments**, create
   `PLATFORM_INFRA_PRODUCTION` and add yourself as a required reviewer.
2. In Settings → Secrets and variables → Actions, add these repo
   secrets (shared with the Cue deploy workflow on the same server):

   | Secret | Required | Notes |
   |---|---|---|
   | `HETZNER_SSH_HOST` | yes | Server IP or hostname |
   | `HETZNER_SSH_USER` | yes | SSH login user, e.g. `deploy` |
   | `HETZNER_SSH_PRIVATE_KEY` | yes | PEM private key matching `authorized_keys` |
   | `HETZNER_SSH_HOST_KEY` | yes | Output of `ssh-keyscan -H <host>` |
   | `HETZNER_SSH_PORT` | optional | Defaults to 22 |
   | `PLATFORM_INFRA_DEPLOY_PATH` | optional | Defaults to `/home/deploy/platform_infra` |

3. On the server, make sure the repo is cloned and `.env` is populated:

   ```bash
   git clone https://github.com/<org>/platform-infra.git /home/deploy/platform_infra
   cd /home/deploy/platform_infra
   make secrets-decrypt              # produces .env.production
   cp .env.production .env           # compose reads .env by default
   ```

### Workflow inputs

Trigger from Actions → **Deploy platform-infra (Production)** → Run
workflow. Inputs:

| Input | Default | Purpose |
|---|---|---|
| `deployment_target` | `DeployPlatformInfra` | See target table below |
| `git_ref` | `main` | Branch, tag, or SHA to deploy |
| `force_clean_build` | `false` | Pass `--no-cache` to docker compose build |
| `wait_for_healthy` | `true` | Block until core services report healthy |
| `service_name` | empty | Required by `RestartService` (e.g. `grafana`) |
| `project_name` | empty | Required by `ProvisionProject` (e.g. `cue`) |
| `confirm_destructive_action` | `false` | Required by `FirstTimeSetup` |

### Targets

| Target | When to use | Disruption |
|---|---|---|
| `FirstTimeSetup` | Empty server only. Requires `confirm_destructive_action=true`. | First-time bring-up |
| `DeployPlatformInfra` | **Default.** Pull, build (cache-respecting), `up -d`. Only services whose image or config changed are recreated. | Minimal |
| `ForceRecreateAll` | After a wal-g upgrade, base-image bump, or anything that needs every container restarted. Implies `--no-cache`. | ~30-60s of Postgres/Keycloak unavailability |
| `RestartService` | Surgical: restart one named service after editing its config. Accepts bare or full names (`grafana`, `platform-grafana`). | Just that service |
| `ProvisionProject` | Idempotent `make provision PROJECT=<name>` — creates per-project DB/realm/bucket. | None |
| `BackupNow` | On-demand `pg_dump` + wal-g base backup for both PG clusters. Run before risky changes. | None |

### Safety guards in `scripts/deploy.sh`

- Every target except `FirstTimeSetup` hard-fails if any of
  `platform_postgres_data`, `platform_keycloak_postgres_data`,
  `platform_redis_data`, or `platform_minio_data` is missing — prevents
  an accidental fresh setup on a server that already has data.
- `FirstTimeSetup` requires `confirm_destructive_action=true`.
- Missing `.env` → fail fast with a hint about `make secrets-decrypt`.
- `RestartService` validates the service name against
  `docker compose config --services` before touching anything.
- `concurrency.group` in the workflow means two platform-infra deploys
  can't race; a Cue deploy can still run in parallel.

### Recommended smoke-test order on first run

1. `BackupNow` — exercises the SSH wiring and gives you a free backup.
2. `RestartService` with `service_name=grafana` — minimal blast radius.
3. `DeployPlatformInfra` on `main` with no actual change — should be
   a near no-op.

## Common operations

```bash
make ps                      # service health
make logs-keycloak           # tail one service
make restart-grafana         # restart one service
make backup-now              # on-demand pg_dump → MinIO
make wal-base-backup         # on-demand wal-g base backup
make restore-drill DB=cue    # cold-restore latest dump into a scratch container
make alerts-status           # current alert states
make alerts-test             # fire a synthetic alert end-to-end
make tf-output               # show non-sensitive terraform outputs
```

Full Makefile reference: `make help`.
