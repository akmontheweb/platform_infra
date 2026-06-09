# keycloak:26.1 digest captured 2026-06-09 — bump in same commit as a feature change
FROM quay.io/keycloak/keycloak@sha256:be6a86215213145bfb4fb3e2b3ab982a806d00262655abdcf3ffa6a38d241c7c

# Build optimised image with PostgreSQL baked in and token-exchange enabled.
# NO realm is imported at build time — realms are managed by Terraform.
RUN /opt/keycloak/bin/kc.sh build --db=postgres --features=token-exchange --health-enabled=true

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
