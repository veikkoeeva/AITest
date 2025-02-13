#!/bin/bash
set -e

echo "[Setup] Starting custom PostgreSQL initialization..."

PGDATA="/var/lib/postgresql/data"
LOCK_FILE="$PGDATA/.init_done"

# The container already runs as 'postgres'
# (thanks to the Dockerfile's "USER postgres"), so we can run commands directly.

# Check if initialization has been done already and if PostgreSQL is running.
if [ -f "$LOCK_FILE" ]; then
  echo "[Setup] Initialization already completed. Checking PostgreSQL status..."

  # 🔍 Check if PostgreSQL is running, start it if it's not
  if pg_isready --username=postgres --host=localhost; then
    echo "[Setup] PostgreSQL is already running."
  else
    echo "[Setup] PostgreSQL is not running, starting now..."
    exec postgres
  fi
fi

# If the data directory is empty, initialize the database
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "[Setup] Initializing database..."
    initdb --username=postgres
fi

# Start PostgreSQL in the background so that we can modify config files.
echo "[Setup] Starting PostgreSQL temporarily..."
pg_ctl -D "$PGDATA" -o "-c listen_addresses='*'" -w start

# Backup and update pg_hba.conf for trusted local connections
if [ -f "$PGDATA/pg_hba.conf" ]; then
    echo "[Setup] Backing up and updating pg_hba.conf..."
    cp "$PGDATA/pg_hba.conf" "${PGDATA}/pg_hba.conf.backup"
    
    cat > "$PGDATA/pg_hba.conf" <<'EOL'
# Trust authentication for local connections only
# Allow local Unix socket connections
local   all   all   trust

# Allow connections from localhost and the Docker gateway IP
host    all   all   172.17.0.1/32  trust
host    all   all   ::1/128        trust

# Deny everything else
host    all   all   0.0.0.0/0      reject
EOL

    echo "[Setup] pg_hba.conf updated."
    echo "[Setup] Updated pg_hba.conf contents:"
    cat "$PGDATA/pg_hba.conf"
else
    echo "[ERROR] pg_hba.conf not found. Aborting initialization."
    exit 1
fi

# Reload PostgreSQL configuration to apply changes
echo "[Setup] Reloading PostgreSQL configuration..."
pg_ctl reload -D "$PGDATA"

until pg_isready --username=postgres --host=localhost; do
    sleep 2
done

echo "[Setup] Running database initialization..."
psql --command="create database devaitest;"
psql --command="alter database devaitest owner to postgres;"
psql --dbname=devaitest <<EOF
create extension if not exists postgis schema public;
create extension if not exists postgis_raster schema public;
create extension if not exists postgis_topology schema topology;
create extension if not exists vector schema public;
create extension if not exists pg_duckdb schema public;
EOF

# Add pg_duckdb setting to postgresql.conf.
echo "[Setup] Configuring pg_duckdb for devaitest..."
echo "duckdb.motherduck_postgres_database = 'devaitest'" >> "$PGDATA/postgresql.conf"

# Mark initialization as done
touch "$LOCK_FILE"
echo "[Setup] Initialization complete; PostgreSQL configured for trust authentication."

# Stop the temporary PostgreSQL server
pg_ctl -D "$PGDATA" -m fast -w stop

# Finally, start PostgreSQL in the foreground
exec postgres
