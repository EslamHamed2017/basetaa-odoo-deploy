#!/usr/bin/env bash
# Backup PostgreSQL database and Odoo filestore.
# Run from the project root: bash scripts/backup.sh
set -euo pipefail

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_BACKUP="${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"
FS_BACKUP="${BACKUP_DIR}/filestore_${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

# Load .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

echo "[backup] Dumping PostgreSQL database..."
docker compose exec -T db pg_dump \
  -U "${POSTGRES_USER}" \
  -d "${POSTGRES_DB}" \
  | gzip > "$DB_BACKUP"

echo "[backup] Archiving Odoo filestore..."
docker compose exec -T odoo tar -czf - /var/lib/odoo > "$FS_BACKUP"

echo "[backup] Done."
echo "  DB backup   : $DB_BACKUP"
echo "  Filestore   : $FS_BACKUP"
