#!/usr/bin/env bash
# Restore PostgreSQL database and Odoo filestore from a backup set.
# Usage: bash scripts/restore.sh <db_backup.sql.gz> <filestore_backup.tar.gz>
set -euo pipefail

DB_BACKUP="${1:?Usage: $0 <db_backup.sql.gz> <filestore_backup.tar.gz>}"
FS_BACKUP="${2:?Usage: $0 <db_backup.sql.gz> <filestore_backup.tar.gz>}"

# Load .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

echo "[restore] Stopping Odoo..."
docker compose stop odoo

echo "[restore] Dropping and recreating database..."
docker compose exec -T db psql -U "${POSTGRES_USER}" -c \
  "DROP DATABASE IF EXISTS \"${POSTGRES_DB}\"; CREATE DATABASE \"${POSTGRES_DB}\" OWNER \"${POSTGRES_USER}\";"

echo "[restore] Restoring database from ${DB_BACKUP}..."
gunzip -c "$DB_BACKUP" | docker compose exec -T db psql \
  -U "${POSTGRES_USER}" \
  -d "${POSTGRES_DB}"

echo "[restore] Restoring filestore from ${FS_BACKUP}..."
docker compose exec -T odoo bash -c "rm -rf /var/lib/odoo/*"
docker compose exec -T odoo tar -xzf - -C / < "$FS_BACKUP"

echo "[restore] Starting Odoo..."
docker compose start odoo

echo "[restore] Done. Visit http://localhost:8069"
