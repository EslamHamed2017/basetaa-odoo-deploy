#!/usr/bin/env bash
# Runs at Odoo container startup. When the Odoo image version changes (or on
# first boot), updates all tenant_* databases so the module registry is always
# current. Prevents KeyError: 'ir.http' after any Odoo image upgrade.
set -euo pipefail

VERSION_FILE="/var/lib/odoo/.odoo_schema_version"
CURRENT_VERSION=$(odoo --version 2>/dev/null | grep -oE 'Odoo Server [0-9A-Za-z.+-]+' | head -1 || echo "unknown")

echo "[startup] Odoo version: ${CURRENT_VERSION}"

if [ -f "$VERSION_FILE" ] && [ "$(cat "$VERSION_FILE")" = "$CURRENT_VERSION" ]; then
  echo "[startup] Version unchanged — tenant databases are up to date."
else
  echo "[startup] Version changed or first run — updating all tenant databases..."

  DB_URL="postgresql://${USER}:${PASSWORD}@${HOST}:${PORT:-5432}/postgres"

  TENANTS=$(psql "$DB_URL" -t -c \
    "SELECT datname FROM pg_database WHERE datname LIKE 'tenant_%' AND datistemplate = false" \
    2>/dev/null | tr -d ' ' | grep -v '^$' || true)

  if [ -z "$TENANTS" ]; then
    echo "[startup] No tenant databases found — nothing to update."
  else
    COUNT=0
    for DB in $TENANTS; do
      echo "[startup] Updating ${DB}..."
      odoo --update=base -d "$DB" --stop-after-init 2>&1 \
        | grep -E '(ERROR|modules loaded|Registry loaded)' || true
      COUNT=$((COUNT + 1))
    done
    echo "[startup] Done. Updated ${COUNT} tenant database(s)."
  fi

  echo "$CURRENT_VERSION" > "$VERSION_FILE"
fi
