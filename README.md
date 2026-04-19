# basetaa-odoo-deploy

Single-tenant Odoo 17 Community deployment using Docker Compose.

## Stack

| Component  | Image            |
|------------|------------------|
| Odoo       | `odoo:17.0`      |
| PostgreSQL | `postgres:15`    |

## Quick start

### 1. Clone the repository

```bash
git clone <your-repo-url> /opt/basetaa-odoo-deploy
cd /opt/basetaa-odoo-deploy
```

### 2. Create the environment file

```bash
cp .env.example .env
```

Edit `.env` and set strong values:

```
POSTGRES_DB=odoo
POSTGRES_USER=odoo
POSTGRES_PASSWORD=<strong password>
```

### 3. Set the Odoo master password

Edit `config/odoo.conf` and change:

```ini
admin_passwd = CHANGE_ME_BEFORE_FIRST_RUN
```

This password protects the database manager at `/web/database/manager`.

### 4. Start the stack

```bash
docker compose up -d
```

### 5. First run

Open `http://<server-ip>:8069` in your browser.
Odoo will show the database creation screen — fill in your details and create the database named `odoo` (must match `db_name` in `odoo.conf`).

## Ports

| Port | Service             |
|------|---------------------|
| 8069 | Odoo HTTP           |
| 8072 | Longpolling (active only when `workers > 0`) |

PostgreSQL is internal only and not exposed to the host.

## Volumes

| Volume       | Purpose                    |
|--------------|----------------------------|
| `db-data`    | PostgreSQL data directory  |
| `odoo-data`  | Odoo filestore             |

## Useful commands

```bash
# View logs
docker compose logs -f odoo

# Shell into Odoo container
docker compose exec odoo bash

# Shell into PostgreSQL
docker compose exec db psql -U odoo -d odoo

# Stop stack
docker compose down

# Stop and remove volumes (DESTRUCTIVE — all data lost)
docker compose down -v
```

## Backup

```bash
bash scripts/backup.sh
```

Backups are written to `./backups/` with a timestamp.

## Restore

```bash
bash scripts/restore.sh backups/db_<timestamp>.sql.gz backups/filestore_<timestamp>.tar.gz
```

## Scaling workers (optional)

To handle more concurrent users, edit `config/odoo.conf`:

```ini
workers = 4   ; must be even
```

Then restart: `docker compose restart odoo`

Port 8072 (longpolling) becomes active and should be proxied by Nginx.

## Directory layout

```
basetaa-odoo-deploy/
├── .env.example        # Environment variable template
├── .gitignore
├── README.md
├── docker-compose.yml
├── config/
│   └── odoo.conf       # Odoo configuration (edit admin_passwd here)
├── addons/             # Custom/community addons (drop .zip or module folder here)
│   └── .gitkeep
└── scripts/
    ├── backup.sh
    └── restore.sh
```
